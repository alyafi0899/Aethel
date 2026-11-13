import 'package:clinic_operations_platform/core/utils/formatters.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  setUpAll(AppFormatters.initializeLocaleData);

  test('formats Indonesian dates and currency', () {
    final date = DateTime(2026, 11, 13, 8, 34);

    expect(AppFormatters.formatDate(date), '13 Nov 2026');
    expect(AppFormatters.formatDateFull(date), '13 November 2026');
    expect(AppFormatters.formatDateTime(date), '13 Nov 2026, 08:34');
    expect(AppFormatters.formatRupiah(75000), 'Rp 75.000');
  });
}
