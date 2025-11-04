import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../data/mock_farm_data.dart';
import '../../models/alert_model.dart';
import '../../models/enums.dart';
import '../../widgets/alert_card.dart';

/// Alert Management Screen
/// Comprehensive alert management with filtering and resolution
class AlertManagementScreen extends StatefulWidget {
  const AlertManagementScreen({super.key});

  @override
  State<AlertManagementScreen> createState() => _AlertManagementScreenState();
}

class _AlertManagementScreenState extends State<AlertManagementScreen> {
  List<AlertModel> _alerts = [];
  List<AlertModel> _filteredAlerts = [];
  
  // Filters
  String _selectedFilter = 'all'; // all, active, resolved
  AlertSeverity? _selectedSeverity;
  SensorType? _selectedSensorType;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadAlerts();
  }

  void _loadAlerts() {
    setState(() {
      _alerts = MockFarmData.getAllAlerts();
      _applyFilters();
    });
  }

  void _applyFilters() {
    var filtered = List<AlertModel>.from(_alerts);

    // Filter by status
    if (_selectedFilter == 'active') {
      filtered = filtered.where((a) => a.isActive).toList();
    } else if (_selectedFilter == 'resolved') {
      filtered = filtered.where((a) => a.resolved).toList();
    }

    // Filter by severity
    if (_selectedSeverity != null) {
      filtered = filtered.where((a) => a.severity == _selectedSeverity).toList();
    }

    // Filter by sensor type
    if (_selectedSensorType != null) {
      filtered = filtered.where((a) => a.sensorType == _selectedSensorType).toList();
    }

    // Filter by search query
    if (_searchQuery.isNotEmpty) {
      filtered = filtered.where((a) {
        return a.message.toLowerCase().contains(_searchQuery.toLowerCase()) ||
               a.sensorType.displayName.toLowerCase().contains(_searchQuery.toLowerCase());
      }).toList();
    }

    // Sort by timestamp (newest first)
    filtered.sort((a, b) => b.timestamp.compareTo(a.timestamp));

    setState(() {
      _filteredAlerts = filtered;
    });
  }

  void _resolveAlert(AlertModel alert) {
    setState(() {
      final index = _alerts.indexWhere((a) => a.id == alert.id);
      if (index != -1) {
        _alerts[index] = alert.copyWith(
          resolved: true,
          resolvedAt: DateTime.now(),
          resolvedBy: 'Current User', // Replace with actual user
        );
        _applyFilters();
      }
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Alert resolved successfully'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _dismissAlert(AlertModel alert) {
    setState(() {
      _alerts.removeWhere((a) => a.id == alert.id);
      _applyFilters();
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Alert dismissed'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final stats = MockFarmData.getAlertStats();

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.background,
      appBar: AppBar(
        title: const Text('Alert Management'),
        actions: [
          IconButton(
            onPressed: _loadAlerts,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh',
          ),
          IconButton(
            onPressed: () {
              // Navigate to alert configuration
            },
            icon: const Icon(Icons.settings),
            tooltip: 'Settings',
          ),
        ],
      ),
      body: Column(
        children: [
          // Stats Section
          _buildStatsSection(stats, isDark),

          // Filters Section
          _buildFiltersSection(isDark),

          // Search Bar
          _buildSearchBar(isDark),

          // Alert List
          Expanded(
            child: _filteredAlerts.isEmpty
                ? _buildEmptyState(isDark)
                : _buildAlertList(),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsSection(Map<String, dynamic> stats, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: Row(
        children: [
          Expanded(
            child: _buildStatItem(
              'Active',
              stats['active'].toString(),
              AppColors.error,
              Icons.warning_amber,
              isDark,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Critical',
              stats['critical'].toString(),
              AppColors.error,
              Icons.error_outline,
              isDark,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Warning',
              stats['warning'].toString(),
              AppColors.warning,
              Icons.warning,
              isDark,
            ),
          ),
          Expanded(
            child: _buildStatItem(
              'Resolved',
              stats['resolved'].toString(),
              AppColors.success,
              Icons.check_circle,
              isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color color, IconData icon, bool isDark) {
    return Column(
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white60 : AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFiltersSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Filters',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                // Status Filter
                _buildFilterChip(
                  'All',
                  _selectedFilter == 'all',
                  () => setState(() {
                    _selectedFilter = 'all';
                    _applyFilters();
                  }),
                  isDark,
                ),
                _buildFilterChip(
                  'Active',
                  _selectedFilter == 'active',
                  () => setState(() {
                    _selectedFilter = 'active';
                    _applyFilters();
                  }),
                  isDark,
                ),
                _buildFilterChip(
                  'Resolved',
                  _selectedFilter == 'resolved',
                  () => setState(() {
                    _selectedFilter = 'resolved';
                    _applyFilters();
                  }),
                  isDark,
                ),
                
                const SizedBox(width: AppSpacing.md),
                
                // Severity Filter
                _buildFilterChip(
                  'Critical',
                  _selectedSeverity == AlertSeverity.high,
                  () => setState(() {
                    _selectedSeverity = _selectedSeverity == AlertSeverity.high ? null : AlertSeverity.high;
                    _applyFilters();
                  }),
                  isDark,
                  color: AppColors.error,
                ),
                _buildFilterChip(
                  'Warning',
                  _selectedSeverity == AlertSeverity.medium,
                  () => setState(() {
                    _selectedSeverity = _selectedSeverity == AlertSeverity.medium ? null : AlertSeverity.medium;
                    _applyFilters();
                  }),
                  isDark,
                  color: AppColors.warning,
                ),
                _buildFilterChip(
                  'Info',
                  _selectedSeverity == AlertSeverity.low,
                  () => setState(() {
                    _selectedSeverity = _selectedSeverity == AlertSeverity.low ? null : AlertSeverity.low;
                    _applyFilters();
                  }),
                  isDark,
                  color: AppColors.info,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap, bool isDark, {Color? color}) {
    final chipColor = color ?? AppColors.primary;
    
    return Padding(
      padding: const EdgeInsets.only(right: AppSpacing.sm),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        selectedColor: chipColor.withOpacity(0.2),
        checkmarkColor: chipColor,
        labelStyle: AppTypography.bodySmall.copyWith(
          color: selected ? chipColor : (isDark ? Colors.white70 : AppColors.textPrimary),
          fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
        ),
        side: BorderSide(
          color: selected ? chipColor : (isDark ? Colors.white24 : Colors.black12),
        ),
      ),
    );
  }

  Widget _buildSearchBar(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      color: isDark ? AppColors.surfaceDark : Colors.white,
      child: TextField(
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _applyFilters();
          });
        },
        decoration: InputDecoration(
          hintText: 'Search alerts...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  onPressed: () {
                    setState(() {
                      _searchQuery = '';
                      _applyFilters();
                    });
                  },
                  icon: const Icon(Icons.clear),
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          filled: true,
          fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral100,
        ),
      ),
    );
  }

  Widget _buildAlertList() {
    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: _filteredAlerts.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.md),
      itemBuilder: (context, index) {
        final alert = _filteredAlerts[index];
        return AlertCard(
          alert: alert,
          onTap: () => _showAlertDetails(alert),
          onResolve: alert.isActive ? () => _resolveAlert(alert) : null,
          onDismiss: () => _dismissAlert(alert),
        );
      },
    );
  }

  Widget _buildEmptyState(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.notifications_none,
            size: 80,
            color: isDark ? Colors.white24 : Colors.black12,
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'No alerts found',
            style: AppTypography.h6.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            _searchQuery.isNotEmpty
                ? 'Try adjusting your search or filters'
                : 'All systems are running smoothly',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white38 : AppColors.textSecondary,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  void _showAlertDetails(AlertModel alert) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _AlertDetailsSheet(
        alert: alert,
        onResolve: alert.isActive ? () {
          Navigator.pop(context);
          _resolveAlert(alert);
        } : null,
        onDismiss: () {
          Navigator.pop(context);
          _dismissAlert(alert);
        },
      ),
    );
  }
}

/// Alert Details Bottom Sheet
class _AlertDetailsSheet extends StatelessWidget {
  final AlertModel alert;
  final VoidCallback? onResolve;
  final VoidCallback? onDismiss;

  const _AlertDetailsSheet({
    required this.alert,
    this.onResolve,
    this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final severityColor = _getSeverityColor(alert.severity);

    return Container(
      margin: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.all(AppSpacing.lg),
            decoration: BoxDecoration(
              color: severityColor.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(AppSpacing.radiusLg),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  _getSeverityIcon(alert.severity),
                  color: severityColor,
                  size: 32,
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        alert.sensorType.displayName,
                        style: AppTypography.h6.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        alert.severity.displayName.toUpperCase(),
                        style: AppTypography.bodySmall.copyWith(
                          color: severityColor,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
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
                  'Alert Message',
                  style: AppTypography.bodySmall.copyWith(
                    color: isDark ? Colors.white60 : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  alert.message,
                  style: AppTypography.bodyLarge.copyWith(
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),

                const SizedBox(height: AppSpacing.lg),

                _buildDetailRow('Timestamp', alert.timestamp.toString(), isDark),
                _buildDetailRow('Time Ago', alert.timeAgo, isDark),
                _buildDetailRow('Farm ID', alert.farmId, isDark),
                _buildDetailRow('Alert ID', alert.id, isDark),

                if (alert.resolved) ...[
                  const SizedBox(height: AppSpacing.md),
                  Container(
                    padding: const EdgeInsets.all(AppSpacing.md),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.check_circle, color: AppColors.success, size: 20),
                            const SizedBox(width: AppSpacing.sm),
                            Text(
                              'Resolved',
                              style: AppTypography.bodyMedium.copyWith(
                                color: AppColors.success,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                        if (alert.resolvedBy != null) ...[
                          const SizedBox(height: AppSpacing.xs),
                          Text(
                            'By: ${alert.resolvedBy}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                        if (alert.resolvedAt != null) ...[
                          Text(
                            'At: ${alert.resolvedAt}',
                            style: AppTypography.bodySmall.copyWith(
                              color: AppColors.success,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: AppSpacing.lg),

                // Actions
                if (onResolve != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: onResolve,
                      icon: const Icon(Icons.check),
                      label: const Text('Resolve Alert'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                
                if (onDismiss != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.delete_outline),
                      label: const Text('Dismiss Alert'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error),
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSeverityColor(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return AppColors.info;
      case AlertSeverity.medium:
        return AppColors.warning;
      case AlertSeverity.high:
        return AppColors.error;
    }
  }

  IconData _getSeverityIcon(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.low:
        return Icons.info_outline;
      case AlertSeverity.medium:
        return Icons.warning_amber;
      case AlertSeverity.high:
        return Icons.error_outline;
    }
  }
}
