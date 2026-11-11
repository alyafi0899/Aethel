import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock_data.dart';
import '../models.dart';

abstract class ServicesRepository {
  Future<List<ServiceItem>> fetchServices();
  Future<void> saveService(ServiceItem service);
}

class SupabaseServicesRepository implements ServicesRepository {
  SupabaseServicesRepository({SupabaseClient? client})
      : _client = client ?? _safeClient();

  final SupabaseClient? _client;

  static SupabaseClient? _safeClient() {
    try {
      return Supabase.instance.client;
    } catch (_) {
      return null;
    }
  }

  @override
  Future<List<ServiceItem>> fetchServices() async {
    final client = _client;
    if (client == null) return MockData.services;

    try {
      final response = await client.from('services').select().order('name');
      if ((response as List).isEmpty) return MockData.services;

      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return ServiceItem(
          name: map['name']?.toString() ?? 'Service',
          category: map['category']?.toString() ?? 'Primary Care',
          duration: '${map['duration_min'] ?? 30} min',
          price: 'Rp ${(map['price'] ?? 75000)}',
          status: map['status']?.toString() ?? 'Published',
          doctors: '4 doctors',
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseServicesRepository fetch error: $e');
      return MockData.services;
    }
  }

  @override
  Future<void> saveService(ServiceItem service) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('services').upsert({
        'name': service.name,
        'category': service.category,
        'status': service.status.toLowerCase().replaceAll(' ', '_'),
      });
    } catch (e) {
      debugPrint('saveService error: $e');
    }
  }
}
