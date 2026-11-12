import 'dart:typed_data';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../models/clinic_enums.dart';
import '../models/clinic_media_model.dart';

abstract class MediaRepository {
  Future<List<ClinicMediaModel>> fetchMedia(String clinicId);
  Future<ClinicMediaModel> uploadPublicMedia({
    required String clinicId,
    required MediaKind kind,
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
    String? altText,
    int sortOrder = 0,
  });
  Future<void> deleteMedia(ClinicMediaModel media);
  Future<void> updateSortOrders(List<ClinicMediaModel> mediaList);
}

class SupabaseMediaRepository implements MediaRepository {
  SupabaseMediaRepository({SupabaseClient? client}) : _customClient = client;

  final SupabaseClient? _customClient;
  SupabaseClient get _client => _customClient ?? Supabase.instance.client;

  final _uuid = const Uuid();
  static const String _bucket = 'clinic-public-media';

  String _sanitizeFileName(String name) {
    return name.replaceAll(RegExp(r'[^a-zA-Z0-9\._-]'), '_');
  }

  @override
  Future<List<ClinicMediaModel>> fetchMedia(String clinicId) async {
    final res = await _client
        .from('clinic_media')
        .select()
        .eq('clinic_id', clinicId)
        .order('sort_order', ascending: true)
        .order('created_at', ascending: true);

    final list = (res as List)
        .map((e) => ClinicMediaModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return list.map((m) {
      final publicUrl = _client.storage.from(_bucket).getPublicUrl(m.filePath);
      return m.copyWith(publicUrl: publicUrl);
    }).toList();
  }

  @override
  Future<ClinicMediaModel> uploadPublicMedia({
    required String clinicId,
    required MediaKind kind,
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
    String? altText,
    int sortOrder = 0,
  }) async {
    final cleanName = _sanitizeFileName(fileName);
    final uniqueId = _uuid.v4();
    final path = '$clinicId/${kind.dbValue}/$uniqueId-$cleanName';

    // 1. Upload to public storage
    await _client.storage.from(_bucket).uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: mimeType ?? 'image/jpeg',
            upsert: true,
          ),
        );

    // 2. Insert or update DB row
    try {
      final payload = {
        'clinic_id': clinicId,
        'kind': kind.dbValue,
        'file_path': path,
        'file_name': fileName,
        'mime_type': mimeType ?? 'image/jpeg',
        'size_bytes': bytes.length,
        'alt_text': altText,
        'sort_order': sortOrder,
        'review_status': 'pending',
      };

      final res = await _client
          .from('clinic_media')
          .upsert(
            payload,
            onConflict: (kind == MediaKind.logo || kind == MediaKind.cover)
                ? 'clinic_id, kind'
                : null,
          )
          .select()
          .single();

      final model = ClinicMediaModel.fromJson(res);
      final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
      return model.copyWith(publicUrl: publicUrl);
    } catch (e) {
      try {
        await _client.storage.from(_bucket).remove([path]);
      } catch (_) {}
      rethrow;
    }
  }

  @override
  Future<void> deleteMedia(ClinicMediaModel media) async {
    await _client.from('clinic_media').delete().eq('id', media.id);
    try {
      await _client.storage.from(_bucket).remove([media.filePath]);
    } catch (_) {}
  }

  @override
  Future<void> updateSortOrders(List<ClinicMediaModel> mediaList) async {
    for (final m in mediaList) {
      await _client
          .from('clinic_media')
          .update({'sort_order': m.sortOrder}).eq('id', m.id);
    }
  }
}

class FakeMediaRepository implements MediaRepository {
  List<ClinicMediaModel> mediaList = [];

  @override
  Future<List<ClinicMediaModel>> fetchMedia(String clinicId) async => mediaList;

  @override
  Future<ClinicMediaModel> uploadPublicMedia({
    required String clinicId,
    required MediaKind kind,
    required String fileName,
    required Uint8List bytes,
    String? mimeType,
    String? altText,
    int sortOrder = 0,
  }) async {
    if (kind == MediaKind.logo || kind == MediaKind.cover) {
      mediaList.removeWhere((m) => m.kind == kind);
    }
    final model = ClinicMediaModel(
      id: 'm-${mediaList.length + 1}',
      clinicId: clinicId,
      kind: kind,
      filePath: '$clinicId/${kind.dbValue}/$fileName',
      fileName: fileName,
      sizeBytes: bytes.length,
      altText: altText,
      sortOrder: sortOrder,
      reviewStatus: DocumentReviewStatus.pending,
      publicUrl: 'https://fake-public-url.com/$fileName',
    );
    mediaList.add(model);
    return model;
  }

  @override
  Future<void> deleteMedia(ClinicMediaModel media) async {
    mediaList.removeWhere((m) => m.id == media.id);
  }

  @override
  Future<void> updateSortOrders(List<ClinicMediaModel> list) async {
    mediaList = List.of(list);
  }
}
