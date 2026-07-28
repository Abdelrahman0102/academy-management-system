class ApiConfig {
  ApiConfig._();

  static const String baseUrl =
  String.fromEnvironment(
    'API_BASE_URL',
    defaultValue:
    'https://turbo-app.com/api/sports_academy',
  );
}