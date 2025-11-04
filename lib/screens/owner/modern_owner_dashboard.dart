import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../data/mock_farm_data.dart';

/// Modern Owner Dashboard with financial and production focus
class ModernOwnerDashboard extends ConsumerStatefulWidget {
  const ModernOwnerDashboard({super.key});

  @override
  ConsumerState<ModernOwnerDashboard> createState() => _ModernOwnerDashboardState();
}

class _ModernOwnerDashboardState extends ConsumerState<ModernOwnerDashboard> {
  String _selectedFarm = 'All Farms';
  String _selectedPeriod = 'This Month';
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final financialData = MockFarmData.getFinancialData();
    final productionData = MockFarmData.getProductionMetrics();
    final caretakerData = MockFarmData.getCaretakerPerformance();
    
    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: Row(
        children: [
          // Owner Sidebar
          ModernAdminSidebar(
            selectedIndex: 0,
            onItemSelected: (index) {
              // Handle navigation for owner
              final routes = ['/owner_dashboard', '/owner_farm', '/owner_settings'];
              if (index < routes.length) {
                Navigator.pushNamed(context, routes[index]);
              }
            },
            userName: "Lizzy",
            userEmail: "owner@farm.com",
            userRole: "Farm Owner",
          ),
          
          Expanded(
            child: Column(
              children: [
                // Header
                ModernAdminHeader(
                  userName: 'Lizzy',
                  farms: ['All Farms', 'Northern Estate', 'Southern Estate'],
                  selectedFarm: _selectedFarm,
                  onFarmChanged: (farm) => setState(() => _selectedFarm = farm!),
                  onNotificationTap: () {},
                  onProfileTap: () {},
                ),
                
                // Content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(AppSpacing.xl),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Welcome Section
                        _buildWelcomeSection(isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Financial Stats
                        _buildFinancialStats(financialData, isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Charts Row
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 2, child: _buildRevenueChart(financialData, isDark)),
                            const SizedBox(width: AppSpacing.lg),
                            Expanded(child: _buildProductionChart(productionData, isDark)),
                          ],
                        ),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Caretaker Performance
                        _buildCaretakerPerformance(caretakerData, isDark),
                        
                        const SizedBox(height: AppSpacing.xl),
                        
                        // Quick Actions
                        _buildQuickActions(isDark),
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
  
  Widget _buildWelcomeSection(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Owner Dashboard',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Monitor your farm performance and finances',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
        // Period Selector
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          ),
          child: DropdownButton<String>(
            value: _selectedPeriod,
            items: ['Today', 'This Week', 'This Month', 'This Year']
                .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                .toList(),
            onChanged: (v) => setState(() => _selectedPeriod = v!),
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }
  
  Widget _buildFinancialStats(Map<String, dynamic> data, bool isDark) {
    final stats = [
      {'title': 'Revenue', 'value': '\$${data['revenue']['current'] / 1000}K', 'change': '+${data['revenue']['change']}%', 'icon': Icons.trending_up, 'color': AppColors.success},
      {'title': 'Expenses', 'value': '\$${data['expenses']['current'] / 1000}K', 'change': '+${data['expenses']['change']}%', 'icon': Icons.trending_down, 'color': AppColors.warning},
      {'title': 'Profit', 'value': '\$${data['profit']['current'] / 1000}K', 'change': '+${data['profit']['change']}%', 'icon': Icons.account_balance, 'color': AppColors.primary},
      {'title': 'ROI', 'value': '42.5%', 'change': '+5.2%', 'icon': Icons.show_chart, 'color': AppColors.info},
    ];
    
    return Row(
      children: stats.map((stat) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: stat != stats.last ? AppSpacing.md : 0),
          padding: const EdgeInsets.all(AppSpacing.lg),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                (stat['color'] as Color).withOpacity(0.15),
                (stat['color'] as Color).withOpacity(0.08),
              ],
            ),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            border: Border.all(color: (stat['color'] as Color).withOpacity(0.3)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: (stat['color'] as Color).withOpacity(0.2),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    ),
                    child: Icon(stat['icon'] as IconData, color: stat['color'] as Color, size: 22),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(isDark ? 0.1 : 0.9),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                    ),
                    child: Text(
                      stat['change'] as String,
                      style: TextStyle(
                        color: (stat['change'] as String).startsWith('+') ? AppColors.success : AppColors.error,
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                stat['value'] as String,
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: stat['color'] as Color,
                ),
              ),
              Text(
                stat['title'] as String,
                style: TextStyle(
                  color: (stat['color'] as Color).withOpacity(0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      )).toList(),
    );
  }
  
  Widget _buildRevenueChart(Map<String, dynamic> data, bool isDark) {
    final monthlyData = data['monthlyData'] as List;
    
    return Container(
      height: 300,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Revenue & Expenses Trend',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: LineChart(
              LineChartData(
                gridData: FlGridData(
                  show: true,
                  drawVerticalLine: false,
                  getDrawingHorizontalLine: (value) => FlLine(
                    color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
                    strokeWidth: 1,
                  ),
                ),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        if (value.toInt() < monthlyData.length) {
                          return Text(
                            monthlyData[value.toInt()]['month'],
                            style: const TextStyle(fontSize: 10),
                          );
                        }
                        return const SizedBox();
                      },
                    ),
                  ),
                ),
                borderData: FlBorderData(show: false),
                lineBarsData: [
                  LineChartBarData(
                    spots: List.generate(monthlyData.length, (i) => 
                      FlSpot(i.toDouble(), monthlyData[i]['revenue'] / 1000)),
                    isCurved: true,
                    color: AppColors.success,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                    belowBarData: BarAreaData(
                      show: true,
                      color: AppColors.success.withOpacity(0.1),
                    ),
                  ),
                  LineChartBarData(
                    spots: List.generate(monthlyData.length, (i) => 
                      FlSpot(i.toDouble(), monthlyData[i]['expenses'] / 1000)),
                    isCurved: true,
                    color: AppColors.warning,
                    barWidth: 3,
                    dotData: const FlDotData(show: false),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildProductionChart(Map<String, dynamic> data, bool isDark) {
    return Container(
      height: 300,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Production Distribution',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          Expanded(
            child: PieChart(
              PieChartData(
                sectionsSpace: 2,
                centerSpaceRadius: 30,
                sections: [
                  PieChartSectionData(
                    value: data['daily']['vegetables'].toDouble(),
                    title: 'Vegetables',
                    color: AppColors.primary,
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: data['daily']['fruits'].toDouble(),
                    title: 'Fruits',
                    color: AppColors.warning,
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: data['daily']['eggs'].toDouble(),
                    title: 'Eggs',
                    color: AppColors.info,
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                  PieChartSectionData(
                    value: data['daily']['milk'].toDouble(),
                    title: 'Dairy',
                    color: AppColors.success,
                    radius: 60,
                    titleStyle: const TextStyle(fontSize: 10, color: Colors.white),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildCaretakerPerformance(List<Map<String, dynamic>> data, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Caretaker Performance',
            style: AppTypography.h6.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.lg),
          ...data.take(3).map((caretaker) => Container(
            margin: const EdgeInsets.only(bottom: AppSpacing.md),
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  backgroundColor: AppColors.primary.withOpacity(0.1),
                  child: Text(
                    caretaker['name'].toString().split(' ').map((e) => e[0]).take(2).join(),
                    style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(caretaker['name'], style: TextStyle(fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
                      Text('${caretaker['farms'].first} • ${caretaker['specialization']}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${caretaker['efficiency']}%', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.success)),
                    Text('${caretaker['tasksCompleted']} tasks', style: TextStyle(fontSize: 11, color: isDark ? Colors.white60 : AppColors.textSecondary)),
                  ],
                ),
              ],
            ),
          )),
        ],
      ),
    );
  }
  
  Widget _buildQuickActions(bool isDark) {
    final actions = [
      {'icon': Icons.receipt_long, 'label': 'View Reports', 'color': AppColors.primary},
      {'icon': Icons.people_alt, 'label': 'Manage Staff', 'color': AppColors.info},
      {'icon': Icons.inventory, 'label': 'Inventory', 'color': AppColors.warning},
      {'icon': Icons.calendar_today, 'label': 'Schedule', 'color': AppColors.success},
    ];
    
    return Row(
      children: actions.map((action) => Expanded(
        child: Container(
          margin: EdgeInsets.only(right: action != actions.last ? AppSpacing.md : 0),
          child: ElevatedButton(
            onPressed: () {},
            style: ElevatedButton.styleFrom(
              backgroundColor: (action['color'] as Color).withOpacity(0.1),
              foregroundColor: action['color'] as Color,
              padding: const EdgeInsets.all(AppSpacing.lg),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                side: BorderSide(color: (action['color'] as Color).withOpacity(0.3)),
              ),
            ),
            child: Column(
              children: [
                Icon(action['icon'] as IconData, size: 24),
                const SizedBox(height: AppSpacing.sm),
                Text(action['label'] as String, style: const TextStyle(fontSize: 12)),
              ],
            ),
          ),
        ),
      )).toList(),
    );
  }
}
