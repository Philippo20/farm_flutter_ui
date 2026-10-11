import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../theme/app_colors.dart';
import 'modern_admin_header.dart';
import 'modern_admin_sidebar.dart';
import 'superadmin_sidebar.dart';

enum MaintenanceAccess { technician, admin, superAdmin }

/// Keeps maintenance screens inside the administrator's own navigation shell.
class AdminMaintenanceShell extends ConsumerStatefulWidget {
  const AdminMaintenanceShell({
    super.key,
    required this.access,
    required this.history,
    required this.child,
  });

  final MaintenanceAccess access;
  final bool history;
  final Widget child;

  @override
  ConsumerState<AdminMaintenanceShell> createState() =>
      _AdminMaintenanceShellState();
}

class _AdminMaintenanceShellState extends ConsumerState<AdminMaintenanceShell> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  Widget build(BuildContext context) {
    final superAdmin = widget.access == MaintenanceAccess.superAdmin;
    final index = (superAdmin ? 16 : 12) + (widget.history ? 1 : 0);
    final mobile = MediaQuery.sizeOf(context).width < 768;
    final user = ref.watch(authProvider).user;
    final name = user?.name ?? (superAdmin ? 'Super Admin' : 'Admin');
    final email = user?.email ?? '';
    final role = superAdmin ? 'Super Administrator' : 'Administrator';
    final content = Column(children: [
      ModernAdminHeader(
        userName: name,
        onMenuTap:
            mobile ? () => _scaffoldKey.currentState?.openDrawer() : null,
        onProfileTap: () => Navigator.pushNamed(context, '/profile'),
      ),
      Expanded(child: widget.child),
    ]);
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Theme.of(context).brightness == Brightness.dark
          ? AppColors.backgroundDark
          : AppColors.backgroundLight,
      drawer: !mobile
          ? null
          : superAdmin
              ? SuperAdminDrawer(
                  selectedIndex: index,
                  onItemSelected: (_) {},
                  userName: name,
                  userEmail: email,
                  userRole: role)
              : AdminDrawer(
                  selectedIndex: index,
                  onItemSelected: (_) {},
                  userName: name,
                  userEmail: email,
                  userRole: role),
      body: mobile
          ? content
          : Row(children: [
              if (superAdmin)
                SuperAdminSidebar(
                    selectedIndex: index,
                    onItemSelected: (_) {},
                    userName: name,
                    userEmail: email,
                    userRole: role)
              else
                ModernAdminSidebar(
                    selectedIndex: index,
                    onItemSelected: (_) {},
                    userName: name,
                    userEmail: email,
                    userRole: role),
              Expanded(child: content),
            ]),
      bottomNavigationBar: !mobile
          ? null
          : superAdmin
              ? SuperAdminMobileBottomNav(
                  selectedIndex: index, onItemSelected: (_) {})
              : AdminMobileBottomNav(
                  selectedIndex: index, onItemSelected: (_) {}),
    );
  }
}
