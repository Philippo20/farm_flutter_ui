import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/providers/theme_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/caretaker_header.dart';
import '../../core/widgets/caretaker_mobile_bottom_nav.dart';
import '../../core/widgets/caretaker_sidebar.dart';
import '../../core/widgets/adaptive_logout_confirmation.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Settings screen for caretaker workflows.
/// Preferences are stored locally on the device using SharedPreferences.
class CareTakerSettingsScreen extends ConsumerStatefulWidget {
  const CareTakerSettingsScreen({super.key});

  @override
  ConsumerState<CareTakerSettingsScreen> createState() =>
      _CareTakerSettingsScreenState();
}

class _CareTakerSettingsScreenState
    extends ConsumerState<CareTakerSettingsScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  static const _prefPrefix = 'caretaker_settings';

  int _selectedNavIndex = 5;

  bool _taskReminders = true;
  bool _anomalyAlerts = true;
  bool _weatherWarnings = true;
  bool _chatNotifications = true;
  bool _emailSummaries = false;
  bool _soundAlerts = true;

  bool _offlineMode = true;
  bool _autoSyncRecords = true;
  bool _compactCards = false;
  bool _biometricLock = false;

  String _shiftStart = '06:00 AM';
  String _reminderLeadTime = '30 minutes';
  String _defaultLandingPage = 'Dashboard';
  final SuperAdminApiService _api = SuperAdminApiService();
  bool _settingsSyncing = false;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
    _loadBackendSettings();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    if (!mounted) return;

    setState(() {
      _taskReminders = prefs.getBool(_prefKey('taskReminders')) ?? true;
      _anomalyAlerts = prefs.getBool(_prefKey('anomalyAlerts')) ?? true;
      _weatherWarnings = prefs.getBool(_prefKey('weatherWarnings')) ?? true;
      _chatNotifications = prefs.getBool(_prefKey('chatNotifications')) ?? true;
      _emailSummaries = prefs.getBool(_prefKey('emailSummaries')) ?? false;
      _soundAlerts = prefs.getBool(_prefKey('soundAlerts')) ?? true;
      _offlineMode = prefs.getBool(_prefKey('offlineMode')) ?? true;
      _autoSyncRecords = prefs.getBool(_prefKey('autoSyncRecords')) ?? true;
      _compactCards = prefs.getBool(_prefKey('compactCards')) ?? false;
      _biometricLock = prefs.getBool(_prefKey('biometricLock')) ?? false;
      _shiftStart = prefs.getString(_prefKey('shiftStart')) ?? '06:00 AM';
      _reminderLeadTime =
          prefs.getString(_prefKey('reminderLeadTime')) ?? '30 minutes';
      _defaultLandingPage =
          prefs.getString(_prefKey('defaultLandingPage')) ?? 'Dashboard';
    });
  }

  Future<void> _loadBackendSettings() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || userId.isEmpty) return;
    try {
      final settings = await _api.getCaretakerSettings(userId);
      if (!mounted) return;
      setState(() {
        _taskReminders = settings['task_reminders'] as bool? ?? _taskReminders;
        _anomalyAlerts = settings['anomaly_alerts'] as bool? ?? _anomalyAlerts;
        _weatherWarnings =
            settings['weather_warnings'] as bool? ?? _weatherWarnings;
        _chatNotifications =
            settings['chat_notifications'] as bool? ?? _chatNotifications;
        _emailSummaries =
            settings['email_summaries'] as bool? ?? _emailSummaries;
        _soundAlerts = settings['sound_alerts'] as bool? ?? _soundAlerts;
        _offlineMode = settings['offline_mode'] as bool? ?? _offlineMode;
        _autoSyncRecords =
            settings['auto_sync_records'] as bool? ?? _autoSyncRecords;
        _compactCards = settings['compact_cards'] as bool? ?? _compactCards;
        _biometricLock = settings['biometric_lock'] as bool? ?? _biometricLock;
        _shiftStart = settings['shift_start'] as String? ?? _shiftStart;
        _reminderLeadTime =
            settings['reminder_lead_time'] as String? ?? _reminderLeadTime;
        _defaultLandingPage =
            settings['default_landing_page'] as String? ?? _defaultLandingPage;
      });
      final theme = settings['theme_mode']?.toString();
      if (theme == 'light') {
        ref.read(themeProvider.notifier).setTheme(ThemeMode.light);
      } else if (theme == 'dark') {
        ref.read(themeProvider.notifier).setTheme(ThemeMode.dark);
      }
    } catch (error) {
      if (mounted) {
        _showMessage('Using local settings until sync is available.');
      }
    }
  }

  Map<String, dynamic> _settingsPayload() => {
        'task_reminders': _taskReminders,
        'anomaly_alerts': _anomalyAlerts,
        'weather_warnings': _weatherWarnings,
        'chat_notifications': _chatNotifications,
        'email_summaries': _emailSummaries,
        'sound_alerts': _soundAlerts,
        'offline_mode': _offlineMode,
        'auto_sync_records': _autoSyncRecords,
        'compact_cards': _compactCards,
        'biometric_lock': _biometricLock,
        'shift_start': _shiftStart,
        'reminder_lead_time': _reminderLeadTime,
        'default_landing_page': _defaultLandingPage,
        'theme_mode': ref.read(themeProvider).name,
      };

  Future<void> _persistSettings() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || userId.isEmpty) return;
    if (mounted) setState(() => _settingsSyncing = true);
    try {
      await _api.updateCaretakerSettings(
        userId: userId,
        settings: _settingsPayload(),
      );
    } catch (_) {
      if (mounted) _showMessage('Saved on this device. Backend sync failed.');
    } finally {
      if (mounted) setState(() => _settingsSyncing = false);
    }
  }

  String _prefKey(String key) => '$_prefPrefix.$key';

  Future<void> _saveBool(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(key), value);
  }

  Future<void> _saveString(String key, String value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey(key), value);
  }

  Future<void> _resetPreferences() async {
    final prefs = await SharedPreferences.getInstance();

    final keys = [
      'taskReminders',
      'anomalyAlerts',
      'weatherWarnings',
      'chatNotifications',
      'emailSummaries',
      'soundAlerts',
      'offlineMode',
      'autoSyncRecords',
      'compactCards',
      'biometricLock',
      'shiftStart',
      'reminderLeadTime',
      'defaultLandingPage',
    ];

    for (final key in keys) {
      await prefs.remove(_prefKey(key));
    }

    if (!mounted) return;

    setState(() {
      _taskReminders = true;
      _anomalyAlerts = true;
      _weatherWarnings = true;
      _chatNotifications = true;
      _emailSummaries = false;
      _soundAlerts = true;
      _offlineMode = true;
      _autoSyncRecords = true;
      _compactCards = false;
      _biometricLock = false;
      _shiftStart = '06:00 AM';
      _reminderLeadTime = '30 minutes';
      _defaultLandingPage = 'Dashboard';
    });

    await _persistSettings();
    _showMessage('Caretaker preferences reset and synced.');
  }

  Color _primaryTextColor(bool isDark) {
    return isDark ? Colors.white : AppColors.textPrimary;
  }

  Color _secondaryTextColor(bool isDark) {
    return isDark
        ? AppColors.textOnDark.withOpacity(0.82)
        : AppColors.textSecondary;
  }

  Color _inactiveNavColor(bool isDark) {
    return isDark
        ? AppColors.textOnDark.withOpacity(0.75)
        : AppColors.textSecondary;
  }

  Future<void> _confirmLogout(bool isDark) async {
    final confirmed = await showAdaptiveLogoutConfirmation(
      context,
      title: 'Sign out',
      message: 'End the current caretaker session on this device?',
      confirmLabel: 'Sign out',
    );

    if (!confirmed || !mounted) return;

    await ref.read(authProvider.notifier).logout();
    if (!mounted) return;

    Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Future<void> _setBoolPreference(
    String key,
    bool value,
    VoidCallback updater,
  ) async {
    setState(updater);
    await _saveBool(key, value);
    await _persistSettings();
  }

  Future<void> _setStringPreference(
    String key,
    String value,
    VoidCallback updater,
  ) async {
    setState(updater);
    await _saveString(key, value);
    await _persistSettings();
  }

  Future<void> _setTheme(ThemeMode mode) async {
    ref.read(themeProvider.notifier).setTheme(mode);
    await _saveString('themeMode', mode.name);
    await _persistSettings();
  }

  Widget _settingsModal({
    required BuildContext modalContext,
    required Widget title,
    required Widget content,
    required List<Widget> actions,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final surface = isDark ? AppColors.darkCard : AppColors.card;
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(20),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520, maxHeight: 680),
        child: Container(
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                child: DecoratedBox(
                  decoration: const BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.all(Radius.circular(12)),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 8, 12),
                    child: Row(
                      children: [
                        Expanded(
                          child: DefaultTextStyle(
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                            child: title,
                          ),
                        ),
                        IconButton(
                          tooltip: 'Close',
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(modalContext, false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 8),
                  child: content,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: actions,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _editProfile() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final addressController = TextEditingController(text: user.address);
    final formKey = GlobalKey<FormState>();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _settingsModal(
        modalContext: dialogContext,
        title: const Text('Edit profile'),
        content: Form(
          key: formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: nameController,
                  decoration: const InputDecoration(labelText: 'Full name'),
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Enter your name'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: emailController,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(labelText: 'Email'),
                  validator: (value) => value == null || !value.contains('@')
                      ? 'Enter a valid email'
                      : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: addressController,
                  decoration: const InputDecoration(labelText: 'Address'),
                ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Save changes'),
          ),
        ],
      ),
    );
    if (shouldSave != true || !mounted) {
      nameController.dispose();
      emailController.dispose();
      addressController.dispose();
      return;
    }
    try {
      await _api.updateUserProfile(
        id: user.id,
        name: nameController.text.trim(),
        email: emailController.text.trim(),
        address: addressController.text.trim(),
      );
      await ref.read(authProvider.notifier).updateCurrentUserProfile(
            name: nameController.text.trim(),
            email: emailController.text.trim(),
            address: addressController.text.trim(),
          );
      _showMessage('Profile updated successfully.');
    } catch (error) {
      _showMessage('Unable to update profile: $error');
    } finally {
      nameController.dispose();
      emailController.dispose();
      addressController.dispose();
    }
  }

  Future<void> _changePassword() async {
    final userId = ref.read(authProvider).user?.id;
    if (userId == null || userId.isEmpty) return;
    final passwordController = TextEditingController();
    final confirmController = TextEditingController();
    final formKey = GlobalKey<FormState>();
    final shouldSave = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => _settingsModal(
        modalContext: dialogContext,
        title: const Text('Change password'),
        content: Form(
          key: formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: passwordController,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'New password'),
                validator: (value) => value == null || value.length < 8
                    ? 'Use at least 8 characters'
                    : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: confirmController,
                obscureText: true,
                decoration:
                    const InputDecoration(labelText: 'Confirm password'),
                validator: (value) => value != passwordController.text
                    ? 'Passwords do not match'
                    : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              if (formKey.currentState?.validate() ?? false) {
                Navigator.pop(dialogContext, true);
              }
            },
            child: const Text('Update password'),
          ),
        ],
      ),
    );
    if (shouldSave != true || !mounted) {
      passwordController.dispose();
      confirmController.dispose();
      return;
    }
    try {
      await _api.updateUserPassword(
        id: userId,
        password: passwordController.text,
      );
      _showMessage('Password updated successfully.');
    } catch (error) {
      _showMessage('Unable to update password: $error');
    } finally {
      passwordController.dispose();
      confirmController.dispose();
    }
  }

  void _showHelpCenter() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => _settingsModal(
        modalContext: dialogContext,
        title: const Text('Caretaker help center'),
        content: const SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Input confirmations',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text(
                  'Review assigned inputs and update them as Received or Confirmed.'),
              SizedBox(height: 14),
              Text('Records and tasks',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text(
                  'Use the task and record screens to keep farm activity current. Changes are synced to the backend.'),
              SizedBox(height: 14),
              Text('Connectivity',
                  style: TextStyle(fontWeight: FontWeight.w700)),
              SizedBox(height: 4),
              Text(
                  'Keep Auto-sync enabled so saved work is sent when connectivity returns.'),
            ],
          ),
        ),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  Future<void> _navigateTo(String route, int index) async {
    if (_selectedNavIndex == index) return;

    setState(() => _selectedNavIndex = index);

    try {
      await Navigator.pushReplacementNamed(context, route);
    } catch (_) {
      if (!mounted) return;
      try {
        await Navigator.pushNamed(context, route);
      } catch (error) {
        _showMessage('Navigation error: $error');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final themeMode = ref.watch(themeProvider);
    final userName = authState.user?.name ?? 'Caretaker';
    final userEmail = authState.user?.email ?? 'caretaker@farmestates.com';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? CaretakerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
              userName: userName,
              userEmail: userEmail,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName, userEmail, themeMode)
          : _buildDesktopLayout(isDark, userName, userEmail, themeMode),
      bottomNavigationBar: isMobile
          ? CaretakerMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(
    bool isDark,
    String userName,
    String userEmail,
    ThemeMode themeMode,
  ) {
    return Row(
      children: [
        CaretakerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Caretaker',
        ),
        Expanded(
          child: Column(
            children: [
              CaretakerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildContent(
                      isDark, false, userName, userEmail, themeMode),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(
    bool isDark,
    String userName,
    String userEmail,
    ThemeMode themeMode,
  ) {
    return Column(
      children: [
        CaretakerHeader(
          userName: userName,
          onNotificationTap: () {},
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              100,
            ),
            child: _buildContent(isDark, true, userName, userEmail, themeMode),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(
    bool isDark,
    bool isMobile,
    String userName,
    String userEmail,
    ThemeMode themeMode,
  ) {
    final leftColumn = Column(
      children: [
        _buildProfileSection(isDark, userName, userEmail),
        const SizedBox(height: AppSpacing.md),
        _buildAppearanceSection(isDark, themeMode),
        const SizedBox(height: AppSpacing.md),
        _buildNotificationSection(isDark),
      ],
    );

    final rightColumn = Column(
      children: [
        _buildWorkPreferencesSection(isDark),
        const SizedBox(height: AppSpacing.md),
        _buildDeviceSection(isDark),
        const SizedBox(height: AppSpacing.md),
        _buildSupportSection(isDark),
      ],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeroHeader(isDark, isMobile),
        const SizedBox(height: AppSpacing.lg),
        if (isMobile) ...[
          leftColumn,
          const SizedBox(height: AppSpacing.md),
          rightColumn,
        ] else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: leftColumn),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: rightColumn),
            ],
          ),
      ],
    );
  }

  Widget _buildHeroHeader(bool isDark, bool isMobile) {
    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [
                  AppColors.primary.withOpacity(0.22),
                  AppColors.surfaceDark,
                ]
              : [
                  AppColors.primary.withOpacity(0.12),
                  Colors.white,
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: AppColors.primary.withOpacity(isDark ? 0.3 : 0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.sm,
              vertical: AppSpacing.xs,
            ),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            ),
            child: Text(
              'Caretaker Workspace',
              style: AppTypography.labelSmall.copyWith(
                color: AppColors.primaryDark,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.4,
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Settings',
            style: AppTypography.h4.copyWith(
              color: _primaryTextColor(isDark),
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(
            'Control reminders, appearance, offline behavior, and device preferences for daily farm operations.',
            style: AppTypography.bodyMedium.copyWith(
              color: _secondaryTextColor(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Icon(
                Icons.verified_user_outlined,
                size: 16,
                color: isDark
                    ? Colors.white.withOpacity(0.9)
                    : AppColors.primaryDark,
              ),
              const SizedBox(width: AppSpacing.xs),
              Expanded(
                child: Text(
                  _settingsSyncing
                      ? 'Saving changes to your caretaker profile...'
                      : 'Changes sync to your caretaker profile automatically.',
                  style: AppTypography.bodySmall.copyWith(
                    color: _secondaryTextColor(isDark),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildProfileSection(bool isDark, String userName, String userEmail) {
    final initials = userName
        .trim()
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0].toUpperCase())
        .join();

    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.person_outline_rounded,
            title: 'Profile',
            subtitle: 'Current account identity for caretaker operations',
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Center(
                  child: Text(
                    initials.isEmpty ? 'CT' : initials,
                    style: AppTypography.h6.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      userName,
                      style: AppTypography.h6.copyWith(
                        color: _primaryTextColor(isDark),
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      userEmail,
                      style: AppTypography.bodySmall.copyWith(
                        color: _secondaryTextColor(isDark),
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSpacing.sm,
                        vertical: AppSpacing.xs,
                      ),
                      decoration: BoxDecoration(
                        color: AppColors.info.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                      ),
                      child: Text(
                        'Caretaker role',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.info,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          _buildInfoRow(
            isDark,
            icon: Icons.assignment_turned_in_outlined,
            label: 'Primary workspace',
            value: _defaultLandingPage,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildInfoRow(
            isDark,
            icon: Icons.schedule_outlined,
            label: 'Shift starts',
            value: _shiftStart,
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _editProfile,
                  icon: const Icon(Icons.edit_outlined, size: 18),
                  label: const Text('Edit Profile'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryTextColor(isDark),
                    side: BorderSide(
                      color: isDark
                          ? Colors.white.withOpacity(0.14)
                          : AppColors.neutral300,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: _changePassword,
                  icon: const Icon(Icons.lock_outline_rounded, size: 18),
                  label: const Text('Security'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAppearanceSection(bool isDark, ThemeMode themeMode) {
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.palette_outlined,
            title: 'Appearance',
            subtitle: 'Choose how the caretaker workspace looks',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildThemeOption(
            isDark: isDark,
            title: 'Light mode',
            subtitle: 'Higher contrast for bright environments',
            icon: Icons.light_mode_outlined,
            isSelected: themeMode == ThemeMode.light,
            onTap: () => _setTheme(ThemeMode.light),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildThemeOption(
            isDark: isDark,
            title: 'Dark mode',
            subtitle: 'Reduce glare during night or indoor monitoring',
            icon: Icons.dark_mode_outlined,
            isSelected: themeMode == ThemeMode.dark,
            onTap: () => _setTheme(ThemeMode.dark),
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.dashboard_customize_outlined,
            title: 'Compact cards',
            subtitle: 'Use denser cards for more information on screen',
            value: _compactCards,
            onChanged: (value) => _setBoolPreference(
              'compactCards',
              value,
              () => _compactCards = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNotificationSection(bool isDark) {
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.notifications_active_outlined,
            title: 'Notifications',
            subtitle: 'Tune alerts for work reminders and incidents',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.task_alt_outlined,
            title: 'Task reminders',
            subtitle: 'Remind me about scheduled field tasks',
            value: _taskReminders,
            onChanged: (value) => _setBoolPreference(
              'taskReminders',
              value,
              () => _taskReminders = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.sensors_outlined,
            title: 'Anomaly alerts',
            subtitle: 'Flag unexpected sensor readings immediately',
            value: _anomalyAlerts,
            onChanged: (value) => _setBoolPreference(
              'anomalyAlerts',
              value,
              () => _anomalyAlerts = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.cloud_queue_outlined,
            title: 'Weather warnings',
            subtitle: 'Surface weather-driven risk alerts',
            value: _weatherWarnings,
            onChanged: (value) => _setBoolPreference(
              'weatherWarnings',
              value,
              () => _weatherWarnings = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.chat_bubble_outline_rounded,
            title: 'Chat notifications',
            subtitle: 'Show alerts for supervisor and team messages',
            value: _chatNotifications,
            onChanged: (value) => _setBoolPreference(
              'chatNotifications',
              value,
              () => _chatNotifications = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.mail_outline_rounded,
            title: 'Email summaries',
            subtitle: 'Send daily summaries to the signed-in email address',
            value: _emailSummaries,
            onChanged: (value) => _setBoolPreference(
              'emailSummaries',
              value,
              () => _emailSummaries = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.volume_up_outlined,
            title: 'Sound alerts',
            subtitle: 'Play a short tone when critical alerts arrive',
            value: _soundAlerts,
            onChanged: (value) => _setBoolPreference(
              'soundAlerts',
              value,
              () => _soundAlerts = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWorkPreferencesSection(bool isDark) {
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.tune_outlined,
            title: 'Work Preferences',
            subtitle: 'Default behavior for daily caretaker routines',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDropdownField(
            isDark: isDark,
            icon: Icons.schedule_outlined,
            label: 'Shift start time',
            value: _shiftStart,
            items: const ['05:00 AM', '06:00 AM', '07:00 AM', '08:00 AM'],
            onChanged: (value) {
              if (value == null) return;
              _setStringPreference(
                'shiftStart',
                value,
                () => _shiftStart = value,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDropdownField(
            isDark: isDark,
            icon: Icons.alarm_outlined,
            label: 'Reminder lead time',
            value: _reminderLeadTime,
            items: const ['15 minutes', '30 minutes', '1 hour', '2 hours'],
            onChanged: (value) {
              if (value == null) return;
              _setStringPreference(
                'reminderLeadTime',
                value,
                () => _reminderLeadTime = value,
              );
            },
          ),
          const SizedBox(height: AppSpacing.md),
          _buildDropdownField(
            isDark: isDark,
            icon: Icons.home_outlined,
            label: 'Default landing page',
            value: _defaultLandingPage,
            items: const [
              'Dashboard',
              'Record Entry',
              'Input Confirmation',
              'Calendar',
            ],
            onChanged: (value) {
              if (value == null) return;
              _setStringPreference(
                'defaultLandingPage',
                value,
                () => _defaultLandingPage = value,
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildDeviceSection(bool isDark) {
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.phone_android_outlined,
            title: 'Device & Data',
            subtitle: 'Control sync, offline handling, and lock behavior',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.cloud_off_outlined,
            title: 'Offline mode',
            subtitle: 'Keep forms usable when connection quality drops',
            value: _offlineMode,
            onChanged: (value) => _setBoolPreference(
              'offlineMode',
              value,
              () => _offlineMode = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.sync_outlined,
            title: 'Auto-sync records',
            subtitle: 'Push saved records when connectivity returns',
            value: _autoSyncRecords,
            onChanged: (value) => _setBoolPreference(
              'autoSyncRecords',
              value,
              () => _autoSyncRecords = value,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildSwitchTile(
            isDark: isDark,
            icon: Icons.fingerprint_outlined,
            title: 'Biometric lock',
            subtitle: 'Require device biometrics before opening the app',
            value: _biometricLock,
            onChanged: (value) => _setBoolPreference(
              'biometricLock',
              value,
              () => _biometricLock = value,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSupportSection(bool isDark) {
    return _sectionCard(
      isDark,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildSectionHeader(
            isDark,
            icon: Icons.shield_outlined,
            title: 'Support & Session',
            subtitle: 'Reset local settings, get help, or end this session',
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActionTile(
            isDark: isDark,
            icon: Icons.help_outline_rounded,
            title: 'Help center',
            subtitle: 'Get guidance for records, alerts, and reporting',
            onTap: _showHelpCenter,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildActionTile(
            isDark: isDark,
            icon: Icons.restart_alt_rounded,
            title: 'Reset local preferences',
            subtitle: 'Restore the default caretaker settings on this device',
            onTap: _resetPreferences,
          ),
          const SizedBox(height: AppSpacing.sm),
          _buildActionTile(
            isDark: isDark,
            icon: Icons.logout_rounded,
            title: 'Sign out',
            subtitle: 'Log out and return to the login screen',
            iconColor: AppColors.error,
            onTap: () => _confirmLogout(isDark),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(bool isDark, {required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
        ),
        boxShadow: isDark
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.04),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: child,
    );
  }

  Widget _buildSectionHeader(
    bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.primary.withOpacity(0.12),
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: Icon(icon, color: AppColors.primary, size: 20),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.h6.copyWith(
                  color: _primaryTextColor(isDark),
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.bodySmall.copyWith(
                  color: _secondaryTextColor(isDark),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildInfoRow(
    bool isDark, {
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: _secondaryTextColor(isDark),
            ),
          ),
        ),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            color: _primaryTextColor(isDark),
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _buildThemeOption({
    required bool isDark,
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withOpacity(isDark ? 0.18 : 0.1)
              : (isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: isSelected
                ? AppColors.primary.withOpacity(0.5)
                : (isDark
                    ? Colors.white.withOpacity(0.08)
                    : AppColors.neutral200),
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected
                    ? AppColors.primary.withOpacity(0.18)
                    : AppColors.neutral300.withOpacity(0.18),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(
                icon,
                size: 20,
                color: isSelected
                    ? AppColors.primary
                    : _secondaryTextColor(isDark),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: _primaryTextColor(isDark),
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: _secondaryTextColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
              color:
                  isSelected ? AppColors.primary : _secondaryTextColor(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSwitchTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(icon, size: 18, color: AppColors.primary),
          ),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTypography.bodyMedium.copyWith(
                    color: _primaryTextColor(isDark),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: AppTypography.caption.copyWith(
                    color: _secondaryTextColor(isDark),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Switch.adaptive(
            value: value,
            activeColor: AppColors.primary,
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildDropdownField({
    required bool isDark,
    required IconData icon,
    required String label,
    required String value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: AppColors.primary),
            const SizedBox(width: AppSpacing.xs),
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: _secondaryTextColor(isDark),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        DropdownButtonFormField<String>(
          value: value,
          dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
          decoration: InputDecoration(
            filled: true,
            fillColor:
                isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.md,
              vertical: 14,
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : AppColors.neutral300,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.12)
                    : AppColors.neutral300,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              borderSide: const BorderSide(
                color: AppColors.primary,
                width: 1.3,
              ),
            ),
          ),
          style: AppTypography.bodyMedium.copyWith(
            color: _primaryTextColor(isDark),
          ),
          iconEnabledColor: _secondaryTextColor(isDark),
          items: items
              .map(
                (item) => DropdownMenuItem<String>(
                  value: item,
                  child: Text(
                    item,
                    style: AppTypography.bodySmall.copyWith(
                      color: _primaryTextColor(isDark),
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: onChanged,
        ),
      ],
    );
  }

  Widget _buildActionTile({
    required bool isDark,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? iconColor,
  }) {
    final resolvedIconColor = iconColor ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: resolvedIconColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              ),
              child: Icon(icon, size: 20, color: resolvedIconColor),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodyMedium.copyWith(
                      color: _primaryTextColor(isDark),
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: AppTypography.caption.copyWith(
                      color: _secondaryTextColor(isDark),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: _secondaryTextColor(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/caretaker_dashboard',
      },
      {
        'icon': Icons.edit_note_outlined,
        'label': 'Record',
        'index': 1,
        'route': '/record-entry',
      },
      {
        'icon': Icons.check_circle_outline,
        'label': 'Confirm',
        'index': 2,
        'route': '/input-confirmation',
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'Chat',
        'index': 3,
        'route': '/chat',
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Calendar',
        'index': 4,
        'route': '/calendar',
      },
      {
        'icon': Icons.settings_outlined,
        'label': 'Settings',
        'index': 5,
        'route': '/caretaker_settings',
      },
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
            color:
                isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            children: navItems.map((item) {
              final index = item['index'] as int;
              final isSelected = _selectedNavIndex == index;

              return Expanded(
                child: InkWell(
                  onTap: () => _navigateTo(item['route'] as String, index),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item['icon'] as IconData,
                        size: 24,
                        color: isSelected
                            ? AppColors.primary
                            : _inactiveNavColor(isDark),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item['label'] as String,
                        style: AppTypography.caption.copyWith(
                          color: isSelected
                              ? AppColors.primary
                              : _inactiveNavColor(isDark),
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          fontSize: 11,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }
}
