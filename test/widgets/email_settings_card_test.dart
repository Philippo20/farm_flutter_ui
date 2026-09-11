import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/email_settings_card.dart';
import 'package:farmestates_ai_dashbaord/services/email_settings_service.dart';

class FakeEmailService extends EmailSettingsService {
  Map<String, dynamic>? saved;
  bool fail = false;
  @override
  Future<Map<String, dynamic>> load() async => {
        'enabled': false,
        'host': 'smtp.example.com',
        'port': 587,
        'security': 'starttls',
        'username': 'sender',
        'sender_name': 'Farm Estates',
        'sender_email': 'sender@example.com',
        'reply_to': '',
        'password_configured': true,
        'farm_alerts': true,
        'workflow_alerts': true,
        'account_alerts': true
      };
  @override
  Future<Map<String, dynamic>> save(Map<String, dynamic> settings) async {
    if (fail) throw Exception('Save failed');
    saved = settings;
    return {...settings, 'password_configured': true}..remove('password');
  }
}

void main() {
  for (final width in [320.0, 800.0, 1440.0]) {
    for (final dark in [false, true]) {
      testWidgets('email settings at $width dark=$dark', (tester) async {
        GoogleFonts.config.allowRuntimeFetching = false;
        tester.view.physicalSize = Size(width, 900);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final service = FakeEmailService();
        await tester.pumpWidget(MaterialApp(
            theme: ThemeData(
                brightness: dark ? Brightness.dark : Brightness.light),
            home: Scaffold(
                body: SingleChildScrollView(
                    child: EmailSettingsCard(service: service)))));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        final host = find.byType(TextFormField).first;
        await tester.ensureVisible(host);
        await tester.enterText(host, 'mail.example.com');
        await tester.pumpAndSettle();
        service.fail = true;
        await tester.ensureVisible(find.text('Save email settings'));
        await tester.tap(find.text('Save email settings'));
        await tester.pumpAndSettle();
        expect(find.text('Exception: Save failed'), findsOneWidget);
        expect(tester.widget<TextFormField>(host).controller!.text,
            'mail.example.com');
        service.fail = false;
        await tester.ensureVisible(find.text('Save email settings'));
        await tester.tap(find.text('Save email settings'));
        await tester.pumpAndSettle();
        expect(service.saved!['host'], 'mail.example.com');
        expect(service.saved!['password'], '');
        expect(find.text('Email settings saved'), findsOneWidget);
        expect(tester.takeException(), isNull);
      });
    }
  }
}
