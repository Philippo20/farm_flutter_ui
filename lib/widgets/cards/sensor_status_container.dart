import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EnergyConsumptionContainer extends StatefulWidget {
  final bool isDark;
  final VoidCallback? onExpand;

  const EnergyConsumptionContainer({
    super.key,
    required this.isDark,
    this.onExpand,
  });

  @override
  State<EnergyConsumptionContainer> createState() => _EnergyConsumptionContainerState();
}

class _EnergyConsumptionContainerState extends State<EnergyConsumptionContainer> 
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  bool _isExpanded = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = widget.isDark;
    
    return Container(
      constraints: BoxConstraints(
        maxWidth: MediaQuery.of(context).size.width - 40,
      ),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF232323) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Energy Overview',
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                    widget.onExpand?.call();
                  },
                ),
              ],
            ),
          ),
          
          if (!_isExpanded) ...[
            const SizedBox(height: 8),
            _buildCompactView(isDark, colorScheme),
          ] else ...[
            const SizedBox(height: 16),
            _buildExpandedView(isDark, colorScheme),
          ],
        ],
      ),
    );
  }

  Widget _buildCompactView(bool isDark, ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  title: "Grid Usage",
                  value: "4.2 kW",
                  icon: Icons.electrical_services,
                  color: Colors.blue,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStatCard(
                  title: "Solar Output",
                  value: "3.8 kW",
                  icon: Icons.solar_power,
                  color: Colors.orange,
                  isDark: isDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),
          _buildEnergySummary(isDark, colorScheme),
          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildExpandedView(bool isDark, ColorScheme colorScheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 22),
          child: Container(
            decoration: BoxDecoration(
              color: isDark ? Colors.grey[900] : Colors.grey[100],
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(4),
            child: TabBar(
              controller: _tabController,
              isScrollable: false,
              indicator: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: (isDark ? colorScheme.secondary : colorScheme.primary)
                    .withOpacity(0.2),
                border: Border.all(
                  color: (isDark ? colorScheme.secondary : colorScheme.primary)
                      .withOpacity(0.5),
                  width: 1,
                ),
              ),
              labelColor: isDark ? colorScheme.secondary : colorScheme.primary,
              unselectedLabelColor: isDark 
                  ? Colors.white.withOpacity(0.5) 
                  : Colors.black.withOpacity(0.5),
              tabs: [
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.electrical_services, size: 20),
                      const SizedBox(width: 8),
                      Text('Grid', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
                Tab(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.solar_power, size: 20),
                      const SizedBox(width: 8),
                      Text('Solar', style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          height: 350,
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildGridConsumption(isDark),
              _buildSolarProduction(isDark),
            ],
          ),
        ),
        
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _buildEnergySummary(isDark, colorScheme),
        ),
      ],
    );
  }

  Widget _buildGridConsumption(bool isDark) {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.bar_chart, size: 40, color: Colors.blue),
                const SizedBox(height: 10),
                Text('Grid Consumption Chart',
                    style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black54)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 400, // Adjust this value as needed
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.3,
            crossAxisSpacing: 10,
            mainAxisSpacing: 15,
            padding: EdgeInsets.zero,
            children: [
              
              _buildStatCard(
                title: 'Current Usage',
                value: '4.2 kW',
                icon: Icons.flash_on,
                color: Colors.amber,
                isDark: isDark,
              ),
              
              _buildStatCard(
                title: 'Peak Today',
                value: '6.1 kW',
                icon: Icons.bolt,
                color: Colors.red,
                isDark: isDark,
              ),
              _buildStatCard(
                title: 'Cost Today',
                value: 'GHC 52.42',
                icon: Icons.attach_money,
                color: Colors.green,
                isDark: isDark,
              ),
              _buildStatCard(
                title: 'Monthly Avg',
                value: '5.2 kW',
                icon: Icons.calendar_today,
                color: Colors.purple,
                isDark: isDark,
              ),
            ],
          ),
        ),
         SizedBox(height: 20),

      ],
    ),
  );
}

Widget _buildSolarProduction(bool isDark) {
  return SingleChildScrollView(
    padding: const EdgeInsets.symmetric(horizontal: 20),
    child: Column(
      children: [
        Container(
          height: 200,
          width: double.infinity,
          decoration: BoxDecoration(
            color: isDark ? Colors.grey[850] : Colors.grey[50],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.show_chart, size: 40, color: Colors.orange),
                const SizedBox(height: 10),
                Text('Solar Production Chart',
                    style: GoogleFonts.inter(color: isDark ? Colors.white70 : Colors.black54)),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: 420, // Adjust this value as needed
          ),
          child: GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 15,
            padding: EdgeInsets.zero,
            children: [
              _buildStatCard(
                title: 'Current Output',
                value: '3.8 kW',
                icon: Icons.sunny,
                color: Colors.orange,
                isDark: isDark,
              ),
              _buildStatCard(
                title: 'Peak Today',
                value: '4.5 kW',
                icon: Icons.arrow_upward,
                color: Colors.deepOrange,
                isDark: isDark,
              ),
              _buildStatCard(
                title: 'Total Today',
                value: '22 kWh',
                icon: Icons.battery_full,
                color: Colors.green,
                isDark: isDark,
              ),
              _buildStatCard(
                title: 'Efficiency',
                value: '87%',
                icon: Icons.star,
                color: Colors.blue,
                isDark: isDark,
              ),
              
            ],
          ),
        ),
        SizedBox(height: 20),
      ],
      
    ),
  );
}

  Widget _buildStatCard({
  required String title,
  required String value,
  required IconData icon,
  required Color color,
  required bool isDark,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: isDark ? Colors.grey[800]!.withOpacity(0.5) : Colors.grey[50],
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
        width: 1,
      ),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 28,
              height: 50,
              decoration: BoxDecoration(
                color: color.withOpacity(0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 16, color: color),
            ),
            const Spacer(),
            Container(
            
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Icon(Icons.trending_up, size: 14, color: color),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white70 : Colors.black54,
              ),
            ),
            Text(
              value,
              style: GoogleFonts.poppins(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : Colors.black,
              ),
            ),
          ],
        ),
      ],
    ),
  );
}

  Widget _buildEnergySummary(bool isDark, ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark 
            ? colorScheme.secondaryContainer.withOpacity(0.2)
            : colorScheme.secondaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark 
              ? colorScheme.secondary.withOpacity(0.3)
              : colorScheme.secondary.withOpacity(0.2),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colorScheme.secondary.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.energy_savings_leaf,
              color: colorScheme.secondary,
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Net Energy Today',
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                Text(
                  '18.4 kWh from solar (64% of total)',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.green.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: Colors.green.withOpacity(0.3),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.eco, size: 16, color: Colors.green),
                const SizedBox(width: 6),
                Text(
                  'Eco Mode',
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}