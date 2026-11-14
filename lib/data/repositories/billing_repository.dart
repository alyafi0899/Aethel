import '../models.dart';

@Deprecated('Use BillingRepository with visit_invoices and payment RPCs.')
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

@Deprecated(
    'Use SupabaseClinicalRepository; legacy invoice writes are disabled.')
class SupabaseBillingRepository implements BillingRepository {
  SupabaseBillingRepository({Object? client});

  @override
  Future<List<Invoice>> fetchInvoices() => Future.error(UnsupportedError(
        'Legacy invoice API is disabled. Use the visit billing workflow.',
      ));

  @override
  Future<void> createInvoice(
          {required String patientName,
          required String serviceName,
          required double amount}) =>
      Future.error(UnsupportedError(
        'Invoices are created by complete_consultation.',
      ));

  @override
  Future<void> recordOfflinePayment(String invoiceId,
          {String? paymentMethod}) =>
      Future.error(UnsupportedError(
        'Use the record_offline_payment RPC.',
      ));

  @override
  Future<void> requestRefund(String invoiceId,
          {required double amount, required String reason}) =>
      Future.error(UnsupportedError(
        'Refund operations are not part of the active billing contract.',
      ));
}
