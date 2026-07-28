import 'package:flutter/widgets.dart';

/// Non-secret, app-wide constants. Secrets/build-time config live in
/// [EnvConfig] instead — this file is safe to read without worrying about
/// exposing anything sensitive.
class AppConfig {
  const AppConfig._();

  static const String appName = 'Bariqon';

  static const Locale defaultLocale = Locale('en');

  static const List<Locale> supportedLocales = [Locale('en'), Locale('ar')];

  /// RTL locales among [supportedLocales] — used wherever a direction
  /// decision needs to be made outside of Flutter's own Directionality
  /// resolution (e.g. picking a font family pair in the theme system).
  static bool isRtl(Locale locale) => locale.languageCode == 'ar';
}
