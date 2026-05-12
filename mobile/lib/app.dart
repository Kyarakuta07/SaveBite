import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'core/config/app_env.dart';
import 'core/config/app_locale_config.dart';
import 'core/theme/app_theme.dart';
import 'routes/app_router.dart';

/// Root widget — per skill: project-structure.md.
class SaveBiteApp extends ConsumerWidget {
  const SaveBiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'SaveBite',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
      theme: AppTheme.light,
      locale: AppLocaleConfig.primaryLocale,
      supportedLocales: AppLocaleConfig.supportedLocales,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      localeResolutionCallback: AppLocaleConfig.resolveLocale,
      builder: (context, child) {
        // Show environment banner in non-production builds.
        // WHY: Prevents developers from accidentally testing on the wrong
        // backend. The banner is invisible in production builds.
        if (AppEnv.isProduction) return child!;
        return Banner(
          location: BannerLocation.topStart,
          message: AppEnv.env.toUpperCase(),
          color: AppEnv.isStaging
              ? const Color(0xFFFF9800) // orange for staging
              : const Color(0xFF4CAF50), // green for dev
          child: child!,
        );
      },
    );
  }
}
