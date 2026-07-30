import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/models/records/farm_record_model.dart';
import '../../core/providers/records_provider.dart';
import '../../core/widgets/caretaker_sidebar.dart';
import '../../core/widgets/caretaker_header.dart';
import '../../core/widgets/caretaker_mobile_bottom_nav.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Record Entry Screen
/// Create and submit farm records for daily monitoring and activities
class RecordEntryScreen extends ConsumerStatefulWidget {
  const RecordEntryScreen({super.key});

  @override
  ConsumerState<RecordEntryScreen> createState() => _RecordEntryScreenState();
}

class _RecordEntryScreenState extends ConsumerState<RecordEntryScreen> {
  final SuperAdminApiService _api = SuperAdminApiService();
  final _formKey = GlobalKey<FormState>();
  int _selectedNavIndex = 1;
  int _selectedRecordTab = 0;

  // Form fields
  String? _selectedFarm;
  String? _selectedBatch;
  String _selectedRecordType = 'daily_monitoring';
  DateTime _recordDate = DateTime.now();

  // Environmental readings
  final _temperatureController = TextEditingController();
  final _humidityController = TextEditingController();
  final _phController = TextEditingController();
  final _ecController = TextEditingController();
  final _lightController = TextEditingController();

  // Plant observations
  final _plantHealthController = TextEditingController();
  final _growthStageController = TextEditingController();
  final _plantCountController = TextEditingController();
  final _observationsController = TextEditingController();

  // Activities and issues
  final List<String> _selectedActivities = [];
  bool _hasIssues = false;
  String _issueSeverity = 'low';
  final _issueDescriptionController = TextEditingController();

  // Notes
  final _notesController = TextEditingController();

  bool _isSubmitting = false;
  bool _isLoading = true;
  String? _errorMessage;
  List<Map<String, dynamic>> _farms = [];
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _tasks = [];

  @override
  void initState() {
    super.initState();
    _loadRecordData();
  }

  @override
  void dispose() {
    _temperatureController.dispose();
    _humidityController.dispose();
    _phController.dispose();
    _ecController.dispose();
    _lightController.dispose();
    _plantHealthController.dispose();
    _growthStageController.dispose();
    _plantCountController.dispose();
    _observationsController.dispose();
    _issueDescriptionController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  String _value(Map<String, dynamic> doc, List<String> keys,
      {String fallback = ''}) {
    for (final key in keys) {
      final value = doc[key];
      if (value != null && value.toString().trim().isNotEmpty) {
        return value.toString();
      }
    }
    return fallback;
  }

  String _farmId(Map<String, dynamic> farm) =>
      _value(farm, const [r'$id', 'farm_id', 'id']);

  String _batchId(Map<String, dynamic> batch) =>
      _value(batch, const [r'$id', 'batch_id', 'id', 'batch_no']);

  bool _matchesCurrentCaretaker(Map<String, dynamic> farm) {
    final user = ref.read(authProvider).user;
    if (user == null) return false;
    final caretaker = _value(farm, const ['caretakerID', 'caretaker_id']);
    final caretakerName = _value(farm, const ['caretaker_name']);
    return caretaker == user.id ||
        caretaker == user.email ||
        caretaker == user.name ||
        caretakerName.toLowerCase() == user.name.toLowerCase();
  }

  List<Map<String, dynamic>> get _assignedFarms {
    final farms = _farms.where(_matchesCurrentCaretaker).toList();
    if (farms.isNotEmpty) return farms;
    final user = ref.read(authProvider).user;
    if (user == null) return [];
    return _farms.where((farm) {
      final text = farm.values.join(' ').toLowerCase();
      return text.contains(user.id.toLowerCase()) ||
          text.contains(user.email.toLowerCase()) ||
          text.contains(user.name.toLowerCase());
    }).toList();
  }

  Map<String, dynamic>? get _selectedFarmDoc {
    if (_selectedFarm == null) return null;
    try {
      return _assignedFarms
          .firstWhere((farm) => _farmId(farm) == _selectedFarm);
    } catch (_) {
      return null;
    }
  }

  List<Map<String, dynamic>> get _farmBatches {
    final farm = _selectedFarmDoc;
    if (farm == null) return [];
    final farmId = _farmId(farm);
    final farmName = _value(farm, const ['name', 'farm_name']);
    return _batches.where((batch) {
      return _value(batch, const ['farmID', 'farm_id', 'farmId']) == farmId ||
          _value(batch, const ['farm_name']) == farmName;
    }).toList();
  }

  Map<String, dynamic>? get _selectedBatchDoc {
    if (_selectedBatch == null) return null;
    for (final batch in _farmBatches) {
      if (_batchId(batch) == _selectedBatch) return batch;
    }
    return null;
  }

  List<Map<String, dynamic>> get _assignedTasks {
    final user = ref.read(authProvider).user;
    return _tasks.where((task) {
      final assignee = _value(task,
          const ['assigned_to_id', 'assigned_to_email', 'assigned_to_name']);
      final direct = user != null &&
          (assignee == user.id ||
              assignee == user.email ||
              assignee == user.name);
      if (direct) return true;
      final farm = _selectedFarmDoc;
      if (farm == null) return false;
      return _value(task, const ['farm_id', 'farmID']) == _farmId(farm) ||
          _value(task, const ['farm_name']) ==
              _value(farm, const ['name', 'farm_name']);
    }).toList();
  }

  Future<void> _loadRecordData() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });
    try {
      final results = await Future.wait([
        _api.getFarms(),
        _api.getBatches(),
        _api.getFarmTasks(),
      ]);
      if (!mounted) return;
      setState(() {
        _farms = results[0];
        _batches = results[1];
        _tasks = results[2];
        final assigned = _assignedFarms;
        if (assigned.isNotEmpty && _selectedFarm == null) {
          _selectedFarm = _farmId(assigned.first);
        }
        final batches = _farmBatches;
        if (batches.isNotEmpty && _selectedBatch == null) {
          _selectedBatch = _batchId(batches.first);
        }
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.toString();
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Caretaker';
    final userEmail = authState.user?.email ?? 'caretaker@farmestates.com';
    final userRole = 'Caretaker';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile
          ? SafeArea(
              top: false,
              child: CaretakerMobileBottomNav(
                selectedIndex: _selectedNavIndex,
                onItemSelected: (index) =>
                    setState(() => _selectedNavIndex = index),
              ))
          : null,
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        CaretakerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) {
            setState(() => _selectedNavIndex = index);
          },
          userName: userName,
          userEmail: userEmail,
          userRole: userRole,
        ),
        Expanded(
          child: Column(
            children: [
              CaretakerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: Form(
                  key: _formKey,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: _buildFormContent(isDark),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(bool isDark, String userName) {
    return Column(
      children: [
        CaretakerHeader(
          userName: userName,
          onNotificationTap: () {},
        ),
        Expanded(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: _buildFormContent(isDark),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFormContent(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (_isLoading) {
      return const AdminDataSkeleton(rowCount: 6);
    }
    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }

    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: isMobile ? screenWidth : 1060),
        child: Column(
          children: [
            _buildHeader(isDark),
            SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),
            _buildRecordTabs(isDark),
            SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
            _buildActiveRecordSection(isDark, isMobile),
            SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
            _buildSubmitButton(isDark),
            SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  List<({String title, String subtitle, IconData icon})> get _recordTabs =>
      const [
        (
          title: 'Basic',
          subtitle: 'Farm, batch, type, and date',
          icon: Icons.info_outline_rounded
        ),
        (
          title: 'Environment',
          subtitle: 'Climate and nutrient readings',
          icon: Icons.sensors_rounded
        ),
        (
          title: 'Plants',
          subtitle: 'Health, stage, count, and notes',
          icon: Icons.spa_rounded
        ),
        (
          title: 'Activities',
          subtitle: 'Completed assigned work',
          icon: Icons.checklist_rounded
        ),
        (
          title: 'Issues',
          subtitle: 'Incidents and concerns',
          icon: Icons.report_problem_outlined
        ),
        (
          title: 'Notes',
          subtitle: 'Extra handover information',
          icon: Icons.sticky_note_2_outlined
        ),
      ];

  Widget _buildRecordTabs(bool isDark) {
    final tabs = _recordTabs;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
        ),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(tabs.length, (index) {
            final tab = tabs[index];
            final isSelected = index == _selectedRecordTab;
            return Padding(
              padding: EdgeInsets.only(
                right: index == tabs.length - 1 ? 0 : AppSpacing.xs,
              ),
              child: Tooltip(
                message: tab.subtitle,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => setState(() => _selectedRecordTab = index),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 180),
                    curve: Curves.easeOut,
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary.withOpacity(isDark ? 0.18 : 0.1)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary.withOpacity(0.45)
                            : Colors.transparent,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          tab.icon,
                          size: 18,
                          color: isSelected
                              ? AppColors.primary
                              : (isDark
                                  ? Colors.white60
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          tab.title,
                          style: AppTypography.bodySmall.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white70
                                    : AppColors.textSecondary),
                            fontWeight:
                                isSelected ? FontWeight.w700 : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _buildActiveRecordSection(bool isDark, bool isMobile) {
    final tab = _recordTabs[_selectedRecordTab];
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 180),
      switchInCurve: Curves.easeOut,
      switchOutCurve: Curves.easeIn,
      child: KeyedSubtree(
        key: ValueKey(_selectedRecordTab),
        child: _buildSection(
          title: tab.title == 'Basic' ? 'Basic Information' : tab.title,
          subtitle: tab.subtitle,
          icon: tab.icon,
          isDark: isDark,
          children:
              _recordSectionChildren(_selectedRecordTab, isDark, isMobile),
        ),
      ),
    );
  }

  List<Widget> _recordSectionChildren(int index, bool isDark, bool isMobile) {
    switch (index) {
      case 0:
        return [
          _buildFarmSelector(isDark),
          const SizedBox(height: AppSpacing.md),
          _buildBatchSelector(isDark),
          const SizedBox(height: AppSpacing.md),
          _buildRecordTypeSelector(isDark),
          const SizedBox(height: AppSpacing.md),
          _buildDatePicker(isDark),
        ];
      case 1:
        return [_buildEnvironmentFields(isDark, isMobile)];
      case 2:
        return [
          _buildTextField('Plant Health', _plantHealthController,
              'e.g., Healthy, Yellowing, etc.', isDark),
          const SizedBox(height: AppSpacing.md),
          _buildTextField('Growth Stage', _growthStageController,
              'e.g., Vegetative, Flowering', isDark),
          const SizedBox(height: AppSpacing.md),
          _buildNumberField('Plant Count', _plantCountController,
              Icons.format_list_numbered_rounded, isDark),
          const SizedBox(height: AppSpacing.md),
          _buildTextField('Observations', _observationsController,
              'Any notable observations...', isDark,
              maxLines: 3),
        ];
      case 3:
        return [_buildActivitiesSelector(isDark)];
      case 4:
        return [
          _buildIssuesToggle(isDark),
          if (_hasIssues) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSeveritySelector(isDark),
            const SizedBox(height: AppSpacing.md),
            _buildTextField(
              'Issue Description',
              _issueDescriptionController,
              'Describe the issue...',
              isDark,
              maxLines: 3,
            ),
          ],
        ];
      case 5:
        return [
          _buildTextField(
            'Notes',
            _notesController,
            'Any additional notes...',
            isDark,
            maxLines: 4,
          ),
        ];
      default:
        return const [];
    }
  }

  Widget _buildEnvironmentFields(bool isDark, bool isMobile) {
    if (isMobile) {
      return Column(
        children: [
          _buildNumberField('Temperature (C)', _temperatureController,
              Icons.thermostat_rounded, isDark),
          const SizedBox(height: AppSpacing.md),
          _buildNumberField('Humidity (%)', _humidityController,
              Icons.water_drop_rounded, isDark),
          const SizedBox(height: AppSpacing.md),
          _buildNumberField(
              'pH Level', _phController, Icons.science_rounded, isDark),
          const SizedBox(height: AppSpacing.md),
          _buildNumberField(
              'EC (mS/cm)', _ecController, Icons.bolt_rounded, isDark),
          const SizedBox(height: AppSpacing.md),
          _buildNumberField('Light Intensity (lux)', _lightController,
              Icons.light_mode_rounded, isDark),
        ],
      );
    }

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _buildNumberField('Temperature (C)',
                  _temperatureController, Icons.thermostat_rounded, isDark),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildNumberField('Humidity (%)', _humidityController,
                  Icons.water_drop_rounded, isDark),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildNumberField(
                  'pH Level', _phController, Icons.science_rounded, isDark),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildNumberField(
                  'EC (mS/cm)', _ecController, Icons.bolt_rounded, isDark),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        _buildNumberField('Light Intensity (lux)', _lightController,
            Icons.light_mode_rounded, isDark),
      ],
    );
  }

  // ignore: unused_element
  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/caretaker_dashboard'
      },
      {
        'icon': Icons.edit_note_outlined,
        'label': 'Record',
        'index': 1,
        'route': '/record-entry'
      },
      {
        'icon': Icons.check_circle_outline,
        'label': 'Confirm',
        'index': 2,
        'route': '/input-confirmation'
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'Chat',
        'index': 3,
        'route': '/chat'
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Calendar',
        'index': 4,
        'route': '/calendar'
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
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
            width: 1,
          ),
        ),
      ),
      child: SafeArea(
        child: SizedBox(
          height: 70,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == _selectedNavIndex;

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (_selectedNavIndex != index) {
                        setState(() => _selectedNavIndex = index);
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
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
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

  void _handleBackNavigation() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    context.go('/caretaker_dashboard');
  }

  InputDecoration _inputDecoration({
    required String label,
    required bool isDark,
    String? hint,
    IconData? icon,
  }) {
    final fill = isDark ? const Color(0xFF222222) : Colors.white;
    final borderColor =
        isDark ? Colors.white.withOpacity(0.12) : AppColors.neutral300;
    final focusedColor = AppColors.primary.withOpacity(0.75);

    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: icon != null ? Icon(icon, size: 20) : null,
      filled: true,
      fillColor: fill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      labelStyle: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white70 : AppColors.textSecondary,
      ),
      hintStyle: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white38 : AppColors.neutral500,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: focusedColor, width: 1.4),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final isMobile = MediaQuery.of(context).size.width < 600;
    final headerBg = isDark ? const Color(0xFF1F2720) : const Color(0xFFF2FAF3);

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            headerBg,
            (isDark ? const Color(0xFF1B1B1B) : Colors.white),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
            color: AppColors.success.withOpacity(isDark ? 0.35 : 0.28)),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: AppColors.success.withOpacity(0.08),
              blurRadius: 14,
              offset: const Offset(0, 6),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: _handleBackNavigation,
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
            child: Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                border: Border.all(
                  color: isDark
                      ? Colors.white.withOpacity(0.16)
                      : AppColors.neutral200,
                ),
              ),
              child: Icon(
                Icons.arrow_back_rounded,
                size: 20,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.14),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.edit_note_rounded,
                          size: 20, color: AppColors.success),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        'Farm Record Entry',
                        style: AppTypography.titleSmall.copyWith(
                          fontSize: isMobile ? 16 : 18,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.success.withOpacity(0.12),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusFull),
                        border: Border.all(
                            color: AppColors.success.withOpacity(0.35)),
                      ),
                      child: Text(
                        'Draft',
                        style: AppTypography.labelSmall.copyWith(
                          color: AppColors.success,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  DateFormat('EEEE, MMM d, yyyy').format(_recordDate),
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.white.withOpacity(0.85),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: isDark
                          ? Colors.white.withOpacity(0.1)
                          : AppColors.neutral200,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline_rounded,
                          size: 16, color: AppColors.info),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Complete all required fields before submitting.',
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white70
                                : AppColors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool isDark,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
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
                  borderRadius: BorderRadius.circular(10),
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
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          ...children,
        ],
      ),
    );
  }

  Widget _buildFarmSelector(bool isDark) {
    final farms = _assignedFarms;

    return DropdownButtonFormField<String>(
      value: _selectedFarm,
      style: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
      decoration: _inputDecoration(
        label: 'Select Farm',
        icon: Icons.agriculture_rounded,
        isDark: isDark,
      ),
      items: farms
          .map((farm) => DropdownMenuItem(
                value: _farmId(farm),
                child: Text(_value(farm, const ['name', 'farm_name'],
                    fallback: 'Unnamed farm')),
              ))
          .toList(),
      onChanged: (value) => setState(() {
        _selectedFarm = value;
        _selectedBatch = null;
      }),
      validator: (value) => value == null ? 'Please select a farm' : null,
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Center(
      child: Container(
        constraints: const BoxConstraints(maxWidth: 520),
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color:
                isDark ? Colors.white.withOpacity(0.08) : AppColors.neutral200,
          ),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded,
                size: 42, color: AppColors.error),
            const SizedBox(height: AppSpacing.md),
            Text(
              'Unable to load record form',
              style: AppTypography.titleSmall.copyWith(
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              _errorMessage ?? '',
              textAlign: TextAlign.center,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            ElevatedButton.icon(
              onPressed: _loadRecordData,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBatchSelector(bool isDark) {
    final batches = _farmBatches;

    return DropdownButtonFormField<String>(
      value: batches.any((batch) => _batchId(batch) == _selectedBatch)
          ? _selectedBatch
          : null,
      style: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
      decoration: _inputDecoration(
        label: 'Select Batch',
        icon: Icons.inventory_2_rounded,
        isDark: isDark,
      ),
      items: batches
          .map((batch) => DropdownMenuItem(
                value: _batchId(batch),
                child: Text(_value(
                  batch,
                  const ['batch_no', 'batch_number', 'batch_id'],
                  fallback: 'Batch',
                )),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedBatch = value),
      validator: (value) =>
          batches.isNotEmpty && value == null ? 'Please select a batch' : null,
    );
  }

  Widget _buildRecordTypeSelector(bool isDark) {
    final types = {
      'daily_monitoring': 'Daily Monitoring',
      'watering': 'Watering',
      'feeding': 'Feeding/Nutrients',
      'pruning': 'Pruning',
      'transplanting': 'Transplanting',
      'harvesting': 'Harvesting',
      'cleaning': 'Cleaning',
      'pest_control': 'Pest Control',
      'other': 'Other',
    };

    return DropdownButtonFormField<String>(
      value: _selectedRecordType,
      style: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
      decoration: _inputDecoration(
        label: 'Record Type',
        icon: Icons.category_rounded,
        isDark: isDark,
      ),
      items: types.entries
          .map((entry) => DropdownMenuItem(
                value: entry.key,
                child: Text(entry.value),
              ))
          .toList(),
      onChanged: (value) => setState(() => _selectedRecordType = value!),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () async {
        final date = await showDatePicker(
          context: context,
          initialDate: _recordDate,
          firstDate: DateTime.now().subtract(const Duration(days: 30)),
          lastDate: DateTime.now(),
        );
        if (date != null) {
          setState(() => _recordDate = date);
        }
      },
      child: InputDecorator(
        decoration: _inputDecoration(
          label: 'Record Date',
          icon: Icons.calendar_today_rounded,
          isDark: isDark,
        ),
        child: Text(
          DateFormat('yyyy-MM-dd').format(_recordDate),
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller,
      IconData icon, bool isDark) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      style: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: _inputDecoration(
        label: label,
        icon: icon,
        isDark: isDark,
      ),
    );
  }

  Widget _buildTextField(
      String label, TextEditingController controller, String hint, bool isDark,
      {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      style: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      decoration: _inputDecoration(
        label: label,
        hint: hint,
        isDark: isDark,
      ),
    );
  }

  Widget _buildActivitiesSelector(bool isDark) {
    final taskActivities = _assignedTasks
        .map((task) => _value(task, const ['title'], fallback: 'Assigned task'))
        .where((title) => title.trim().isNotEmpty)
        .toSet()
        .toList();
    final activities = [
      ...taskActivities,
      'Checked water levels',
      'Adjusted pH',
      'Added nutrients',
      'Pruned dead leaves',
      'Checked for pests',
      'Cleaned grow beds',
      'Monitored temperature',
      'Checked humidity',
      'Inspected roots',
      'Recorded observations',
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: activities.map((activity) {
        final isSelected = _selectedActivities.contains(activity);
        return FilterChip(
          label: Text(
            activity,
            style: AppTypography.caption.copyWith(
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              color: isSelected
                  ? AppColors.success
                  : (isDark ? Colors.white70 : AppColors.textPrimary),
            ),
          ),
          selected: isSelected,
          onSelected: (selected) {
            setState(() {
              if (selected) {
                _selectedActivities.add(activity);
              } else {
                _selectedActivities.remove(activity);
              }
            });
          },
          backgroundColor:
              isDark ? Colors.white.withOpacity(0.06) : AppColors.neutral100,
          selectedColor: AppColors.success.withOpacity(0.12),
          side: BorderSide(
            color: isSelected
                ? AppColors.success.withOpacity(0.4)
                : (isDark ? Colors.white12 : AppColors.neutral300),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
          showCheckmark: true,
          checkmarkColor: AppColors.success,
        );
      }).toList(),
    );
  }

  Widget _buildIssuesToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _hasIssues
            ? AppColors.error.withOpacity(isDark ? 0.16 : 0.08)
            : (isDark ? Colors.white.withOpacity(0.04) : AppColors.neutral50),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _hasIssues
              ? AppColors.error.withOpacity(0.45)
              : (isDark ? Colors.white12 : AppColors.neutral300),
        ),
      ),
      child: Row(
        children: [
          Icon(
            _hasIssues
                ? Icons.report_problem_rounded
                : Icons.verified_user_outlined,
            size: 20,
            color: _hasIssues ? AppColors.error : AppColors.success,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Report issues or concerns',
                  style: AppTypography.bodySmall.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  _hasIssues
                      ? 'Issue details are required'
                      : 'No active issues reported',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          Switch(
            value: _hasIssues,
            onChanged: (value) => setState(() => _hasIssues = value),
            activeColor: AppColors.error,
          ),
        ],
      ),
    );
  }

  Widget _buildSeveritySelector(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _issueSeverity,
      style: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
      decoration: _inputDecoration(
        label: 'Issue Severity',
        icon: Icons.priority_high_rounded,
        isDark: isDark,
      ),
      items: const [
        DropdownMenuItem(value: 'low', child: Text('Low')),
        DropdownMenuItem(value: 'medium', child: Text('Medium')),
        DropdownMenuItem(value: 'high', child: Text('High')),
        DropdownMenuItem(value: 'critical', child: Text('Critical')),
      ],
      onChanged: (value) => setState(() => _issueSeverity = value!),
    );
  }

  Widget _buildSubmitButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _isSubmitting ? null : _submitRecord,
        icon: _isSubmitting
            ? const SizedBox(
                height: 16,
                width: 16,
                child: CircularProgressIndicator(
                    color: Colors.white, strokeWidth: 2),
              )
            : const Icon(Icons.cloud_upload_rounded, size: 20),
        label: Text(
          _isSubmitting ? 'Submitting...' : 'Submit Record',
          style: AppTypography.bodySmall.copyWith(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.success,
          foregroundColor: Colors.white,
          elevation: 1,
          minimumSize: const Size(double.infinity, 54),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }

  Future<void> _submitRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    final user = ref.read(authProvider).user;
    final farm = _selectedFarmDoc;
    final batch = _selectedBatchDoc;
    if (farm == null || user == null) {
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Select a valid assigned farm before submitting.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final record = FarmRecordModel(
      id: 'REC_${DateTime.now().millisecondsSinceEpoch}',
      farmId: _farmId(farm),
      farmName: _value(farm, const ['name', 'farm_name'], fallback: 'Farm'),
      batchId: batch == null ? '' : _batchId(batch),
      batchNumber: batch == null
          ? null
          : _value(batch, const ['batch_no', 'batch_number', 'batch_id']),
      type: RecordType.fromString(_selectedRecordType),
      recordDate: _recordDate,
      createdBy: user.id,
      createdByName: user.name,
      temperature: _temperatureController.text.isNotEmpty
          ? double.tryParse(_temperatureController.text)
          : null,
      humidity: _humidityController.text.isNotEmpty
          ? double.tryParse(_humidityController.text)
          : null,
      ph: _phController.text.isNotEmpty
          ? double.tryParse(_phController.text)
          : null,
      ec: _ecController.text.isNotEmpty
          ? double.tryParse(_ecController.text)
          : null,
      lightIntensity: _lightController.text.isNotEmpty
          ? double.tryParse(_lightController.text)
          : null,
      plantHealth: _plantHealthController.text.isNotEmpty
          ? _plantHealthController.text
          : null,
      growthStage: _growthStageController.text.isNotEmpty
          ? _growthStageController.text
          : null,
      plantCount: _plantCountController.text.isNotEmpty
          ? int.tryParse(_plantCountController.text)
          : null,
      observations: _observationsController.text.isNotEmpty
          ? _observationsController.text
          : null,
      activitiesPerformed: _selectedActivities,
      hasIssues: _hasIssues,
      issueDescription: _hasIssues ? _issueDescriptionController.text : null,
      issueSeverity:
          _hasIssues ? IssueSeverity.fromString(_issueSeverity) : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      createdAt: DateTime.now(),
    );

    try {
      await _api.createFarmRecord(
        data: {
          'farm_id': record.farmId,
          'farm_name': record.farmName,
          'batch_id': record.batchId,
          'batch_number': record.batchNumber ?? '',
          'record_type': record.type.value,
          'record_date': record.recordDate.toIso8601String(),
          'created_by': record.createdBy,
          'created_by_name': record.createdByName,
          'temperature': _temperatureController.text.trim(),
          'humidity': _humidityController.text.trim(),
          'ph': _phController.text.trim(),
          'ec': _ecController.text.trim(),
          'light_intensity': _lightController.text.trim(),
          'plant_health': _plantHealthController.text.trim(),
          'growth_stage': _growthStageController.text.trim(),
          'plant_count': _plantCountController.text.trim(),
          'observations': _observationsController.text.trim(),
          'activities_performed': _selectedActivities.join(', '),
          'has_issues': _hasIssues,
          'issue_description':
              _hasIssues ? _issueDescriptionController.text.trim() : '',
          'issue_severity': _hasIssues ? _issueSeverity : 'none',
          'notes': _notesController.text.trim(),
        },
      );
      ref.read(recordsProvider.notifier).addRecord(record);
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Record submitted successfully'),
          backgroundColor: AppColors.success,
        ),
      );
      context.pop();
    } catch (error) {
      if (!mounted) return;
      setState(() => _isSubmitting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Submit failed: $error'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }
}
