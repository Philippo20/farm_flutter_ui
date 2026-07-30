import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/caretaker_sidebar.dart';
import '../../core/widgets/caretaker_header.dart';
import '../../core/widgets/caretaker_mobile_bottom_nav.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

/// Input Confirmation Screen for Caretaker
/// Confirm receipt and usage of farm inputs
class InputConfirmationScreen extends ConsumerStatefulWidget {
  const InputConfirmationScreen({super.key});

  @override
  ConsumerState<InputConfirmationScreen> createState() =>
      _InputConfirmationScreenState();
}

class _InputConfirmationScreenState
    extends ConsumerState<InputConfirmationScreen> {
  int _selectedNavIndex = 2;
  String _selectedFilter = 'All';
  String _selectedStatus = 'All';
  bool _isLoading = true;
  String? _errorMessage;
  final SuperAdminApiService _api = SuperAdminApiService();
  final Set<String> _updatingIds = <String>{};

  final List<Map<String, dynamic>> _inputRequests = <Map<String, dynamic>>[];

  @override
  void initState() {
    super.initState();
    _loadInputRequests();
  }

  Future<void> _loadInputRequests() async {
    if (mounted) {
      setState(() {
        _isLoading = true;
        _errorMessage = null;
      });
    }
    try {
      final user = ref.read(authProvider).user;
      final documents = await _api.getInputConfirmations(caretakerId: user?.id);
      final mapped = documents.map(_mapInputRequest).toList();
      if (!mounted) return;
      setState(() {
        _inputRequests
          ..clear()
          ..addAll(mapped);
        _isLoading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _isLoading = false;
        _errorMessage = error.toString();
      });
    }
  }

  Map<String, dynamic> _mapInputRequest(Map<String, dynamic> document) {
    final item = (document['item'] ?? 'Farm input').toString();
    final status = (document['status'] ?? 'Pending').toString();
    final requestedAt = (document['requested_at'] ??
            document['created_at'] ??
            document[r'$createdAt'] ??
            '')
        .toString();
    return {
      'documentId': (document[r'$id'] ?? document['id'] ?? '').toString(),
      'id': (document['input_id'] ?? document[r'$id'] ?? '').toString(),
      'item': item,
      'quantity': (document['quantity'] ?? '').toString(),
      'requestedBy':
          (document['requested_by_name'] ?? 'Farm Manager').toString(),
      'requestDate': requestedAt,
      'status': status,
      'farmName': (document['farm_name'] ?? '').toString(),
      'icon': _inputIcon(item),
      'color': _getStatusColor(status),
    };
  }

  IconData _inputIcon(String item) {
    final value = item.toLowerCase();
    if (value.contains('seed')) return Icons.grass_rounded;
    if (value.contains('water') || value.contains('nutrient')) {
      return Icons.water_drop_rounded;
    }
    if (value.contains('fertil') || value.contains('compost')) {
      return Icons.eco_rounded;
    }
    if (value.contains('chemical') || value.contains('ph')) {
      return Icons.science_rounded;
    }
    return Icons.inventory_2_rounded;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Caretaker';
    final userEmail = authState.user?.email ?? 'caretaker@farmestates.com';

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      bottomNavigationBar: isMobile
          ? SafeArea(
              top: false,
              child: CaretakerMobileBottomNav(
                selectedIndex: _selectedNavIndex,
                onItemSelected: (index) =>
                    setState(() => _selectedNavIndex = index),
              ))
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        CaretakerSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Caretaker',
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
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 1080),
                    child: _buildContent(isDark, AppSpacing.lg),
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
            child: _buildContent(isDark, AppSpacing.md),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, double spacing) {
    if (_isLoading) {
      return const AdminDataSkeleton(rowCount: 4, showStats: true);
    }
    if (_errorMessage != null) {
      return _buildErrorState(isDark);
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildHeader(isDark),
        SizedBox(height: spacing),
        _buildFilters(isDark),
        SizedBox(height: spacing),
        _buildInputRequestsList(isDark),
      ],
    );
  }

  Widget _buildErrorState(bool isDark) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: Column(
        children: [
          Icon(Icons.cloud_off_rounded,
              size: 36,
              color: isDark ? Colors.white54 : AppColors.textSecondary),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Unable to load input confirmations',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            _errorMessage ?? 'Please try again.',
            textAlign: TextAlign.center,
            style: AppTypography.caption.copyWith(
              color: isDark ? Colors.white60 : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.md),
          ElevatedButton.icon(
            onPressed: _loadInputRequests,
            icon: const Icon(Icons.refresh_rounded, size: 18),
            label: const Text('Try again'),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    final pendingCount =
        _inputRequests.where((r) => r['status'] == 'Pending').length;
    final receivedCount =
        _inputRequests.where((r) => r['status'] == 'Received').length;
    final confirmedCount =
        _inputRequests.where((r) => r['status'] == 'Confirmed').length;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? const [Color(0xFF203024), Color(0xFF1A1A1A)]
              : const [Color(0xFFEFFAF1), Colors.white],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: AppColors.success.withOpacity(isDark ? 0.35 : 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: isDark ? Colors.white.withOpacity(0.08) : Colors.white,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
                  border: Border.all(
                    color: isDark ? Colors.white12 : AppColors.neutral200,
                  ),
                ),
                child: IconButton(
                  padding: EdgeInsets.zero,
                  icon: Icon(
                    Icons.arrow_back_rounded,
                    size: 20,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                  onPressed: _handleBack,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Input Confirmation',
                      style: AppTypography.h5.copyWith(
                        fontWeight: FontWeight.w700,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    Text(
                      'Review and confirm incoming farm inputs',
                      style: AppTypography.caption.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildSummaryChip('Pending', pendingCount.toString(),
                    AppColors.warning, isDark),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildSummaryChip('Received', receivedCount.toString(),
                    AppColors.info, isDark),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: _buildSummaryChip('Confirmed', confirmedCount.toString(),
                    AppColors.success, isDark),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryChip(
      String label, String value, Color color, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(isDark ? 0.2 : 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.35)),
      ),
      child: Row(
        children: [
          Icon(Icons.circle, size: 8, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: AppTypography.caption.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
      ),
      child: isMobile
          ? Column(
              children: [
                _buildFilterDropdown('Status', _selectedStatus,
                    ['All', 'Pending', 'Received', 'Confirmed'], (value) {
                  setState(() => _selectedStatus = value!);
                }, isDark),
                const SizedBox(height: AppSpacing.sm),
                _buildFilterDropdown('Date Filter', _selectedFilter,
                    ['All', 'Today', 'This Week', 'This Month'], (value) {
                  setState(() => _selectedFilter = value!);
                }, isDark),
              ],
            )
          : Row(
              children: [
                Expanded(
                  child: _buildFilterDropdown('Status', _selectedStatus,
                      ['All', 'Pending', 'Received', 'Confirmed'], (value) {
                    setState(() => _selectedStatus = value!);
                  }, isDark),
                ),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: _buildFilterDropdown('Date Filter', _selectedFilter,
                      ['All', 'Today', 'This Week', 'This Month'], (value) {
                    setState(() => _selectedFilter = value!);
                  }, isDark),
                ),
              ],
            ),
    );
  }

  Widget _buildFilterDropdown(String label, String value, List<String> items,
      ValueChanged<String?> onChanged, bool isDark) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        labelStyle: AppTypography.caption.copyWith(
          color: isDark ? Colors.white70 : AppColors.textSecondary,
        ),
        filled: true,
        fillColor: isDark ? const Color(0xFF222222) : AppColors.neutral50,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppColors.neutral300,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: isDark ? Colors.white12 : AppColors.neutral300,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: AppColors.primary.withOpacity(0.7),
            width: 1.3,
          ),
        ),
      ),
      style: AppTypography.bodySmall.copyWith(
        color: isDark ? Colors.white : AppColors.textPrimary,
      ),
      dropdownColor: isDark ? AppColors.surfaceDark : Colors.white,
      items: items
          .map((item) => DropdownMenuItem(value: item, child: Text(item)))
          .toList(),
      onChanged: onChanged,
    );
  }

  List<Map<String, dynamic>> _filteredRequests() {
    final latestDate = _inputRequests
        .map((r) => DateTime.tryParse(r['requestDate'] as String))
        .whereType<DateTime>()
        .fold<DateTime?>(
            null, (prev, d) => prev == null || d.isAfter(prev) ? d : prev);

    final referenceDate = latestDate ?? DateTime.now();

    return _inputRequests.where((request) {
      if (_selectedStatus != 'All' && request['status'] != _selectedStatus) {
        return false;
      }

      if (_selectedFilter == 'All') return true;

      final requestDate = DateTime.tryParse(request['requestDate'] as String);
      if (requestDate == null) return true;

      if (_selectedFilter == 'Today') {
        return requestDate.year == referenceDate.year &&
            requestDate.month == referenceDate.month &&
            requestDate.day == referenceDate.day;
      }
      if (_selectedFilter == 'This Week') {
        final diff = referenceDate.difference(requestDate).inDays;
        return diff >= 0 && diff <= 6;
      }
      if (_selectedFilter == 'This Month') {
        return requestDate.year == referenceDate.year &&
            requestDate.month == referenceDate.month;
      }
      return true;
    }).toList();
  }

  Widget _buildInputRequestsList(bool isDark) {
    final filteredRequests = _filteredRequests();

    if (filteredRequests.isEmpty) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(AppSpacing.xl),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          border: Border.all(
            color: isDark ? Colors.white10 : AppColors.neutral200,
          ),
        ),
        child: Column(
          children: [
            Icon(Icons.inbox_outlined,
                size: 30,
                color: isDark ? Colors.white38 : AppColors.textSecondary),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'No input requests found',
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w600,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: filteredRequests
          .map((request) => _buildInputRequestCard(request, isDark))
          .toList(),
    );
  }

  Widget _buildInputRequestCard(Map<String, dynamic> request, bool isDark) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final status = request['status'] as String;
    final color = request['color'] as Color;

    final info = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                request['item'] as String,
                style: AppTypography.bodyMedium.copyWith(
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            _buildStatusPill(status),
          ],
        ),
        const SizedBox(height: 6),
        Wrap(
          spacing: 8,
          runSpacing: 6,
          children: [
            _metaTag('ID: ${request['id']}', isDark),
            _metaTag('${request['quantity']}', isDark),
            _metaTag('Requested by ${request['requestedBy']}', isDark),
            _metaTag(request['requestDate'] as String, isDark),
          ],
        ),
      ],
    );

    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark ? Colors.white10 : AppColors.neutral200,
        ),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: isMobile ? 42 : 46,
                height: isMobile ? 42 : 46,
                decoration: BoxDecoration(
                  color: color.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  request['icon'] as IconData,
                  color: color,
                  size: isMobile ? 20 : 22,
                ),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(child: info),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _buildActionButtons(request, status, isDark),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildActionButtons(
      Map<String, dynamic> request, String status, bool isDark) {
    if (status == 'Confirmed') {
      return [
        TextButton.icon(
          onPressed: () {},
          icon: const Icon(Icons.visibility_outlined, size: 16),
          label: const Text('View'),
          style: TextButton.styleFrom(
            foregroundColor: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
        ),
      ];
    }

    if (status == 'Received') {
      return [
        ElevatedButton.icon(
          onPressed: _updatingIds.contains(_documentId(request))
              ? null
              : () => _updateRequestStatus(request, 'Confirmed'),
          icon: const Icon(Icons.check_circle_outline_rounded, size: 16),
          label: const Text('Confirm'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ];
    }

    return [
      OutlinedButton.icon(
        onPressed: _updatingIds.contains(_documentId(request))
            ? null
            : () => _updateRequestStatus(request, 'Received'),
        icon: const Icon(Icons.inventory_2_outlined, size: 16),
        label: const Text('Mark Received'),
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark ? Colors.white70 : AppColors.textPrimary,
          side: BorderSide(
            color: isDark ? Colors.white24 : AppColors.neutral300,
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
      ElevatedButton.icon(
        onPressed: _updatingIds.contains(_documentId(request))
            ? null
            : () => _updateRequestStatus(request, 'Confirmed'),
        icon: const Icon(Icons.check_rounded, size: 16),
        label: const Text('Confirm'),
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        ),
      ),
    ];
  }

  Widget _metaTag(String label, bool isDark) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: isDark ? Colors.white.withOpacity(0.06) : AppColors.neutral100,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: AppTypography.caption.copyWith(
          color: isDark ? Colors.white60 : AppColors.textSecondary,
        ),
      ),
    );
  }

  Widget _buildStatusPill(String status) {
    final color = _getStatusColor(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(AppSpacing.radiusFull),
        border: Border.all(color: color.withOpacity(0.4)),
      ),
      child: Text(
        status,
        style: AppTypography.caption.copyWith(
          color: color,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }

  String _documentId(Map<String, dynamic> request) =>
      (request['documentId'] ?? request['id'] ?? '').toString();

  Future<void> _updateRequestStatus(
      Map<String, dynamic> request, String newStatus) async {
    final id = _documentId(request);
    if (id.isEmpty || _updatingIds.contains(id)) return;
    final user = ref.read(authProvider).user;
    setState(() => _updatingIds.add(id));
    try {
      await _api.updateInputConfirmationStatus(
        id: id,
        status: newStatus,
        caretakerId: user?.id ?? '',
        caretakerName: user?.name ?? 'Caretaker',
      );
      final index =
          _inputRequests.indexWhere((item) => _documentId(item) == id);
      if (!mounted) return;
      if (index != -1) {
        setState(() {
          _inputRequests[index]['status'] = newStatus;
          _inputRequests[index]['color'] = _getStatusColor(newStatus);
        });
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Input marked $newStatus.')),
      );
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Unable to update input: $error')),
      );
    } finally {
      if (mounted) setState(() => _updatingIds.remove(id));
    }
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
    } else {
      Navigator.pushReplacementNamed(context, '/caretaker_dashboard');
    }
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
                        } catch (_) {
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
                              : (isDark
                                  ? Colors.white.withOpacity(0.5)
                                  : AppColors.textSecondary),
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
