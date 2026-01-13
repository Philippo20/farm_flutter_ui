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
import '../../providers/auth_provider.dart';

/// Record Entry Screen
/// Create and submit farm records for daily monitoring and activities
class RecordEntryScreen extends ConsumerStatefulWidget {
  const RecordEntryScreen({super.key});

  @override
  ConsumerState<RecordEntryScreen> createState() => _RecordEntryScreenState();
}

class _RecordEntryScreenState extends ConsumerState<RecordEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  int _selectedNavIndex = 1;
  
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
  List<String> _selectedActivities = [];
  bool _hasIssues = false;
  String _issueSeverity = 'low';
  final _issueDescriptionController = TextEditingController();
  
  // Notes
  final _notesController = TextEditingController();
  
  bool _isSubmitting = false;

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
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail, String userRole) {
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

    return Column(
      children: [
        // Header
        _buildHeader(isDark),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),

        // Basic Information
        _buildSection('Basic Information', isDark, [
          _buildFarmSelector(isDark),
          const SizedBox(height: AppSpacing.md),
          _buildBatchSelector(isDark),
          const SizedBox(height: AppSpacing.md),
          _buildRecordTypeSelector(isDark),
          const SizedBox(height: AppSpacing.md),
          _buildDatePicker(isDark),
        ]),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),

        // Environmental Readings
        _buildSection('Environmental Readings', isDark, [
          isMobile
              ? Column(
                  children: [
                    _buildNumberField('Temperature (°C)', _temperatureController, Icons.thermostat, isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildNumberField('Humidity (%)', _humidityController, Icons.water_drop, isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildNumberField('pH Level', _phController, Icons.science, isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildNumberField('EC (mS/cm)', _ecController, Icons.electric_bolt, isDark),
                    const SizedBox(height: AppSpacing.md),
                    _buildNumberField('Light Intensity (lux)', _lightController, Icons.light_mode, isDark),
                  ],
                )
              : Column(
                  children: [
                    Row(
                      children: [
                        Expanded(child: _buildNumberField('Temperature (°C)', _temperatureController, Icons.thermostat, isDark)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildNumberField('Humidity (%)', _humidityController, Icons.water_drop, isDark)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    Row(
                      children: [
                        Expanded(child: _buildNumberField('pH Level', _phController, Icons.science, isDark)),
                        const SizedBox(width: AppSpacing.md),
                        Expanded(child: _buildNumberField('EC (mS/cm)', _ecController, Icons.electric_bolt, isDark)),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.md),
                    _buildNumberField('Light Intensity (lux)', _lightController, Icons.light_mode, isDark),
                  ],
                ),
        ]),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),

        // Plant Observations
        _buildSection('Plant Observations', isDark, [
          _buildTextField('Plant Health', _plantHealthController, 'e.g., Healthy, Yellowing, etc.', isDark),
          const SizedBox(height: AppSpacing.md),
          _buildTextField('Growth Stage', _growthStageController, 'e.g., Vegetative, Flowering', isDark),
          const SizedBox(height: AppSpacing.md),
          _buildNumberField('Plant Count', _plantCountController, Icons.format_list_numbered, isDark),
          const SizedBox(height: AppSpacing.md),
          _buildTextField('Observations', _observationsController, 'Any notable observations...', isDark, maxLines: 3),
        ]),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),

        // Activities Performed
        _buildSection('Activities Performed', isDark, [
          _buildActivitiesSelector(isDark),
        ]),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),

        // Issues & Concerns
        _buildSection('Issues & Concerns', isDark, [
          _buildIssuesToggle(isDark),
          if (_hasIssues) ...[
            const SizedBox(height: AppSpacing.md),
            _buildSeveritySelector(isDark),
            const SizedBox(height: AppSpacing.md),
            _buildTextField('Issue Description', _issueDescriptionController, 'Describe the issue...', isDark, maxLines: 3),
          ],
        ]),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),

        // Additional Notes
        _buildSection('Additional Notes', isDark, [
          _buildTextField('Notes', _notesController, 'Any additional notes...', isDark, maxLines: 4),
        ]),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),

        // Submit Button
        _buildSubmitButton(isDark),
        SizedBox(height: isMobile ? AppSpacing.md : AppSpacing.xl),
      ],
    );
  }

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
                              : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
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

  Widget _buildHeader(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            AppColors.success.withOpacity(0.1),
            AppColors.success.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: AppColors.success.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: AppColors.success.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.edit_note, size: 28, color: AppColors.success),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Farm Record Entry',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
                Text(
                  DateFormat('EEEE, MMMM d, yyyy').format(_recordDate),
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 12,
                    color: isDark ? Colors.white70 : AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection(String title, bool isDark, List<Widget> children) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...children,
      ],
    );
  }

  Widget _buildFarmSelector(bool isDark) {
    final farms = ['Green Valley Farm', 'Sunny Acres', 'Fresh Farms', 'Urban Greens', 'Eco Gardens'];
    
    return DropdownButtonFormField<String>(
      value: _selectedFarm,
      decoration: InputDecoration(
        labelText: 'Select Farm',
        prefixIcon: const Icon(Icons.agriculture),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      items: farms.map((farm) => DropdownMenuItem(value: farm, child: Text(farm))).toList(),
      onChanged: (value) => setState(() => _selectedFarm = value),
      validator: (value) => value == null ? 'Please select a farm' : null,
    );
  }

  Widget _buildBatchSelector(bool isDark) {
    final batches = ['LE-20241101-20241201', 'TO-20241015-20241115', 'BA-20241110-20241208'];
    
    return DropdownButtonFormField<String>(
      value: _selectedBatch,
      decoration: InputDecoration(
        labelText: 'Select Batch',
        prefixIcon: const Icon(Icons.inventory_2),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      items: batches.map((batch) => DropdownMenuItem(value: batch, child: Text(batch))).toList(),
      onChanged: (value) => setState(() => _selectedBatch = value),
      validator: (value) => value == null ? 'Please select a batch' : null,
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
      decoration: InputDecoration(
        labelText: 'Record Type',
        prefixIcon: const Icon(Icons.category),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
      items: types.entries.map((entry) => DropdownMenuItem(
        value: entry.key,
        child: Text(entry.value),
      )).toList(),
      onChanged: (value) => setState(() => _selectedRecordType = value!),
    );
  }

  Widget _buildDatePicker(bool isDark) {
    return InkWell(
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
        decoration: InputDecoration(
          labelText: 'Record Date',
          prefixIcon: const Icon(Icons.calendar_today),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          filled: true,
          fillColor: isDark ? AppColors.surfaceDark : Colors.white,
        ),
        child: Text(DateFormat('yyyy-MM-dd').format(_recordDate)),
      ),
    );
  }

  Widget _buildNumberField(String label, TextEditingController controller, IconData icon, bool isDark) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, String hint, bool isDark, {int maxLines = 1}) {
    return TextFormField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
      ),
    );
  }

  Widget _buildActivitiesSelector(bool isDark) {
    final activities = [
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
          label: Text(activity),
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
          selectedColor: AppColors.success.withOpacity(0.2),
          checkmarkColor: AppColors.success,
        );
      }).toList(),
    );
  }

  Widget _buildIssuesToggle(bool isDark) {
    return SwitchListTile(
      title: const Text('Report Issues or Concerns'),
      value: _hasIssues,
      onChanged: (value) => setState(() => _hasIssues = value),
      activeColor: AppColors.error,
      contentPadding: EdgeInsets.zero,
    );
  }

  Widget _buildSeveritySelector(bool isDark) {
    return DropdownButtonFormField<String>(
      value: _issueSeverity,
      decoration: InputDecoration(
        labelText: 'Issue Severity',
        prefixIcon: const Icon(Icons.priority_high),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
        filled: true,
        fillColor: isDark ? AppColors.surfaceDark : Colors.white,
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
    return ElevatedButton(
      onPressed: _isSubmitting ? null : _submitRecord,
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.success,
        minimumSize: const Size(double.infinity, 50),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        ),
      ),
      child: _isSubmitting
          ? const SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
            )
          : const Text(
              'Submit Record',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
    );
  }

  Future<void> _submitRecord() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);

    // Simulate API call
    await Future.delayed(const Duration(seconds: 2));

    // Create record
    final record = FarmRecordModel(
      id: 'REC_${DateTime.now().millisecondsSinceEpoch}',
      farmId: _selectedFarm ?? 'farm1',
      farmName: _selectedFarm ?? 'Demo Farm',
      batchId: _selectedBatch ?? 'batch1',
      batchNumber: _selectedBatch,
      type: RecordType.fromString(_selectedRecordType),
      recordDate: _recordDate,
      createdBy: 'current_user',
      createdByName: 'Current Caretaker',
      temperature: _temperatureController.text.isNotEmpty ? double.tryParse(_temperatureController.text) : null,
      humidity: _humidityController.text.isNotEmpty ? double.tryParse(_humidityController.text) : null,
      ph: _phController.text.isNotEmpty ? double.tryParse(_phController.text) : null,
      ec: _ecController.text.isNotEmpty ? double.tryParse(_ecController.text) : null,
      lightIntensity: _lightController.text.isNotEmpty ? double.tryParse(_lightController.text) : null,
      plantHealth: _plantHealthController.text.isNotEmpty ? _plantHealthController.text : null,
      growthStage: _growthStageController.text.isNotEmpty ? _growthStageController.text : null,
      plantCount: _plantCountController.text.isNotEmpty ? int.tryParse(_plantCountController.text) : null,
      observations: _observationsController.text.isNotEmpty ? _observationsController.text : null,
      activitiesPerformed: _selectedActivities,
      hasIssues: _hasIssues,
      issueDescription: _hasIssues ? _issueDescriptionController.text : null,
      issueSeverity: _hasIssues ? IssueSeverity.fromString(_issueSeverity) : null,
      notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      createdAt: DateTime.now(),
    );

    // Save to provider
    ref.read(recordsProvider.notifier).addRecord(record);

    setState(() => _isSubmitting = false);

    if (!mounted) return;

    // Show success and navigate back
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Record submitted successfully'),
        backgroundColor: AppColors.success,
      ),
    );
    
    context.pop(); // Go back to dashboard
  }
}
