import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';

/// Modern Farms Management Screen
class ModernFarmsScreen extends ConsumerStatefulWidget {
  const ModernFarmsScreen({super.key});

  @override
  ConsumerState<ModernFarmsScreen> createState() => _ModernFarmsScreenState();
}

class _ModernFarmsScreenState extends ConsumerState<ModernFarmsScreen> {
  String _searchQuery = '';
  String _selectedType = 'All';
  
  final List<Map<String, dynamic>> _farms = [
    {
      'id': 'F001',
      'name': 'Green Valley Farm',
      'location': 'Nairobi, Kenya',
      'size': '12.5 acres',
      'type': 'Hydroponics',
      'status': 'Active',
      'lastActivity': '2 hours ago',
      'crops': 'Lettuce, Kale',
      'caretakers': 6,
      'revenue': 125000,
      'health': 96,
      'image': 'https://iqrorwxhniriml5q.ldycdn.com/cloud/omBppKiiRmiSorrimjlli/206822878926538318.jpg',
      'color': AppColors.success,
      'temperature': 27.8,
    },
    {
      'id': 'F002',
      'name': 'Sunshine Fields',
      'location': 'Nakuru, Kenya',
      'size': '8.2 acres',
      'type': 'Greenhouse',
      'status': 'Active',
      'lastActivity': '5 hours ago',
      'crops': 'Tomatoes, Peppers',
      'caretakers': 5,
      'revenue': 98000,
      'health': 92,
      'image': 'https://image.made-in-china.com/2f0j00fbjqYJURHtcn/Affordable-Agriculture-Polycarbonate-Greenhouse-with-Hydroponic-Growing-System-for-Mushrooms-Vegetables-Fruits-Flowers-Lettuce-and-Peppers.jpg',
      'color': AppColors.warning,
      'temperature': 27.1,
    },
    {
      'id': 'F003',
      'name': 'Mountain View Farm',
      'location': 'Eldoret, Kenya',
      'size': '15.0 acres',
      'type': 'Mixed',
      'status': 'Maintenance',
      'lastActivity': '1 day ago',
      'crops': 'Mixed Greens',
      'caretakers': 7,
      'revenue': 145000,
      'health': 85,
      'image': 'https://cdn.mos.cms.futurecdn.net/WFB6T4D75sgSapDGpLPxHD.jpg',
      'color': AppColors.info,
      'temperature': 25.4,
    },
    {
      'id': 'F004',
      'name': 'River Side Farm',
      'location': 'Kisumu, Kenya',
      'size': '6.8 acres',
      'type': 'Hydroponics',
      'status': 'Active',
      'lastActivity': '30 minutes ago',
      'crops': 'Tomatoes, Herbs',
      'caretakers': 4,
      'revenue': 88000,
      'health': 90,
      'image': 'https://media.istockphoto.com/id/483721777/photo/tomatoes.jpg?s=612x612&w=0&k=20&c=Z6GqFTtOzvAKYjOAbr8knRLnn3UcEkRbkPTvzGhfF58=',
      'color': AppColors.primary,
      'temperature': 26.2,
    },
  ];

  double get _totalAcreage => _farms.fold(0.0, (sum, farm) {
        final sizeString = (farm['size'] as String).split(' ').first;
        final acres = double.tryParse(sizeString) ?? 0;
        return sum + acres;
      });

  double get _totalRevenue => _farms.fold(0.0, (sum, farm) {
        final revenue = (farm['revenue'] as num?)?.toDouble() ?? 0;
        return sum + revenue;
      });

  double get _averageHealth => _farms.isEmpty
      ? 0
      : _farms.fold<double>(0, (sum, farm) => sum + (farm['health'] as num).toDouble()) /
          _farms.length;
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          ModernAdminSidebar(selectedIndex: 2, onItemSelected: (_) {}),
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
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Farm Management', style: AppTypography.h4.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
                                Text('Monitor all farm locations', style: AppTypography.bodyMedium.copyWith(color: isDark ? Colors.white70 : AppColors.textSecondary)),
                              ],
                            ),
                            ElevatedButton.icon(
                              onPressed: () {},
                              icon: const Icon(Icons.add, size: 20),
                              label: const Text('Add Farm'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Stats
                        _buildStatsCards(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Farms Grid
                        Column(
                          children: _farms.map((farm) => _buildFarmRow(farm, isDark)).toList(),
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
  
  Widget _buildStatsCards(bool isDark) {
    final stats = [
      {
        'title': 'Total Farms',
        'value': '${_farms.length}',
        'icon': Icons.agriculture,
        'color': AppColors.primary,
      },
      {
        'title': 'Total Acreage',
        'value': '${_totalAcreage.toStringAsFixed(1)} acres',
        'icon': Icons.landscape,
        'color': AppColors.success,
      },
      {
        'title': 'Total Revenue',
        'value': '\$${(_totalRevenue / 1000).toStringAsFixed(1)}K',
        'icon': Icons.attach_money,
        'color': AppColors.warning,
      },
      {
        'title': 'Avg Health',
        'value': '${_averageHealth.toStringAsFixed(0)}%',
        'icon': Icons.favorite,
        'color': AppColors.info,
      },
    ];
    
    return Row(
      children: stats.map((stat) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: stat != stats.last ? AppSpacing.md : 0),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            color: (stat['color'] as Color).withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: (stat['color'] as Color).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 24),
              const SizedBox(height: AppSpacing.md),
              Text(stat['value'] as String, style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold, color: stat['color'] as Color)),
              Text(stat['title'] as String, style: TextStyle(color: (stat['color'] as Color).withOpacity(0.8), fontSize: 12)),
            ],
          ),
        ),
      )).toList(),
    );
  }
  
  Widget _buildFarmRow(Map<String, dynamic> farm, bool isDark) {
    final statusColor = _statusColor(farm['status'] as String);

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: InkWell(
        onTap: () {},
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Row(
            children: [
              // Farm Image
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  border: Border.all(color: statusColor.withOpacity(0.3), width: 2),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(AppSpacing.radiusMd - 2),
                  child: Image.network(
                    farm['image'] as String,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              statusColor.withOpacity(0.3),
                              statusColor.withOpacity(0.1),
                            ],
                          ),
                        ),
                        child: Icon(Icons.agriculture, size: 36, color: statusColor),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(width: AppSpacing.lg),

              // Summary info
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            farm['name'] as String,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: isDark ? Colors.white : AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.circle, size: 10, color: statusColor),
                              const SizedBox(width: 4),
                              Text(
                                farm['status'] as String,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            farm['location'] as String,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(Icons.landscape_outlined, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          farm['size'] as String,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        Icon(Icons.grass, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            farm['crops'] as String,
                            style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const SizedBox(width: AppSpacing.md),
                        Icon(Icons.schedule, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                        const SizedBox(width: 4),
                        Text(
                          farm['lastActivity'] as String,
                          style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.lg),

              // Key metrics
              Expanded(
                flex: 3,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMetric('Temp', '${farm['temperature']}°C', Icons.thermostat, AppColors.warning, isDark),
                    _buildMetric('Type', farm['type'] as String, Icons.eco, AppColors.success, isDark),
                    _buildMetric('Staff', '${farm['caretakers']}', Icons.people, AppColors.primary, isDark),
                    _buildMetric('Revenue', '\$${((farm['revenue'] as num) / 1000).toStringAsFixed(1)}K', Icons.trending_up, AppColors.info, isDark),
                  ],
                ),
              ),

              const SizedBox(width: AppSpacing.lg),

              // Health indicator
              Column(
                children: [
                  Text(
                    'Health',
                    style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary),
                  ),
                  const SizedBox(height: 4),
                  SizedBox(
                    width: 60,
                    height: 60,
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox(
                          width: 60,
                          height: 60,
                          child: CircularProgressIndicator(
                            value: (farm['health'] as num) / 100,
                            backgroundColor: Colors.grey.withOpacity(0.2),
                            valueColor: AlwaysStoppedAnimation(
                              (farm['health'] as num) > 80
                                  ? AppColors.success
                                  : (farm['health'] as num) > 60
                                      ? AppColors.warning
                                      : AppColors.error,
                            ),
                            strokeWidth: 6,
                          ),
                        ),
                        Text(
                          '${farm['health']}%',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: (farm['health'] as num) > 80
                                ? AppColors.success
                                : (farm['health'] as num) > 60
                                    ? AppColors.warning
                                    : AppColors.error,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),

              const SizedBox(width: AppSpacing.lg),

              // Actions
              Column(
                children: [
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility_outlined),
                    iconSize: 20,
                    color: AppColors.info,
                    tooltip: 'View Details',
                  ),
                  IconButton(
                    onPressed: () {},
                    icon: const Icon(Icons.edit_outlined),
                    iconSize: 20,
                    color: AppColors.primary,
                    tooltip: 'Edit',
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return AppColors.success;
      case 'maintenance':
        return AppColors.warning;
      case 'idle':
        return AppColors.info;
      default:
        return AppColors.neutral500;
    }
  }
  
  Widget _buildMetric(String label, String value, IconData icon, Color color, bool isDark) {
    return Column(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 14,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
  
  Widget _buildDropdown(String label, String value, List<String> items, Function(String?) onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : AppColors.neutral100,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
        onChanged: onChanged,
        underline: const SizedBox(),
        icon: const Icon(Icons.arrow_drop_down),
      ),
    );
  }
}
