import 'dart:convert';
import 'dart:typed_data';

import 'package:clinic_operations_platform/features/clinic/data/media_repository.dart';
import 'package:clinic_operations_platform/features/clinic/models/clinic_enums.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

http.Response _jsonResponse(
  Object body, {
  required http.Request request,
  int statusCode = 200,
}) {
  return http.Response(
    jsonEncode(body),
    statusCode,
    request: request,
    headers: {'content-type': 'application/json'},
  );
}

Map<String, dynamic> _mediaRow({
  String id = 'media-1',
  String kind = 'logo',
  String filePath = 'clinic-1/logo/old-logo.jpg',
  Map<String, dynamic> updates = const {},
}) {
  return {
    'id': id,
    'clinic_id': 'clinic-1',
    'kind': kind,
    'file_path': filePath,
    'file_name': 'logo.jpg',
    'mime_type': 'image/jpeg',
    'size_bytes': 3,
    'alt_text': null,
    'sort_order': 0,
    'review_status': 'pending',
    'review_note': null,
    'uploaded_by': null,
    ...updates,
  };
}

void main() {
  test('replaces logo row without ON CONFLICT and removes previous object',
      () async {
    final requests = <http.Request>[];
    final mockHttp = MockClient((request) async {
      requests.add(request);
      if (request.url.path.startsWith(
          '/storage/v1/object/clinic-public-media/clinic-1/logo/')) {
        return _jsonResponse({'Key': 'uploaded'}, request: request);
      }
      if (request.url.path == '/rest/v1/clinic_media' &&
          request.method == 'GET') {
        return _jsonResponse([_mediaRow()], request: request);
      }
      if (request.url.path == '/rest/v1/clinic_media' &&
          request.method == 'PATCH') {
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse(
          _mediaRow(
            filePath: payload['file_path'] as String,
            updates: payload,
          ),
          request: request,
        );
      }
      if (request.url.path == '/storage/v1/object/clinic-public-media' &&
          request.method == 'DELETE') {
        return _jsonResponse([], request: request);
      }
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    });
    final client = SupabaseClient(
      'https://test.supabase.co',
      'test-key',
      httpClient: mockHttp,
    );
    addTearDown(() {
      client.dispose();
      mockHttp.close();
    });
    final repository = SupabaseMediaRepository(client: client);

    final saved = await repository.uploadPublicMedia(
      clinicId: 'clinic-1',
      kind: MediaKind.logo,
      fileName: 'logo.jpg',
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(saved.id, 'media-1');
    expect(saved.filePath, startsWith('clinic-1/logo/'));
    expect(
      requests.where((request) => request.method == 'PATCH'),
      hasLength(1),
    );
    expect(
      requests.any(
          (request) => request.url.queryParameters.containsKey('on_conflict')),
      isFalse,
    );
    final removalRequest = requests.singleWhere(
      (request) => request.method == 'DELETE',
    );
    expect(
      (jsonDecode(removalRequest.body) as Map<String, dynamic>)['prefixes'],
      ['clinic-1/logo/old-logo.jpg'],
    );
  });

  test('inserts gallery rows so multiple clinic photos remain supported',
      () async {
    final requests = <http.Request>[];
    final mockHttp = MockClient((request) async {
      requests.add(request);
      if (request.url.path.startsWith(
          '/storage/v1/object/clinic-public-media/clinic-1/gallery/')) {
        return _jsonResponse({'Key': 'uploaded'}, request: request);
      }
      if (request.url.path == '/rest/v1/clinic_media' &&
          request.method == 'POST') {
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse(
          _mediaRow(
            id: 'gallery-1',
            kind: 'gallery',
            filePath: payload['file_path'] as String,
            updates: payload,
          ),
          request: request,
        );
      }
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    });
    final client = SupabaseClient(
      'https://test.supabase.co',
      'test-key',
      httpClient: mockHttp,
    );
    addTearDown(() {
      client.dispose();
      mockHttp.close();
    });
    final repository = SupabaseMediaRepository(client: client);

    final saved = await repository.uploadPublicMedia(
      clinicId: 'clinic-1',
      kind: MediaKind.gallery,
      fileName: 'ruang-tunggu.jpg',
      bytes: Uint8List.fromList([1, 2, 3]),
      sortOrder: 2,
    );

    expect(saved.kind, MediaKind.gallery);
    expect(
      requests.where((request) =>
          request.url.path == '/rest/v1/clinic_media' &&
          request.method == 'POST'),
      hasLength(1),
    );
    expect(
      requests.any(
          (request) => request.url.queryParameters.containsKey('on_conflict')),
      isFalse,
    );
  });

  test('recovers when a concurrent upload creates the singleton row first',
      () async {
    final requests = <http.Request>[];
    var lookupCount = 0;
    final existingRow = _mediaRow(
      id: 'concurrent-logo',
      filePath: 'clinic-1/logo/concurrent.jpg',
    );
    final mockHttp = MockClient((request) async {
      requests.add(request);
      if (request.url.path.startsWith(
          '/storage/v1/object/clinic-public-media/clinic-1/logo/')) {
        return _jsonResponse({'Key': 'uploaded'}, request: request);
      }
      if (request.url.path == '/rest/v1/clinic_media' &&
          request.method == 'GET') {
        lookupCount++;
        return _jsonResponse(
          lookupCount == 1 ? [] : [existingRow],
          request: request,
        );
      }
      if (request.url.path == '/rest/v1/clinic_media' &&
          request.method == 'POST') {
        return _jsonResponse(
          {
            'code': '23505',
            'message': 'duplicate key value violates unique constraint',
          },
          request: request,
          statusCode: 409,
        );
      }
      if (request.url.path == '/rest/v1/clinic_media' &&
          request.method == 'PATCH') {
        final payload = jsonDecode(request.body) as Map<String, dynamic>;
        return _jsonResponse(
          _mediaRow(
            id: 'concurrent-logo',
            filePath: payload['file_path'] as String,
            updates: payload,
          ),
          request: request,
        );
      }
      if (request.url.path == '/storage/v1/object/clinic-public-media' &&
          request.method == 'DELETE') {
        return _jsonResponse([], request: request);
      }
      throw StateError('Unexpected request: ${request.method} ${request.url}');
    });
    final client = SupabaseClient(
      'https://test.supabase.co',
      'test-key',
      httpClient: mockHttp,
    );
    addTearDown(() {
      client.dispose();
      mockHttp.close();
    });
    final repository = SupabaseMediaRepository(client: client);

    final saved = await repository.uploadPublicMedia(
      clinicId: 'clinic-1',
      kind: MediaKind.logo,
      fileName: 'logo.jpg',
      bytes: Uint8List.fromList([1, 2, 3]),
    );

    expect(saved.id, 'concurrent-logo');
    expect(lookupCount, 2);
    expect(
      requests.where((request) => request.method == 'PATCH'),
      hasLength(1),
    );
  });
}
