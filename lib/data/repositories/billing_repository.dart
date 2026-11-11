import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../mock_data.dart';
import '../models.dart';

abstract class BillingRepository {
  Future<List<Invoice>> fetchInvoices();
  Future<void> createInvoice(
      {required String patientName,
      required String serviceName,
      required double amount});
  Future<void> recordOfflinePayment(String invoiceId, {String? paymentMethod});
  Future<void> requestRefund(String invoiceId,
      {required double amount, required String reason});
}

class SupabaseBillingRepository implements BillingRepository {
  SupabaseBillingRepository({SupabaseClient? client})
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
  Future<List<Invoice>> fetchInvoices() async {
    final client = _client;
    if (client == null) return MockData.invoices;

    try {
      final response = await client
          .from('invoices')
          .select()
          .order('created_at', ascending: false);
      if ((response as List).isEmpty) return MockData.invoices;

      return (response as List).map((row) {
        final map = row as Map<String, dynamic>;
        return Invoice(
          id: map['reference']?.toString() ??
              map['id']?.toString() ??
              'INV-000',
          date: map['created_at'] != null
              ? map['created_at'].toString().substring(0, 10)
              : 'Jun 17, 2025',
          patient: map['patient_name']?.toString() ?? 'Pasien',
          appointmentId: map['appointment_id']?.toString() ?? '',
          service: map['service_name']?.toString() ?? 'General consultation',
          amount: ((map['amount'] as num?)?.toDouble() ?? 0) / 1000,
          method: map['payment_method']?.toString() ?? 'Cash',
          status: map['status']?.toString() ?? 'Paid',
        );
      }).toList();
    } catch (e) {
      debugPrint('SupabaseBillingRepository fetch error: $e');
      return MockData.invoices;
    }
  }

  @override
  Future<void> createInvoice(
      {required String patientName,
      required String serviceName,
      required double amount}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('invoices').insert({
        'reference':
            'INV-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
        'patient_name': patientName,
        'service_name': serviceName,
        'amount': (amount * 1000).toInt(),
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('createInvoice error: $e');
    }
  }

  @override
  Future<void> recordOfflinePayment(String invoiceId,
      {String? paymentMethod}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('invoices').update({
        'status': 'paid',
        'payment_method': paymentMethod ?? 'Cash',
      }).eq('id', invoiceId);
    } catch (e) {
      debugPrint('recordOfflinePayment error: $e');
    }
  }

  @override
  Future<void> requestRefund(String invoiceId,
      {required double amount, required String reason}) async {
    final client = _client;
    if (client == null) return;
    try {
      await client.from('refund_requests').insert({
        'invoice_id': invoiceId,
        'amount': (amount * 1000).toInt(),
        'reason': reason,
        'status': 'pending',
      });
    } catch (e) {
      debugPrint('requestRefund error: $e');
    }
  }
}
