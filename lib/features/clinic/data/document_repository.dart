import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/clinic_document_model.dart';
import '../models/clinic_enums.dart';
import '../models/health_worker_models.dart';

abstract class DocumentRepository {
  Future<List<ClinicDocumentModel>> fetchClinicDocuments(String clinicId);

  Future<ClinicDocumentModel> uploadClinicDocument({
    required String clinicId,
    required DocumentType docType,
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  });

  Future<void> deleteClinicDocument(ClinicDocumentModel doc);

  Future<List<HealthWorkerDocumentModel>> fetchWorkerDocuments({
    required String clinicId,
    required String workerId,
  });

  Future<HealthWorkerDocumentModel> uploadWorkerDocument({
    required String clinicId,
    required String workerId,
    required WorkerDocumentType docType,
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  });

  Future<void> deleteWorkerDocument(HealthWorkerDocumentModel doc);

  Future<String> getSignedUrl(String filePath, {int expiresIn = 60});
}

class SupabaseDocumentRepository implements DocumentRepository {
  SupabaseDocumentRepository({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;
  final _uuid = const Uuid();
  static const String _bucket = 'clinic-documents';

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9\._-]'), '_');
  }

  @override
  Future<String> getSignedUrl(String filePath, {int expiresIn = 60}) async {
    return await _client.storage
        .from(_bucket)
        .createSignedUrl(filePath, expiresIn);
  }

  @override
  Future<List<ClinicDocumentModel>> fetchClinicDocuments(
      String clinicId) async {
    final res = await _client
        .from('clinic_documents')
        .select()
        .eq('clinic_id', clinicId)
        .order('created_at', ascending: false);

    final list = (res as List)
        .map((e) => ClinicDocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();

    // Attach signed URL for each
    final withUrls = <ClinicDocumentModel>[];
    for (final doc in list) {
      try {
        final url = await getSignedUrl(doc.filePath);
        withUrls.add(doc.copyWith(signedUrl: url));
      } catch (_) {
        withUrls.add(doc);
      }
    }
    return withUrls;
  }

  @override
  Future<ClinicDocumentModel> uploadClinicDocument({
    required String clinicId,
    required DocumentType docType,
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final cleanName = _sanitizeFileName(fileName);
    final uniqueId = _uuid.v4();
    final path = '$clinicId/${docType.dbValue}/$uniqueId-$cleanName';

    // 1. Upload to storage
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType ?? 'application/pdf',
            upsert: true,
          ),
        );

    // 2. Insert DB row (with rollback if fails)
    try {
      final res = await _client
          .from('clinic_documents')
          .insert({
            'clinic_id': clinicId,
            'doc_type': docType.dbValue,
            'file_path': path,
            'file_name': fileName,
            'mime_type': mimeType ?? 'application/pdf',
            'size_bytes': bytes.length,
          })
          .select()
          .single();

      final model = ClinicDocumentModel.fromJson(res);
      final signedUrl = await getSignedUrl(path);
      return model.copyWith(signedUrl: signedUrl);
    } catch (e) {
      // Cleanup orphan storage object
      try {
        await _client.storage.from(_bucket).remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<void> deleteClinicDocument(ClinicDocumentModel doc) async {
    // 1. Delete DB row
    await _client.from('clinic_documents').delete().eq('id', doc.id);
    // 2. Delete storage object
    try {
      await _client.storage.from(_bucket).remove([doc.filePath]);
    } catch (_) {}
  }

  @override
  Future<List<HealthWorkerDocumentModel>> fetchWorkerDocuments({
    required String clinicId,
    required String workerId,
  }) async {
    final res = await _client
        .from('health_worker_documents')
        .select()
        .eq('clinic_id', clinicId)
        .eq('worker_id', workerId)
        .order('created_at', ascending: false);

    final list = (res as List)
        .map((e) =>
            HealthWorkerDocumentModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final withUrls = <HealthWorkerDocumentModel>[];
    for (final doc in list) {
      try {
        final url = await getSignedUrl(doc.filePath);
        withUrls.add(doc.copyWith(signedUrl: url));
      } catch (_) {
        withUrls.add(doc);
      }
    }
    return withUrls;
  }

  @override
  Future<HealthWorkerDocumentModel> uploadWorkerDocument({
    required String clinicId,
    required String workerId,
    required WorkerDocumentType docType,
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final cleanName = _sanitizeFileName(fileName);
    final uniqueId = _uuid.v4();
    final path =
        '$clinicId/workers/$workerId/${docType.dbValue}/$uniqueId-$cleanName';

    // 1. Upload to storage
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType ?? 'application/pdf',
            upsert: true,
          ),
        );

    // 2. Insert DB row (with cleanup if fails)
    try {
      final res = await _client
          .from('health_worker_documents')
          .insert({
            'clinic_id': clinicId,
            'worker_id': workerId,
            'doc_type': docType.dbValue,
            'file_path': path,
            'file_name': fileName,
            'mime_type': mimeType ?? 'application/pdf',
            'size_bytes': bytes.length,
          })
          .select()
          .single();

      final model = HealthWorkerDocumentModel.fromJson(res);
      final signedUrl = await getSignedUrl(path);
      return model.copyWith(signedUrl: signedUrl);
    } catch (e) {
      try {
        await _client.storage.from(_bucket).remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<void> deleteWorkerDocument(HealthWorkerDocumentModel doc) async {
    await _client.from('health_worker_documents').delete().eq('id', doc.id);
    try {
      await _client.storage.from(_bucket).remove([doc.filePath]);
    } catch (_) {}
  }
}

class FakeDocumentRepository implements DocumentRepository {
  List<ClinicDocumentModel> clinicDocs = [];
  List<HealthWorkerDocumentModel> workerDocs = [];

  @override
  Future<String> getSignedUrl(String filePath, {int expiresIn = 60}) async {
    return 'https://fake-signed-url.com/$filePath';
  }

  @override
  Future<List<ClinicDocumentModel>> fetchClinicDocuments(
          String clinicId) async =>
      clinicDocs;

  @override
  Future<ClinicDocumentModel> uploadClinicDocument({
    required String clinicId,
    required DocumentType docType,
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final doc = ClinicDocumentModel(
      id: 'doc-${clinicDocs.length + 1}',
      clinicId: clinicId,
      docType: docType,
      filePath: '$clinicId/${docType.dbValue}/$fileName',
      fileName: fileName,
      sizeBytes: bytes.length,
      signedUrl: 'https://fake-signed-url.com/$fileName',
    );
    clinicDocs.add(doc);
    return doc;
  }

  @override
  Future<void> deleteClinicDocument(ClinicDocumentModel doc) async {
    clinicDocs.removeWhere((d) => d.id == doc.id);
  }

  @override
  Future<List<HealthWorkerDocumentModel>> fetchWorkerDocuments({
    required String clinicId,
    required String workerId,
  }) async =>
      workerDocs;

  @override
  Future<HealthWorkerDocumentModel> uploadWorkerDocument({
    required String clinicId,
    required String workerId,
    required WorkerDocumentType docType,
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
  }) async {
    final doc = HealthWorkerDocumentModel(
      id: 'wdoc-${workerDocs.length + 1}',
      workerId: workerId,
      clinicId: clinicId,
      docType: docType,
      filePath: '$clinicId/workers/$workerId/${docType.dbValue}/$fileName',
      fileName: fileName,
      sizeBytes: bytes.length,
      signedUrl: 'https://fake-signed-url.com/$fileName',
    );
    workerDocs.add(doc);
    return doc;
  }

  @override
  Future<void> deleteWorkerDocument(HealthWorkerDocumentModel doc) async {
    workerDocs.removeWhere((d) => d.id == doc.id);
  }
}
