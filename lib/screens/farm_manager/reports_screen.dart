import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:fl_chart/fl_chart.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/farm_manager_sidebar.dart';
import '../../core/widgets/farm_manager_header.dart';
import '../../core/widgets/farm_manager_mobile_drawer.dart';
import '../../providers/auth_provider.dart';

/// Reports Screen for Farm Manager
/// View comprehensive farm reports and analytics
class ReportsScreen extends ConsumerStatefulWidget {
  const ReportsScreen({super.key});

  @override
  ConsumerState<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends ConsumerState<ReportsScreen> {
  int _selectedNavIndex = 6;
  String _selectedPeriod = 'Last 30 Days';
  String _selectedFarm = 'All Farms';
  String _selectedReportType = 'Production';
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

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
      key: _scaffoldKey,
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? FarmManagerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) => setState(() => _selectedNavIndex = index),
              userName: userName,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile ? _buildBottomNavigation(isDark) : null,
    );
  }

  Widget _buildMobileDrawer(bool isDark, String userName, String userEmail, String userRole) {
    return Drawer(
      backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
      child: FarmManagerSidebar(
        selectedIndex: _selectedNavIndex,
        onItemSelected: (index) {
          setState(() => _selectedNavIndex = index);
          Navigator.pop(context);
        },
        userName: userName,
        userEmail: userEmail,
        userRole: userRole,
      ),
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
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildMobileHeader(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildMobileActionButtons(isDark),
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

  Widget _buildMobileHeader(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farm Reports',
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Analytics and performance metrics',
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildMobileActionButtons(bool isDark) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showExportDialog(context, isDark),
            icon: const Icon(Icons.download, size: 16),
            label: const Text('Export', style: TextStyle(fontSize: 12)),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showPrintDialog(context, isDark),
            icon: const Icon(Icons.print, size: 16),
            label: const Text('Print', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => _showScheduleReportDialog(context, isDark),
            icon: const Icon(Icons.schedule, size: 16),
            label: const Text('Schedule', style: TextStyle(fontSize: 12)),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Farm Reports',
                style: AppTypography.h4.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Comprehensive analytics and performance metrics',
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            OutlinedButton.icon(
              onPressed: () => _showScheduleReportDialog(context, isDark),
              icon: const Icon(Icons.schedule, size: 18),
              label: const Text('Schedule'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(horizontal: AppSpacing.md, vertical: AppSpacing.md),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            ElevatedButton.icon(
              onPressed: () => _showExportDialog(context, isDark),
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
              onPressed: () => _showPrintDialog(context, isDark),
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
            items: items.map((item) => DropdownMenuItem(value: item, child: Text(item, style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)))).toList(),
            onChanged: onChanged,
            isExpanded: true,
            underline: const SizedBox(),
            icon: Icon(Icons.arrow_drop_down, color: isDark ? Colors.white54 : AppColors.textSecondary),
            dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
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
          childAspectRatio: isMobile ? 2.5 : 3.0,
          children: [
            _buildSummaryCard('Total Production', '12.5K kg', '+18%', AppColors.primary, Icons.inventory, isDark),
            _buildSummaryCard('Revenue', 'GH₵420K', '+23%', AppColors.success, Icons.attach_money, isDark),
            _buildSummaryCard('Active Batches', '24', '+12%', AppColors.info, Icons.grid_view, isDark),
            _buildSummaryCard('Efficiency', '94.2%', '+5%', AppColors.warning, Icons.trending_up, isDark),
          ],
        );
      },
    );
  }

  Widget _buildSummaryCard(String title, String value, String change, Color color, IconData icon, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    
    return Card(
      elevation: 0,
      color: color.withOpacity(0.15),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        side: BorderSide(color: color.withOpacity(0.3), width: 1.5),
      ),
      child: Padding(
        padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(isMobile ? 6 : 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(icon, color: color, size: isMobile ? 18 : 22),
            ),
            SizedBox(width: isMobile ? AppSpacing.xs : AppSpacing.sm),
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
                      fontSize: isMobile ? 9 : 11,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    value,
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.bold,
                      color: color,
                      fontSize: isMobile ? 14 : 18,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: isMobile ? 4 : 6, vertical: isMobile ? 2 : 3),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(isDark ? 0.15 : 0.9),
                borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.arrow_upward, size: isMobile ? 8 : 10, color: AppColors.success),
                  SizedBox(width: isMobile ? 1 : 2),
                  Text(change, style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: isMobile ? 8 : 10)),
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
              const SizedBox(width: AppSpacing.md),
              Expanded(child: _buildDistributionChart(isDark, isMobile)),
            ],
          );
        } else {
          return Column(
            children: [
              _buildProductionChart(isDark, isMobile),
              const SizedBox(height: AppSpacing.md),
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
              height: isMobile ? 180 : 250,
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
              height: isMobile ? 180 : 250,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: isMobile ? 30 : 40,
                  sections: [
                    PieChartSectionData(value: 40, title: '40%', color: AppColors.primary, radius: isMobile ? 40 : 60, titleStyle: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 30, title: '30%', color: AppColors.success, radius: isMobile ? 40 : 60, titleStyle: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 20, title: '20%', color: AppColors.info, radius: isMobile ? 40 : 60, titleStyle: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.white, fontWeight: FontWeight.bold)),
                    PieChartSectionData(value: 10, title: '10%', color: AppColors.warning, radius: isMobile ? 40 : 60, titleStyle: TextStyle(fontSize: isMobile ? 10 : 11, color: Colors.white, fontWeight: FontWeight.bold)),
                  ],
                ),
              ),
            ),
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
      {'farm': 'Green Valley Farm', 'production': '3.5K kg', 'revenue': 'GH₵125K', 'efficiency': '95%', 'status': 'Excellent'},
      {'farm': 'Sunny Acres', 'production': '2.8K kg', 'revenue': 'GH₵85K', 'efficiency': '88%', 'status': 'Good'},
      {'farm': 'Fresh Farms', 'production': '2.1K kg', 'revenue': 'GH₵65K', 'efficiency': '72%', 'status': 'Fair'},
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Farm Performance Summary',
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: isMobile ? 14 : 18,
                  ),
                ),
                if (!isMobile)
                  TextButton.icon(
                    onPressed: () {},
                    icon: const Icon(Icons.visibility, size: 16),
                    label: const Text('View All'),
                  ),
              ],
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
                          _buildTableCell('Actions', true, isDark),
                        ],
                      ),
                      ...reports.map((r) => TableRow(
                        children: [
                          _buildTableCell(r['farm']!, false, isDark),
                          _buildTableCell(r['production']!, false, isDark),
                          _buildTableCell(r['revenue']!, false, isDark),
                          _buildTableCell(r['efficiency']!, false, isDark),
                          _buildTableCell(r['status']!, false, isDark, isStatus: true),
                          _buildTableActions(r, isDark),
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(report['farm']!, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
              ),
              _buildStatusBadge(report['status']!, isDark),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: _buildMobileReportStat('Production', report['production']!, isDark),
              ),
              Expanded(
                child: _buildMobileReportStat('Revenue', report['revenue']!, isDark),
              ),
              Expanded(
                child: _buildMobileReportStat('Efficiency', report['efficiency']!, isDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.visibility, size: 14),
                label: const Text('Details', style: TextStyle(fontSize: 11)),
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobileReportStat(String label, String value, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : AppColors.textSecondary)),
        Text(value, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
      ],
    );
  }

  Widget _buildStatusBadge(String status, bool isDark) {
    final statusColor = status == 'Excellent' ? AppColors.success : status == 'Good' ? AppColors.info : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
      ),
      child: Text(
        status,
        style: TextStyle(color: statusColor, fontSize: 10, fontWeight: FontWeight.w600),
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

  Widget _buildTableActions(Map<String, dynamic> report, bool isDark) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          IconButton(
            onPressed: () {},
            icon: const Icon(Icons.visibility, size: 18),
            tooltip: 'View Details',
            color: AppColors.info,
          ),
          IconButton(
            onPressed: () => _showExportDialog(context, isDark),
            icon: const Icon(Icons.download, size: 18),
            tooltip: 'Export',
            color: AppColors.primary,
          ),
        ],
      ),
    );
  }

  // ============= DIALOGS =============

  void _showExportDialog(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    String selectedFormat = 'PDF';
    bool includeCharts = true;
    bool includeTable = true;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.primary, AppColors.primary.withOpacity(0.8)]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                        child: const Icon(Icons.download, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Export Report', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Download farm analytics', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Export Format', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.md),
                      Row(
                        children: [
                          Expanded(child: _buildExportFormatOption('PDF', Icons.picture_as_pdf, selectedFormat == 'PDF', isDark, () => setDialogState(() => selectedFormat = 'PDF'))),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: _buildExportFormatOption('Excel', Icons.table_chart, selectedFormat == 'Excel', isDark, () => setDialogState(() => selectedFormat = 'Excel'))),
                          const SizedBox(width: AppSpacing.sm),
                          Expanded(child: _buildExportFormatOption('CSV', Icons.description, selectedFormat == 'CSV', isDark, () => setDialogState(() => selectedFormat = 'CSV'))),
                        ],
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Include in Export', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      _buildExportCheckbox('Charts & Graphs', includeCharts, (v) => setDialogState(() => includeCharts = v!), isDark),
                      _buildExportCheckbox('Data Tables', includeTable, (v) => setDialogState(() => includeTable = v!), isDark),
                      const SizedBox(height: AppSpacing.md),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: AppColors.info.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                          border: Border.all(color: AppColors.info.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.info_outline, color: AppColors.info, size: 18),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(child: Text('Export will include data for: $_selectedPeriod, $_selectedFarm', style: TextStyle(fontSize: 12, color: isDark ? Colors.white70 : AppColors.textSecondary))),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Text('Report exported as $selectedFormat')]),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.download, size: 18),
                          label: Text('Export $selectedFormat'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                        ),
                      ),
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

  Widget _buildExportFormatOption(String format, IconData icon, bool isSelected, bool isDark, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.1) : (isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50),
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: isSelected ? AppColors.primary : (isDark ? Colors.white10 : AppColors.neutral200)),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : (isDark ? Colors.white54 : AppColors.textSecondary), size: 24),
            const SizedBox(height: 4),
            Text(format, style: TextStyle(fontSize: 12, fontWeight: isSelected ? FontWeight.bold : FontWeight.normal, color: isSelected ? AppColors.primary : (isDark ? Colors.white : AppColors.textPrimary))),
          ],
        ),
      ),
    );
  }

  Widget _buildExportCheckbox(String label, bool value, Function(bool?) onChanged, bool isDark) {
    return CheckboxListTile(
      value: value,
      onChanged: onChanged,
      title: Text(label, style: TextStyle(fontSize: 13, color: isDark ? Colors.white : AppColors.textPrimary)),
      controlAffinity: ListTileControlAffinity.leading,
      contentPadding: EdgeInsets.zero,
      dense: true,
      activeColor: AppColors.primary,
    );
  }

  void _showPrintDialog(BuildContext context, bool isDark) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusLg)),
        title: Row(
          children: [
            Icon(Icons.print, color: AppColors.primary),
            const SizedBox(width: AppSpacing.sm),
            Text('Print Report', style: TextStyle(color: isDark ? Colors.white : AppColors.textPrimary)),
          ],
        ),
        content: Text(
          'This will send the current report to your default printer.\n\nPeriod: $_selectedPeriod\nFarm: $_selectedFarm\nReport Type: $_selectedReportType',
          style: TextStyle(color: isDark ? Colors.white70 : AppColors.textSecondary),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), const Text('Report sent to printer')]),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.print, size: 18),
            label: const Text('Print'),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
          ),
        ],
      ),
    );
  }

  void _showScheduleReportDialog(BuildContext context, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    String frequency = 'Weekly';
    String deliveryMethod = 'Email';

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
          backgroundColor: isDark ? AppColors.surfaceDark : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSpacing.radiusXl)),
          insetPadding: EdgeInsets.symmetric(horizontal: isMobile ? AppSpacing.md : AppSpacing.xxl, vertical: AppSpacing.xl),
          child: Container(
            width: isMobile ? double.infinity : 450,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [AppColors.info, AppColors.info.withOpacity(0.8)]),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: Colors.white.withOpacity(0.2), borderRadius: BorderRadius.circular(AppSpacing.radiusMd)),
                        child: const Icon(Icons.schedule, color: Colors.white, size: 24),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Schedule Report', style: AppTypography.h6.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
                            Text('Automate report delivery', style: AppTypography.bodySmall.copyWith(color: Colors.white70)),
                          ],
                        ),
                      ),
                      IconButton(onPressed: () => Navigator.pop(context), icon: const Icon(Icons.close, color: Colors.white70)),
                    ],
                  ),
                ),
                // Content
                Padding(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Frequency', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: ['Daily', 'Weekly', 'Monthly'].map((f) => ChoiceChip(
                          label: Text(f),
                          selected: frequency == f,
                          onSelected: (selected) {
                            if (selected) setDialogState(() => frequency = f);
                          },
                          selectedColor: AppColors.info.withOpacity(0.2),
                          labelStyle: TextStyle(color: frequency == f ? AppColors.info : (isDark ? Colors.white70 : AppColors.textSecondary)),
                        )).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Text('Delivery Method', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white70 : AppColors.textSecondary)),
                      const SizedBox(height: AppSpacing.sm),
                      Wrap(
                        spacing: AppSpacing.sm,
                        children: ['Email', 'Dashboard', 'Both'].map((m) => ChoiceChip(
                          label: Text(m),
                          selected: deliveryMethod == m,
                          onSelected: (selected) {
                            if (selected) setDialogState(() => deliveryMethod = m);
                          },
                          selectedColor: AppColors.info.withOpacity(0.2),
                          labelStyle: TextStyle(color: deliveryMethod == m ? AppColors.info : (isDark ? Colors.white70 : AppColors.textSecondary)),
                        )).toList(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      Container(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50,
                          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Report Settings', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: isDark ? Colors.white : AppColors.textPrimary)),
                            const SizedBox(height: AppSpacing.sm),
                            _buildScheduleInfoRow('Report Type', _selectedReportType, isDark),
                            _buildScheduleInfoRow('Farm', _selectedFarm, isDark),
                            _buildScheduleInfoRow('Period', _selectedPeriod, isDark),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Actions
                Container(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  decoration: BoxDecoration(
                    color: isDark ? Colors.white.withOpacity(0.03) : AppColors.neutral50,
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppSpacing.radiusXl)),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: AppSpacing.md)),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () {
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Row(children: [const Icon(Icons.check_circle, color: Colors.white), const SizedBox(width: 8), Text('Report scheduled: $frequency via $deliveryMethod')]),
                                backgroundColor: AppColors.success,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          },
                          icon: const Icon(Icons.schedule, size: 18),
                          label: const Text('Schedule'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.info,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: AppSpacing.md),
                          ),
                        ),
                      ),
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

  Widget _buildScheduleInfoRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: isDark ? Colors.white54 : AppColors.textSecondary)),
          Text(value, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: isDark ? Colors.white : AppColors.textPrimary)),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {'icon': Icons.dashboard_outlined, 'label': 'Dashboard', 'index': 0, 'route': '/farm-manager'},
      {'icon': Icons.agriculture_outlined, 'label': 'Farms', 'index': 1, 'route': '/farm-manager/farms'},
      {'icon': Icons.inventory_2_outlined, 'label': 'Inventory', 'index': 2, 'route': '/farm-manager/inventory'},
      {'icon': Icons.local_shipping_outlined, 'label': 'Deliveries', 'index': 3, 'route': '/farm-manager/deliveries'},
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
            children: navItems.map((item) {
              final index = item['index'] as int;
              final route = item['route'] as String;
              final isSelected = index == 4; // Reports is active

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
                          debugPrint('Navigation error: $e');
                        }
                      }
                    },
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          item['icon'] as IconData,
                          size: 24,
                          color: isSelected ? AppColors.primary : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected ? AppColors.primary : (isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary),
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
