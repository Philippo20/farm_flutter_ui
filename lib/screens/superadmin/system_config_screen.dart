import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  // Default values
  static const Map<String, dynamic> _defaultConfig = {
    'emailNotifications': true,
    'smsNotifications': false,
    'maintenanceMode': false,
    'autoBackup': true,
    'twoFactorAuth': true,
    'sessionTimeout': '30',
    'passwordMinLength': '8',
    'maxUploadSize': '50',
    'apiBaseUrl': 'https://api.farmestates.com',
    'webhookUrl': 'https://hooks.farmestates.com',
    'apiRateLimit': '1000',
  };

  // Toggle states
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _maintenanceMode = false;
  bool _autoBackup = true;
  bool _twoFactorAuth = true;

  // Text controllers
  late TextEditingController _sessionTimeoutController;
  late TextEditingController _passwordMinLengthController;
  late TextEditingController _maxUploadSizeController;
  late TextEditingController _apiBaseUrlController;
  late TextEditingController _webhookUrlController;
  late TextEditingController _apiRateLimitController;

  // Track unsaved changes
  bool _hasUnsavedChanges = false;
  bool _isSaving = false;

  int _selectedNavIndex = 7;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    _sessionTimeoutController =
        TextEditingController(text: _defaultConfig['sessionTimeout'])
          ..addListener(_onConfigChanged);
    _passwordMinLengthController =
        TextEditingController(text: _defaultConfig['passwordMinLength'])
          ..addListener(_onConfigChanged);
    _maxUploadSizeController =
        TextEditingController(text: _defaultConfig['maxUploadSize'])
          ..addListener(_onConfigChanged);
    _apiBaseUrlController =
        TextEditingController(text: _defaultConfig['apiBaseUrl'])
          ..addListener(_onConfigChanged);
    _webhookUrlController =
        TextEditingController(text: _defaultConfig['webhookUrl'])
          ..addListener(_onConfigChanged);
    _apiRateLimitController =
        TextEditingController(text: _defaultConfig['apiRateLimit'])
          ..addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    _sessionTimeoutController.dispose();
    _passwordMinLengthController.dispose();
    _maxUploadSizeController.dispose();
    _apiBaseUrlController.dispose();
    _webhookUrlController.dispose();
    _apiRateLimitController.dispose();
    super.dispose();
  }

  void _onConfigChanged() {
    if (!_hasUnsavedChanges) {
      setState(() => _hasUnsavedChanges = true);
    }
  }

  void _onToggleChanged(String key, bool value) {
    setState(() {
      _hasUnsavedChanges = true;
      switch (key) {
        case 'emailNotifications':
          _emailNotifications = value;
          break;
        case 'smsNotifications':
          _smsNotifications = value;
          break;
        case 'maintenanceMode':
          _maintenanceMode = value;
          break;
        case 'autoBackup':
          _autoBackup = value;
          break;
        case 'twoFactorAuth':
          _twoFactorAuth = value;
          break;
      }
    });
  }

  Map<String, dynamic> _getCurrentConfig() {
    return {
      'emailNotifications': _emailNotifications,
      'smsNotifications': _smsNotifications,
      'maintenanceMode': _maintenanceMode,
      'autoBackup': _autoBackup,
      'twoFactorAuth': _twoFactorAuth,
      'sessionTimeout': _sessionTimeoutController.text,
      'passwordMinLength': _passwordMinLengthController.text,
      'maxUploadSize': _maxUploadSizeController.text,
      'apiBaseUrl': _apiBaseUrlController.text,
      'webhookUrl': _webhookUrlController.text,
      'apiRateLimit': _apiRateLimitController.text,
    };
  }

  List<String> _validateConfig() {
    final errors = <String>[];

    // Validate session timeout
    final sessionTimeout = int.tryParse(_sessionTimeoutController.text);
    if (sessionTimeout == null || sessionTimeout < 5 || sessionTimeout > 1440) {
      errors.add('Session timeout must be between 5 and 1440 minutes');
    }

    // Validate password min length
    final passwordLength = int.tryParse(_passwordMinLengthController.text);
    if (passwordLength == null || passwordLength < 6 || passwordLength > 32) {
      errors.add('Password minimum length must be between 6 and 32 characters');
    }

    // Validate max upload size
    final uploadSize = int.tryParse(_maxUploadSizeController.text);
    if (uploadSize == null || uploadSize < 1 || uploadSize > 500) {
      errors.add('Max upload size must be between 1 and 500 MB');
    }

    // Validate API base URL
    if (_apiBaseUrlController.text.isEmpty ||
        !_apiBaseUrlController.text.startsWith('http')) {
      errors.add(
          'API Base URL must be a valid URL starting with http:// or https://');
    }

    // Validate API rate limit
    final rateLimit = int.tryParse(_apiRateLimitController.text);
    if (rateLimit == null || rateLimit < 10 || rateLimit > 10000) {
      errors.add(
          'API rate limit must be between 10 and 10000 requests per minute');
    }

    return errors;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final userName = user?.name ?? 'Super Admin';
    final userEmail = user?.email ?? '';
    final firstName = userName.split(' ').first;

    return PopScope(
      canPop: !_hasUnsavedChanges,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        final shouldPop = await _showUnsavedChangesDialog(context, isDark);
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop();
        }
      },
      child: Scaffold(
        key: _scaffoldKey,
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        drawer: isMobile
            ? SuperAdminDrawer(
                selectedIndex: _selectedNavIndex,
                onItemSelected: (index) {
                  setState(() => _selectedNavIndex = index);
                },
                userName: userName,
                userEmail: userEmail,
                userRole: 'Super Administrator',
              )
            : null,
        body: isMobile
            ? _buildMobileLayout(isDark, firstName)
            : _buildDesktopLayout(isDark, userName, userEmail, firstName),
      ),
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String firstName) {
    return Row(
      children: [
        SuperAdminSidebar(
          selectedIndex: 7,
          onItemSelected: (_) {},
          userName: userName,
          userEmail: userEmail,
          userRole: 'Super Administrator',
        ),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(
                userName: firstName,
                onNotificationTap: () {},
                onProfileTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: _buildContent(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String firstName) {
    return Column(
      children: [
        ModernAdminHeader(
          userName: firstName,
          onNotificationTap: () {},
          onProfileTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildContent(isDark),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildConfigurationHero(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        _buildConfigurationStats(isDark, isMobile),
        const SizedBox(height: AppSpacing.xl),
        _buildProfessionalConfigGrid(isDark, isMobile),
        const SizedBox(height: AppSpacing.xl),
        _buildProfessionalActionBar(isDark, isMobile),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }

  Widget _buildConfigurationHero(bool isDark, bool isMobile) {
    final titleColor = isDark ? Colors.white : AppColors.textPrimary;
    final subtitleColor = isDark ? Colors.white70 : AppColors.textSecondary;
    final statusColor =
        _hasUnsavedChanges ? AppColors.warning : AppColors.success;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.lg : AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isDark
              ? [
                  AppColors.primary.withOpacity(0.28),
                  AppColors.surfaceDark,
                  AppColors.backgroundDark,
                ]
              : [
                  AppColors.primary.withOpacity(0.12),
                  Colors.white,
                  AppColors.neutral50,
                ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.primary.withOpacity(0.12),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.24 : 0.06),
            blurRadius: 28,
            offset: const Offset(0, 16),
          ),
        ],
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeroCopy(titleColor, subtitleColor),
                const SizedBox(height: AppSpacing.lg),
                _buildConfigStatusPill(statusColor),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildHeroCopy(titleColor, subtitleColor)),
                const SizedBox(width: AppSpacing.xl),
                _buildConfigStatusPill(statusColor),
              ],
            ),
    );
  }

  Widget _buildHeroCopy(Color titleColor, Color subtitleColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: AppColors.primary.withOpacity(0.2)),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: AppColors.primary,
            size: 26,
          ),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'System Configuration',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.w800,
                  color: titleColor,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Manage platform controls, security policy, operational limits, and integration endpoints from one controlled workspace.',
                style: AppTypography.bodyMedium.copyWith(
                  color: subtitleColor,
                  height: 1.45,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildConfigStatusPill(Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.md,
        vertical: AppSpacing.sm,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.13),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _hasUnsavedChanges
                ? Icons.edit_note_rounded
                : Icons.verified_rounded,
            color: color,
            size: 18,
          ),
          const SizedBox(width: 8),
          Text(
            _hasUnsavedChanges
                ? '${_getChangedSettings().length} unsaved change(s)'
                : 'Configuration in sync',
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConfigurationStats(bool isDark, bool isMobile) {
    final stats = [
      _ConfigStatus(
        label: 'Security posture',
        value: _twoFactorAuth ? 'Hardened' : 'Standard',
        detail: _twoFactorAuth ? '2FA enforced' : '2FA optional',
        icon: Icons.shield_rounded,
        color: AppColors.success,
      ),
      _ConfigStatus(
        label: 'System mode',
        value: _maintenanceMode ? 'Maintenance' : 'Live',
        detail:
            _maintenanceMode ? 'User access restricted' : 'All services online',
        icon:
            _maintenanceMode ? Icons.engineering_rounded : Icons.public_rounded,
        color: _maintenanceMode ? AppColors.error : AppColors.primary,
      ),
      _ConfigStatus(
        label: 'Backups',
        value: _autoBackup ? 'Automated' : 'Manual',
        detail: _autoBackup ? 'Daily at 2:00 AM' : 'No scheduled backup',
        icon: Icons.backup_rounded,
        color: AppColors.info,
      ),
      _ConfigStatus(
        label: 'API throttle',
        value: '${_apiRateLimitController.text}/min',
        detail: 'Gateway request limit',
        icon: Icons.speed_rounded,
        color: AppColors.warning,
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: stats.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isMobile ? 1 : 4,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
        childAspectRatio: isMobile ? 3.3 : 1.75,
      ),
      itemBuilder: (context, index) =>
          _buildConfigStatusCard(stats[index], isDark),
    );
  }

  Widget _buildConfigStatusCard(_ConfigStatus stat, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: stat.color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(stat.icon, color: stat.color, size: 22),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  stat.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  stat.detail,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white54 : AppColors.textSecondary,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalConfigGrid(bool isDark, bool isMobile) {
    final cards = [
      _buildProfessionalSection(
        'Notification Controls',
        'Choose which events notify users and operations teams.',
        Icons.notifications_active_rounded,
        AppColors.info,
        isDark,
        [
          _buildProfessionalToggle(
              'Email Notifications',
              'Send farm, account, and workflow alerts by email.',
              _emailNotifications,
              (val) => _onToggleChanged('emailNotifications', val),
              isDark),
          _buildProfessionalToggle(
              'SMS Notifications',
              'Send SMS alerts for critical events only.',
              _smsNotifications,
              (val) => _onToggleChanged('smsNotifications', val),
              isDark),
        ],
      ),
      _buildProfessionalSection(
        'Security Policy',
        'Control administrator access and password requirements.',
        Icons.admin_panel_settings_rounded,
        AppColors.error,
        isDark,
        [
          _buildProfessionalToggle(
              'Two-Factor Authentication',
              'Require 2FA for all admin users.',
              _twoFactorAuth,
              (val) => _onToggleChanged('twoFactorAuth', val),
              isDark),
          _buildProfessionalTextField(
              'Session Timeout', _sessionTimeoutController, isDark,
              hint: '5-1440 minutes',
              suffix: 'min',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          _buildProfessionalTextField(
              'Password Minimum Length', _passwordMinLengthController, isDark,
              hint: '6-32 characters',
              suffix: 'chars',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ],
      ),
      _buildProfessionalSection(
        'Platform Operations',
        'Manage availability, backups, and upload limits.',
        Icons.settings_suggest_rounded,
        AppColors.primary,
        isDark,
        [
          _buildProfessionalToggle(
              'Maintenance Mode',
              'Restrict users while administrators perform maintenance.',
              _maintenanceMode,
              (val) => _showMaintenanceModeDialog(context, isDark, val),
              isDark,
              warning: _maintenanceMode),
          _buildProfessionalToggle(
              'Auto Backup',
              'Run automatic platform backups every day at 2:00 AM.',
              _autoBackup,
              (val) => _onToggleChanged('autoBackup', val),
              isDark),
          _buildProfessionalTextField(
              'Max Upload Size', _maxUploadSizeController, isDark,
              hint: '1-500 MB',
              suffix: 'MB',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ],
      ),
      _buildProfessionalSection(
        'API & Integrations',
        'Configure platform endpoints and traffic controls.',
        Icons.hub_rounded,
        AppColors.success,
        isDark,
        [
          _buildProfessionalTextField(
              'API Base URL', _apiBaseUrlController, isDark,
              hint: 'https://api.example.com'),
          _buildProfessionalTextField(
              'Webhook URL', _webhookUrlController, isDark,
              hint: 'https://hooks.example.com'),
          _buildProfessionalTextField(
              'API Rate Limit', _apiRateLimitController, isDark,
              hint: '10-10000',
              suffix: 'req/min',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ],
      ),
    ];

    if (isMobile) {
      return Column(
        children: [
          for (int i = 0; i < cards.length; i++) ...[
            cards[i],
            if (i != cards.length - 1) const SizedBox(height: AppSpacing.lg),
          ],
        ],
      );
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final gap = AppSpacing.lg;
        final width = (constraints.maxWidth - gap) / 2;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children:
              cards.map((card) => SizedBox(width: width, child: card)).toList(),
        );
      },
    );
  }

  Widget _buildProfessionalSection(String title, String subtitle, IconData icon,
      Color color, bool isDark, List<Widget> children) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.18 : 0.04),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                ),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.w800,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                        height: 1.35,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          ...children,
        ],
      ),
    );
  }

  Widget _buildProfessionalToggle(String title, String subtitle, bool value,
      Function(bool) onChanged, bool isDark,
      {bool warning = false}) {
    final accent = warning ? AppColors.error : AppColors.primary;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: warning
              ? AppColors.error.withOpacity(0.35)
              : (isDark ? Colors.white10 : Colors.black.withOpacity(0.05)),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 10,
            height: 42,
            decoration: BoxDecoration(
              color: value
                  ? accent
                  : (isDark ? Colors.white24 : AppColors.neutral300),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        title,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    if (warning) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: AppColors.error.withOpacity(0.12),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: const Text(
                          'ACTIVE',
                          style: TextStyle(
                            fontSize: 9,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: accent,
          ),
        ],
      ),
    );
  }

  Widget _buildProfessionalTextField(
      String label, TextEditingController controller, bool isDark,
      {String? hint,
      String? suffix,
      TextInputType? keyboardType,
      List<TextInputFormatter>? inputFormatters}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: TextField(
        controller: controller,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          suffixText: suffix,
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white38
                : AppColors.textSecondary.withOpacity(0.65),
          ),
          suffixStyle: TextStyle(
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            fontWeight: FontWeight.w700,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: BorderSide(
              color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: const BorderSide(color: AppColors.primary, width: 1.4),
          ),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          filled: true,
          fillColor:
              isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.md,
          ),
        ),
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }

  Widget _buildProfessionalActionBar(bool isDark, bool isMobile) {
    final resetButton = OutlinedButton.icon(
      onPressed:
          _hasUnsavedChanges ? () => _showResetDialog(context, isDark) : null,
      icon: const Icon(Icons.restore_rounded, size: 18),
      label: const Text('Reset to Defaults'),
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg, vertical: AppSpacing.md),
        side: BorderSide(
          color: _hasUnsavedChanges
              ? AppColors.warning
              : (isDark ? Colors.white24 : AppColors.neutral300),
        ),
        foregroundColor: _hasUnsavedChanges ? AppColors.warning : null,
      ),
    );

    final saveButton = ElevatedButton.icon(
      onPressed: _hasUnsavedChanges && !_isSaving
          ? () => _saveConfiguration(context, isDark)
          : null,
      icon: _isSaving
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  strokeWidth: 2, color: Colors.white),
            )
          : const Icon(Icons.save_rounded, size: 18),
      label: Text(_isSaving ? 'Saving...' : 'Save Configuration'),
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.xl, vertical: AppSpacing.md),
        disabledBackgroundColor: isDark ? Colors.white12 : AppColors.neutral200,
      ),
    );

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
            color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06)),
      ),
      child: isMobile
          ? Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                resetButton,
                const SizedBox(height: AppSpacing.md),
                saveButton,
              ],
            )
          : Row(
              children: [
                Icon(
                  _hasUnsavedChanges
                      ? Icons.pending_actions_rounded
                      : Icons.task_alt_rounded,
                  color: _hasUnsavedChanges
                      ? AppColors.warning
                      : AppColors.success,
                  size: 22,
                ),
                const SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: Text(
                    _hasUnsavedChanges
                        ? 'Review and save configuration changes before leaving this screen.'
                        : 'All configuration values are synchronized.',
                    style: AppTypography.bodyMedium.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                resetButton,
                const SizedBox(width: AppSpacing.md),
                saveButton,
              ],
            ),
    );
  }

  Future<bool> _showUnsavedChangesDialog(
      BuildContext context, bool isDark) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
            title: Row(
              children: [
                Icon(Icons.warning_amber, color: AppColors.warning),
                const SizedBox(width: AppSpacing.sm),
                Text('Unsaved Changes',
                    style: TextStyle(
                        color: isDark ? Colors.white : AppColors.textPrimary)),
              ],
            ),
            content: Text(
              'You have unsaved changes. Are you sure you want to leave without saving?',
              style: TextStyle(
                  color: isDark ? Colors.white70 : AppColors.textSecondary),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.warning),
                child: const Text('Discard Changes',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
          ),
        ) ??
        false;
  }

  void _showResetDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.warning,
                    AppColors.warning.withOpacity(0.8)
                  ]),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd)),
                      child: const Icon(Icons.restore,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Reset to Defaults',
                              style: AppTypography.h6.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text('Restore all settings',
                              style: AppTypography.bodySmall
                                  .copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.warning.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border: Border.all(
                            color: AppColors.warning.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning,
                              color: AppColors.warning, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'This will reset all configuration settings to their default values. This action cannot be undone.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.lg),
                    Text(
                      'The following settings will be reset:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    ..._getChangedSettings().map((setting) => Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(Icons.circle,
                                  size: 6, color: AppColors.warning),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(setting,
                                    style: TextStyle(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.white60
                                            : AppColors.textSecondary)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : AppColors.neutral50,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSpacing.radiusXl)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : AppColors.neutral300),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _resetToDefaults();
                          Navigator.pop(context);
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Row(
                                children: [
                                  const Icon(Icons.check_circle,
                                      color: Colors.white, size: 20),
                                  const SizedBox(width: 8),
                                  const Text('Settings reset to defaults'),
                                ],
                              ),
                              backgroundColor: AppColors.success,
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusMd)),
                            ),
                          );
                        },
                        icon: const Icon(Icons.restore, size: 18),
                        label: const Text('Reset All'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.warning,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> _getChangedSettings() {
    final changes = <String>[];
    if (_emailNotifications != _defaultConfig['emailNotifications'])
      changes.add('Email Notifications');
    if (_smsNotifications != _defaultConfig['smsNotifications'])
      changes.add('SMS Notifications');
    if (_maintenanceMode != _defaultConfig['maintenanceMode'])
      changes.add('Maintenance Mode');
    if (_autoBackup != _defaultConfig['autoBackup']) changes.add('Auto Backup');
    if (_twoFactorAuth != _defaultConfig['twoFactorAuth'])
      changes.add('Two-Factor Authentication');
    if (_sessionTimeoutController.text != _defaultConfig['sessionTimeout'])
      changes.add('Session Timeout');
    if (_passwordMinLengthController.text !=
        _defaultConfig['passwordMinLength']) changes.add('Password Min Length');
    if (_maxUploadSizeController.text != _defaultConfig['maxUploadSize'])
      changes.add('Max Upload Size');
    if (_apiBaseUrlController.text != _defaultConfig['apiBaseUrl'])
      changes.add('API Base URL');
    if (_webhookUrlController.text != _defaultConfig['webhookUrl'])
      changes.add('Webhook URL');
    if (_apiRateLimitController.text != _defaultConfig['apiRateLimit'])
      changes.add('API Rate Limit');
    return changes.isEmpty ? ['All settings'] : changes;
  }

  void _resetToDefaults() {
    setState(() {
      _emailNotifications = _defaultConfig['emailNotifications'];
      _smsNotifications = _defaultConfig['smsNotifications'];
      _maintenanceMode = _defaultConfig['maintenanceMode'];
      _autoBackup = _defaultConfig['autoBackup'];
      _twoFactorAuth = _defaultConfig['twoFactorAuth'];
      _sessionTimeoutController.text = _defaultConfig['sessionTimeout'];
      _passwordMinLengthController.text = _defaultConfig['passwordMinLength'];
      _maxUploadSizeController.text = _defaultConfig['maxUploadSize'];
      _apiBaseUrlController.text = _defaultConfig['apiBaseUrl'];
      _webhookUrlController.text = _defaultConfig['webhookUrl'];
      _apiRateLimitController.text = _defaultConfig['apiRateLimit'];
      _hasUnsavedChanges = false;
    });
  }

  void _showMaintenanceModeDialog(
      BuildContext context, bool isDark, bool enable) {
    if (!enable) {
      _onToggleChanged('maintenanceMode', false);
      return;
    }

    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.error,
                    AppColors.error.withOpacity(0.8)
                  ]),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd)),
                      child: const Icon(Icons.engineering,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Enable Maintenance Mode',
                              style: AppTypography.h6.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text('System will be unavailable',
                              style: AppTypography.bodySmall
                                  .copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: AppColors.error.withOpacity(0.1),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                        border:
                            Border.all(color: AppColors.error.withOpacity(0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.warning,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(
                            child: Text(
                              'Enabling maintenance mode will prevent all users from accessing the system. Only super admins will be able to log in.',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white70
                                      : AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Container(
                      padding: const EdgeInsets.all(AppSpacing.md),
                      decoration: BoxDecoration(
                        color: isDark
                            ? Colors.white.withOpacity(0.05)
                            : AppColors.neutral50,
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusMd),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('What happens:',
                              style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                  color: isDark
                                      ? Colors.white
                                      : AppColors.textPrimary)),
                          const SizedBox(height: 8),
                          _buildMaintenanceItem(
                              'All active user sessions will be terminated',
                              Icons.logout,
                              isDark),
                          _buildMaintenanceItem(
                              'Users will see a maintenance page',
                              Icons.construction,
                              isDark),
                          _buildMaintenanceItem(
                              'API endpoints will return 503 errors',
                              Icons.api,
                              isDark),
                          _buildMaintenanceItem(
                              'Scheduled tasks will be paused',
                              Icons.pause_circle,
                              isDark),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : AppColors.neutral50,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSpacing.radiusXl)),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => Navigator.pop(context),
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                          side: BorderSide(
                              color: isDark
                                  ? Colors.white24
                                  : AppColors.neutral300),
                        ),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      flex: 2,
                      child: ElevatedButton.icon(
                        onPressed: () {
                          _onToggleChanged('maintenanceMode', true);
                          Navigator.pop(context);
                        },
                        icon: const Icon(Icons.engineering, size: 18),
                        label: const Text('Enable Maintenance'),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.error,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              vertical: AppSpacing.md),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMaintenanceItem(String text, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: AppColors.error.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: TextStyle(
                    fontSize: 12,
                    color: isDark ? Colors.white60 : AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }

  Future<void> _saveConfiguration(BuildContext context, bool isDark) async {
    // Validate first
    final errors = _validateConfig();
    if (errors.isNotEmpty) {
      _showValidationErrorsDialog(context, isDark, errors);
      return;
    }

    setState(() => _isSaving = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    final config = _getCurrentConfig();

    // In a real app, you would save to backend/local storage here
    // For now, we'll just show a success message

    setState(() {
      _isSaving = false;
      _hasUnsavedChanges = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('Configuration Saved!',
                        style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${config.length} settings updated successfully',
                        style: const TextStyle(fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 4),
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
        ),
      );
    }
  }

  void _showValidationErrorsDialog(
      BuildContext context, bool isDark, List<String> errors) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        child: Container(
          width: 400,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    AppColors.error,
                    AppColors.error.withOpacity(0.8)
                  ]),
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppSpacing.radiusXl)),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius:
                              BorderRadius.circular(AppSpacing.radiusMd)),
                      child: const Icon(Icons.error_outline,
                          color: Colors.white, size: 24),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Validation Errors',
                              style: AppTypography.h6.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold)),
                          Text('${errors.length} issue(s) found',
                              style: AppTypography.bodySmall
                                  .copyWith(color: Colors.white70)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              // Content
              Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Please fix the following issues before saving:',
                      style: TextStyle(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : AppColors.textPrimary),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    ...errors.map((error) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(Icons.error,
                                  size: 18, color: AppColors.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(error,
                                    style: TextStyle(
                                        fontSize: 13,
                                        color: isDark
                                            ? Colors.white70
                                            : AppColors.textSecondary)),
                              ),
                            ],
                          ),
                        )),
                  ],
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.03)
                      : AppColors.neutral50,
                  borderRadius: const BorderRadius.vertical(
                      bottom: Radius.circular(AppSpacing.radiusXl)),
                ),
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(context),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding:
                          const EdgeInsets.symmetric(vertical: AppSpacing.md),
                    ),
                    child: const Text('OK, I\'ll Fix It'),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ConfigStatus {
  final String label;
  final String value;
  final String detail;
  final IconData icon;
  final Color color;

  const _ConfigStatus({
    required this.label,
    required this.value,
    required this.detail,
    required this.icon,
    required this.color,
  });
}
