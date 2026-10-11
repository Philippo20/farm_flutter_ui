import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:farmestates_ai_dashbaord/core/widgets/modern_admin_sidebar.dart';
import 'package:farmestates_ai_dashbaord/core/guards/route_guard.dart';

import 'package:farmestates_ai_dashbaord/models/enums.dart';

void main() {
  setUp(() => GoogleFonts.config.allowRuntimeFetching = false);
  test('pricing route is limited to the two administrator roles', () {
    expect(RouteGuard.canAccess('/admin/pricing', 'admin'), true);
    expect(RouteGuard.canAccess('/admin/pricing', 'superadmin'), true);
    for (final role in [
      UserRole.caretaker,
      UserRole.technician,
      UserRole.farmManager
    ]) {
      expect(RouteGuard.canAccess('/admin/pricing', role.apiValue), false);
    }
  });
  testWidgets('Admin drawer opens pricing at its new index', (tester) async {
    var selected = -1;
    final scaffoldKey = GlobalKey<ScaffoldState>();
    await tester.pumpWidget(MaterialApp(
        routes: {
          '/admin/pricing': (_) => const Scaffold(body: Text('Pricing screen')),
        },
        home: Scaffold(
            key: scaffoldKey,
            drawer: AdminDrawer(
                selectedIndex: 2,
                onItemSelected: (index) => selected = index,
                userName: 'Admin',
                userEmail: 'admin@test.com',
                userRole: 'Administrator'))));
    scaffoldKey.currentState!.openDrawer();
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(find.text('Pricing'), 200);
    await tester.tap(find.text('Pricing'));
    await tester.pumpAndSettle();
    expect(selected, 14);
    expect(find.text('Pricing screen'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
  testWidgets(
      'mobile pricing destination uses index 14 without displacing primary tabs',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
        home: Scaffold(
            bottomNavigationBar: AdminMobileBottomNav(
                selectedIndex: 14, onItemSelected: (_) {}))));
    expect(find.text('Pricing'), findsOneWidget);
    expect(find.text('Home'), findsOneWidget);
    expect(find.text('Users'), findsOneWidget);
    expect(find.text('Farms'), findsOneWidget);
    expect(find.text('Sensors'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
