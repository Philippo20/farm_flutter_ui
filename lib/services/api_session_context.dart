/// Authentication metadata sent only to this application's API origin.
class ApiSessionContext {
  static String? jwt;
  static String? role;
  static final origin = Uri.parse(const String.fromEnvironment('API_BASE_URL',
          defaultValue: 'https://api-5u45d.ondigitalocean.app'))
      .origin;
}
