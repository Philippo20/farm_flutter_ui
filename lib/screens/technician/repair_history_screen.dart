import 'dart:async';
import 'package:intl/intl.dart';
import '../../services/superadmin_api_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/technician_header.dart';
import '../../core/widgets/technician_mobile_bottom_nav.dart';
import '../../core/widgets/technician_sidebar.dart';
import '../../core/widgets/role_mobile_navigation.dart';
import '../../providers/auth_provider.dart';

class RepairHistoryScreen extends ConsumerStatefulWidget {
  const RepairHistoryScreen({super.key, this.loadRecords});
  final Future<List<Map<String, dynamic>>> Function()? loadRecords;

  @override
  ConsumerState<RepairHistoryScreen> createState() =>
      _RepairHistoryScreenState();
}

class _RepairHistoryScreenState extends ConsumerState<RepairHistoryScreen> {
  int _selectedNavIndex = 3;
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String _selectedFilter = 'All';

  final _api = SuperAdminApiService();
  List<Map<String, dynamic>> _repairs = [];
  bool _loading = true, _fetching = false;
  String? _error;
  String _search = '';
  Timer? _timer;
  @override
  void initState() {
    super.initState();
    _load();
    _timer =
        Timer.periodic(const Duration(seconds: 30), (_) => _load(silent: true));
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load({bool silent = false}) async {
    if (_fetching) return;
    _fetching = true;
    if (!silent)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final user = ref.read(currentUserProvider);
      if (widget.loadRecords == null && user == null)
        throw StateError('Sign in to view your repair history.');
      final rows = await (widget.loadRecords?.call() ??
          _api.getTechnicianRepairHistory(user!.id));
      rows.sort((a, b) => _date(b).compareTo(_date(a)));
      if (mounted)
        setState(() {
          _repairs = rows;
          _error = null;
        });
    } catch (_) {
      if (mounted)
        setState(
            () => _error = 'Unable to load repair records. Please try again.');
    } finally {
      _fetching = false;
      if (mounted && _loading) setState(() => _loading = false);
    }
  }

  String _value(Map<String, dynamic> row, String key,
          [String fallback = 'Not recorded']) =>
      row[key]?.toString().trim().isNotEmpty == true
          ? row[key].toString()
          : fallback;
  DateTime _date(Map<String, dynamic> row) =>
      DateTime.tryParse(
          _value(row, 'updated_at', _value(row, r'$updatedAt', ''))) ??
      DateTime.tryParse(_value(row, 'created_at', '')) ??
      DateTime(1970);
  String _status(Map<String, dynamic> row) => _value(row, 'status', 'Unknown');
  Color _statusColor(String status) => status == 'Completed'
      ? AppColors.success
      : status == 'Cancelled'
          ? AppColors.textSecondary
          : status == 'In Progress' || status == 'Started'
              ? AppColors.info
              : AppColors.warning;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isMobile = MediaQuery.of(context).size.width < 600;
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Technician';
    final userEmail = authState.user?.email ?? 'technician@farmestates.com';

    return Scaffold(
      key: _scaffoldKey,
      drawer: isMobile
          ? RoleMobileDrawer(
              userName: userName,
              userEmail: userEmail,
              userRole: 'Technician',
              selectedIndex: _selectedNavIndex,
              onItemSelected: (_) {},
              items: technicianNavigationItems,
            )
          : null,
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      body: isMobile
          ? _buildMobileLayout(isDark, userName)
          : _buildDesktopLayout(isDark, userName, userEmail),
      bottomNavigationBar: isMobile
          ? TechnicianMobileBottomNav(
              selectedIndex: _selectedNavIndex,
              onItemSelected: (index) =>
                  setState(() => _selectedNavIndex = index),
            )
          : null,
    );
  }

  Widget _buildDesktopLayout(bool isDark, String userName, String userEmail) {
    return Row(
      children: [
        TechnicianSidebar(
          selectedIndex: _selectedNavIndex,
          onItemSelected: (index) => setState(() => _selectedNavIndex = index),
          userName: userName,
          userEmail: userEmail,
          userRole: 'Technician',
        ),
        Expanded(
          child: Column(
            children: [
              TechnicianHeader(userName: userName, onNotificationTap: () {}),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  child: _buildContent(isDark, false),
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
        TechnicianHeader(
          userName: userName,
          onNotificationTap: () {},
          onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
              AppSpacing.md,
              AppSpacing.md,
              AppSpacing.md,
              16,
            ),
            child: _buildContent(isDark, true),
          ),
        ),
      ],
    );
  }

  Widget _buildContent(bool isDark, bool isMobile) {
    final foreground = isDark ? Colors.white : AppColors.textPrimary;
    final secondary = isDark ? Colors.white60 : AppColors.textSecondary;
    final completed = _repairs.where((r) => _status(r) == 'Completed').length;
    final active = _repairs
        .where((r) => !['Completed', 'Cancelled'].contains(_status(r)))
        .length;
    final filtered = _repairs
        .where((row) =>
            (_selectedFilter == 'All' || _status(row) == _selectedFilter) &&
            ['title', 'description', 'farm_name', 'task_id', 'assigned_to_name']
                .any((key) => _value(row, key, '')
                    .toLowerCase()
                    .contains(_search.trim().toLowerCase())))
        .toList();
    final statuses = {'All', ..._repairs.map(_status)}.toList();
    if (!statuses.contains(_selectedFilter)) statuses.add(_selectedFilter);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Repair history',
              style: AppTypography.h5.copyWith(
                  fontSize: AppTypography.headingSize,
                  fontWeight: AppTypography.headingWeight,
                  color: foreground)),
          const SizedBox(height: 4),
          Text('Maintenance tasks assigned to you',
              style: TextStyle(fontSize: AppTypography.captionSize, color: secondary)),
        ])),
        IconButton(
            tooltip: 'Refresh repair history',
            onPressed: _fetching ? null : _load,
            icon: const Icon(Icons.refresh, size: 20))
      ]),
      const SizedBox(height: 16),
      if (_loading && _repairs.isEmpty)
        const Padding(
            padding: EdgeInsets.all(24),
            child: Center(child: CircularProgressIndicator()))
      else if (_error != null && _repairs.isEmpty)
        Container(
            padding: const EdgeInsets.all(24),
            decoration: _decoration(isDark),
            child: Column(children: [
              const Icon(Icons.cloud_off_outlined, size: 32),
              const SizedBox(height: 12),
              Text(_error!,
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: AppTypography.captionSize, color: secondary)),
              TextButton(onPressed: _load, child: const Text('Retry')),
            ]))
      else ...[
        Row(children: [
          for (final stat in [
            ('Records', _repairs.length),
            ('Completed', completed),
            ('Open', active)
          ]) ...[
            if (stat.$1 != 'Records') const SizedBox(width: 10),
            Expanded(
                child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: _decoration(isDark),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(stat.$2.toString(),
                              style: TextStyle(
                                  fontSize: AppTypography.pageTitleSize,
                                  fontWeight: AppTypography.headingWeight,
                                  color: foreground)),
                          const SizedBox(height: 4),
                          Text(stat.$1,
                              style: TextStyle(fontSize: AppTypography.fieldLabelSize, color: secondary)),
                        ]))),
          ],
        ]),
        const SizedBox(height: 12),
        Container(
            padding: const EdgeInsets.all(14),
            decoration: _decoration(isDark),
            child: Column(children: [
              TextField(
                  onChanged: (value) => setState(() => _search = value),
                  style: const TextStyle(fontSize: AppTypography.actionSize),
                  decoration: InputDecoration(
                      hintText: 'Search repairs or farms',
                      prefixIcon: const Icon(Icons.search, size: 20),
                      isDense: true,
                      filled: true,
                      fillColor: isDark
                          ? Colors.white.withValues(alpha: .04)
                          : AppColors.neutral50,
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none))),
              const SizedBox(height: 10),
              Align(
                  alignment: Alignment.centerLeft,
                  child: Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: statuses
                          .map((status) => ChoiceChip(
                              showCheckmark: false,
                              label: Text(status,
                                  style: const TextStyle(fontSize: AppTypography.fieldLabelSize)),
                              selected: _selectedFilter == status,
                              onSelected: (_) =>
                                  setState(() => _selectedFilter = status)))
                          .toList())),
            ])),
        if (_error != null)
          Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Row(children: [
                Expanded(
                    child: Text(_error!,
                        style:
                            TextStyle(fontSize: AppTypography.captionSize, color: AppColors.error))),
                TextButton(onPressed: _load, child: const Text('Retry'))
              ])),
        const SizedBox(height: 12),
        if (filtered.isEmpty)
          Container(
              padding: const EdgeInsets.all(24),
              decoration: _decoration(isDark),
              child: Column(children: [
                Icon(Icons.build_circle_outlined, size: 32, color: secondary),
                const SizedBox(height: 10),
                Text(
                    _repairs.isEmpty
                        ? 'No repair records yet'
                        : 'No matching records',
                    style: TextStyle(
                        fontSize: AppTypography.bodySize,
                        fontWeight: AppTypography.headingWeight,
                        color: foreground)),
                const SizedBox(height: 6),
                Text(
                    _repairs.isEmpty
                        ? 'Assigned maintenance tasks will appear here when recorded.'
                        : 'Try another search or status.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: AppTypography.captionSize, color: secondary))
              ]))
        else
          LayoutBuilder(builder: (context, constraints) {
            final columns = constraints.maxWidth >= 800 ? 2 : 1;
            final count = (filtered.length / columns).ceil();
            return Column(children: [
              for (var row = 0; row < count; row++) ...[
                if (row > 0) const SizedBox(height: 12),
                Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  for (var col = 0; col < columns; col++) ...[
                    if (col > 0) const SizedBox(width: 12),
                    Expanded(
                        child: row * columns + col < filtered.length
                            ? _buildRepairCard(
                                filtered[row * columns + col], isDark)
                            : const SizedBox()),
                  ]
                ]),
              ]
            ]);
          }),
      ],
    ]);
  }

  BoxDecoration _decoration(bool dark) => BoxDecoration(
      color: dark ? AppColors.surfaceDark : Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: dark ? Colors.white10 : AppColors.neutral200));

  Widget _buildRepairCard(Map<String, dynamic> repair, bool dark) {
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final secondary = dark ? Colors.white60 : AppColors.textSecondary;
    final status = _status(repair);
    final color = _statusColor(status);
    String date(String key) {
      final parsed = DateTime.tryParse(_value(repair, key, ''));
      return parsed == null
          ? 'Not recorded'
          : DateFormat('d MMM yyyy').format(parsed.toLocal());
    }

    Widget detail(String label, String value) => Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: TextStyle(fontSize: AppTypography.microSize, color: secondary)),
          const SizedBox(height: 5),
          Text(value, style: TextStyle(fontSize: AppTypography.captionSize, color: foreground))
        ]));
    return Container(
        padding: const EdgeInsets.all(16),
        decoration: _decoration(dark),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(Icons.build_outlined, size: 18, color: color)),
            const SizedBox(width: 10),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(_value(repair, 'title', 'Maintenance task'),
                      style: TextStyle(
                          fontSize: AppTypography.bodySize,
                          fontWeight: AppTypography.headingWeight,
                          color: foreground)),
                  const SizedBox(height: 5),
                  Text(_value(repair, 'farm_name'),
                      style: TextStyle(fontSize: AppTypography.captionSize, color: secondary))
                ]))
          ]),
          const SizedBox(height: 12),
          Wrap(spacing: 8, runSpacing: 6, children: [
            Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                decoration: BoxDecoration(
                    color: color.withValues(alpha: .1),
                    borderRadius: BorderRadius.circular(6)),
                child: Text(status,
                    style: TextStyle(
                        fontSize: AppTypography.fieldLabelSize,
                        fontWeight: AppTypography.headingWeight,
                        color: color))),
            Text(_value(repair, 'task_id', 'Reference unavailable'),
                style: TextStyle(fontSize: AppTypography.fieldLabelSize, color: secondary))
          ]),
          if (_value(repair, 'description', '').isNotEmpty) ...[
            const SizedBox(height: 12),
            Text(_value(repair, 'description'),
                style: TextStyle(fontSize: AppTypography.captionSize, height: 1.4, color: foreground))
          ],
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            detail('Technician', _value(repair, 'assigned_to_name')),
            const SizedBox(width: 10),
            detail('Priority', _value(repair, 'priority'))
          ]),
          const SizedBox(height: 12),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            detail('Last updated', date('updated_at')),
            const SizedBox(width: 10),
            detail('Due date', date('due_date'))
          ]),
          for (final note in [
            ('Manager note', 'manager_comment'),
            ('Task update', 'caretaker_comment')
          ])
            if (_value(repair, note.$2, '').isNotEmpty) ...[
              const SizedBox(height: 12),
              Text(note.$1,
                  style: TextStyle(
                      fontSize: AppTypography.fieldLabelSize,
                      fontWeight: AppTypography.headingWeight,
                      color: secondary)),
              const SizedBox(height: 5),
              Text(_value(repair, note.$2),
                  style:
                      TextStyle(fontSize: AppTypography.captionSize, height: 1.4, color: foreground)),
            ],
        ]));
  }
}
