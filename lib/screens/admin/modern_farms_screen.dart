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
  
  // State for inline details view
  bool _showingDetails = false;
  Map<String, dynamic>? _selectedFarm;
  
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
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile ? _buildMobileLayout(isDark) : _buildDesktopLayout(isDark),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark) {
    return Row(
      children: [
        ModernAdminSidebar(selectedIndex: 2, onItemSelected: (_) {}),
        Expanded(
          child: Column(
            children: [
              ModernAdminHeader(userName: 'Admin', onNotificationTap: () {}, onProfileTap: () {}),
              Expanded(
                child: _showingDetails && _selectedFarm != null
                    ? _buildFarmDetailsContent(isDark, _selectedFarm!)
                    : _buildFarmListContent(isDark),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFarmListContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Builder(
        builder: (context) {
          final screenWidth = MediaQuery.of(context).size.width;
          final isTablet = screenWidth < 1200;
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Farm Management',
                          style: AppTypography.h4.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontSize: isTablet ? 22 : 28,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          'Monitor all farm locations',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                            fontSize: isTablet ? 13 : 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  if (!isTablet) ...[
                    const SizedBox(width: AppSpacing.md),
                    ElevatedButton.icon(
                      onPressed: () => _showAddFarmDialog(context, isDark),
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
                ],
              ),
              if (isTablet) ...[
                const SizedBox(height: AppSpacing.md),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => _showAddFarmDialog(context, isDark),
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add Farm'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: AppSpacing.xl),
              // Stats
              _buildStatsCards(isDark),
              const SizedBox(height: AppSpacing.xl),
              // Farms Grid
              Column(
                children: _farms.map((farm) => _buildFarmRow(farm, isDark)).toList(),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildMobileLayout(bool isDark) {
    return Column(
      children: [
        ModernAdminHeader(userName: 'Admin', onNotificationTap: () {}, onProfileTap: () {}),
        Expanded(
          child: _showingDetails && _selectedFarm != null
              ? _buildFarmDetailsContent(isDark, _selectedFarm!)
              : _buildMobileFarmListContent(isDark),
        ),
      ],
    );
  }

  Widget _buildMobileFarmListContent(bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Farm Management', style: AppTypography.h5.copyWith(fontWeight: FontWeight.bold, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.lg),
          // Stats (mobile optimized)
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            mainAxisSpacing: AppSpacing.sm,
            crossAxisSpacing: AppSpacing.sm,
            childAspectRatio: 1.5,
            children: [
              _buildStatCard('Total Farms', '${_farms.length}', Icons.agriculture, AppColors.primary, isDark),
              _buildStatCard('Active Farms', '${_farms.where((f) => f['status'] == 'Active').length}', Icons.check_circle, AppColors.success, isDark),
              _buildStatCard('Total Revenue', '\$${(_totalRevenue / 1000).toStringAsFixed(1)}K', Icons.attach_money, AppColors.info, isDark),
              _buildStatCard('Avg Health', '${_averageHealth.toStringAsFixed(0)}%', Icons.favorite, AppColors.warning, isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
          // Farms List (mobile optimized)
          ..._farms.map((farm) => _buildMobileFarmCard(farm, isDark)),
        ],
      ),
    );
  }

  Widget _buildFarmDetailsContent(bool isDark, Map<String, dynamic> farm) {
    final statusColor = _getStatusColor(farm['status']);
    final revenue = farm['revenue'] as num;
    final expenses = (revenue * 0.3).round();
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Back button header
          Row(
            children: [
              IconButton(
                onPressed: () => setState(() {
                  _showingDetails = false;
                  _selectedFarm = null;
                }),
                icon: Icon(
                  Icons.arrow_back,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                tooltip: 'Back to farms',
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Text(
                  farm['name'],
                  style: AppTypography.h5.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                ),
                child: Text(
                  farm['status'],
                  style: AppTypography.bodySmall.copyWith(
                    color: statusColor,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),

          // Farm Overview Card
          _buildDetailsCard(
            title: 'Farm Overview',
            icon: Icons.agriculture,
            isDark: isDark,
            child: Column(
              children: [
                _buildDetailsRow('Location', farm['location'], Icons.location_on, isDark),
                _buildDetailsRow('Farm Size', farm['size'], Icons.square_foot, isDark),
                _buildDetailsRow('Farm Type', farm['type'], Icons.category, isDark),
                _buildDetailsRow('Crops', farm['crops'], Icons.eco, isDark),
                _buildDetailsRow('Owner', farm['owner'] ?? 'Admin User', Icons.person, isDark),
                _buildDetailsRow('Last Activity', farm['lastActivity'], Icons.schedule, isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Health & Progress Card
          _buildDetailsCard(
            title: 'Health & Progress',
            icon: Icons.favorite,
            isDark: isDark,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Farm Health',
                            style: AppTypography.bodySmall.copyWith(
                              color: isDark ? Colors.white54 : AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                          Row(
                            children: [
                              Text(
                                '${farm['health']}%',
                                style: AppTypography.h4.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                              const SizedBox(width: AppSpacing.sm),
                              Icon(
                                farm['health'] >= 90 ? Icons.trending_up : Icons.trending_flat,
                                color: farm['health'] >= 90 ? AppColors.success : AppColors.warning,
                                size: 20,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 80,
                      height: 80,
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox(
                            width: 80,
                            height: 80,
                            child: CircularProgressIndicator(
                              value: (farm['health'] as num) / 100,
                              strokeWidth: 8,
                              backgroundColor: isDark ? Colors.white12 : AppColors.neutral200,
                              valueColor: AlwaysStoppedAnimation<Color>(AppColors.success),
                            ),
                          ),
                          Icon(Icons.eco, color: AppColors.success, size: 28),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                _buildProgressBar('Temperature', '${farm['temperature']}°C', 0.7, AppColors.warning, isDark),
                _buildProgressBar('Humidity', '65%', 0.65, AppColors.info, isDark),
                _buildProgressBar('Soil pH', '6.2', 0.85, AppColors.success, isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Revenue & Expenses Card
          _buildDetailsCard(
            title: 'Revenue & Expenses',
            icon: Icons.attach_money,
            isDark: isDark,
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _buildFinanceCard('Revenue', '\$${revenue.toStringAsFixed(0)}', AppColors.success, isDark),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildFinanceCard('Expenses', '\$${expenses.toStringAsFixed(0)}', AppColors.error, isDark),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Row(
                  children: [
                    Expanded(
                      child: _buildFinanceCard('Profit', '\$${(revenue - expenses).toStringAsFixed(0)}', AppColors.info, isDark),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: _buildFinanceCard('ROI', '${((revenue - expenses) / revenue * 100).toStringAsFixed(1)}%', AppColors.primary, isDark),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Energy Consumption Card
          _buildDetailsCard(
            title: 'Energy Consumption',
            icon: Icons.bolt,
            isDark: isDark,
            child: Column(
              children: [
                _buildDetailsRow('Daily Average', '150 kWh', Icons.power, isDark),
                _buildDetailsRow('Monthly Total', '4,500 kWh', Icons.calendar_month, isDark),
                _buildDetailsRow('Energy Cost', '\$675/month', Icons.attach_money, isDark),
                _buildDetailsRow('Solar Usage', '35%', Icons.wb_sunny, isDark),
                const SizedBox(height: AppSpacing.md),
                _buildProgressBar('Grid Power', '65%', 0.65, AppColors.warning, isDark),
                _buildProgressBar('Solar Power', '35%', 0.35, AppColors.success, isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.lg),

          // Resources & Staff Card
          _buildDetailsCard(
            title: 'Resources & Staff',
            icon: Icons.people,
            isDark: isDark,
            child: Column(
              children: [
                _buildDetailsRow('Caretakers', '${farm['caretakers']}', Icons.person, isDark),
                _buildDetailsRow('Sensors Active', '12', Icons.sensors, isDark),
                _buildDetailsRow('Irrigation Zones', '8', Icons.water_drop, isDark),
                _buildDetailsRow('Equipment', '15 units', Icons.build, isDark),
              ],
            ),
          ),
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildDetailsCard({
    required String title,
    required IconData icon,
    required bool isDark,
    required Widget child,
  }) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.transparent : Colors.black.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
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
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Icon(icon, color: AppColors.primary, size: 20),
              ),
              const SizedBox(width: AppSpacing.md),
              Text(
                title,
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }

  Widget _buildDetailsRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white54 : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text(
            '$label: ',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTypography.bodySmall.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.end,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressBar(String label, String value, double progress, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: AppTypography.bodySmall.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
              Text(
                value,
                style: AppTypography.bodySmall.copyWith(
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          LinearProgressIndicator(
            value: progress,
            backgroundColor: isDark ? Colors.white12 : AppColors.neutral200,
            valueColor: AlwaysStoppedAnimation<Color>(color),
            borderRadius: BorderRadius.circular(4),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildFinanceCard(String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white54 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
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

  Widget _buildStatCard(String title, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: AppSpacing.sm),
          Flexible(
            child: Text(
              value,
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: color,
                fontSize: 16,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
          Flexible(
            child: Text(
              title,
              style: TextStyle(
                color: color.withOpacity(0.8),
                fontSize: 11,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMobileFarmCard(Map<String, dynamic> farm, bool isDark) {
    final statusColor = farm['status'] == 'Active' ? AppColors.success : AppColors.error;
    return InkWell(
      onTap: () => _showViewFarmDialog(context, farm, isDark),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        margin: const EdgeInsets.only(bottom: AppSpacing.md),
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        farm['name'] as String,
                        style: AppTypography.bodyLarge.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                          fontSize: 15,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        farm['location'] as String,
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? Colors.white60 : AppColors.textSecondary,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 6,
                        height: 6,
                        decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle),
                      ),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          farm['status'] as String,
                          style: TextStyle(
                            color: statusColor,
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            Row(
              children: [
                Expanded(
                  child: _buildMobileMetric('Size', farm['size'] as String, isDark),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildMobileMetric('Type', farm['type'] as String, isDark),
                ),
                const SizedBox(width: AppSpacing.xs),
                Expanded(
                  child: _buildMobileMetric('Health', '${farm['health']}%', isDark),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileMetric(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? Colors.white60 : AppColors.textSecondary,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0, 'route': '/dashboard'},
      {'icon': Icons.people_outline, 'label': 'Users', 'index': 1, 'route': '/users'},
      {'icon': Icons.agriculture_outlined, 'label': 'Farms', 'index': 2, 'route': '/farms'},
      {'icon': Icons.sensors_outlined, 'label': 'Sensors', 'index': 3, 'route': '/sensors'},
      {'icon': Icons.analytics_outlined, 'label': 'Analytics', 'index': 4, 'route': '/analytics'},
      {'icon': Icons.settings_outlined, 'label': 'Settings', 'index': 5, 'route': '/settings'},
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
            children: navItems.take(5).map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == 2; // Farms screen is index 2

              return Expanded(
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      if (index != 2) {
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
                                : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
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
  
  Widget _buildStatsCards(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;
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
    
    return LayoutBuilder(
      builder: (context, constraints) {
        if (isTablet) {
          // Use grid for tablet
          return GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            crossAxisSpacing: AppSpacing.md,
            mainAxisSpacing: AppSpacing.md,
            childAspectRatio: 2.5,
            children: stats.map((stat) => Container(
              padding: const EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: (stat['color'] as Color).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                border: Border.all(color: (stat['color'] as Color).withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 20),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    stat['value'] as String,
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.bold,
                      color: stat['color'] as Color,
                      fontSize: 16,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stat['title'] as String,
                    style: TextStyle(
                      color: (stat['color'] as Color).withOpacity(0.8),
                      fontSize: 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            )).toList(),
          );
        }
        
        // Use row for desktop
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
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 24),
                  const SizedBox(height: AppSpacing.sm),
                  Text(
                    stat['value'] as String,
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: stat['color'] as Color,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    stat['title'] as String,
                    style: TextStyle(
                      color: (stat['color'] as Color).withOpacity(0.8),
                      fontSize: 12,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          )).toList(),
        );
      },
    );
  }
  
  Widget _buildFarmRow(Map<String, dynamic> farm, bool isDark) {
    final statusColor = _statusColor(farm['status'] as String);
    final screenWidth = MediaQuery.of(context).size.width;
    final isTablet = screenWidth < 1200 && screenWidth >= 600;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: InkWell(
        onTap: () => _showViewFarmDialog(context, farm, isDark),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        child: Padding(
          padding: EdgeInsets.all(isTablet ? AppSpacing.md : AppSpacing.lg),
          child: isTablet ? _buildTabletFarmCard(farm, isDark, statusColor) : _buildDesktopFarmCard(farm, isDark, statusColor),
        ),
      ),
    );
  }

  Widget _buildDesktopFarmCard(Map<String, dynamic> farm, bool isDark, Color statusColor) {
    return Row(
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
            mainAxisSize: MainAxisSize.min,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
                        Flexible(
                          child: Text(
                            farm['status'] as String,
                            style: TextStyle(
                              color: statusColor,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.landscape_outlined, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      farm['size'] as String,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Icon(Icons.schedule, size: 14, color: isDark ? Colors.white60 : AppColors.textSecondary),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      farm['lastActivity'] as String,
                      style: TextStyle(fontSize: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
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
          mainAxisSize: MainAxisSize.min,
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
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: () => _showViewFarmDialog(context, farm, isDark),
              icon: const Icon(Icons.visibility_outlined),
              iconSize: 20,
              color: AppColors.info,
              tooltip: 'View Details',
            ),
            IconButton(
              onPressed: () => _showEditFarmDialog(context, farm, isDark),
              icon: const Icon(Icons.edit_outlined),
              iconSize: 20,
              color: AppColors.primary,
              tooltip: 'Edit',
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildTabletFarmCard(Map<String, dynamic> farm, bool isDark, Color statusColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Farm Image
            Container(
              width: 60,
              height: 60,
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
                      child: Icon(Icons.agriculture, size: 28, color: statusColor),
                    );
                  },
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
                      Expanded(
                        child: Text(
                          farm['name'] as String,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.circle, size: 8, color: statusColor),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                farm['status'] as String,
                                style: TextStyle(
                                  color: statusColor,
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.location_on_outlined, size: 12, color: isDark ? Colors.white60 : AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          farm['location'] as String,
                          style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        // Metrics Grid
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          crossAxisSpacing: AppSpacing.sm,
          mainAxisSpacing: AppSpacing.sm,
          childAspectRatio: 1.5,
          children: [
            _buildMetric('Temp', '${farm['temperature']}°C', Icons.thermostat, AppColors.warning, isDark),
            _buildMetric('Type', farm['type'] as String, Icons.eco, AppColors.success, isDark),
            _buildMetric('Staff', '${farm['caretakers']}', Icons.people, AppColors.primary, isDark),
            _buildMetric('Revenue', '\$${((farm['revenue'] as num) / 1000).toStringAsFixed(1)}K', Icons.trending_up, AppColors.info, isDark),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Health indicator
            Row(
              children: [
                SizedBox(
                  width: 50,
                  height: 50,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 50,
                        height: 50,
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
                          strokeWidth: 5,
                        ),
                      ),
                      Text(
                        '${farm['health']}%',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
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
                const SizedBox(width: AppSpacing.sm),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Health',
                      style: TextStyle(fontSize: 10, color: isDark ? Colors.white60 : AppColors.textSecondary),
                    ),
                    Text(
                      farm['size'] as String,
                      style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary),
                    ),
                  ],
                ),
              ],
            ),
            // Actions
            Row(
              children: [
                IconButton(
                  onPressed: () => _showViewFarmDialog(context, farm, isDark),
                  icon: const Icon(Icons.visibility_outlined),
                  iconSize: 18,
                  color: AppColors.info,
                  tooltip: 'View Details',
                ),
                IconButton(
                  onPressed: () => _showEditFarmDialog(context, farm, isDark),
                  icon: const Icon(Icons.edit_outlined),
                  iconSize: 18,
                  color: AppColors.primary,
                  tooltip: 'Edit',
                ),
              ],
            ),
          ],
        ),
      ],
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
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(height: 4),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
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
  
  // ============ MODAL DIALOGS ============
  
  void _showAddFarmDialog(BuildContext context, bool isDark) {
    final nameController = TextEditingController();
    final ownerController = TextEditingController();
    final locationController = TextEditingController();
    final sizeController = TextEditingController();
    final cropsController = TextEditingController();
    String selectedTier = 'Standard';
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 500,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.success, AppColors.success.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: const Icon(Icons.add_business, color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Add New Farm', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), Text('Register a new farm in the system', style: AppTypography.bodySmall.copyWith(color: Colors.white70))])),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Farm Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildFormTextField(controller: nameController, hint: 'Enter farm name', icon: Icons.agriculture, isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Owner', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildFormTextField(controller: ownerController, hint: 'Enter owner name', icon: Icons.person_outline, isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Location', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildFormTextField(controller: locationController, hint: 'Enter farm location', icon: Icons.location_on_outlined, isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isMobile) Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Farm Size', isDark), const SizedBox(height: AppSpacing.sm), _buildFormTextField(controller: sizeController, hint: 'e.g., 12.5 acres', icon: Icons.square_foot, isDark: isDark)])),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Subscription Tier', isDark), const SizedBox(height: AppSpacing.sm), _buildFormDropdown(value: selectedTier, items: ['Basic', 'Standard', 'Premium'], icon: Icons.star_outline, isDark: isDark, onChanged: (v) => setDialogState(() => selectedTier = v!))])),
                        ]) else ...[
                          _buildFormLabel('Farm Size', isDark), const SizedBox(height: AppSpacing.sm), _buildFormTextField(controller: sizeController, hint: 'e.g., 12.5 acres', icon: Icons.square_foot, isDark: isDark),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Subscription Tier', isDark), const SizedBox(height: AppSpacing.sm), _buildFormDropdown(value: selectedTier, items: ['Basic', 'Standard', 'Premium'], icon: Icons.star_outline, isDark: isDark, onChanged: (v) => setDialogState(() => selectedTier = v!)),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Crop Types', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildFormTextField(controller: cropsController, hint: 'e.g., Lettuce, Tomatoes, Kale', icon: Icons.eco, isDark: isDark),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl))),
                  child: Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Text('${nameController.text.isEmpty ? "Farm" : nameController.text} added successfully!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.add, size: 18), label: const Text('Add Farm'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  void _showViewFarmDialog(BuildContext context, Map<String, dynamic> farm, bool isDark) {
    final statusColor = _statusColor(farm['status']);
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
        insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
        child: Container(
          width: isMobile ? double.infinity : 550,
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Header with Farm Image
              Container(
                height: 150,
                decoration: BoxDecoration(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  image: DecorationImage(
                    image: NetworkImage(farm['image'] as String),
                    fit: BoxFit.cover,
                    onError: (_, __) {},
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                    gradient: LinearGradient(colors: [Colors.black.withOpacity(0.7), Colors.transparent], begin: Alignment.bottomCenter, end: Alignment.topCenter),
                  ),
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
                        Container(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4), decoration: BoxDecoration(color: statusColor.withOpacity(0.9), borderRadius: BorderRadius.circular(AppSpacing.radiusFull)), child: Row(mainAxisSize: MainAxisSize.min, children: [Icon(Icons.circle, size: 8, color: Colors.white), const SizedBox(width: 4), Text(farm['status'], style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600))])),
                        IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                      ]),
                      Row(children: [
                        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                          Text(farm['name'], style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
                          Row(children: [const Icon(Icons.location_on, size: 14, color: Colors.white70), const SizedBox(width: 4), Text(farm['location'], style: const TextStyle(color: Colors.white70, fontSize: 12))]),
                        ])),
                      ]),
                    ],
                  ),
                ),
              ),
              // Content
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Quick Stats Grid
                      GridView.count(
                        crossAxisCount: isMobile ? 2 : 4,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                        childAspectRatio: isMobile ? 1.8 : 1.5,
                        children: [
                          _buildModalStatCard('Size', farm['size'], Icons.square_foot, AppColors.primary, isDark),
                          _buildModalStatCard('Type', farm['type'], Icons.category, AppColors.info, isDark),
                          _buildModalStatCard('Staff', '${farm['caretakers']}', Icons.people, AppColors.warning, isDark),
                          _buildModalStatCard('Health', '${farm['health']}%', Icons.favorite, farm['health'] > 80 ? AppColors.success : AppColors.warning, isDark),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      // Details Section
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50, borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Farm Details', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: isDark ? Colors.white : AppColors.textPrimary)),
                            const SizedBox(height: AppSpacing.md),
                            _buildDetailRow('Crops', farm['crops'], Icons.eco, isDark),
                            _buildDetailRow('Revenue', '\$${(farm['revenue'] as num).toStringAsFixed(0)}', Icons.attach_money, isDark),
                            _buildDetailRow('Temperature', '${farm['temperature']}°C', Icons.thermostat, isDark),
                            _buildDetailRow('Last Activity', farm['lastActivity'], Icons.schedule, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Actions
              Container(
                padding: const EdgeInsets.all(AppSpacing.lg),
                decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl))),
                child: Row(
                  children: [
                    Expanded(child: OutlinedButton.icon(onPressed: () { Navigator.pop(context); setState(() { _selectedFarm = farm; _showingDetails = true; }); }, icon: const Icon(Icons.insights, size: 18), label: const Text('Details'), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: AppColors.info), foregroundColor: AppColors.info, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(child: ElevatedButton(onPressed: () => Navigator.pop(context), style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: const Text('Close'))),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
  
  void _showEditFarmDialog(BuildContext context, Map<String, dynamic> farm, bool isDark) {
    final nameController = TextEditingController(text: farm['name']);
    final locationController = TextEditingController(text: farm['location']);
    final sizeController = TextEditingController(text: farm['size']);
    String selectedType = farm['type'];
    String selectedStatus = farm['status'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 500,
            constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.success, AppColors.success.withOpacity(0.8)], begin: Alignment.topLeft, end: Alignment.bottomRight),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(10), decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)), child: const Icon(Icons.edit, color: Colors.white, size: 24)),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text('Edit Farm', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)), Text('Update farm details', style: AppTypography.bodySmall.copyWith(color: Colors.white70))])),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Form
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildFormLabel('Farm Name', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildFormTextField(controller: nameController, hint: 'Farm name', icon: Icons.business, isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Location', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildFormTextField(controller: locationController, hint: 'Location', icon: Icons.location_on, isDark: isDark),
                        const SizedBox(height: AppSpacing.lg),
                        if (!isMobile) Row(children: [
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Farm Size', isDark), const SizedBox(height: AppSpacing.sm), _buildFormTextField(controller: sizeController, hint: 'Size', icon: Icons.square_foot, isDark: isDark)])),
                          const SizedBox(width: AppSpacing.md),
                          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [_buildFormLabel('Farm Type', isDark), const SizedBox(height: AppSpacing.sm), _buildFormDropdown(value: selectedType, items: ['Hydroponics', 'Greenhouse', 'Mixed', 'Organic'], icon: Icons.category, isDark: isDark, onChanged: (v) => setDialogState(() => selectedType = v!))])),
                        ]) else ...[
                          _buildFormLabel('Farm Size', isDark), const SizedBox(height: AppSpacing.sm), _buildFormTextField(controller: sizeController, hint: 'Size', icon: Icons.square_foot, isDark: isDark),
                          const SizedBox(height: AppSpacing.lg),
                          _buildFormLabel('Farm Type', isDark), const SizedBox(height: AppSpacing.sm), _buildFormDropdown(value: selectedType, items: ['Hydroponics', 'Greenhouse', 'Mixed', 'Organic'], icon: Icons.category, isDark: isDark, onChanged: (v) => setDialogState(() => selectedType = v!)),
                        ],
                        const SizedBox(height: AppSpacing.lg),
                        _buildFormLabel('Status', isDark),
                        const SizedBox(height: AppSpacing.sm),
                        _buildFormDropdown(value: selectedStatus, items: ['Active', 'Maintenance', 'Idle'], icon: Icons.toggle_on, isDark: isDark, onChanged: (v) => setDialogState(() => selectedStatus = v!)),
                      ],
                    ),
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50, borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl))),
                  child: Row(
                    children: [
                      Expanded(child: OutlinedButton(onPressed: () => Navigator.pop(context), style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), side: BorderSide(color: isDark ? Colors.white24 : AppColors.neutral300), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))), child: Text('Cancel', style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary)))),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(flex: 2, child: ElevatedButton.icon(onPressed: () { Navigator.pop(context); ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Text('${nameController.text} updated!')]), backgroundColor: AppColors.success, behavior: SnackBarBehavior.floating, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)))); }, icon: const Icon(Icons.save, size: 18), label: const Text('Save Changes'), style: ElevatedButton.styleFrom(backgroundColor: AppColors.success, foregroundColor: Colors.white, padding: const EdgeInsets.symmetric(vertical: AppSpacing.md), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd))))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
  
  // Helper Widgets for Modals
  Widget _buildFormLabel(String label, bool isDark) => Text(label, style: AppTypography.bodyMedium.copyWith(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary));
  
  Widget _buildFormTextField({required TextEditingController controller, required String hint, required IconData icon, required bool isDark}) {
    return TextFormField(
      controller: controller,
      style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: isDark ? Colors.white38 : AppColors.textSecondary.withOpacity(0.5)),
        prefixIcon: Icon(icon, color: isDark ? Colors.white54 : AppColors.textSecondary, size: 20),
        filled: true,
        fillColor: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: BorderSide(color: isDark ? Colors.white12 : AppColors.neutral200)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd), borderSide: const BorderSide(color: AppColors.primary, width: 2)),
        contentPadding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
      ),
    );
  }
  
  Widget _buildFormDropdown({required String value, required List<String> items, required IconData icon, required bool isDark, required Function(String?) onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
      decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50, borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: isDark ? Colors.white12 : AppColors.neutral200)),
      child: DropdownButtonHideUnderline(child: DropdownButton<String>(value: value, isExpanded: true, icon: Icon(Icons.keyboard_arrow_down, color: isDark ? Colors.white54 : AppColors.textSecondary), dropdownColor: isDark ? AppColors.surfaceDark : Colors.white, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary, fontSize: 14), items: items.map((item) => DropdownMenuItem(value: item, child: Row(children: [Icon(icon, color: isDark ? Colors.white54 : AppColors.textSecondary, size: 20), const SizedBox(width: AppSpacing.md), Text(item)]))).toList(), onChanged: onChanged)),
    );
  }
  
  Widget _buildModalStatCard(String label, String value, IconData icon, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm, vertical: AppSpacing.sm),
      decoration: BoxDecoration(color: color.withOpacity(isDark ? 0.15 : 0.1), borderRadius: BorderRadius.circular(AppSpacing.radiusMd), border: Border.all(color: color.withOpacity(0.3))),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(height: 2),
          FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary), maxLines: 1),
          ),
          Text(label, style: TextStyle(fontSize: 9, color: isDark ? Colors.white60 : AppColors.textSecondary), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }
  
  Widget _buildDetailRow(String label, String value, IconData icon, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
      child: Row(
        children: [
          Icon(icon, size: 16, color: isDark ? Colors.white54 : AppColors.textSecondary),
          const SizedBox(width: AppSpacing.sm),
          Text('$label: ', style: TextStyle(fontSize: 12, color: isDark ? Colors.white54 : AppColors.textSecondary)),
          Expanded(child: Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary))),
        ],
      ),
    );
  }
}
