import 'package:flutter_test/flutter_test.dart';
import 'package:intl/intl.dart';
import 'package:savebite/core/config/app_locale_config.dart';
import 'package:savebite/core/utils/formatters.dart';

void main() {
  group('Formatters', () {
    setUpAll(() async {
      await AppLocaleConfig.initialize();
    });

    test('formats Indonesian date time after locale initialization', () {
      final formatted = Formatters.dateTime(DateTime(2026, 5, 7, 14, 30));

      expect(Intl.defaultLocale, AppLocaleConfig.primaryLocaleName);
      expect(formatted, '7 Mei 2026, 14:30');
    });

    test('formats Indonesian Rupiah without decimal digits', () {
      expect(Formatters.rupiah(125000), 'Rp 125.000');
    });

    test('countdown does not depend on locale data', () {
      expect(Formatters.countdown(5025), '1j 23m 45d');
      expect(Formatters.countdown(0), 'Berakhir');
    });
  });
}
