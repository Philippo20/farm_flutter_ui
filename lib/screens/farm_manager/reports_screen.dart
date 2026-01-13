import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../providers/auth_provider.dart';

/// Reports Screen for Farm Manager
/// View comprehensive farm reports and analytics
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedNavIndex = 4;
  String _selectedPeriod = 'Last 30 Days';
  String _selectedFarm = 'All Farms';
  String _selectedReportType = 'Production';

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Farm Manager';
    final userEmail = authState.user?.email ?? 'manager@farmestates.com';
    final userRole = 'Farm Manager';

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
        FarmManagerSidebar(
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
              FarmManagerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.xl),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _buildFilters(isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _buildSummaryCards(isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _buildChartsSection(isDark),
                      const SizedBox(height: AppSpacing.xl),
                      _buildReportTable(isDark),
                    ],
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
        FarmManagerHeader(
          userName: userName,
          onNotificationTap: () {},
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildFilters(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildSummaryCards(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildChartsSection(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildReportTable(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Reports',
              style: AppTypography.h4.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: isMobile ? 20 : 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Comprehensive analytics and performance metrics',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
                fontSize: isMobile ? 12 : 14,
              ),
            ),
          ],
        ),
        if (!isMobile)
          Row(
            children: [
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Export PDF'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.print, size: 18),
                label: const Text('Print'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: isDark ? Colors.white.withOpacity(0.1) : Colors.white,
                  foregroundColor: isDark ? Colors.white : AppColors.textPrimary,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg, vertical: AppSpacing.md),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildFilters(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: isMobile
          ? Column(
              children: [
                _buildFilterDropdown('Period', _selectedPeriod, ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'This Year'], (v) => setState(() => _selectedPeriod = v!), isDark),
                const SizedBox(height: AppSpacing.sm),
                _buildFilterDropdown('Farm', _selectedFarm, ['All Farms', 'Green Valley', 'Sunny Acres'], (v) => setState(() => _selectedFarm = v!), isDark),
                const SizedBox(height: AppSpacing.sm),
                _buildFilterDropdown('Report Type', _selectedReportType, ['Production', 'Financial', 'Inventory', 'Performance'], (v) => setState(() => _selectedReportType = v!), isDark),
              ],
            )
          : Row(
              children: [
                Expanded(child: _buildFilterDropdown('Period', _selectedPeriod, ['Last 7 Days', 'Last 30 Days', 'Last 90 Days', 'This Year'], (v) => setState(() => _selectedPeriod = v!), isDark)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildFilterDropdown('Farm', _selectedFarm, ['All Farms', 'Green Valley', 'Sunny Acres'], (v) => setState(() => _selectedFarm = v!), isDark)),
                const SizedBox(width: AppSpacing.md),
                Expanded(child: _buildFilterDropdown('Report Type', _selectedReportType, ['Production', 'Financial', 'Inventory', 'Performance'], (v) => setState(() => _selectedReportType = v!), isDark)),
              ],
            ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, Function(String?) onChanged, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        const SizedBox(height: AppSpacing.xs),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? Colors.white10 : AppColors.neutral100,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
          ),
          child: DropdownButton<String>(
            value: value,
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item))).toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }

  Widget _buildSummaryCards(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 800 ? 4 : 2;
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: AppSpacing.sm,
          crossAxisSpacing: AppSpacing.sm,
          childAspectRatio: isMobile ? 2.8 : 3.2,
          children: [
            _buildSummaryCard('Total Production', '12.5K kg', '+18%', AppColors.primary, Icons.inventory, isDark),
            _buildSummaryCard('Revenue', '\$420K', '+23%', AppColors.success, Icons.attach_money, isDark),
            _buildSummaryCard('Active Batches', '24', '+12%', AppColors.info, Icons.grid_view, isDark),
            _buildSummaryCard('Efficiency', '94.2%', '+5%', AppColors.warning, Icons.trending_up, isDark),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, String change, Color color, IconData icon, bool isDark) {
    return Card(
      elevation: 0,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: 18),
            ),
            const SizedBox(width: AppSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    title,
                    style: AppTypography.bodySmall.copyWith(
                      color: color.withOpacity(0.8),
                      fontWeight: FontWeight.w600,
                      fontSize: 10,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: 16,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_upward, size: 9, color: AppColors.success),
                  const SizedBox(width: 2),
                  Text(change, style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 9)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChartsSection(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth > 900;
        if (isWide) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(flex: 2, child: _buildProductionChart(isDark, isMobile)),
              SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
              Expanded(child: _buildDistributionChart(isDark, isMobile)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildProductionChart(isDark, isMobile),
              SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
              _buildDistributionChart(isDark, isMobile),
            ],
          );
        }
      },
    );
  }

  Widget _buildProductionChart(bool isDark, bool isMobile) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Production Trend',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: isMobile ? 14 : 18,
              ),
            ),
            SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
            SizedBox(
              height: isMobile ? 200 : 250,
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
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isMobile ? 30 : 40,
                        getTitlesWidget: (value, meta) => Text(
                          '${value.toInt()}K',
                          style: TextStyle(fontSize: isMobile ? 9 : 10, color: isDark ? Colors.white60 : AppColors.textSecondary),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: isMobile ? 25 : 30,
                        getTitlesWidget: (value, meta) {
                          const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun'];
                          if (value.toInt() >= 0 && value.toInt() < months.length) {
                            return Text(
                              months[value.toInt()],
                              style: TextStyle(fontSize: isMobile ? 9 : 10, color: isDark ? Colors.white60 : AppColors.textSecondary),
                            );
                          }
                          return const SizedBox();
                        },
                      ),
                    ),
                    rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                    topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: const [FlSpot(0, 8), FlSpot(1, 9), FlSpot(2, 8.5), FlSpot(3, 10), FlSpot(4, 11), FlSpot(5, 12)],
                      isCurved: true,
                      color: AppColors.primary,
                      barWidth: 3,
                      dotData: const FlDotData(show: false),
                      belowBarData: BarAreaData(show: true, color: AppColors.primary.withOpacity(0.1)),
                    ),
                  ],
                  minY: 0,
                  maxY: 15,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDistributionChart(bool isDark, bool isMobile) {
    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Distribution',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: isMobile ? 14 : 18,
              ),
            ),
            SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
            SizedBox(
              height: isMobile ? 200 : 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: isMobile ? 30 : 40,
                  sections: [
                    PieChartSectionData(value: 40, title: '40%', color: AppColors.primary, radius: isMobile ? 45 : 60, titleStyle: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 30, title: '30%', color: AppColors.success, radius: isMobile ? 45 : 60, titleStyle: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 20, title: '20%', color: AppColors.info, radius: isMobile ? 45 : 60, titleStyle: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 10, title: '10%', color: AppColors.warning, radius: isMobile ? 45 : 60, titleStyle: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
            if (isMobile) ...[
              const SizedBox(height: AppSpacing.sm),
              Wrap(
                spacing: AppSpacing.sm,
                runSpacing: AppSpacing.xs,
                children: [
                  _buildLegendItem('Green Valley', AppColors.primary, isDark),
                  _buildLegendItem('Sunny Acres', AppColors.success, isDark),
                  _buildLegendItem('Fresh Farms', AppColors.info, isDark),
                  _buildLegendItem('Others', AppColors.warning, isDark),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color, bool isDark) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white70 : AppColors.textSecondary)),
      ],
    );
  }

  Widget _buildReportTable(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    final reports = [
      {'farm': 'Green Valley Farm', 'production': '3.5K kg', 'revenue': '\$125K', 'efficiency': '95%', 'status': 'Excellent'},
      {'farm': 'Sunny Acres', 'production': '2.8K kg', 'revenue': '\$85K', 'efficiency': '88%', 'status': 'Good'},
      {'farm': 'Fresh Farms', 'production': '2.1K kg', 'revenue': '\$65K', 'efficiency': '72%', 'status': 'Fair'},
    ];

    return Card(
      elevation: 0,
      color: isDark ? AppColors.surfaceDark : Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppSpacing.md : AppSpacing.lg),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farm Performance Summary',
              style: AppTypography.h6.copyWith(
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white : AppColors.textPrimary,
                fontSize: isMobile ? 14 : 18,
              ),
            ),
            SizedBox(height: isMobile ? AppSpacing.sm : AppSpacing.md),
            isMobile
                ? Column(
                    children: reports.map((r) => _buildMobileReportCard(r, isDark)).toList(),
                  )
                : Table(
                    border: TableBorder.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
                    children: [
                      TableRow(
                        decoration: BoxDecoration(color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50),
                        children: [
                          _buildTableCell('Farm', true, isDark),
                          _buildTableCell('Production', true, isDark),
                          _buildTableCell('Revenue', true, isDark),
                          _buildTableCell('Efficiency', true, isDark),
                          _buildTableCell('Status', true, isDark),
                        ],
                      ),
                      ...reports.map((r) => TableRow(
                        children: [
                          _buildTableCell(r['farm']!, false, isDark),
                          _buildTableCell(r['production']!, false, isDark),
                          _buildTableCell(r['revenue']!, false, isDark),
                          _buildTableCell(r['efficiency']!, false, isDark),
                          _buildTableCell(r['status']!, false, isDark, isStatus: true),
                        ],
                      )),
                    ],
                  ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobileReportCard(Map<String, dynamic> report, bool isDark) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.sm),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(color: isDark ? Colors.white10 : Colors.black.withOpacity(0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(report['farm']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: isDark ? Colors.white : AppColors.textPrimary)),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Production: ${report['production']}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : AppColors.textSecondary)),
              Text('Revenue: ${report['revenue']}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : AppColors.textSecondary)),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Efficiency: ${report['efficiency']}', style: TextStyle(fontSize: 11, color: isDark ? Colors.white70 : AppColors.textSecondary)),
              _buildTableCell(report['status']!, false, isDark, isStatus: true),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTableCell(String text, bool isHeader, bool isDark, {bool isStatus = false}) {
    if (isStatus) {
      final statusColor = text == 'Excellent' ? AppColors.success : text == 'Good' ? AppColors.info : AppColors.warning;
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.sm),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: statusColor.withOpacity(0.1),
            borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
          ),
          child: Text(
            text,
            style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          fontSize: isHeader ? 12 : 13,
          color: isDark ? Colors.white : AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0, 'route': '/farm-manager'},
      {'icon': Icons.inventory_2_outlined, 'label': 'Inventory', 'index': 1, 'route': '/farm-manager/inventory'},
      {'icon': Icons.grid_view_outlined, 'label': 'Batches', 'index': 2, 'route': '/farm-manager/batch-generation'},
      {'icon': Icons.request_quote_outlined, 'label': 'Funds', 'index': 3, 'route': '/farm-manager/fund-request'},
      {'icon': Icons.assessment_outlined, 'label': 'Reports', 'index': 4, 'route': '/farm-manager/reports'},
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
}
