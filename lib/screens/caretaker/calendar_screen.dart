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

  Color _inactiveNavColor(bool isDark) {
    return isDark
        ? AppColors.textOnDark.withOpacity(0.75)
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
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 2,
                        child: _buildCalendar(isDark),
                      ),
                      const SizedBox(width: AppSpacing.lg),
                      Expanded(
                        flex: 1,
                        child: _buildEventsList(isDark),
                      ),
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
        CaretakerHeader(
          userName: userName,
          onNotificationTap: () {},
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildCalendar(isDark),
                const SizedBox(height: AppSpacing.lg),
                _buildEventsList(isDark),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCalendar(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Calendar Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                DateFormat('MMMM yyyy').format(_focusedDate),
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  fontSize: isMobile ? 18 : 20,
                  color: _primaryTextColor(isDark),
                ),
              ),
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.chevron_left,
                      color: _primaryTextColor(isDark),
                    ),
                    onPressed: () {
                      setState(() {
                        _focusedDate =
                            DateTime(_focusedDate.year, _focusedDate.month - 1);
                      });
                    },
                  ),
                  TextButton(
                    style: TextButton.styleFrom(
                      foregroundColor: _primaryTextColor(isDark),
                    ),
                    onPressed: () {
                      setState(() {
                        _focusedDate = DateTime.now();
                        _selectedDate = DateTime.now();
                      });
                    },
                    child: Text(
                      'Today',
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w600,
                        color: _primaryTextColor(isDark),
                      ),
                    ),
                  ),
                  IconButton(
                    icon: Icon(
                      Icons.chevron_right,
                      color: _primaryTextColor(isDark),
                    ),
                    onPressed: () {
                      setState(() {
                        _focusedDate =
                            DateTime(_focusedDate.year, _focusedDate.month + 1);
                      });
                    },
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          // Calendar Grid
          _buildCalendarGrid(isDark),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(bool isDark) {
    final firstDayOfMonth = DateTime(_focusedDate.year, _focusedDate.month, 1);
    final lastDayOfMonth =
        DateTime(_focusedDate.year, _focusedDate.month + 1, 0);
    final firstDayWeekday = firstDayOfMonth.weekday;
    final daysInMonth = lastDayOfMonth.day;

    final weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Column(
      children: [
        // Weekday Headers
        Row(
          children: weekdays.map((day) {
            return Expanded(
              child: Center(
                child: Text(
                  day,
                  style: AppTypography.caption.copyWith(
                    fontWeight: FontWeight.w600,
                    fontSize: isMobile ? 11 : 12,
                    color: _primaryTextColor(isDark),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Calendar Days
        ...List.generate(6, (weekIndex) {
          return Row(
            children: List.generate(7, (dayIndex) {
              final dayNumber =
                  (weekIndex * 7) + dayIndex - firstDayWeekday + 2;
              final isCurrentMonth = dayNumber > 0 && dayNumber <= daysInMonth;
              final dayDate = isCurrentMonth
                  ? DateTime(_focusedDate.year, _focusedDate.month, dayNumber)
                  : null;
              final isSelected = dayDate != null &&
                  dayDate.year == _selectedDate.year &&
                  dayDate.month == _selectedDate.month &&
                  dayDate.day == _selectedDate.day;
              final isToday = dayDate != null &&
                  dayDate.year == DateTime.now().year &&
                  dayDate.month == DateTime.now().month &&
                  dayDate.day == DateTime.now().day;
              final hasEvent = dayDate != null &&
                  _events.any((event) {
                    final eventDate = event['date'] as DateTime;
                    return eventDate.year == dayDate.year &&
                        eventDate.month == dayDate.month &&
                        eventDate.day == dayDate.day;
                  });

              return Expanded(
                child: GestureDetector(
                  onTap: isCurrentMonth
                      ? () {
                          setState(() => _selectedDate = dayDate!);
                        }
                      : null,
                  child: Container(
                    margin: const EdgeInsets.all(2),
                    height: isMobile ? 40 : 50,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : (isToday
                              ? AppColors.primary.withOpacity(0.1)
                              : Colors.transparent),
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      border: isToday && !isSelected
                          ? Border.all(color: AppColors.primary, width: 2)
                          : null,
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          isCurrentMonth ? dayNumber.toString() : '',
                          style: AppTypography.bodySmall.copyWith(
                            color: isSelected
                                ? Colors.white
                                : (isDark
                                    ? Colors.white
                                    : AppColors.textPrimary),
                            fontWeight: isSelected || isToday
                                ? FontWeight.bold
                                : FontWeight.normal,
                            fontSize: isMobile ? 12 : 14,
                          ),
                        ),
                        if (hasEvent)
                          Container(
                            width: 4,
                            height: 4,
                            margin: const EdgeInsets.only(top: 2),
                            decoration: const BoxDecoration(
                              color: AppColors.warning,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          );
        }),
      ],
    );
  }

  Widget _buildEventsList(bool isDark) {
    final selectedDateEvents = _events.where((event) {
      final eventDate = event['date'] as DateTime;
      return eventDate.year == _selectedDate.year &&
          eventDate.month == _selectedDate.month &&
          eventDate.day == _selectedDate.day;
    }).toList();

    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Events - ${DateFormat('MMM d, yyyy').format(_selectedDate)}',
            style: AppTypography.h5.copyWith(
              fontWeight: FontWeight.bold,
              fontSize: isMobile ? 16 : 18,
              color: _primaryTextColor(isDark),
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          if (selectedDateEvents.isEmpty)
            Padding(
              padding: const EdgeInsets.all(AppSpacing.lg),
              child: Center(
                child: Text(
                  'No events scheduled',
                  style: AppTypography.bodyMedium.copyWith(
                    color: _secondaryTextColor(isDark),
                  ),
                ),
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: selectedDateEvents.length,
              itemBuilder: (context, index) {
                final event = selectedDateEvents[index];
                final color = event['color'] as Color;

                return Container(
                  margin: const EdgeInsets.only(bottom: AppSpacing.sm),
                  padding:
                      EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                    border: Border.all(
                      color: color.withOpacity(0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 4,
                        height: 40,
                        decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                      const SizedBox(width: AppSpacing.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              event['title'] as String,
                              style: AppTypography.bodyMedium.copyWith(
                                fontWeight: FontWeight.w600,
                                color: isDark
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontSize: isMobile ? 13 : 14,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              event['time'] as String,
                              style: AppTypography.caption.copyWith(
                                color: _secondaryTextColor(isDark),
                                fontSize: isMobile ? 11 : 12,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
    );
  }

  Widget _buildBottomNavigation(bool isDark) {
    final navItems = [
      {
        'icon': Icons.dashboard_outlined,
        'label': 'Dashboard',
        'index': 0,
        'route': '/caretaker_dashboard'
      },
      {
        'icon': Icons.edit_note_outlined,
        'label': 'Record',
        'index': 1,
        'route': '/record-entry'
      },
      {
        'icon': Icons.check_circle_outline,
        'label': 'Confirm',
        'index': 2,
        'route': '/input-confirmation'
      },
      {
        'icon': Icons.chat_bubble_outline,
        'label': 'Chat',
        'index': 3,
        'route': '/chat'
      },
      {
        'icon': Icons.calendar_today_outlined,
        'label': 'Calendar',
        'index': 4,
        'route': '/calendar'
      },
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
            color: isDark
                ? Colors.white.withOpacity(0.08)
                : Colors.black.withOpacity(0.08),
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
                              : _inactiveNavColor(isDark),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item['label'] as String,
                          style: AppTypography.caption.copyWith(
                            color: isSelected
                                ? AppColors.primary
                                : _inactiveNavColor(isDark),
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
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
