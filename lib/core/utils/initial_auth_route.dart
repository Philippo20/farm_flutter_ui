/// Accept both fragment-free recovery emails and older hash-route links.
String initialAuthRoute(Uri uri) {
  if (uri.queryParameters['recovery'] == '1' ||
      uri.path == '/reset-password') {
    return '/reset-password';
  }
  if (uri.fragment.startsWith('/sales-invoice') ||
      uri.fragment.startsWith('/reset-password')) {
    return uri.fragment;
  }
  return '/login';
}
