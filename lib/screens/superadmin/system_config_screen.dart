import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../providers/auth_provider.dart';

/// System Configuration - Platform settings and configurations
class SystemConfigScreen extends ConsumerStatefulWidget {
  const SystemConfigScreen({super.key});

  @override
  ConsumerState<SystemConfigScreen> createState() => _SystemConfigScreenState();
}

class _SystemConfigScreenState extends ConsumerState<SystemConfigScreen> {
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _maintenanceMode = false;
  bool _autoBackup = true;
  bool _twoFactorAuth = true;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          SuperAdminSidebar(
            selectedIndex: 7,
            onItemSelected: (_) {},
            userName: user?.name ?? 'Super Admin',
            userEmail: user?.email ?? '',
            userRole: 'Super Administrator',
          ),
          Expanded(
            child: Column(
              children: [
                ModernAdminHeader(
                  userName: user?.name.split(' ').first ?? 'Super Admin',
                  onNotificationTap: () {},
                  onProfileTap: () {},
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('System Configuration', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                        Text('Platform settings and system configurations', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Notification Settings
                        _buildSection(
                          'Notification Settings',
                          Icons.notifications,
                          AppColors.info,
                          isDark,
                          [
                            _buildToggle('Email Notifications', 'Send email alerts to users', _emailNotifications, (val) => setState(() => _emailNotifications = val), isDark),
                            _buildToggle('SMS Notifications', 'Send SMS alerts for critical events', _smsNotifications, (val) => setState(() => _smsNotifications = val), isDark),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // Security Settings
                        _buildSection(
                          'Security Settings',
                          Icons.security,
                          AppColors.error,
                          isDark,
                          [
                            _buildToggle('Two-Factor Authentication', 'Require 2FA for all admin users', _twoFactorAuth, (val) => setState(() => _twoFactorAuth = val), isDark),
                            _buildTextField('Session Timeout (minutes)', '30', isDark),
                            _buildTextField('Password Min Length', '8', isDark),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // System Settings
                        _buildSection(
                          'System Settings',
                          Icons.settings_applications,
                          AppColors.primary,
                          isDark,
                          [
                            _buildToggle('Maintenance Mode', 'Disable user access for maintenance', _maintenanceMode, (val) => setState(() => _maintenanceMode = val), isDark),
                            _buildToggle('Auto Backup', 'Automatic daily backups at 2:00 AM', _autoBackup, (val) => setState(() => _autoBackup = val), isDark),
                            _buildTextField('Max Upload Size (MB)', '50', isDark),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.lg),
                        
                        // API Settings
                        _buildSection(
                          'API & Integration',
                          Icons.api,
                          AppColors.success,
                          isDark,
                          [
                            _buildTextField('API Base URL', 'https://api.farmestates.com', isDark),
                            _buildTextField('Webhook URL', 'https://hooks.farmestates.com', isDark),
                            _buildTextField('API Rate Limit (req/min)', '1000', isDark),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Save Button
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () {},
                              child: const Text('Reset to Defaults'),
                            ),
                            const SizedBox(width: AppSpacing.md),
                            ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Configuration saved successfully!')),
                                );
                              },
                              icon: const Icon(Icons.save),
                              label: const Text('Save Changes'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl, vertical: AppSpacing.md),
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
      ),
    );
  }
  
  Widget _buildSection(String title, IconData icon, Color color, bool isDark, List<Widget> children) {
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
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(title, style: AppTypography.h6.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }
  
  Widget _buildToggle(String title, String subtitle, bool value, Function(bool) onChanged, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
                Text(subtitle, style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary)),
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
  
  Widget _buildTextField(String label, String initialValue, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: TextEditingController(text: initialValue),
        decoration: InputDecoration(
          labelText: label,
          border: const OutlineInputBorder(),
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        ),
      ),
    );
  }
}
