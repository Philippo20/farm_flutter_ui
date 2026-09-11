import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/initial_auth_route.dart';

void main() {
  test('Root email links with tokens open recovery without a marker', () {
    for (final link in [
      'https://example.com/?userId=user&secret=token',
      'https://example.com/?user_id=user&secret=token#/login',
      'https://example.com/#/?userId=user&secret=token',
    ]) {
      final uri = Uri.parse(link);
      expect(initialAuthRoute(uri), '/reset-password');
      expect(recoveryLinkParameters(uri)['secret'], 'token');
    }
  });
  test('Incomplete tokens do not turn the home page into recovery', () {
    expect(initialAuthRoute(Uri.parse('https://example.com/?userId=user')), '/login');
    expect(initialAuthRoute(Uri.parse('https://example.com/?secret=token')), '/login');
  });
  test('Recovery token extraction supports legacy fragment query', () {
    final uri = Uri.parse('https://example.com/#/reset-password?userId=user&secret=a%2Bb');
    expect(recoveryLinkParameters(uri), {'userId': 'user', 'secret': 'a+b'});
  });
  test('Recovery query opens reset screen with Appwrite tokens before hash', () {
    final uri = Uri.parse('https://example.com/?recovery=1&userId=user&secret=token#/');
    expect(initialAuthRoute(uri), '/reset-password');
    expect(uri.queryParameters['userId'], 'user');
    expect(uri.queryParameters['secret'], 'token');
  });
  test('Legacy recovery fragment and direct path remain supported', () {
    expect(initialAuthRoute(Uri.parse('https://example.com/?userId=user&secret=token#/reset-password')), '/reset-password');
    expect(initialAuthRoute(Uri.parse('https://example.com/reset-password?userId=user&secret=token')), '/reset-password');
  });
  test('Invoice and login navigation remain supported', () {
    expect(initialAuthRoute(Uri.parse('https://example.com/#/sales-invoice?id=123')), '/sales-invoice?id=123');
    expect(initialAuthRoute(Uri.parse('https://example.com/')), '/login');
  });
}
