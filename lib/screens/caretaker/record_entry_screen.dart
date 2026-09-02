import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  final _formKey = GlobalKey<FormState>();
  int _selectedNavIndex = 1;
  int _selectedRecordTab = 0;
  int _maxUnlockedStep = 0;

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
  final _plantedController = TextEditingController();
  final _transplantedController = TextEditingController();
  final _harvestedController = TextEditingController();
  final _harvestWeightController = TextEditingController();
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
  String? _submitError;
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
    _plantedController.dispose();
    _transplantedController.dispose();
    _harvestedController.dispose();
    _harvestWeightController.dispose();
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

  String _numericText(Map<String, dynamic> batch, String key,
      {bool decimal = false}) {
    final raw = batch[key];
    final number = raw is num ? raw : num.tryParse(raw?.toString() ?? '');
    if (number == null) return '0';
    return decimal
        ? number.toDouble().toStringAsFixed(1)
        : number.toInt().toString();
  }

  void _populateBatchProgress() {
    final batch = _selectedBatchDoc;
    if (batch == null) {
      _plantedController.clear();
      _transplantedController.clear();
      _harvestedController.clear();
      _harvestWeightController.clear();
      return;
    }
    _plantedController.text = _numericText(batch, 'total_seeds_nursed');
    _transplantedController.text = _numericText(batch, 'total_transplanted');
    _harvestedController.text = _numericText(batch, 'total_harvested');
    _harvestWeightController.text =
        _numericText(batch, 'total_weight_kg', decimal: true);
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
        if (batches.isEmpty) {
          _selectedBatch = null;
        } else if (!batches.any((batch) => _batchId(batch) == _selectedBatch)) {
          _selectedBatch = _batchId(batches.first);
        }
        _populateBatchProgress();
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
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
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
            if (_submitError != null) ...[
              _buildSubmitError(isDark),
              SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.lg),
            ],
            _buildStepActions(isDark),
            SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),
          ],
        ),
      ),
    );
  }

  List<({String title, String subtitle, IconData icon})> get _recordTabs =>
      const [
        (
          title: 'Select Batch',
          subtitle: 'Choose the assigned farm and production batch',
          icon: Icons.inventory_2_outlined
        ),
        (
          title: 'Record Details',
          subtitle: 'Enter progress, readings, observations, and activities',
          icon: Icons.edit_note_rounded
        ),
        (
          title: 'Review',
          subtitle: 'Report issues, add notes, and submit the record',
          icon: Icons.fact_check_outlined
        ),
      ];

  Widget _buildRecordTabs(bool isDark) {
    final tabs = _recordTabs;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withValues(alpha: 0.08)
              : AppColors.neutral200,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: List.generate(tabs.length, (index) {
          final tab = tabs[index];
          final isSelected = index == _selectedRecordTab;
          final isComplete = index < _maxUnlockedStep && !isSelected;
          final isUnlocked = index <= _maxUnlockedStep;
          final color = isSelected || isComplete
              ? AppColors.primary
              : (isDark ? Colors.white30 : AppColors.neutral400);
          return Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Tooltip(
                    message: tab.subtitle,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(10),
                      onTap: isUnlocked
                          ? () => setState(() {
                                _selectedRecordTab = index;
                                _submitError = null;
                              })
                          : null,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 180),
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: isSelected || isComplete
                                    ? AppColors.primary
                                    : (isDark
                                        ? Colors.white.withValues(alpha: 0.06)
                                        : AppColors.neutral100),
                                shape: BoxShape.circle,
                                border: Border.all(color: color),
                              ),
                              child: Icon(
                                isComplete ? Icons.check_rounded : tab.icon,
                                size: 17,
                                color: isSelected || isComplete
                                    ? Colors.white
                                    : color,
                              ),
                            ),
                            const SizedBox(height: 7),
                            Text(
                              tab.title,
                              maxLines: 2,
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              style: AppTypography.caption.copyWith(
                                color: color,
                                fontWeight: isSelected || isComplete
                                    ? FontWeight.w600
                                    : FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                if (index < tabs.length - 1)
                  Container(
                    width: 18,
                    height: 2,
                    margin: const EdgeInsets.only(top: 16),
                    color: index < _maxUnlockedStep
                        ? AppColors.primary
                        : (isDark ? Colors.white12 : AppColors.neutral200),
                  ),
              ],
            ),
          );
        }),
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
          title: tab.title,
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
        return [
          _buildSelectedBatchSummary(isDark),
          const SizedBox(height: AppSpacing.lg),
          _buildSubsectionTitle(
            'Batch Progress',
            'Update the current cumulative production totals.',
            Icons.trending_up_rounded,
            isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildBatchProgressFields(isDark, isMobile),
          const SizedBox(height: AppSpacing.lg),
          _buildSubsectionTitle(
            'Plant Observations',
            'Record crop health and the current growth stage.',
            Icons.spa_outlined,
            isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildTextField('Plant Health', _plantHealthController,
              'e.g., Healthy, Yellowing, etc.', isDark),
          const SizedBox(height: AppSpacing.md),
          _buildTextField('Growth Stage', _growthStageController,
              'e.g., Vegetative, Flowering', isDark),
          const SizedBox(height: AppSpacing.md),
          _buildTextField('Observations', _observationsController,
              'Any notable observations...', isDark,
              maxLines: 3),
          const SizedBox(height: AppSpacing.lg),
          _buildSubsectionTitle(
            'Environment',
            'Add available climate and nutrient readings.',
            Icons.sensors_outlined,
            isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildEnvironmentFields(isDark, isMobile),
          const SizedBox(height: AppSpacing.lg),
          _buildSubsectionTitle(
            'Completed Activities',
            'Select work completed during this record period.',
            Icons.checklist_rounded,
            isDark,
          ),
          const SizedBox(height: AppSpacing.md),
          _buildActivitiesSelector(isDark),
        ];
      case 2:
        return [
          _buildReviewSummary(isDark),
          const SizedBox(height: AppSpacing.lg),
          _buildSubsectionTitle(
            'Issues and Concerns',
            'Flag anything that requires attention from the Farm Manager.',
            Icons.report_problem_outlined,
            isDark,
          ),
          const SizedBox(height: AppSpacing.md),
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
          const SizedBox(height: AppSpacing.lg),
          _buildSubsectionTitle(
            'Handover Notes',
            'Add any final context for the farm team.',
            Icons.sticky_note_2_outlined,
            isDark,
          ),
          const SizedBox(height: AppSpacing.md),
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

  Widget _buildSubsectionTitle(
    String title,
    String subtitle,
    IconData icon,
    bool isDark,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 18, color: AppColors.primary),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: AppTypography.caption.copyWith(
                  color: isDark ? Colors.white60 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildReviewSummary(bool isDark) {
    final batch = _selectedBatchDoc;
    final batchNumber = batch == null
        ? 'No batch selected'
        : _value(
            batch,
            const ['batch_no', 'batch_number', 'batch_id'],
            fallback: 'Batch',
          );
    final items = [
      ('Batch', batchNumber, Icons.inventory_2_outlined),
      ('Planted / Nursed', _plantedController.text, Icons.spa_outlined),
      ('Transplanted', _transplantedController.text, Icons.grass_rounded),
      ('Harvested', _harvestedController.text, Icons.agriculture_outlined),
      (
        'Harvest Weight',
        '${_harvestWeightController.text} kg',
        Icons.scale_outlined
      ),
      (
        'Activities',
        '${_selectedActivities.length} selected',
        Icons.checklist_rounded
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth >= 700 ? 3 : 2;
        final spacing = AppSpacing.sm;
        final width =
            (constraints.maxWidth - (spacing * (columns - 1))) / columns;
        return Wrap(
          spacing: spacing,
          runSpacing: spacing,
          children: items.map((item) {
            return Container(
              width: width,
              constraints: const BoxConstraints(minHeight: 76),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isDark
                    ? Colors.white.withValues(alpha: 0.04)
                    : AppColors.neutral50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? Colors.white10 : AppColors.neutral200,
                ),
              ),
              child: Row(
                children: [
                  Icon(item.$3, size: 18, color: AppColors.primary),
                  const SizedBox(width: 9),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.caption.copyWith(
                            color: isDark
                                ? Colors.white60
                                : AppColors.textSecondary,
                          ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          item.$2.isEmpty ? '0' : item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTypography.bodySmall.copyWith(
                            color:
                                isDark ? Colors.white : AppColors.textPrimary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Widget _buildSelectedBatchSummary(bool isDark) {
    final batch = _selectedBatchDoc;
    if (batch == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: AppColors.warning.withOpacity(isDark ? 0.14 : 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.warning.withOpacity(0.3)),
        ),
        child: Text(
          'Select an assigned farm and batch in Basic Information first.',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textPrimary,
          ),
        ),
      );
    }
    final batchNumber = _value(
      batch,
      const ['batch_no', 'batch_number', 'batch_id'],
      fallback: 'Batch',
    );
    final crop = _value(
      batch,
      const ['plant_name', 'plant_type'],
      fallback: 'Crop not set',
    );
    final variety = _value(
      batch,
      const ['plant_variety', 'variety_name'],
      fallback: 'Variety not set',
    );
    final status = _value(
      batch,
      const ['production_status', 'status'],
      fallback: 'Planted',
    );
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(isDark ? 0.14 : 0.07),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              color: AppColors.primary,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  batchNumber,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$crop - $variety',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.12),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              status,
              style: AppTypography.caption.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBatchProgressFields(bool isDark, bool isMobile) {
    final fields = [
      _buildNumberField(
        'Planted / Nursed',
        _plantedController,
        Icons.spa_outlined,
        isDark,
        allowDecimal: false,
        validator: _nonNegativeWholeNumber,
      ),
      _buildNumberField(
        'Transplanted',
        _transplantedController,
        Icons.grass_rounded,
        isDark,
        allowDecimal: false,
        validator: _nonNegativeWholeNumber,
      ),
      _buildNumberField(
        'Harvested',
        _harvestedController,
        Icons.agriculture_rounded,
        isDark,
        allowDecimal: false,
        validator: _nonNegativeWholeNumber,
      ),
      _buildNumberField(
        'Harvest Weight (kg)',
        _harvestWeightController,
        Icons.scale_outlined,
        isDark,
        allowDecimal: true,
        validator: _nonNegativeNumber,
      ),
    ];
    if (isMobile) {
      return Column(
        children: [
          for (var index = 0; index < fields.length; index++) ...[
            fields[index],
            if (index < fields.length - 1)
              const SizedBox(height: AppSpacing.md),
          ],
        ],
      );
    }
    return Column(
      children: [
        Row(
          children: [
            Expanded(child: fields[0]),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: fields[1]),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(child: fields[2]),
            const SizedBox(width: AppSpacing.md),
            Expanded(child: fields[3]),
          ],
        ),
      ],
    );
  }

  String? _nonNegativeWholeNumber(String? value) {
    if (_selectedBatchDoc == null && (value == null || value.trim().isEmpty)) {
      return null;
    }
    final parsed = int.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 0 ? 'Enter zero or a whole number' : null;
  }

  String? _nonNegativeNumber(String? value) {
    if (_selectedBatchDoc == null && (value == null || value.trim().isEmpty)) {
      return null;
    }
    final parsed = double.tryParse(value?.trim() ?? '');
    return parsed == null || parsed < 0 ? 'Enter zero or a valid weight' : null;
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
    navigator.pushReplacementNamed('/caretaker_dashboard');
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
        _maxUnlockedStep = 0;
        _submitError = null;
        final batches = _farmBatches;
        if (batches.isNotEmpty) {
          _selectedBatch = _batchId(batches.first);
        }
        _populateBatchProgress();
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
      onChanged: (value) => setState(() {
        _selectedBatch = value;
        _maxUnlockedStep = 0;
        _submitError = null;
        _populateBatchProgress();
      }),
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
      IconData icon, bool isDark,
      {bool allowDecimal = true, String? Function(String?)? validator}) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.numberWithOptions(decimal: allowDecimal),
      style: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      validator: validator,
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

  Widget _buildStepActions(bool isDark) {
    final isLastStep = _selectedRecordTab == _recordTabs.length - 1;
    return Row(
      children: [
        if (_selectedRecordTab > 0) ...[
          Expanded(
            child: OutlinedButton.icon(
              onPressed: _isSubmitting
                  ? null
                  : () => setState(() {
                        _selectedRecordTab -= 1;
                        _submitError = null;
                      }),
              icon: const Icon(Icons.arrow_back_rounded, size: 18),
              label: const Text('Back'),
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(0, 54),
                foregroundColor:
                    isDark ? Colors.white70 : AppColors.textPrimary,
                side: BorderSide(
                  color: isDark ? Colors.white24 : AppColors.neutral300,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
        ],
        Expanded(
          flex: _selectedRecordTab == 0 ? 1 : 2,
          child: isLastStep
              ? _buildSubmitButton(isDark)
              : ElevatedButton.icon(
                  onPressed: _isSubmitting ? null : _continueToNextStep,
                  icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                  label: const Text('Continue'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    minimumSize: const Size(0, 54),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
        ),
      ],
    );
  }

  void _continueToNextStep() {
    if (_selectedRecordTab == 0) {
      if (_selectedFarmDoc == null) {
        _rejectSubmission('Select one of your assigned farms to continue.');
        return;
      }
      if (_selectedBatchDoc == null) {
        _rejectSubmission(
          _farmBatches.isEmpty
              ? 'This farm has no active batches available for record entry.'
              : 'Select a production batch to continue.',
        );
        return;
      }
    }
    if (_selectedRecordTab == 1) {
      final progressIsValid =
          _nonNegativeWholeNumber(_plantedController.text) == null &&
              _nonNegativeWholeNumber(_transplantedController.text) == null &&
              _nonNegativeWholeNumber(_harvestedController.text) == null &&
              _nonNegativeNumber(_harvestWeightController.text) == null;
      if (!progressIsValid || !_formKey.currentState!.validate()) {
        _rejectSubmission(
          'Check the highlighted record values before continuing.',
        );
        return;
      }
    }
    setState(() {
      _selectedRecordTab += 1;
      _maxUnlockedStep = _maxUnlockedStep < _selectedRecordTab
          ? _selectedRecordTab
          : _maxUnlockedStep;
      _submitError = null;
    });
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

  Widget _buildSubmitError(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.error.withOpacity(isDark ? 0.16 : 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.error.withOpacity(0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.error_outline_rounded,
              color: AppColors.error, size: 19),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              _submitError!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.error),
            ),
          ),
        ],
      ),
    );
  }

  void _rejectSubmission(String message, {int? tab}) {
    setState(() {
      _isSubmitting = false;
      _submitError = message;
      if (tab != null) _selectedRecordTab = tab;
    });
  }

  Future<void> _submitRecord() async {
    if (!_formKey.currentState!.validate()) return;

    final user = ref.read(authProvider).user;
    final farm = _selectedFarmDoc;
    final batch = _selectedBatchDoc;
    if (farm == null || user == null) {
      _rejectSubmission(
        'Select a valid assigned farm before submitting.',
        tab: 0,
      );
      return;
    }
    if (batch != null) {
      final progressIsValid =
          _nonNegativeWholeNumber(_plantedController.text) == null &&
              _nonNegativeWholeNumber(_transplantedController.text) == null &&
              _nonNegativeWholeNumber(_harvestedController.text) == null &&
              _nonNegativeNumber(_harvestWeightController.text) == null;
      if (!progressIsValid) {
        _rejectSubmission(
          'Check the batch progress values. Use zero or positive numbers only.',
          tab: 1,
        );
        return;
      }
    }
    if (_hasIssues && _issueDescriptionController.text.trim().isEmpty) {
      _rejectSubmission('Describe the issue before submitting.', tab: 2);
      return;
    }
    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

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
      plantCount: _plantedController.text.isNotEmpty
          ? int.tryParse(_plantedController.text)
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
          'plant_count': _plantedController.text.trim(),
          'planted_count': _plantedController.text.trim(),
          'transplanted_count': _transplantedController.text.trim(),
          'harvested_count': _harvestedController.text.trim(),
          'harvest_weight_kg': _harvestWeightController.text.trim(),
          'observations': _observationsController.text.trim(),
          'activities_performed': _selectedActivities.join(', '),
          'has_issues': _hasIssues,
          'issue_description':
              _hasIssues ? _issueDescriptionController.text.trim() : '',
          'issue_severity': _hasIssues ? _issueSeverity : 'none',
          'notes': _notesController.text.trim(),
        },
      );
    } catch (error) {
      if (!mounted) return;
      _rejectSubmission('Submit failed: $error');
      return;
    }
    if (!mounted) return;
    ref.read(recordsProvider.notifier).addRecord(record);
    setState(() {
      _isSubmitting = false;
      _submitError = null;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Record submitted successfully'),
        backgroundColor: AppColors.success,
      ),
    );
    Navigator.of(context).pushReplacementNamed('/caretaker_dashboard');
  }
}
