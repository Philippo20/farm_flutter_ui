import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Reports Screen
/// Generate and view various farm reports
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  String _selectedReportType = 'batch';
  DateTime _startDate = DateTime.now().subtract(const Duration(days: 30));
  DateTime _endDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          'Reports',
          style: AppTypography.h5.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Report Type Selector
            _buildReportTypeSelector(isDark),
            const SizedBox(height: AppSpacing.xl),

            // Date Range Selector
            _buildDateRangeSelector(isDark),
            const SizedBox(height: AppSpacing.xl),

            // Generate Button
            _buildGenerateButton(isDark),
            const SizedBox(height: AppSpacing.xl),

            // Recent Reports
            _buildRecentReports(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTypeSelector(bool isDark) {
    final reportTypes = [
      {'id': 'batch', 'name': 'Batch Report', 'icon': Icons.inventory_2},
      {'id': 'financial', 'name': 'Financial Summary', 'icon': Icons.attach_money},
      {'id': 'inventory', 'name': 'Inventory Report', 'icon': Icons.warehouse},
      {'id': 'performance', 'name': 'Performance Report', 'icon': Icons.analytics},
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Report Type',
          style: AppTypography.h6.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 2.5,
          ),
          itemCount: reportTypes.length,
          itemBuilder: (context, index) {
            final type = reportTypes[index];
            final isSelected = _selectedReportType == type['id'];
            return InkWell(
              onTap: () => setState(() => _selectedReportType = type['id'] as String),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
              child: Container(
                padding: const EdgeInsets.all(AppSpacing.md),
                decoration: BoxDecoration(
                  color: isSelected
                      ? AppColors.primary.withOpacity(0.1)
                      : (isDark ? Colors.grey[850] : Colors.white),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(
                    color: isSelected ? AppColors.primary : (isDark ? Colors.grey[700]! : Colors.grey[300]!),
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      type['icon'] as IconData,
                      color: isSelected ? AppColors.primary : (isDark ? Colors.white70 : AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        type['name'] as String,
                        style: AppTypography.bodyMedium.copyWith(
                          color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary),
                          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Widget _buildDateRangeSelector(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Date Range',
          style: AppTypography.h6.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          children: [
            Expanded(
              child: _buildDateField('Start Date', _startDate, isDark, (date) {
                setState(() => _startDate = date);
              }),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: _buildDateField('End Date', _endDate, isDark, (date) {
                setState(() => _endDate = date);
              }),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildDateField(String label, DateTime date, bool isDark, Function(DateTime) onDateSelected) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: date,
          firstDate: DateTime(2020),
          lastDate: DateTime.now(),
        );
        if (picked != null) onDateSelected(picked);
      },
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 16, color: AppColors.primary),
                const SizedBox(width: AppSpacing.sm),
                Text(
                  DateFormat('MMM dd, yyyy').format(date),
                  style: AppTypography.bodyMedium.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGenerateButton(bool isDark) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _generateReport,
        icon: const Icon(Icons.picture_as_pdf),
        label: const Text('Generate PDF Report'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.all(AppSpacing.md),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
        ),
      ),
    );
  }

  Widget _buildRecentReports(bool isDark) {
    final recentReports = [
      {
        'name': 'Batch Report - October 2024',
        'type': 'Batch Report',
        'date': DateTime.now().subtract(const Duration(days: 5)),
        'size': '2.4 MB',
      },
      {
        'name': 'Financial Summary - Q3 2024',
        'type': 'Financial Summary',
        'date': DateTime.now().subtract(const Duration(days: 12)),
        'size': '1.8 MB',
      },
      {
        'name': 'Inventory Report - September',
        'type': 'Inventory Report',
        'date': DateTime.now().subtract(const Duration(days: 20)),
        'size': '1.2 MB',
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Recent Reports',
          style: AppTypography.h6.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: recentReports.length,
          separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
          itemBuilder: (context, index) {
            final report = recentReports[index];
            return Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.white,
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: AppColors.error.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                    ),
                    child: const Icon(Icons.picture_as_pdf, color: AppColors.error),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          report['name'] as String,
                          style: AppTypography.bodyMedium.copyWith(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          '${report['type']} • ${DateFormat('MMM dd, yyyy').format(report['date'] as DateTime)} • ${report['size']}',
                          style: AppTypography.bodySmall.copyWith(
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.share),
                    onPressed: () => _shareReport(report['name'] as String),
                    color: AppColors.primary,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  void _generateReport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Generating ${_getReportTypeName()} for ${DateFormat('MMM dd').format(_startDate)} - ${DateFormat('MMM dd, yyyy').format(_endDate)}'),
        backgroundColor: AppColors.success,
        action: SnackBarAction(
          label: 'View',
          textColor: Colors.white,
          onPressed: () {},
        ),
      ),
    );
  }

  void _shareReport(String reportName) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Sharing $reportName...'),
        backgroundColor: AppColors.info,
      ),
    );
  }

  String _getReportTypeName() {
    switch (_selectedReportType) {
      case 'batch':
        return 'Batch Report';
      case 'financial':
        return 'Financial Summary';
      case 'inventory':
        return 'Inventory Report';
      case 'performance':
        return 'Performance Report';
      default:
        return 'Report';
    }
  }
}
