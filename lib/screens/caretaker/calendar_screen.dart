import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/caretaker_sidebar.dart';
import '../../core/widgets/caretaker_header.dart';
import '../../core/widgets/caretaker_mobile_bottom_nav.dart';
import '../../providers/auth_provider.dart';

/// Calendar Screen for Caretaker
/// View tasks, schedules, and events
class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  int _selectedNavIndex = 4;
  DateTime _selectedDate = DateTime.now();
  DateTime _focusedDate = DateTime.now();

  final List<Map<String, dynamic>> _events = [
    {
      'id': 'EVT001',
      'title': 'Watering Schedule',
      'date': DateTime.now(),
      'time': '08:00 AM',
      'type': 'task',
      'color': AppColors.info,
    },
    {
      'id': 'EVT002',
      'title': 'Nutrient Check',
      'date': DateTime.now().add(const Duration(days: 1)),
      'time': '10:00 AM',
      'type': 'task',
      'color': AppColors.warning,
    },
    {
      'id': 'EVT003',
      'title': 'Harvest Day',
      'date': DateTime.now().add(const Duration(days: 3)),
      'time': '09:00 AM',
      'type': 'event',
      'color': AppColors.success,
    },
    {
      'id': 'EVT004',
      'title': 'Farm Inspection',
      'date': DateTime.now().add(const Duration(days: 5)),
      'time': '02:00 PM',
      'type': 'meeting',
      'color': AppColors.primary,
    },
  ];

  Color _primaryTextColor(bool isDark) {
    return isDark ? Colors.white : AppColors.textPrimary;
  }

  Color _secondaryTextColor(bool isDark) {
    return isDark
        ? AppColors.textOnDark.withOpacity(0.82)
        : AppColors.textSecondary;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Caretaker';
    final userEmail = authState.user?.email ?? 'caretaker@farmestates.com';
    final userRole = 'Caretaker';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: isMobile
          ? CaretakerMobileDrawer(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
              userName: userName,
              userEmail: userEmail,
            )
          : null,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail, userRole),
      bottomNavigationBar: isMobile
          ? CaretakerMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(
      bool isDark, String userName, String userEmail, String userRole) {
    return Row(
      children: [
        CaretakerSidebar(
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
              CaretakerHeader(
                userName: userName,
                onNotificationTap: () {},
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildContent(isDark),
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
        CaretakerHeader(
          userName: userName,
          onNotificationTap: () {},
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: _buildContent(isDark),
          ),
        ),
      ],
    );
  }

  bool _sameDay(DateTime a, DateTime b) => DateUtils.isSameDay(a, b);

  void _changeMonth(int offset) => setState(() {
        _focusedDate = DateTime(_focusedDate.year, _focusedDate.month + offset);
        _selectedDate = _focusedDate;
      });

  Widget _buildContent(bool dark) =>
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Calendar',
                    style: AppTypography.h5.copyWith(
                        fontSize: AppTypography.pageTitleSize,
                        fontWeight: AppTypography.headingWeight,
                        color: _primaryTextColor(dark))),
                const SizedBox(height: 4),
                Text('Your tasks and farm schedule',
                    style: AppTypography.bodySmall
                        .copyWith(color: _secondaryTextColor(dark))),
              ])),
          OutlinedButton.icon(
              onPressed: () => setState(() {
                    _selectedDate = DateTime.now();
                    _focusedDate = _selectedDate;
                  }),
              icon: const Icon(Icons.today_outlined, size: 16),
              label: const Text('Today')),
        ]),
        const SizedBox(height: 16),
        LayoutBuilder(builder: (context, constraints) {
          if (constraints.maxWidth < 760)
            return Column(children: [
              _buildCalendar(dark),
              const SizedBox(height: 16),
              _buildEventsList(dark)
            ]);
          return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(flex: 3, child: _buildCalendar(dark)),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildEventsList(dark)),
          ]);
        }),
      ]);

  Widget _panel(bool dark, Widget child) => Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: dark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border:
              Border.all(color: dark ? Colors.white10 : AppColors.neutral200)),
      child: child);

  Widget _buildCalendar(bool dark) => _panel(
      dark,
      Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Expanded(
              child: Text(DateFormat('MMMM yyyy').format(_focusedDate),
                  style: AppTypography.bodyMedium.copyWith(
                      fontSize: AppTypography.cardTitleSize,
                      fontWeight: AppTypography.headingWeight,
                      color: _primaryTextColor(dark)))),
          IconButton(
              tooltip: 'Previous month',
              onPressed: () => _changeMonth(-1),
              icon: const Icon(Icons.chevron_left, size: 20)),
          IconButton(
              tooltip: 'Next month',
              onPressed: () => _changeMonth(1),
              icon: const Icon(Icons.chevron_right, size: 20)),
        ]),
        const SizedBox(height: 12),
        _buildCalendarGrid(dark),
        const SizedBox(height: 12),
        Wrap(spacing: 16, runSpacing: 8, children: [
          _legend('Today', AppColors.primary, dark, outlined: true),
          _legend('Scheduled', AppColors.warning, dark),
          _legend('Selected', AppColors.primary, dark),
        ]),
      ]));

  Widget _legend(String label, Color color, bool dark,
          {bool outlined = false}) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: outlined ? null : color,
                border: Border.all(color: color))),
        const SizedBox(width: 6),
        Text(label,
            style: AppTypography.caption
                .copyWith(fontSize: AppTypography.fieldLabelSize, color: _secondaryTextColor(dark))),
      ]);

  Widget _buildCalendarGrid(bool dark) {
    final first = DateTime(_focusedDate.year, _focusedDate.month);
    final days = DateTime(_focusedDate.year, _focusedDate.month + 1, 0).day;
    final offset = first.weekday - 1;
    final weeks = ((offset + days) / 7).ceil();
    return Column(children: [
      Row(
          children: ['M', 'T', 'W', 'T', 'F', 'S', 'S']
              .map((day) => Expanded(
                  child: Center(
                      child: Text(day,
                          style: AppTypography.caption.copyWith(
                              fontSize: AppTypography.fieldLabelSize,
                              fontWeight: AppTypography.headingWeight,
                              color: _secondaryTextColor(dark))))))
              .toList()),
      const SizedBox(height: 8),
      ...List.generate(
          weeks,
          (week) => Row(
                  children: List.generate(7, (column) {
                final day = week * 7 + column - offset + 1;
                if (day < 1 || day > days)
                  return const Expanded(child: SizedBox(height: 48));
                final date = DateTime(first.year, first.month, day);
                final selected = _sameDay(date, _selectedDate);
                final today = _sameDay(date, DateTime.now());
                final count = _events
                    .where((event) => _sameDay(event['date'] as DateTime, date))
                    .length;
                return Expanded(
                    child: Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 1, vertical: 3),
                        child: Semantics(
                            selected: selected,
                            button: true,
                            label:
                                '${DateFormat.yMMMMEEEEd().format(date)}, $count scheduled',
                            child: InkWell(
                                onTap: () =>
                                    setState(() => _selectedDate = date),
                                borderRadius: BorderRadius.circular(10),
                                child: Ink(
                                    height: 42,
                                    decoration: BoxDecoration(
                                        color: selected
                                            ? AppColors.primary
                                            : today
                                                ? AppColors.primary
                                                    .withValues(alpha: .06)
                                                : Colors.transparent,
                                        borderRadius: BorderRadius.circular(10),
                                        border: today && !selected
                                            ? Border.all(
                                                color: AppColors.primary)
                                            : null),
                                    child: Column(
                                        mainAxisAlignment:
                                            MainAxisAlignment.center,
                                        children: [
                                          Text('$day',
                                              textScaler:
                                                  const TextScaler.linear(1),
                                              style: AppTypography.bodySmall
                                                  .copyWith(
                                                      fontSize: AppTypography.actionSize,
                                                      fontWeight:
                                                          selected || today
                                                              ? AppTypography.headingWeight
                                                              : AppTypography.bodyWeight,
                                                      color: selected
                                                          ? Colors.white
                                                          : _primaryTextColor(
                                                              dark))),
                                          const SizedBox(height: 3),
                                          Container(
                                              width: 4,
                                              height: 4,
                                              decoration: BoxDecoration(
                                                  shape: BoxShape.circle,
                                                  color: count == 0
                                                      ? Colors.transparent
                                                      : selected
                                                          ? Colors.white
                                                          : AppColors.warning)),
                                        ]))))));
              }))),
    ]);
  }

  Widget _buildEventsList(bool dark) {
    final events = _events
        .where((event) => _sameDay(event['date'] as DateTime, _selectedDate))
        .toList();
    return _panel(
        dark,
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(DateFormat('EEEE, d MMMM').format(_selectedDate),
              style: AppTypography.bodyMedium.copyWith(
                  fontSize: AppTypography.cardTitleSize,
                  fontWeight: AppTypography.headingWeight,
                  color: _primaryTextColor(dark))),
          const SizedBox(height: 5),
          Text('${events.length} scheduled · Preview events',
              style: AppTypography.caption
                  .copyWith(color: _secondaryTextColor(dark))),
          const SizedBox(height: 16),
          if (events.isEmpty)
            Container(
                width: double.infinity,
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: .04),
                    borderRadius: BorderRadius.circular(12)),
                child: Column(children: [
                  const Icon(Icons.event_available_outlined,
                      color: AppColors.primary, size: 28),
                  const SizedBox(height: 12),
                  Text('A clear day',
                      style: AppTypography.bodyMedium.copyWith(
                          fontWeight: AppTypography.headingWeight,
                          color: _primaryTextColor(dark))),
                  const SizedBox(height: 5),
                  Text('No events scheduled for this date.',
                      textAlign: TextAlign.center,
                      style: AppTypography.bodySmall
                          .copyWith(color: _secondaryTextColor(dark)))
                ])),
          ...events.map((event) {
            final color = event['color'] as Color;
            final type = event['type'] as String;
            final icon = type == 'meeting'
                ? Icons.groups_outlined
                : type == 'event'
                    ? Icons.eco_outlined
                    : Icons.task_alt;
            return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: dark ? Colors.white10 : AppColors.neutral200)),
                child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                              color: color.withValues(alpha: .1),
                              borderRadius: BorderRadius.circular(10)),
                          child: Icon(icon, size: 18, color: color)),
                      const SizedBox(width: 12),
                      Expanded(
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                            Text(event['title'] as String,
                                style: AppTypography.bodyMedium.copyWith(
                                    fontSize: AppTypography.actionSize,
                                    fontWeight: AppTypography.headingWeight,
                                    color: _primaryTextColor(dark))),
                            const SizedBox(height: 7),
                            Wrap(spacing: 8, runSpacing: 5, children: [
                              Text(event['time'] as String,
                                  style: AppTypography.caption.copyWith(
                                      color: _secondaryTextColor(dark))),
                              Text(type[0].toUpperCase() + type.substring(1),
                                  style: AppTypography.caption.copyWith(
                                      color: color,
                                      fontWeight: AppTypography.headingWeight)),
                            ]),
                          ])),
                    ]));
          }),
        ]));
  }
}
