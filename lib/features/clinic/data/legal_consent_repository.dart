import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/legal_consent_model.dart';

const String kLegalVersion = '2026-11';

abstract class LegalConsentRepository {
  Future<List<LegalConsentModel>> fetchUserConsents(String userId);
  Future<void> recordConsents({
    required String userId,
    required String version,
  });
}

class SupabaseLegalConsentRepository implements LegalConsentRepository {
  SupabaseLegalConsentRepository({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  @override
  Future<List<LegalConsentModel>> fetchUserConsents(String userId) async {
    final res =
        await _client.from('legal_consents').select().eq('user_id', userId);
    return (res as List)
        .map((e) => LegalConsentModel.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<void> recordConsents({
    required String userId,
    required String version,
  }) async {
    await _client.from('legal_consents').upsert([
      {
        'user_id': userId,
        'document_type': 'terms',
        'document_version': version,
      },
      {
        'user_id': userId,
        'document_type': 'privacy',
        'document_version': version,
      },
    ], onConflict: 'user_id, document_type, document_version');
  }
}

class FakeLegalConsentRepository implements LegalConsentRepository {
  List<LegalConsentModel> mockConsents = [];

  @override
  Future<List<LegalConsentModel>> fetchUserConsents(String userId) async =>
      mockConsents;

  @override
  Future<void> recordConsents({
    required String userId,
    required String version,
  }) async {
    mockConsents = [
      LegalConsentModel(
        id: 'lc-1',
        userId: userId,
        documentType: 'terms',
        documentVersion: version,
        acceptedAt: DateTime.now(),
      ),
      LegalConsentModel(
        id: 'lc-2',
        userId: userId,
        documentType: 'privacy',
        documentVersion: version,
        acceptedAt: DateTime.now(),
      ),
    ];
  }
}
