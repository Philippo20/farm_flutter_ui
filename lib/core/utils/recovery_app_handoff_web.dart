// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;

bool get supportsRecoveryAppHandoff {
  final agent = html.window.navigator.userAgent.toLowerCase();
  return agent.contains('android') || agent.contains('windows');
}

void openRecoveryApp() {
  final android = html.window.navigator.userAgent.toLowerCase().contains('android');
  // Never forward the recovery token, password or user ID to an app launcher.
  final fallback = Uri.base.replace(query: '', fragment: '/login').toString();
  final link = android
      ? 'intent://app/login#Intent;scheme=farmestates;package=com.example.farmestates_ai_dashbaord;S.browser_fallback_url=${Uri.encodeComponent(fallback)};end'
      : 'farmestates://app/login';
  html.window.location.assign(link);
}
