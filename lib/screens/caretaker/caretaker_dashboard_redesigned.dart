import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';
import '../../core/widgets/caretaker_sidebar.dart';
import '../../core/widgets/caretaker_header.dart';
import '../../core/widgets/weather_time_widget.dart';
import '../../core/widgets/weather_info_chip.dart';
import '../../data/mock_farm_data.dart';
import '../../widgets/alert_summary_card.dart';
import '../../providers/auth_provider.dart';
import 'widgets/sensor_overview_panel.dart';

/// Caretaker Dashboard – Professional Redesign
class CaretakerDashboardRedesigned extends ConsumerStatefulWidget {
  const CaretakerDashboardRedesigned({super.key});

  @override
  ConsumerState<CaretakerDashboardRedesigned> createState() =>
      _CaretakerDashboardRedesignedState();
}

class _CaretakerDashboardRedesignedState
    extends ConsumerState<CaretakerDashboardRedesigned> {
  int _selectedNavIndex = 0;
  WeatherInfo? _weatherInfo;

  @override
  void initState() {
    super.initState();
    _weatherInfo = const WeatherInfo(condition: 'Sunny', temperature: 28.5);
  }

  // ─── build ────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final auth = ref.watch(authProvider);
    final userName = auth.user?.name ?? 'Caretaker';
    final userEmail = auth.user?.email ?? 'caretaker@farmestates.com';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _mobileShell(isDark, userName)
          : _desktopShell(isDark, userName, userEmail),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => Navigator.pushNamed(context, '/record-entry'),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_rounded, size: 20),
        label: Text(isMobile ? 'Record' : 'New Record',
            style:
                GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13)),
      ),
      bottomNavigationBar: isMobile ? _bottomNav(isDark) : null,
    );
  }

  // ─── desktop shell ────────────────────────────────────────────────────────

  Widget _desktopShell(bool isDark, String userName, String userEmail) {
    return Row(children: [
      CaretakerSidebar(
        selectedIndex: _selectedNavIndex,
        onItemSelected: (i) => setState(() => _selectedNavIndex = i),
        userName: userName,
        userEmail: userEmail,
        userRole: 'Caretaker',
      ),
      Expanded(
        child: Column(children: [
          CaretakerHeader(
              userName: userName,
              weatherInfo: _weatherInfo,
              onNotificationTap: () {}),
          Expanded(
            child: LayoutBuilder(builder: (context, box) {
              final narrow = box.maxWidth < 700;
              return SingleChildScrollView(
                padding: EdgeInsets.all(narrow ? 16 : 24),
                child: _dashboardContent(isDark, narrow: narrow),
              );
            }),
          ),
        ]),
      ),
    ]);
  }

  // ─── mobile shell ─────────────────────────────────────────────────────────

  Widget _mobileShell(bool isDark, String userName) {
    return Column(children: [
      CaretakerHeader(
          userName: userName,
          weatherInfo: _weatherInfo,
          onNotificationTap: () {}),
      Expanded(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          child: _dashboardContent(isDark, narrow: true),
        ),
      ),
    ]);
  }

  // ─── shared dashboard content ─────────────────────────────────────────────

  Widget _dashboardContent(bool isDark, {required bool narrow}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── top: weather + alerts ──
        if (narrow) ...[
          const AlertSummaryCard(showRecentAlerts: true, maxRecentAlerts: 2),
          const SizedBox(height: 12),
          const WeatherTimeWidget(),
        ] else
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: const [
            Expanded(
                flex: 2,
                child: AlertSummaryCard(
                    showRecentAlerts: true, maxRecentAlerts: 2)),
            SizedBox(width: 16),
            Expanded(flex: 1, child: WeatherTimeWidget()),
          ]),

        const SizedBox(height: 20),

        // ── KPI cards ──
        _kpiSection(isDark),

        const SizedBox(height: 24),

        // ── sensor overview ──
        SensorOverviewPanel(
          sensorData: MockFarmData.getSensorData(),
          onViewAllTap: () {},
        ),

        const SizedBox(height: 24),

        // ── quick actions ──
        _sectionTitle(isDark, 'Quick Actions', Icons.grid_view_rounded),
        const SizedBox(height: 12),
        _quickActions(isDark),
      ],
    );
  }

  // ─── KPI section ──────────────────────────────────────────────────────────

  Widget _kpiSection(bool isDark) {
    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final cols = w > 700 ? 4 : 2;
      final gap = w < 400 ? 8.0 : 10.0;
      final cardW = (w - (cols - 1) * gap) / cols;
      final ratio = cardW < 155 ? 2.2 : (cardW < 200 ? 2.6 : 3.0);

      return GridView.count(
        crossAxisCount: cols,
        childAspectRatio: ratio,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: [
          _kpiCard(
              isDark, 'Tasks', '5/8', Icons.task_alt_rounded, AppColors.primary,
              sub: 'completed'),
          _kpiCard(
              isDark, 'Plants', '120', Icons.eco_rounded, AppColors.success,
              sub: 'monitored'),
          _kpiCard(isDark, 'Harvest', '85 kg', Icons.agriculture_rounded,
              AppColors.warning,
              sub: 'ready'),
          _kpiCard(isDark, 'Inputs', '\$450', Icons.inventory_2_rounded,
              AppColors.info,
              sub: 'used today'),
        ],
      );
    });
  }

  Widget _kpiCard(
      bool isDark, String title, String value, IconData icon, Color color,
      {String? sub}) {
    return LayoutBuilder(builder: (context, box) {
      final compact = box.maxWidth < 155;

      return Container(
        padding: EdgeInsets.symmetric(
            horizontal: compact ? 10 : 14, vertical: compact ? 8 : 10),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: color.withOpacity(isDark ? 0.15 : 0.12),
          ),
          boxShadow: isDark
              ? null
              : [
                  BoxShadow(
                      color: color.withOpacity(0.06),
                      blurRadius: 12,
                      offset: const Offset(0, 3)),
                ],
        ),
        child: Row(children: [
          Container(
            padding: EdgeInsets.all(compact ? 6 : 8),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, size: compact ? 16 : 18, color: color),
          ),
          SizedBox(width: compact ? 8 : 10),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 16 : 18,
                      fontWeight: FontWeight.w700,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                      height: 1.1,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(sub ?? title,
                    style: GoogleFonts.inter(
                      fontSize: compact ? 10 : 11,
                      color: isDark ? Colors.white38 : AppColors.textSecondary,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
              ],
            ),
          ),
        ]),
      );
    });
  }

  // ─── quick actions ────────────────────────────────────────────────────────

  Widget _quickActions(bool isDark) {
    final actions = <_QA>[
      _QA('Record Entry', Icons.edit_note_rounded, AppColors.primary,
          '8 pending', () => Navigator.pushNamed(context, '/record-entry')),
      _QA('Confirm Inputs', Icons.check_circle_outline_rounded,
          AppColors.success, '3 awaiting', () {}),
      _QA('Calendar', Icons.calendar_month_rounded, AppColors.info,
          'View schedule', () {}),
      _QA('Chat', Icons.forum_rounded, AppColors.warning, 'Get help', () {}),
      _QA('Records', Icons.history_rounded, const Color(0xFF7E57C2),
          'Past entries', () {}),
      _QA('Settings', Icons.tune_rounded, AppColors.neutral600, 'Preferences',
          () {}),
    ];

    return LayoutBuilder(builder: (context, box) {
      final w = box.maxWidth;
      final cols =
          w > 1350 ? 6 : (w > 1024 ? 5 : (w > 780 ? 4 : (w > 400 ? 3 : 2)));
      final gap = w < 400 ? 8.0 : 10.0;
      final cardW = (w - (cols - 1) * gap) / cols;
      final isDesktop = w > 780;
      final ratio = isDesktop
          ? (cardW < 170 ? 1.35 : 1.55)
          : (cardW < 120 ? 0.9 : (cardW < 155 ? 1.0 : 1.15));

      return GridView.count(
        crossAxisCount: cols,
        childAspectRatio: ratio,
        crossAxisSpacing: gap,
        mainAxisSpacing: gap,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: actions.map((a) => _actionCard(isDark, a, cardW)).toList(),
      );
    });
  }

  Widget _actionCard(bool isDark, _QA a, double cardW) {
    final compact = cardW < 140;
    final denseDesktop = cardW >= 165;

    return Material(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: a.onTap,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark
                  ? Colors.white.withOpacity(0.06)
                  : Colors.black.withOpacity(0.05),
            ),
          ),
          padding: EdgeInsets.all(denseDesktop ? 10 : (compact ? 10 : 14)),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(denseDesktop ? 8 : (compact ? 10 : 12)),
                decoration: BoxDecoration(
                  color: a.color.withOpacity(0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  a.icon,
                  size: denseDesktop ? 20 : (compact ? 22 : 26),
                  color: a.color,
                ),
              ),
              SizedBox(height: denseDesktop ? 6 : (compact ? 8 : 10)),
              Text(a.title,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: denseDesktop ? 12 : (compact ? 12 : 13),
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  )),
              const SizedBox(height: 2),
              Text(a.sub,
                  textAlign: TextAlign.center,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: denseDesktop ? 10 : (compact ? 10 : 11),
                    color: isDark ? Colors.white38 : AppColors.textSecondary,
                  )),
            ],
          ),
        ),
      ),
    );
  }

  // ─── section title ────────────────────────────────────────────────────────

  Widget _sectionTitle(bool isDark, String text, IconData icon) {
    return Row(children: [
      Icon(icon,
          size: 18, color: isDark ? Colors.white54 : AppColors.textSecondary),
      const SizedBox(width: 8),
      Text(text,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.2,
            color: isDark ? Colors.white : AppColors.textPrimary,
          )),
    ]);
  }

  // ─── bottom nav ───────────────────────────────────────────────────────────

  Widget _bottomNav(bool isDark) {
    const items = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Home',
        'route': '/caretaker_dashboard'
      },
      {
        'icon': Icons.edit_note_outlined,
        'label': 'Record',
        'route': '/record-entry'
      },
      {
        'icon': Icons.check_circle_outline,
        'label': 'Confirm',
        'route': '/input-confirmation'
      },
      {'icon': Icons.forum_outlined, 'label': 'Chat', 'route': '/chat'},
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Calendar',
        'route': '/calendar'
      },
    ];

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        border: Border(
            top: BorderSide(
                color: isDark
                    ? Colors.white.withOpacity(0.06)
                    : Colors.black.withOpacity(0.06))),
        boxShadow: [
          if (!isDark)
            BoxShadow(
                color: Colors.black.withOpacity(0.06),
                blurRadius: 10,
                offset: const Offset(0, -3)),
        ],
      ),
      child: SafeArea(
        child: SizedBox(
          height: 62,
          child: Row(
            children: items.asMap().entries.map((e) {
              final i = e.key;
              final m = e.value;
              final sel = i == _selectedNavIndex;
              final c = sel
                  ? AppColors.primary
                  : (isDark ? Colors.white38 : AppColors.textSecondary);

              return Expanded(
                child: InkWell(
                  onTap: () {
                    if (i != _selectedNavIndex) {
                      setState(() => _selectedNavIndex = i);
                      try {
                        Navigator.pushReplacementNamed(
                            context, m['route'] as String);
                      } catch (_) {
                        try {
                          Navigator.pushNamed(context, m['route'] as String);
                        } catch (_) {}
                      }
                    }
                  },
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(m['icon'] as IconData, size: 22, color: c),
                      const SizedBox(height: 3),
                      Text(m['label'] as String,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: sel ? FontWeight.w600 : FontWeight.w500,
                            color: c,
                          )),
                      if (sel)
                        Container(
                          margin: const EdgeInsets.only(top: 3),
                          width: 16,
                          height: 2.5,
                          decoration: BoxDecoration(
                            color: AppColors.primary,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        ),
                    ],
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

// ─── Quick Action model ─────────────────────────────────────────────────────

class _QA {
  final String title;
  final IconData icon;
  final Color color;
  final String sub;
  final VoidCallback onTap;
  const _QA(this.title, this.icon, this.color, this.sub, this.onTap);
}
