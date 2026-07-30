import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../constants/colors.dart';

class FourthRow extends StatefulWidget {
  final bool isDark;

  const FourthRow({super.key, required this.isDark});

  @override
  State<FourthRow> createState() => _FourthRowState();
}

class _FourthRowState extends State<FourthRow> {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildEnergyTitleContainer(),
        SizedBox(height: 16),
        _buildEnergySourcesCard(),
        SizedBox(height: 16),
        _buildTitle("Energy Insight", 25),
        SizedBox(
          height: 16,
        ),
        _buildTabCard(isDark: widget.isDark),
      ],
    );
  }

  Widget _buildEnergyTitleContainer() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[800] : Colors.deepOrangeAccent,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: widget.isDark ? Colors.grey[700]! : Colors.grey[300]!,
            width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.deepOrangeAccent.withOpacity(0.2)
                  : Colors.white.withOpacity(0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.solar_power,
              color: widget.isDark ? Colors.deepOrangeAccent : Colors.white,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(
              'Farm Energy Consumption',
              style: GoogleFonts.poppins(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: widget.isDark ? Colors.white : Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnergySourcesCard() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        _buildEnergyCard(
          icon: Icons.sunny,
          label: 'Solar',
          status: 'ACTIVE',
          color: Colors.orange,
        ),
        _buildEnergyCard(
          icon: Icons.electrical_services,
          label: 'Grid',
          status: 'ACTIVE',
          color: Colors.blueGrey,
        ),
        _buildEnergyCard(
          icon: Icons.battery_full,
          label: 'Battery',
          status: 'CHARGING',
          color: Colors.green,
        ),
      ],
    );
  }

  Widget _buildEnergyCard({
    required IconData icon,
    required String label,
    required String status,
    required Color color,
  }) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Container(
          padding: const EdgeInsets.fromLTRB(5, 10, 5, 15),
          decoration: BoxDecoration(
            color: widget.isDark ? Colors.grey[850] : Colors.grey[100],
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: color.withOpacity(0.2),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(height: 10),
              Text(
                label,
                style: GoogleFonts.poppins(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: widget.isDark ? Colors.white : Colors.black,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                status,
                style: GoogleFonts.poppins(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: status == "ACTIVE"
                      ? (widget.isDark ? Colors.greenAccent : Colors.green)
                      : Colors.orange,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String title, double fontSize) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: GoogleFonts.poppins(
          fontSize: fontSize,
          fontWeight: FontWeight.w500,
          color: widget.isDark ? Colors.white : AppColors.darkCard,
        ),
      ),
    );
  }

  Widget _buildTabCard({required bool isDark}) {
    return DefaultTabController(
      length: 3,
      child: SizedBox(
        width: double.infinity,
        // padding: const EdgeInsets.all(0),
        /*
        decoration: BoxDecoration(
         // color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        */
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            LayoutBuilder(builder: (context, constraints) {
              final compactTabs = constraints.maxWidth < 330;
              return TabBar(
                labelColor: isDark ? Colors.greenAccent : Colors.green[800],
                unselectedLabelColor: isDark ? Colors.white70 : Colors.black54,
                indicatorColor: isDark ? Colors.greenAccent : Colors.green[800],
                indicatorWeight: 5,
                labelPadding: EdgeInsets.symmetric(
                  horizontal: compactTabs ? 4 : 8,
                ),
                tabs: [
                  _energyTab(
                    icon: Icons.electrical_services,
                    label: 'Grid',
                    compact: compactTabs,
                  ),
                  _energyTab(
                    icon: Icons.sunny,
                    label: 'Solar',
                    compact: compactTabs,
                  ),
                  _energyTab(
                    icon: Icons.battery_full,
                    label: 'Battery',
                    compact: compactTabs,
                  ),
                ],
              );
            }),

            const SizedBox(height: 12),

            // Tab Content
            SizedBox(
                height: 312,
                child: TabBarView(
                  children: [
                    SingleChildScrollView(child: _tabCardContentGrid(isDark)),
                    SingleChildScrollView(child: _tabCardContentSolar(isDark)),
                    SingleChildScrollView(
                        child: _tabCardContentBattery(isDark)),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _energyTab({
    required IconData icon,
    required String label,
    required bool compact,
  }) {
    if (compact) {
      return Tab(
        icon: Tooltip(
          message: label,
          child: Icon(icon, size: 20),
        ),
      );
    }

    return Tab(
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabCardContentGrid(bool isDark) {
    final textColor = isDark ? Colors.white70 : Colors.black87;

    final parameters = [
      {
        "icon": Icons.receipt_long,
        "label": "Bill",
        "value": "GHS 120.45",
      },
      {
        "icon": Icons.flash_on,
        "label": "Voltage",
        "value": "220 V",
      },
      {
        "icon": Icons.electrical_services,
        "label": "Current",
        "value": "10 A",
      },
      {
        "icon": Icons.bolt,
        "label": "Power",
        "value": "2.2 kW",
      },
      {
        "icon": Icons.energy_savings_leaf,
        "label": "Energy",
        "value": "15 kWh",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            "Grid Supply",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        ...parameters.map((param) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(param["icon"] as IconData,
                      size: 20,
                      color: isDark ? Colors.greenAccent : Colors.green),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      param["label"] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    param["value"] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _tabCardContentSolar(bool isDark) {
    final textColor = isDark ? Colors.white70 : Colors.black87;

    final parameters = [
      {
        "icon": Icons.attach_money,
        "label": "Money Saved",
        "value": "₵156.00",
      },
      {
        "icon": Icons.flash_on,
        "label": "Voltage",
        "value": "48 V",
      },
      {
        "icon": Icons.electrical_services,
        "label": "Current",
        "value": "15 A",
      },
      {
        "icon": Icons.bolt,
        "label": "Power",
        "value": "720 W",
      },
      {
        "icon": Icons.energy_savings_leaf,
        "label": "Energy",
        "value": "12.4 kWh",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8.0),
          child: Text(
            "Solar Supply",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        ...parameters.map((param) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(param["icon"] as IconData,
                      size: 20,
                      color: isDark ? Colors.orangeAccent : Colors.orange),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      param["label"] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    param["value"] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _tabCardContentBattery(bool isDark) {
    final textColor = isDark ? Colors.white70 : Colors.black87;

    final parameters = [
      {
        "icon": Icons.flash_on,
        "label": "Voltage",
        "value": "24 V",
      },
      {
        "icon": Icons.battery_charging_full,
        "label": "Current",
        "value": "10 A",
      },
      {
        "icon": Icons.bolt,
        "label": "Power",
        "value": "240 W",
      },
      {
        "icon": Icons.battery_full,
        "label": "Charge Level",
        "value": "85%",
      },
      {
        "icon": Icons.health_and_safety,
        "label": "Health",
        "value": "Good",
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 12.0),
          child: Text(
            "Battery Supply",
            style: GoogleFonts.poppins(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
        ),
        ...parameters.map((param) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: isDark ? Colors.grey[850] : Colors.grey[100],
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Icon(param["icon"] as IconData,
                      size: 20,
                      color: isDark ? Colors.cyanAccent : Colors.cyan[700]),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      param["label"] as String,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        color: textColor,
                      ),
                    ),
                  ),
                  Text(
                    param["value"] as String,
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}
