import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:farmestates_ai_dashbaord/core/providers/live_workspace_provider.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/app_dialog.dart';
import 'package:farmestates_ai_dashbaord/models/user_model.dart';
import 'package:farmestates_ai_dashbaord/models/enums.dart';
import 'package:farmestates_ai_dashbaord/screens/accountant/accountant_approvals_screen.dart';
import 'package:farmestates_ai_dashbaord/services/superadmin_api_service.dart';

final request = <String, dynamic>{
  'id': 'r1',
  'kind': 'fund_request',
  'reference': 'FR-LIVE',
  'title': 'Water supplies',
  'requester': 'Farm manager',
  'requester_id': 'manager',
  'farm_name': 'Farm 1',
  'amount': 350.5,
  'currency': 'GHS',
  'status': 'Pending',
  'description': 'Water for the growing batches.',
  'revision': 'v1',
  'requested_at': '2026-10-06T10:00:00Z'
};

class ReviewApi extends SuperAdminApiService {
  int calls = 0;
  String? notes;
  Completer<void>? pending;
  @override
  Future<void> reviewApproval(
      Map<String, dynamic> item, String decision, String value) async {
    calls++;
    notes = value;
    await pending?.future;
    throw const SuperAdminApiException(
        'Request changed. Refresh before reviewing.');
  }
}

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  test(
      'Calendar and review requests use authenticated API and preserve decisions',
      () async {
    final calls = <http.Request>[];
    final api = SuperAdminApiService(client: MockClient((r) async {
      calls.add(r);
      return http.Response(
          jsonEncode({
            'users': [request]
          }),
          200);
    }));
    expect((await api.getCaretakerCalendar()).single['id'], 'r1');
    await api.getApprovalQueue();
    await api.reviewApproval(request, 'Rejected', 'Budget unavailable');
    expect(calls.map((c) => c.url.path), [
      '/caretaker/calendar',
      '/accountant/approvals',
      '/accountant/approvals/fund_request/r1'
    ]);
    expect(calls.every((c) => c.headers.containsKey('Authorization')), isTrue);
    expect(jsonDecode(calls.last.body), {
      'decision': 'Rejected',
      'notes': 'Budget unavailable',
      'revision': 'v1'
    });
  });
  for (final size in [const Size(360, 740), const Size(900, 550)]) {
    testWidgets(
        'Review has fixed actions and preserves notes on API failure $size',
        (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final api = ReviewApi();
      await tester.pumpWidget(ProviderScope(
          overrides: [
            liveWorkspaceApiProvider.overrideWithValue(api),
            approvalReviewerProvider.overrideWithValue(UserModel(
                id: 'accountant',
                name: 'Reviewer',
                email: 'r@example.test',
                role: UserRole.accountant,
                address: '',
                createdAt: DateTime(2026))),
          ],
          child: MaterialApp(
              home: Scaffold(
                  body: Builder(
                      builder: (context) => TextButton(
                          onPressed: () => showAppDialog(
                              context: context,
                              builder: (_) =>
                                  ApprovalReviewDialog(item: request)),
                          child: const Text('Review')))))));
      await tester.tap(find.text('Review'));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
      await tester.ensureVisible(find.byType(TextField));
      await tester.enterText(find.byType(TextField), 'Keep these notes');
      api.pending = Completer<void>();
      await tester.tap(find.text('Save decision'));
      await tester.pump();
      expect(find.text('Saving…'), findsOneWidget);
      await tester.tap(find.text('Saving…'));
      expect(api.calls, 1);
      api.pending!.complete();
      await tester.pumpAndSettle();
      expect(find.byType(ApprovalReviewDialog), findsOneWidget);
      expect(find.text('Keep these notes'), findsOneWidget);
      await tester.ensureVisible(
          find.text('Request changed. Refresh before reviewing.'));
      expect(find.text('Request changed. Refresh before reviewing.'),
          findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  }
  testWidgets('Queue shows real values and searches records without samples',
      (tester) async {
    await tester.pumpWidget(ProviderScope(
        overrides: [
          approvalQueueProvider.overrideWith((ref) async => [request])
        ],
        child: const MaterialApp(
            home: Scaffold(
                body: SingleChildScrollView(child: ApprovalQueueContent())))));
    await tester.pumpAndSettle();
    expect(find.text('FR-LIVE'), findsOneWidget);
    expect(find.text('GHS 350.50'), findsWidgets);
    expect(find.text('REQ-221'), findsNothing);
    await tester.enterText(find.byType(TextField), 'No matching request');
    await tester.pumpAndSettle();
    expect(find.text('FR-LIVE'), findsNothing);
    expect(find.text('No requests match these filters.'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
