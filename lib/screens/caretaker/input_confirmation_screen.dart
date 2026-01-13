import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/caretaker_sidebar.dart';
import '../../core/widgets/caretaker_header.dart';
import '../../providers/auth_provider.dart';

/// Input Confirmation Screen for Caretaker
/// Confirm receipt and usage of farm inputs
class InputConfirmationScreen extends ConsumerStatefulWidget {
  const InputConfirmationScreen({super.key});

  @override
  ConsumerState<InputConfirmationScreen> createState() => _InputConfirmationScreenState();
}

class _InputConfirmationScreenState extends ConsumerState<InputConfirmationScreen> {
  int _selectedNavIndex = 2;
  String _selectedFilter = 'All';
  String _selectedStatus = 'Pending';

  final List<Map<String, dynamic>> _inputRequests = [
    {
      'id': 'INP001',
      'item': 'Organic Fertilizer',
      'quantity': '50 kg',
      'requestedBy': 'Farm Manager',
      'requestDate': '2024-01-10',
      'status': 'Pending',
      'icon': Icons.eco,
      'color': AppColors.success,
    },
    {
      'id': 'INP002',
      'item': 'pH Adjuster',
      'quantity': '10 L',
      'requestedBy': 'Farm Manager',
      'requestDate': '2024-01-12',
      'status': 'Received',
      'icon': Icons.science,
      'color': AppColors.info,
    },
    {
      'id': 'INP003',
      'item': 'Seeds - Lettuce',
      'quantity': '500 pcs',
      'requestedBy': 'Farm Manager',
      'requestDate': '2024-01-08',
      'status': 'Confirmed',
      'icon': Icons.agriculture,
      'color': AppColors.primary,
    },
    {
      'id': 'INP004',
      'item': 'Nutrient Solution',
      'quantity': '25 L',
      'requestedBy': 'Farm Manager',
      'requestDate': '2024-01-15',
      'status': 'Pending',
      'icon': Icons.water_drop,
      'color': AppColors.warning,
    },
  ];

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
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildFilters(isDark),
                      const SizedBox(height: AppSpacing.lg),
                      _buildInputRequestsList(isDark),
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
                _buildHeader(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildFilters(isDark),
                const SizedBox(height: AppSpacing.md),
                _buildInputRequestsList(isDark),
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
        Text(
          'Input Confirmation',
          style: AppTypography.h4.copyWith(
            fontWeight: FontWeight.bold,
            fontSize: isMobile ? 20 : 24,
          ),
        ),
        if (!isMobile)
          ElevatedButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.add),
            label: const Text('New Confirmation'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
      ],
    );
  }

  Widget _buildFilters(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    if (isMobile) {
      return Column(
        children: [
          _buildFilterDropdown('Status', _selectedStatus, ['All', 'Pending', 'Received', 'Confirmed'], (value) {
            setState(() => _selectedStatus = value!);
          }, isDark),
          const SizedBox(height: AppSpacing.sm),
          _buildFilterDropdown('Filter', _selectedFilter, ['All', 'Today', 'This Week', 'This Month'], (value) {
            setState(() => _selectedFilter = value!);
          }, isDark),
        ],
      );
    }

    return Row(
      children: [
        Expanded(
          child: _buildFilterDropdown('Status', _selectedStatus, ['All', 'Pending', 'Received', 'Confirmed'], (value) {
            setState(() => _selectedStatus = value!);
          }, isDark),
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: _buildFilterDropdown('Filter', _selectedFilter, ['All', 'Today', 'This Week', 'This Month'], (value) {
            setState(() => _selectedFilter = value!);
          }, isDark),
        ),
      ],
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items, ValueChanged<String?> onChanged, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
        ),
      ),
      child: DropdownButton<String>(
        value: value,
        isExpanded: true,
        underline: const SizedBox(),
        items: items.map((item) {
          return DropdownMenuItem(
            value: item,
            child: Text(item),
          );
        }).toList(),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildInputRequestsList(bool isDark) {
    final filteredRequests = _inputRequests.where((request) {
      if (_selectedStatus != 'All' && request['status'] != _selectedStatus) {
        return false;
      }
      return true;
    }).toList();

    if (filteredRequests.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Text(
            'No input requests found',
            style: AppTypography.bodyLarge.copyWith(
              color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
            ),
          ),
        ),
      );
    }

    return Column(
      children: filteredRequests.map((request) {
        return _buildInputRequestCard(request, isDark);
      }).toList(),
    );
  }

  Widget _buildInputRequestCard(Map<String, dynamic> request, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final status = request['status'] as String;
    final color = request['color'] as Color;

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: EdgeInsets.all(isMobile ? AppSpacing.sm : AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.all(isMobile ? 8 : 12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            ),
            child: Icon(
              request['icon'] as IconData,
              color: color,
              size: isMobile ? 20 : 24,
            ),
          ),
          SizedBox(width: isMobile ? AppSpacing.sm : AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  request['item'] as String,
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                    fontSize: isMobile ? 13 : 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 3 : 4),
                Text(
                  '${request['quantity']} • Requested by ${request['requestedBy']}',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white.withOpacity(0.6) : AppColors.textSecondary,
                    fontSize: isMobile ? 11 : 12,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: isMobile ? 3 : 4),
                Text(
                  'Requested: ${request['requestDate']}',
                  style: AppTypography.caption.copyWith(
                    color: isDark ? Colors.white.withOpacity(0.5) : AppColors.textSecondary,
                    fontSize: isMobile ? 10 : 11,
                  ),
                ),
              ],
            ),
          ),
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: isMobile ? 6 : 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: _getStatusColor(status).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  status,
                  style: AppTypography.caption.copyWith(
                    color: _getStatusColor(status),
                    fontSize: isMobile ? 10 : 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              if (status == 'Pending') ...[
                SizedBox(height: isMobile ? 4 : 8),
                ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isMobile ? AppSpacing.xs : AppSpacing.sm,
                      vertical: isMobile ? 4 : 8,
                    ),
                    minimumSize: Size.zero,
                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                  ),
                  child: Text(
                    'Confirm',
                    style: TextStyle(fontSize: isMobile ? 11 : 12),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'Pending':
        return AppColors.warning;
      case 'Received':
        return AppColors.info;
      case 'Confirmed':
        return AppColors.success;
      default:
        return AppColors.textSecondary;
    }
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
                                : (isDark
                                    ? Colors.white.withOpacity(0.5)
                                    : AppColors.textSecondary),
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
