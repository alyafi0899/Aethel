import 'package:flutter/foundation.dart';
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

  Future<Map<String, dynamic>?> _findSingleKindMedia(
    String clinicId,
    MediaKind kind,
  ) {
    return _client
        .from('clinic_media')
        .select('id, file_path')
        .eq('clinic_id', clinicId)
        .eq('kind', kind.dbValue)
        .maybeSingle();
  }

  Future<({Map<String, dynamic> row, String? previousPath})>
      _saveSingleKindMedia(
    Map<String, dynamic> payload,
    String clinicId,
    MediaKind kind,
  ) async {
    // This schema uses a partial unique index, which PostgREST cannot infer for ON CONFLICT.
    Future<({Map<String, dynamic> row, String? previousPath})> updateExisting(
      Map<String, dynamic> existing,
    ) async {
      final row = await _client
          .from('clinic_media')
          .update(payload)
          .eq('id', existing['id'] as String)
          .select()
          .single();
      return (
        row: row,
        previousPath: existing['file_path'] as String?,
      );
    }

    final existing = await _findSingleKindMedia(clinicId, kind);
    if (existing != null) return updateExisting(existing);

    try {
      final row =
          await _client.from('clinic_media').insert(payload).select().single();
      return (row: row, previousPath: null);
    } on PostgrestException catch (error) {
      if (error.code != '23505') rethrow;
      final concurrentUpload = await _findSingleKindMedia(clinicId, kind);
      if (concurrentUpload == null) rethrow;
      return updateExisting(concurrentUpload);
    }
  }

  Future<void> _removeStoredFile(String path, String reason) async {
    try {
      await _client.storage.from(_bucket).remove([path]);
    } catch (error) {
      debugPrint('Storage cleanup failed ($reason) for $path: $error');
    }
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

    try {
      await _client.storage.from(_bucket).uploadBinary(
            path,
            bytes,
            fileOptions: FileOptions(
              contentType: mimeType ?? 'image/jpeg',
              upsert: true,
            ),
          );

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

      final isSingleKind = kind == MediaKind.logo || kind == MediaKind.cover;
      final saved = isSingleKind
          ? await _saveSingleKindMedia(payload, clinicId, kind)
          : (
              row: await _client
                  .from('clinic_media')
                  .insert(payload)
                  .select()
                  .single(),
              previousPath: null,
            );

      final model = ClinicMediaModel.fromJson(saved.row);
      final publicUrl = _client.storage.from(_bucket).getPublicUrl(path);
      if (saved.previousPath != null && saved.previousPath != path) {
        await _removeStoredFile(saved.previousPath!, 'replace previous media');
      }
      return model.copyWith(publicUrl: publicUrl);
    } catch (_) {
      await _removeStoredFile(path, 'roll back failed media upload');
      rethrow;
    }
  }

  @override
  Future<void> deleteMedia(ClinicMediaModel media) async {
    await _client.from('clinic_media').delete().eq('id', media.id);
    await _removeStoredFile(media.filePath, 'delete media');
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
