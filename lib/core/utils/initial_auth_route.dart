Map<String, String> recoveryLinkParameters(Uri uri) => {
  ...uri.queryParameters,
  ...?Uri.tryParse(uri.fragment)?.queryParameters,
};

/// Accept recovery links pointing at the app root as well as explicit routes.
String initialAuthRoute(Uri uri) {
  final parameters = recoveryLinkParameters(uri);
  final fragmentPath = Uri.tryParse(uri.fragment)?.path ?? '';
  final isEntryPage = (uri.path.isEmpty || uri.path == '/' || uri.path == '/login') &&
      (fragmentPath.isEmpty || fragmentPath == '/' || fragmentPath == '/login');
  final hasRecoveryToken = (parameters['userId'] ?? parameters['user_id'] ?? '').isNotEmpty &&
      (parameters['secret'] ?? '').isNotEmpty;
  if (parameters['recovery'] == '1' ||
      (isEntryPage && hasRecoveryToken) ||
      uri.path == '/reset-password') {
    return '/reset-password';
  }
  if (uri.fragment.startsWith('/sales-invoice') ||
      uri.fragment.startsWith('/reset-password')) {
    return uri.fragment;
  }
  return '/login';
}
