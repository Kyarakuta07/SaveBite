import 'package:intl/intl.dart';

import '../config/app_locale_config.dart';

/// Currency, date, and distance formatting helpers for ID locale.
class Formatters {
  const Formatters._();

  static const String _datePattern = 'd MMM yyyy';
  static const String _dateTimePattern = 'd MMM yyyy, HH:mm';

  /// Format to Indonesian Rupiah. Handles String/num input.
  static String rupiah(dynamic value) {
    final number = double.tryParse(value.toString()) ?? 0;
    try {
      return NumberFormat.currency(
        locale: AppLocaleConfig.primaryLocaleName,
        symbol: 'Rp ',
        decimalDigits: 0,
      ).format(number);
    } catch (_) {
      return _fallbackRupiah(number);
    }
  }

  /// Relative time: "2 jam lagi", "30 menit lalu"
  static String relativeTime(DateTime dt) {
    final diff = dt.difference(DateTime.now());
    if (diff.isNegative) {
      final ago = diff.abs();
      if (ago.inMinutes < 60) return '${ago.inMinutes} menit lalu';
      if (ago.inHours < 24) return '${ago.inHours} jam lalu';
      return _formatDate(dt, _datePattern);
    }
    if (diff.inMinutes < 60) return '${diff.inMinutes} menit lagi';
    if (diff.inHours < 24) return '${diff.inHours} jam lagi';
    return _formatDate(dt, _datePattern);
  }

  /// Flash sale countdown: "1j 23m 45d"
  static String countdown(int totalSeconds) {
    if (totalSeconds <= 0) return 'Berakhir';
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) return '${h}j ${m}m ${s}d';
    return '${m}m ${s}d';
  }

  /// Distance: "1.2 km" or "800 m"
  static String distance(double km) {
    if (km < 1) return '${(km * 1000).round()} m';
    return '${km.toStringAsFixed(1)} km';
  }

  /// Date: "7 Mei 2026, 14:30"
  static String dateTime(DateTime dt) {
    return _formatDate(dt, _dateTimePattern);
  }

  static String _formatDate(DateTime dt, String pattern) {
    final localeCandidates = <String>[
      Intl.defaultLocale ?? AppLocaleConfig.primaryLocaleName,
      AppLocaleConfig.primaryLocaleName,
      AppLocaleConfig.primaryLanguageCode,
      AppLocaleConfig.fallbackLocaleName,
    ];

    for (final locale in localeCandidates.toSet()) {
      try {
        return DateFormat(pattern, locale).format(dt);
      } catch (_) {
        continue;
      }
    }

    if (pattern == _dateTimePattern) return _fallbackDateTime(dt);
    return _fallbackDate(dt);
  }

  static String _fallbackRupiah(double value) {
    final rounded = value.round().toString();
    final buffer = StringBuffer();

    for (var i = 0; i < rounded.length; i++) {
      final reverseIndex = rounded.length - i;
      buffer.write(rounded[i]);
      if (reverseIndex > 1 && reverseIndex % 3 == 1) {
        buffer.write('.');
      }
    }

    return 'Rp ${buffer.toString()}';
  }

  static String _fallbackDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/'
        '${dt.month.toString().padLeft(2, '0')}/'
        '${dt.year}';
  }

  static String _fallbackDateTime(DateTime dt) {
    return '${_fallbackDate(dt)}, '
        '${dt.hour.toString().padLeft(2, '0')}:'
        '${dt.minute.toString().padLeft(2, '0')}';
  }
}
