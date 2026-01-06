import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Super Admin Sidebar - Dedicated navigation for Super Admin only
class SuperAdminSidebar extends StatefulWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;
  final String userName;
  final String userEmail;
  final String userRole;

  const SuperAdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
    required this.userName,
    required this.userEmail,
    required this.userRole,
  });

  @override
  State<SuperAdminSidebar> createState() => _SuperAdminSidebarState();
}

class _SuperAdminSidebarState extends State<SuperAdminSidebar> {
  bool _isExpanded = true;

  final List<Map<String, dynamic>> _menuItems = [
    {'icon': Icons.dashboard, 'label': 'Dashboard', 'route': '/superadmin_dashboard'},
    {'icon': Icons.people, 'label': 'User Management', 'route': '/superadmin/users'},
    {'icon': Icons.agriculture, 'label': 'Farm Management', 'route': '/superadmin/farms'},
    {'icon': Icons.eco, 'label': 'Plant Types', 'route': '/superadmin/plants'},
    {'icon': Icons.inventory_2, 'label': 'Packaging', 'route': '/superadmin/packaging'},
    {'icon': Icons.attach_money, 'label': 'Pricing', 'route': '/superadmin/pricing'},
    {'icon': Icons.history, 'label': 'Audit Logs', 'route': '/superadmin/audit'},
    {'icon': Icons.settings_applications, 'label': 'System Config', 'route': '/superadmin/config'},
    {'icon': Icons.backup, 'label': 'Backup & Restore', 'route': '/superadmin/backup'},
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: _isExpanded ? 260 : 72,
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        border: Border(
          right: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: Column(
        children: [
          // Header with Super Admin Badge
          _buildHeader(isDark),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Menu Items
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
              itemCount: _menuItems.length,
              itemBuilder: (context, index) {
                return _buildMenuItem(
                  _menuItems[index]['icon'],
                  _menuItems[index]['label'],
                  index,
                  isDark,
                  _menuItems[index]['route'],
                );
              },
            ),
          ),
          
          // Toggle Button
          _buildToggleButton(isDark),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: EdgeInsets.all(_isExpanded ? AppSpacing.lg : AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.primary,
            AppColors.primary.withOpacity(0.8),
          ],
        ),
      ),
      child: Column(
        children: [
          if (_isExpanded) ...[
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.admin_panel_settings, color: Colors.white, size: 24),
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Super Admin',
                        style: AppTypography.bodySmall.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        'Control Center',
                        style: AppTypography.caption.copyWith(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: const [
                  Icon(Icons.verified_user, color: Colors.white, size: 12),
                  SizedBox(width: 4),
                  Text(
                    'Full Access',
                    style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ] else ...[
            const Icon(Icons.admin_panel_settings, color: Colors.white, size: 28),
          ],
        ],
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String label, int index, bool isDark, String route) {
    final isSelected = widget.selectedIndex == index;

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.xs),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            widget.onItemSelected(index);
            Navigator.pushNamed(context, route);
          },
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: EdgeInsets.symmetric(
              horizontal: _isExpanded ? AppSpacing.md : AppSpacing.sm,
              vertical: AppSpacing.sm,
            ),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withOpacity(0.1)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              border: Border.all(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.3)
                    : Colors.transparent,
                width: 1,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  icon,
                  size: 20,
                  color: isSelected
                      ? AppColors.primary
                      : (isDark ? Colors.white70 : AppColors.textSecondary),
                ),
                if (_isExpanded) ...[
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Text(
                      label,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        color: isSelected
                            ? AppColors.primary
                            : (isDark ? Colors.white : AppColors.textPrimary),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildToggleButton(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          child: Container(
            padding: const EdgeInsets.all(AppSpacing.sm),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral100,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              _isExpanded ? Icons.chevron_left : Icons.chevron_right,
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ),
      ),
    );
  }
}
