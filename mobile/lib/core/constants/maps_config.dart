/// Google Maps configuration — values injected via --dart-define
class MapsConfig {
  MapsConfig._();

  static const String androidApiKey = String.fromEnvironment(
    'MAPS_API_KEY',
    defaultValue: '',
  );

  static const String iosApiKey = String.fromEnvironment(
    'MAPS_IOS_KEY',
    defaultValue: '',
  );
}
