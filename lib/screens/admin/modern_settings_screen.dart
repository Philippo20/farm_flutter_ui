import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/providers/theme_provider.dart';

/// Modern Settings Screen with organized sections
class ModernSettingsScreen extends ConsumerStatefulWidget {
  const ModernSettingsScreen({super.key});

  @override
  ConsumerState<ModernSettingsScreen> createState() => _ModernSettingsScreenState();
}

class _ModernSettingsScreenState extends ConsumerState<ModernSettingsScreen> {
  bool _emailNotifications = true;
  bool _pushNotifications = true;
  bool _smsNotifications = false;
  bool _autoBackup = true;
  bool _twoFactorAuth = false;
  String _language = 'English';
  String _timezone = 'UTC-5 (EST)';
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final themeMode = ref.watch(themeProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile ? _buildMobileLayout(isDark, themeMode) : _buildDesktopLayout(isDark, themeMode),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, ThemeMode themeMode) {
    return Row(
      children: [
        ModernAdminSidebar(selectedIndex: 5, onItemSelected: (_) {}),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(userName: 'Admin', onNotificationTap: () {}, onProfileTap: () {}),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text('Settings', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                      Text('Manage your preferences and system configuration', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                      
                      const SizedBox(height: AppSpacing.xl),
                      
                      // Settings Sections
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                children: [
                                  _buildAppearanceSection(isDark, themeMode),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildNotificationsSection(isDark),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildSecuritySection(isDark),
                                ],
                              ),
                            ),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(
                              child: Column(
                                children: [
                                  _buildGeneralSection(isDark),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildDataSection(isDark),
                                  const SizedBox(height: AppSpacing.lg),
                                  _buildAboutSection(isDark),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      );
  }

  Widget _buildMobileLayout(bool isDark, ThemeMode themeMode) {
    return Column(
      children: [
        ModernAdminHeader(userName: 'Admin', onNotificationTap: () {}, onProfileTap: () {}),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                const SizedBox(height: AppSpacing.lg),
                _buildAppearanceSection(isDark, themeMode),
                const SizedBox(height: AppSpacing.md),
                _buildNotificationsSection(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildSecuritySection(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildGeneralSection(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildDataSection(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildAboutSection(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0, 'route': '/dashboard'},
      {'icon': Icons.people_outline, 'label': 'Users', 'index': 1, 'route': '/users'},
      {'icon': Icons.agriculture_outlined, 'label': 'Farms', 'index': 2, 'route': '/farms'},
      {'icon': Icons.sensors_outlined, 'label': 'Sensors', 'index': 3, 'route': '/sensors'},
      {'icon': Icons.analytics_outlined, 'label': 'Analytics', 'index': 4, 'route': '/analytics'},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'index': 5, 'route': '/settings'},
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
            blurRadius: 10,
            offset: const Offset(0, -2),
          ),
        ],
        border: Border(
          top: BorderSide(
            color: isDark ? Colors.white.withOpacity(0.08) : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.take(5).map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == 5; // Settings screen is index 5

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (index != 5) {
                        try {
                          Navigator.pushReplacementNamed(context, route);
                        } catch (e) {
                          try {
                            Navigator.pushNamed(context, route);
                          } catch (e2) {
                            debugPrint('Navigation error: $e2');
                          }
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            fontSize: 11,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
  
  Widget _buildAppearanceSection(bool isDark, ThemeMode themeMode) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.palette, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Appearance', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          // Theme Mode
          _buildSettingRow(
            'Theme Mode',
            'Choose your preferred theme',
            isDark,
            trailing: SegmentedButton<ThemeMode>(
              segments: const [
                ButtonSegment(value: ThemeMode.light, label: Text('Light', style: TextStyle(fontSize: 12)), icon: Icon(Icons.light_mode, size: 16)),
                ButtonSegment(value: ThemeMode.dark, label: Text('Dark', style: TextStyle(fontSize: 12)), icon: Icon(Icons.dark_mode, size: 16)),
                ButtonSegment(value: ThemeMode.system, label: Text('Auto', style: TextStyle(fontSize: 12)), icon: Icon(Icons.auto_mode, size: 16)),
              ],
              selected: {themeMode},
              onSelectionChanged: (Set<ThemeMode> newSelection) {
                ref.read(themeProvider.notifier).toggleTheme();
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildNotificationsSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.notifications, color: AppColors.info, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Notifications', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          _buildSwitchRow('Email Notifications', 'Receive updates via email', _emailNotifications, (v) => setState(() => _emailNotifications = v), isDark),
          _buildSwitchRow('Push Notifications', 'Get push notifications on your device', _pushNotifications, (v) => setState(() => _pushNotifications = v), isDark),
          _buildSwitchRow('SMS Notifications', 'Receive text message alerts', _smsNotifications, (v) => setState(() => _smsNotifications = v), isDark),
        ],
      ),
    );
  }
  
  Widget _buildSecuritySection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.error.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.security, color: AppColors.error, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Security', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          _buildSwitchRow('Two-Factor Authentication', 'Add an extra layer of security', _twoFactorAuth, (v) => setState(() => _twoFactorAuth = v), isDark),
          const SizedBox(height: AppSpacing.md),
          _buildActionButton('Change Password', Icons.lock_outline, AppColors.primary, isDark),
          const SizedBox(height: AppSpacing.sm),
          _buildActionButton('Manage Sessions', Icons.devices, AppColors.info, isDark),
        ],
      ),
    );
  }
  
  Widget _buildGeneralSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.settings, color: AppColors.success, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('General', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          _buildDropdownRow('Language', _language, ['English', 'Spanish', 'French', 'German'], (v) => setState(() => _language = v!), isDark),
          const SizedBox(height: AppSpacing.md),
          _buildDropdownRow('Timezone', _timezone, ['UTC-5 (EST)', 'UTC-8 (PST)', 'UTC+0 (GMT)', 'UTC+1 (CET)'], (v) => setState(() => _timezone = v!), isDark),
        ],
      ),
    );
  }
  
  Widget _buildDataSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.warning.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.storage, color: AppColors.warning, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('Data & Storage', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          _buildSwitchRow('Auto Backup', 'Automatically backup data daily', _autoBackup, (v) => setState(() => _autoBackup = v), isDark),
          const SizedBox(height: AppSpacing.md),
          _buildActionButton('Export Data', Icons.download, AppColors.success, isDark),
          const SizedBox(height: AppSpacing.sm),
          _buildActionButton('Clear Cache', Icons.delete_outline, AppColors.error, isDark),
        ],
      ),
    );
  }
  
  Widget _buildAboutSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(Icons.info, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text('About', style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          
          _buildInfoRow('Version', '2.0.0', isDark),
          _buildInfoRow('Build', '2024.10.31', isDark),
          _buildInfoRow('Platform', 'Flutter', isDark),
          const SizedBox(height: AppSpacing.md),
          _buildActionButton('Check for Updates', Icons.system_update, AppColors.info, isDark),
        ],
      ),
    );
  }
  
  Widget _buildSettingRow(String title, String subtitle, bool isDark, {Widget? trailing}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: 4),
        Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
        if (trailing != null) ...[
          const SizedBox(height: AppSpacing.md),
          trailing,
        ],
      ],
    );
  }
  
  Widget _buildSwitchRow(String title, String subtitle, bool value, Function(bool) onChanged, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.primary,
          ),
        ],
      ),
    );
  }
  
  Widget _buildDropdownRow(String label, String value, List<String> items, Function(String?) onChanged, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
        const SizedBox(height: AppSpacing.sm),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: isDark ? Colors.white10 : AppColors.neutral200),
          ),
          child: DropdownButton<String>(
            value: value,
            isExpanded: true,
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: const TextStyle(fontSize: 13)))).toList(),
            onChanged: onChanged,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }
  
  Widget _buildActionButton(String label, IconData icon, Color color, bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton.icon(
        onPressed: () {},
        icon: Icon(icon, size: 18),
        label: Text(label),
        style: OutlinedButton.styleFrom(
          foregroundColor: color,
          side: BorderSide(color: color.withOpacity(0.3)),
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        ),
      ),
    );
  }
  
  Widget _buildInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white70 : AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
        ],
      ),
    );
  }
}
