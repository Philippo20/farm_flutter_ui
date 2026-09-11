import 'package:flutter_test/flutter_test.dart';
import 'package:farmestates_ai_dashbaord/core/utils/initial_auth_route.dart';

void main() {
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
