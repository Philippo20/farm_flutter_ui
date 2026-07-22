import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

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
    'sessionIdleWarningMinutes': '5',
    'maxConcurrentSessions': '3',
    'forceLogoutOnPasswordChange': true,
    'passwordMinLength': '8',
    'maxUploadSize': '50',
    'apiBaseUrl': 'https://api.farmestates.com',
    'webhookUrl': 'https://hooks.farmestates.com',
    'apiRateLimit': '1000',
    'sensorIngestApiKey': '',
    'currencyCode': 'GHS',
    'currencySymbol': 'GHS',
    'googleMapsEnabled': false,
    'googleMapsApiKey': '',
    'googleMapsDefaultLat': '5.6037',
    'googleMapsDefaultLng': '-0.1870',
    'googleMapsDefaultZoom': '10',
  };

  final SuperAdminApiService _apiService = SuperAdminApiService();

  // Toggle states
  bool _emailNotifications = true;
  bool _smsNotifications = false;
  bool _maintenanceMode = false;
  bool _autoBackup = true;
  bool _twoFactorAuth = true;
  bool _forceLogoutOnPasswordChange = true;
  bool _googleMapsEnabled = false;
  String _currencyCode = 'GHS';

  // Text controllers
  late TextEditingController _sessionTimeoutController;
  late TextEditingController _sessionIdleWarningController;
  late TextEditingController _maxConcurrentSessionsController;
  late TextEditingController _passwordMinLengthController;
  late TextEditingController _maxUploadSizeController;
  late TextEditingController _apiBaseUrlController;
  late TextEditingController _webhookUrlController;
  late TextEditingController _apiRateLimitController;
  late TextEditingController _googleMapsApiKeyController;
  late TextEditingController _googleMapsLatController;
  late TextEditingController _googleMapsLngController;
  late TextEditingController _googleMapsZoomController;

  // Track unsaved changes
  bool _hasUnsavedChanges = false;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _loadError;
  String _sensorIngestApiKey = '';

  int _selectedNavIndex = 8;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadConfiguration();
  }

  void _initializeControllers() {
    _sessionTimeoutController =
        TextEditingController(text: _defaultConfig['sessionTimeout'])
          ..addListener(_onConfigChanged);
    _sessionIdleWarningController =
        TextEditingController(text: _defaultConfig['sessionIdleWarningMinutes'])
          ..addListener(_onConfigChanged);
    _maxConcurrentSessionsController =
        TextEditingController(text: _defaultConfig['maxConcurrentSessions'])
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
    _googleMapsApiKeyController =
        TextEditingController(text: _defaultConfig['googleMapsApiKey'])
          ..addListener(_onConfigChanged);
    _googleMapsLatController =
        TextEditingController(text: _defaultConfig['googleMapsDefaultLat'])
          ..addListener(_onConfigChanged);
    _googleMapsLngController =
        TextEditingController(text: _defaultConfig['googleMapsDefaultLng'])
          ..addListener(_onConfigChanged);
    _googleMapsZoomController =
        TextEditingController(text: _defaultConfig['googleMapsDefaultZoom'])
          ..addListener(_onConfigChanged);
  }

  @override
  void dispose() {
    _sessionTimeoutController.dispose();
    _sessionIdleWarningController.dispose();
    _maxConcurrentSessionsController.dispose();
    _passwordMinLengthController.dispose();
    _maxUploadSizeController.dispose();
    _apiBaseUrlController.dispose();
    _webhookUrlController.dispose();
    _apiRateLimitController.dispose();
    _googleMapsApiKeyController.dispose();
    _googleMapsLatController.dispose();
    _googleMapsLngController.dispose();
    _googleMapsZoomController.dispose();
    super.dispose();
  }

  Future<void> _loadConfiguration() async {
    setState(() {
      _isLoading = true;
      _loadError = null;
    });

    try {
      final config = await _apiService.getSystemConfig();
      if (!mounted) return;
      _applyBackendConfig(config, markDirty: false);
      setState(() {
        _isLoading = false;
        _hasUnsavedChanges = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _loadError = error.toString();
      });
    }
  }

  void _applyBackendConfig(Map<String, dynamic> config,
      {required bool markDirty}) {
    setState(() {
      _emailNotifications =
          config['email_notifications'] as bool? ?? _emailNotifications;
      _smsNotifications =
          config['sms_notifications'] as bool? ?? _smsNotifications;
      _maintenanceMode =
          config['maintenance_mode'] as bool? ?? _maintenanceMode;
      _autoBackup = config['auto_backup'] as bool? ?? _autoBackup;
      _twoFactorAuth = config['two_factor_auth'] as bool? ?? _twoFactorAuth;
      _forceLogoutOnPasswordChange =
          config['force_logout_on_password_change'] as bool? ??
              _forceLogoutOnPasswordChange;
      _googleMapsEnabled =
          config['google_maps_enabled'] as bool? ?? _googleMapsEnabled;
      _currencyCode = (config['currency_code'] ?? _currencyCode).toString();

      _sessionTimeoutController.text =
          (config['session_timeout'] ?? _defaultConfig['sessionTimeout'])
              .toString();
      _sessionIdleWarningController.text =
          (config['session_idle_warning_minutes'] ??
                  _defaultConfig['sessionIdleWarningMinutes'])
              .toString();
      _maxConcurrentSessionsController.text =
          (config['max_concurrent_sessions'] ??
                  _defaultConfig['maxConcurrentSessions'])
              .toString();
      _passwordMinLengthController.text =
          (config['password_min_length'] ?? _defaultConfig['passwordMinLength'])
              .toString();
      _maxUploadSizeController.text =
          (config['max_upload_size'] ?? _defaultConfig['maxUploadSize'])
              .toString();
      _apiBaseUrlController.text =
          (config['api_base_url'] ?? _defaultConfig['apiBaseUrl']).toString();
      _webhookUrlController.text =
          (config['webhook_url'] ?? _defaultConfig['webhookUrl']).toString();
      _apiRateLimitController.text =
          (config['api_rate_limit'] ?? _defaultConfig['apiRateLimit'])
              .toString();
      _sensorIngestApiKey = (config['sensor_ingest_api_key'] ??
              _defaultConfig['sensorIngestApiKey'])
          .toString();
      _googleMapsApiKeyController.text =
          (config['google_maps_api_key'] ?? _defaultConfig['googleMapsApiKey'])
              .toString();
      _googleMapsLatController.text = (config['google_maps_default_lat'] ??
              _defaultConfig['googleMapsDefaultLat'])
          .toString();
      _googleMapsLngController.text = (config['google_maps_default_lng'] ??
              _defaultConfig['googleMapsDefaultLng'])
          .toString();
      _googleMapsZoomController.text = (config['google_maps_default_zoom'] ??
              _defaultConfig['googleMapsDefaultZoom'])
          .toString();
      _hasUnsavedChanges = markDirty;
    });
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
        case 'forceLogoutOnPasswordChange':
          _forceLogoutOnPasswordChange = value;
          break;
        case 'googleMapsEnabled':
          _googleMapsEnabled = value;
          break;
      }
    });
  }

  void _onCurrencyChanged(String? value) {
    if (value == null) return;
    setState(() {
      _currencyCode = value;
      _hasUnsavedChanges = true;
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
      'sessionIdleWarningMinutes': _sessionIdleWarningController.text,
      'maxConcurrentSessions': _maxConcurrentSessionsController.text,
      'forceLogoutOnPasswordChange': _forceLogoutOnPasswordChange,
      'passwordMinLength': _passwordMinLengthController.text,
      'maxUploadSize': _maxUploadSizeController.text,
      'apiBaseUrl': _apiBaseUrlController.text,
      'webhookUrl': _webhookUrlController.text,
      'apiRateLimit': _apiRateLimitController.text,
      'sensorIngestApiKey': _sensorIngestApiKey,
      'currencyCode': _currencyCode,
      'currencySymbol': _currencyCode == 'GHS' ? 'GHS' : _currencyCode,
      'googleMapsEnabled': _googleMapsEnabled,
      'googleMapsApiKey': _googleMapsApiKeyController.text,
      'googleMapsDefaultLat': _googleMapsLatController.text,
      'googleMapsDefaultLng': _googleMapsLngController.text,
      'googleMapsDefaultZoom': _googleMapsZoomController.text,
    };
  }

  Map<String, dynamic> _getBackendConfig(String updatedBy) {
    return {
      'email_notifications': _emailNotifications,
      'sms_notifications': _smsNotifications,
      'maintenance_mode': _maintenanceMode,
      'auto_backup': _autoBackup,
      'two_factor_auth': _twoFactorAuth,
      'session_timeout': int.tryParse(_sessionTimeoutController.text) ?? 30,
      'session_idle_warning_minutes':
          int.tryParse(_sessionIdleWarningController.text) ?? 5,
      'max_concurrent_sessions':
          int.tryParse(_maxConcurrentSessionsController.text) ?? 3,
      'force_logout_on_password_change': _forceLogoutOnPasswordChange,
      'password_min_length':
          int.tryParse(_passwordMinLengthController.text) ?? 8,
      'max_upload_size': int.tryParse(_maxUploadSizeController.text) ?? 50,
      'api_base_url': _apiBaseUrlController.text.trim(),
      'webhook_url': _webhookUrlController.text.trim(),
      'api_rate_limit': int.tryParse(_apiRateLimitController.text) ?? 1000,
      'sensor_ingest_api_key': _sensorIngestApiKey,
      'currency_code': _currencyCode,
      'currency_symbol': _currencyCode == 'GHS' ? 'GHS' : _currencyCode,
      'google_maps_enabled': _googleMapsEnabled,
      'google_maps_api_key': _googleMapsApiKeyController.text.trim(),
      'google_maps_default_lat':
          double.tryParse(_googleMapsLatController.text) ?? 5.6037,
      'google_maps_default_lng':
          double.tryParse(_googleMapsLngController.text) ?? -0.1870,
      'google_maps_default_zoom':
          int.tryParse(_googleMapsZoomController.text) ?? 10,
      'updated_by': updatedBy,
    };
  }

  List<String> _validateConfig() {
    final errors = <String>[];

    // Validate session timeout
    final sessionTimeout = int.tryParse(_sessionTimeoutController.text);
    if (sessionTimeout == null || sessionTimeout < 5 || sessionTimeout > 1440) {
      errors.add('Session timeout must be between 5 and 1440 minutes');
    }

    final idleWarning = int.tryParse(_sessionIdleWarningController.text);
    if (idleWarning == null || idleWarning < 1 || idleWarning > 120) {
      errors.add('Session idle warning must be between 1 and 120 minutes');
    } else if (sessionTimeout != null && idleWarning >= sessionTimeout) {
      errors.add('Session idle warning must be lower than session timeout');
    }

    final maxSessions = int.tryParse(_maxConcurrentSessionsController.text);
    if (maxSessions == null || maxSessions < 1 || maxSessions > 20) {
      errors.add('Max concurrent sessions must be between 1 and 20');
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

    final latitude = double.tryParse(_googleMapsLatController.text);
    if (latitude == null || latitude < -90 || latitude > 90) {
      errors.add('Google Maps latitude must be between -90 and 90');
    }

    final longitude = double.tryParse(_googleMapsLngController.text);
    if (longitude == null || longitude < -180 || longitude > 180) {
      errors.add('Google Maps longitude must be between -180 and 180');
    }

    final zoom = int.tryParse(_googleMapsZoomController.text);
    if (zoom == null || zoom < 1 || zoom > 22) {
      errors.add('Google Maps zoom must be between 1 and 22');
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
          selectedIndex: 8,
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

    if (_isLoading) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildConfigurationHero(isDark, isMobile),
          const SizedBox(height: AppSpacing.lg),
          const AdminDataSkeleton(rowCount: 5),
        ],
      );
    }

    if (_loadError != null) {
      return _buildLoadErrorState(isDark);
    }

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

  Widget _buildLoadErrorState(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(color: AppColors.error.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Unable to load system configuration',
            style: AppTypography.h6.copyWith(
              color: isDark ? Colors.white : AppColors.textPrimary,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _loadError ?? 'Unknown error',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ElevatedButton.icon(
            onPressed: _loadConfiguration,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Retry'),
          ),
        ],
      ),
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
                  fontWeight: FontWeight.w600,
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
              fontWeight: FontWeight.w500,
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  stat.value,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.titleMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
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
              'Password Minimum Length', _passwordMinLengthController, isDark,
              hint: '6-32 characters',
              suffix: 'chars',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
        ],
      ),
      _buildProfessionalSection(
        'Session Settings',
        'Prepare platform-wide login session rules for future enforcement.',
        Icons.timer_rounded,
        AppColors.info,
        isDark,
        [
          _buildProfessionalTextField(
              'Session Timeout', _sessionTimeoutController, isDark,
              hint: '5-1440 minutes',
              suffix: 'min',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          _buildProfessionalTextField(
              'Idle Warning Time', _sessionIdleWarningController, isDark,
              hint: '1-120 minutes',
              suffix: 'min',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          _buildProfessionalTextField('Max Concurrent Sessions',
              _maxConcurrentSessionsController, isDark,
              hint: '1-20 sessions',
              suffix: 'sessions',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly]),
          _buildProfessionalToggle(
              'Logout After Password Change',
              'End existing sessions after a password update.',
              _forceLogoutOnPasswordChange,
              (val) => _onToggleChanged('forceLogoutOnPasswordChange', val),
              isDark),
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
          _buildSensorApiGuide(isDark),
        ],
      ),
      _buildProfessionalSection(
        'Localization & Maps',
        'Set platform currency and Google Maps defaults for future map features.',
        Icons.map_rounded,
        AppColors.warning,
        isDark,
        [
          _buildCurrencySwitcher(isDark),
          _buildProfessionalToggle(
              'Google Maps',
              'Store Google Maps settings for farm location and routing features.',
              _googleMapsEnabled,
              (val) => _onToggleChanged('googleMapsEnabled', val),
              isDark),
          _buildProfessionalTextField(
              'Google Maps API Key', _googleMapsApiKeyController, isDark,
              hint: 'Optional until maps are enabled'),
          _buildProfessionalTextField(
              'Default Latitude', _googleMapsLatController, isDark,
              hint: '5.6037',
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true)),
          _buildProfessionalTextField(
              'Default Longitude', _googleMapsLngController, isDark,
              hint: '-0.1870',
              keyboardType: const TextInputType.numberWithOptions(
                  decimal: true, signed: true)),
          _buildProfessionalTextField(
              'Default Zoom', _googleMapsZoomController, isDark,
              hint: '1-22',
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
        if (constraints.maxWidth < 920) {
          return Column(
            children: [
              for (int i = 0; i < cards.length; i++) ...[
                cards[i],
                if (i != cards.length - 1)
                  const SizedBox(height: AppSpacing.lg),
              ],
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                children: [
                  cards[0],
                  const SizedBox(height: AppSpacing.lg),
                  cards[1],
                  const SizedBox(height: AppSpacing.lg),
                  cards[2],
                  const SizedBox(height: AppSpacing.lg),
                  cards[3],
                  const SizedBox(height: AppSpacing.lg),
                  cards[5],
                ],
              ),
            ),
            const SizedBox(width: AppSpacing.lg),
            Expanded(
              child: Column(
                children: [
                  cards[4],
                ],
              ),
            ),
          ],
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
                        fontWeight: FontWeight.w600,
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
                          fontWeight: FontWeight.w500,
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
                            fontWeight: FontWeight.w500,
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

  String get _sensorIngestEndpoint {
    final base =
        _apiBaseUrlController.text.trim().replaceAll(RegExp(r'/+$'), '');
    return '${base.isEmpty ? 'http://127.0.0.1:8000' : base}/sensors/ingest';
  }

  String get _sensorPayloadSample {
    return '''{
  "serial_number": "GH-FARM1-TEMP-001",
  "farmID": "farm_document_id",
  "farm_name": "Farm Estates Farm 1",
  "sensortype": "temperature",
  "model_number": "SHT31-GW01",
  "location": "Greenhouse A",
  "value": 24.6,
  "unit": "C",
  "range_min": 18,
  "range_max": 28,
  "warning_min": 15,
  "warning_max": 32,
  "alerts_enabled": true,
  "maintenance_frequency": "Monthly"
}''';
  }

  String get _sensorCurlSample {
    return '''curl -X POST "$_sensorIngestEndpoint" \\
  -H "Content-Type: application/json" \\
  -H "x-sensor-key: <FARM_SENSOR_API_KEY>" \\
  -d '${_sensorPayloadSample.replaceAll('\n', ' ')}' ''';
  }

  Widget _buildSensorApiGuide(bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.info.withOpacity(isDark ? 0.12 : 0.07),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.info.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: AppColors.info.withOpacity(0.14),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: const Icon(
                  Icons.sensors_rounded,
                  color: AppColors.info,
                  size: 18,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  'Sensor Hardware API',
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Send each gateway or device reading as JSON. Each farm uses its own API key from Farm Management. Existing devices are updated by serial number; first-time devices must include farm and sensor metadata.',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildCopyableApiValue(
            label: 'POST endpoint',
            value: _sensorIngestEndpoint,
            isDark: isDark,
          ),
          _buildCopyableApiValue(
            label: 'Security header',
            value: 'x-sensor-key: <FARM_SENSOR_API_KEY>',
            isDark: isDark,
          ),
          _buildCopyableApiValue(
            label: 'JSON payload',
            value: _sensorPayloadSample,
            isDark: isDark,
            multiLine: true,
          ),
          _buildCopyableApiValue(
            label: 'cURL test',
            value: _sensorCurlSample,
            isDark: isDark,
            multiLine: true,
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'For Android emulator tests use http://10.0.2.2:8000/sensors/ingest. For real hardware use the LAN, VPN, or public HTTPS address of the FastAPI server.',
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white54 : AppColors.textSecondary,
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCopyableApiValue({
    required String label,
    required String value,
    required bool isDark,
    bool multiLine = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.05) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white10 : Colors.black.withOpacity(0.06),
        ),
      ),
      child: Row(
        crossAxisAlignment:
            multiLine ? CrossAxisAlignment.start : CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                SelectableText(
                  value,
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontFamily: 'monospace',
                    height: multiLine ? 1.35 : null,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Copy',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: value));
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('$label copied')),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            color: AppColors.info,
          ),
        ],
      ),
    );
  }

  Widget _buildCurrencySwitcher(bool isDark) {
    const currencies = ['GHS', 'USD', 'EUR', 'GBP'];

    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: DropdownButtonFormField<String>(
        value: _currencyCode,
        items: currencies
            .map(
              (currency) => DropdownMenuItem<String>(
                value: currency,
                child: Text(currency == 'GHS' ? 'GHS - Ghana Cedi' : currency),
              ),
            )
            .toList(),
        onChanged: _onCurrencyChanged,
        decoration: InputDecoration(
          labelText: 'Currency',
          hintText: 'Select platform currency',
          labelStyle: TextStyle(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
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
        dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
        style: TextStyle(
          color: isDark ? Colors.white : AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
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
            fontWeight: FontWeight.w500,
          ),
          hintStyle: TextStyle(
            color: isDark
                ? Colors.white38
                : AppColors.textSecondary.withOpacity(0.65),
          ),
          suffixStyle: TextStyle(
            color: isDark ? Colors.white54 : AppColors.textSecondary,
            fontWeight: FontWeight.w500,
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
          fontWeight: FontWeight.w500,
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
                      fontWeight: FontWeight.w500,
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
                                  fontWeight: FontWeight.w600)),
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
                          fontWeight: FontWeight.w500,
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
    if (_sessionIdleWarningController.text !=
        _defaultConfig['sessionIdleWarningMinutes'])
      changes.add('Session Idle Warning');
    if (_maxConcurrentSessionsController.text !=
        _defaultConfig['maxConcurrentSessions'])
      changes.add('Max Concurrent Sessions');
    if (_forceLogoutOnPasswordChange !=
        _defaultConfig['forceLogoutOnPasswordChange'])
      changes.add('Logout After Password Change');
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
    if (_currencyCode != _defaultConfig['currencyCode'])
      changes.add('Currency');
    if (_googleMapsEnabled != _defaultConfig['googleMapsEnabled'])
      changes.add('Google Maps');
    if (_googleMapsApiKeyController.text != _defaultConfig['googleMapsApiKey'])
      changes.add('Google Maps API Key');
    if (_googleMapsLatController.text != _defaultConfig['googleMapsDefaultLat'])
      changes.add('Default Latitude');
    if (_googleMapsLngController.text != _defaultConfig['googleMapsDefaultLng'])
      changes.add('Default Longitude');
    if (_googleMapsZoomController.text !=
        _defaultConfig['googleMapsDefaultZoom']) changes.add('Default Zoom');
    return changes.isEmpty ? ['All settings'] : changes;
  }

  void _resetToDefaults() {
    setState(() {
      _emailNotifications = _defaultConfig['emailNotifications'];
      _smsNotifications = _defaultConfig['smsNotifications'];
      _maintenanceMode = _defaultConfig['maintenanceMode'];
      _autoBackup = _defaultConfig['autoBackup'];
      _twoFactorAuth = _defaultConfig['twoFactorAuth'];
      _forceLogoutOnPasswordChange =
          _defaultConfig['forceLogoutOnPasswordChange'];
      _googleMapsEnabled = _defaultConfig['googleMapsEnabled'];
      _currencyCode = _defaultConfig['currencyCode'];
      _sessionTimeoutController.text = _defaultConfig['sessionTimeout'];
      _sessionIdleWarningController.text =
          _defaultConfig['sessionIdleWarningMinutes'];
      _maxConcurrentSessionsController.text =
          _defaultConfig['maxConcurrentSessions'];
      _passwordMinLengthController.text = _defaultConfig['passwordMinLength'];
      _maxUploadSizeController.text = _defaultConfig['maxUploadSize'];
      _apiBaseUrlController.text = _defaultConfig['apiBaseUrl'];
      _webhookUrlController.text = _defaultConfig['webhookUrl'];
      _apiRateLimitController.text = _defaultConfig['apiRateLimit'];
      _googleMapsApiKeyController.text = _defaultConfig['googleMapsApiKey'];
      _googleMapsLatController.text = _defaultConfig['googleMapsDefaultLat'];
      _googleMapsLngController.text = _defaultConfig['googleMapsDefaultLng'];
      _googleMapsZoomController.text = _defaultConfig['googleMapsDefaultZoom'];
      _hasUnsavedChanges = true;
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
                                  fontWeight: FontWeight.w600)),
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
                                  fontWeight: FontWeight.w500,
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

    try {
      final user = ref.read(currentUserProvider);
      final email = user?.email.trim();
      final updatedBy = email != null && email.isNotEmpty ? email : 'system';
      final config = _getBackendConfig(updatedBy);
      final savedConfig = await _apiService.updateSystemConfig(config);
      if (!context.mounted) return;
      _applyBackendConfig(savedConfig, markDirty: false);
      setState(() => _isSaving = false);
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
                        style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(
                        '${_getCurrentConfig().length} settings updated successfully',
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
    } catch (error) {
      if (!context.mounted) return;
      setState(() => _isSaving = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString()),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
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
                                  fontWeight: FontWeight.w600)),
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
                          fontWeight: FontWeight.w500,
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
