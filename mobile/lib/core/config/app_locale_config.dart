import 'package:flutter/widgets.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:intl/intl.dart';

/// Central locale configuration for app startup and formatter utilities.
class AppLocaleConfig {
  const AppLocaleConfig._();

  static const Locale primaryLocale = Locale('id', 'ID');
  static const Locale fallbackLocale = Locale('en', 'US');

  static const String primaryLocaleName = 'id_ID';
  static const String primaryLanguageCode = 'id';
  static const String fallbackLocaleName = 'en_US';

  static const List<Locale> supportedLocales = <Locale>[
    primaryLocale,
    fallbackLocale,
  ];

  static bool _dateFormattingInitialized = false;

  static bool get dateFormattingInitialized => _dateFormattingInitialized;

  static Future<void> initialize() async {
    if (_dateFormattingInitialized) return;

    Intl.defaultLocale = primaryLocaleName;

    try {
      await Future.wait([
        initializeDateFormatting(primaryLocaleName),
        initializeDateFormatting(primaryLanguageCode),
        initializeDateFormatting(fallbackLocaleName),
      ]);
      _dateFormattingInitialized = true;
    } catch (error, stackTrace) {
      debugPrint('Locale initialization failed: $error');
      debugPrintStack(stackTrace: stackTrace);

      Intl.defaultLocale = fallbackLocaleName;
      try {
        await initializeDateFormatting(fallbackLocaleName);
        _dateFormattingInitialized = true;
      } catch (fallbackError, fallbackStackTrace) {
        debugPrint('Fallback locale initialization failed: $fallbackError');
        debugPrintStack(stackTrace: fallbackStackTrace);
        _dateFormattingInitialized = false;
      }
    }
  }

  static Locale resolveLocale(
    Locale? locale,
    Iterable<Locale> supportedLocales,
  ) {
    if (locale == null) return primaryLocale;

    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode &&
          supportedLocale.countryCode == locale.countryCode) {
        return supportedLocale;
      }
    }

    for (final supportedLocale in supportedLocales) {
      if (supportedLocale.languageCode == locale.languageCode) {
        return supportedLocale;
      }
    }

    return primaryLocale;
  }
}
