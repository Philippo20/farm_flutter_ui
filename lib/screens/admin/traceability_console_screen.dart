import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/widgets/modern_admin_header.dart';
import '../../core/widgets/modern_admin_sidebar.dart';
import '../../core/widgets/skeleton_loader.dart';
import '../../core/widgets/superadmin_sidebar.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

class TraceabilityConsoleScreen extends ConsumerStatefulWidget {
  const TraceabilityConsoleScreen({required this.isSuperAdmin, super.key});

  final bool isSuperAdmin;

  @override
  ConsumerState<TraceabilityConsoleScreen> createState() =>
      _TraceabilityConsoleScreenState();
}

class _TraceabilityConsoleScreenState
    extends ConsumerState<TraceabilityConsoleScreen> {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  final _api = SuperAdminApiService();
  final _searchController = TextEditingController();
  final _siteController = TextEditingController();
  final _brandController = TextEditingController();
  final _headlineController = TextEditingController();
  final _emailController = TextEditingController();
  final _primaryController = TextEditingController();
  final _secondaryController = TextEditingController();
  final _logoController = TextEditingController();
  final _privacyController = TextEditingController();

  Map<String, dynamic> _metrics = {};
  Map<String, dynamic> _settings = {};
  List<Map<String, dynamic>> _batches = [];
  List<Map<String, dynamic>> _promotions = [];
  List<Map<String, dynamic>> _events = [];
  List<Map<String, dynamic>> _feedback = [];
  bool _loading = true;
  bool _savingSettings = false;
  String? _error;
  int _tab = 0;
  String _feedbackFilter = 'all';

  int get _navIndex => widget.isSuperAdmin ? 15 : 10;
  String get _role => widget.isSuperAdmin ? 'superadmin' : 'admin';

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
    _load();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _siteController.dispose();
    _brandController.dispose();
    _headlineController.dispose();
    _emailController.dispose();
    _primaryController.dispose();
    _secondaryController.dispose();
    _logoController.dispose();
    _privacyController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await _api.getTraceabilityOverview();
      if (!mounted) return;
      final settings = _map(data['settings']);
      setState(() {
        _metrics = _map(data['metrics']);
        _settings = settings;
        _batches = _list(data['batches']);
        _promotions = _list(data['promotions']);
        _events = _list(data['events']);
        _feedback = _list(data['feedback']);
        _syncSettingsControllers(settings);
        _loading = false;
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _error = error.toString();
        _loading = false;
      });
    }
  }

  Map<String, dynamic> _map(dynamic value) =>
      value is Map ? Map<String, dynamic>.from(value) : {};

  List<Map<String, dynamic>> _list(dynamic value) => value is List
      ? value
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList()
      : [];

  void _syncSettingsControllers(Map<String, dynamic> settings) {
    _siteController.text = '${settings['public_site_url'] ?? ''}';
    _brandController.text = '${settings['brand_name'] ?? ''}';
    _headlineController.text = '${settings['headline'] ?? ''}';
    _emailController.text = '${settings['support_email'] ?? ''}';
    _primaryController.text = '${settings['primary_color'] ?? '#4CAF50'}';
    _secondaryController.text = '${settings['secondary_color'] ?? '#29B6F6'}';
    _logoController.text = '${settings['logo_url'] ?? ''}';
    _privacyController.text = '${settings['privacy_notice_url'] ?? ''}';
  }

  Future<void> _saveSettings() async {
    final user = ref.read(currentUserProvider);
    setState(() => _savingSettings = true);
    try {
      await _api.updateTraceabilitySettings({
        'public_site_url': _siteController.text.trim(),
        'brand_name': _brandController.text.trim(),
        'headline': _headlineController.text.trim(),
        'support_email': _emailController.text.trim(),
        'primary_color': _primaryController.text.trim(),
        'secondary_color': _secondaryController.text.trim(),
        'logo_url': _logoController.text.trim(),
        'privacy_notice_url': _privacyController.text.trim(),
        'lookup_enabled': _flag('lookup_enabled'),
        'maintenance_mode': _settings['maintenance_mode'] == true,
        'show_farm': _flag('show_farm'),
        'show_location': _flag('show_location'),
        'show_dates': _flag('show_dates'),
        'show_quality': _flag('show_quality'),
        'show_journey': _flag('show_journey'),
        'analytics_enabled': _flag('analytics_enabled'),
        'promotions_enabled': _flag('promotions_enabled'),
        'feedback_enabled': _flag('feedback_enabled'),
        'retention_days': (_settings['retention_days'] as num?)?.toInt() ?? 365,
        'updated_by': user?.id ?? 'system',
      });
      if (!mounted) return;
      _notice('Public traceability experience saved');
      await _load();
    } catch (error) {
      if (mounted) _notice(error.toString(), error: true);
    } finally {
      if (mounted) setState(() => _savingSettings = false);
    }
  }

  bool _flag(String key) => _settings[key] != false;

  void _toggle(String key, bool value) {
    setState(() => _settings = {..._settings, key: value});
  }

  void _notice(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.poppins()),
        backgroundColor: error ? Colors.red.shade700 : AppColors.primary,
      ),
    );
  }

  Future<void> _openPublication(Map<String, dynamic> batch) async {
    final user = ref.read(currentUserProvider);
    final changed = await _showAdaptive<bool>(
      _PublicationPanel(
        batch: batch,
        onSubmit: (data) => _api.updateBatchPublication(
          batchId: '${batch['batch_id']}',
          data: {
            ...data,
            'actor_id': user?.id ?? 'system',
            'actor_role': _role,
          },
        ),
      ),
    );
    if (changed == true) {
      _notice('Batch publication updated');
      await _load();
    }
  }

  Future<void> _openPromotion([Map<String, dynamic>? promotion]) async {
    final user = ref.read(currentUserProvider);
    final changed = await _showAdaptive<bool>(
      _PromotionPanel(
        promotion: promotion,
        batches: _batches,
        onSubmit: (data) => _api.saveTraceabilityPromotion(
          id: promotion?[r'$id']?.toString(),
          data: {
            ...data,
            'actor_id': user?.id ?? 'system',
            'actor_role': _role,
          },
        ),
      ),
    );
    if (changed == true) {
      _notice(promotion == null ? 'Promotion created' : 'Promotion updated');
      await _load();
    }
  }

  Future<T?> _showAdaptive<T>(Widget child) {
    if (MediaQuery.sizeOf(context).width < 600) {
      return showModalBottomSheet<T>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => child,
      );
    }
    return showDialog<T>(
      context: context,
      barrierColor: Colors.black54,
      builder: (_) => Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
        backgroundColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 760),
          child: child,
        ),
      ),
    );
  }

  Future<void> _openFeedback(Map<String, dynamic> feedback) async {
    final user = ref.read(currentUserProvider);
    final changed = await _showAdaptive<bool>(
      _FeedbackReviewPanel(
        feedback: feedback,
        onSubmit: (data) => _api.updateTraceabilityFeedback(
          id: '${feedback[r'$id'] ?? feedback['feedback_id']}',
          data: {
            ...data,
            'actor_id': user?.id ?? 'system',
            'actor_role': _role,
          },
        ),
      ),
    );
    if (changed == true) {
      _notice('Feedback review updated');
      await _load();
    }
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final mobile = width < 600;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final user = ref.watch(currentUserProvider);
    final userName =
        user?.name ?? (widget.isSuperAdmin ? 'Super Admin' : 'Admin');
    final userEmail = user?.email ?? '';

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor:
          dark ? AppColors.backgroundDark : AppColors.backgroundLight,
      drawer: mobile
          ? widget.isSuperAdmin
              ? SuperAdminDrawer(
                  selectedIndex: _navIndex,
                  onItemSelected: (_) {},
                  userName: userName,
                  userEmail: userEmail,
                  userRole: 'Super Administrator',
                )
              : AdminDrawer(
                  selectedIndex: _navIndex,
                  onItemSelected: (_) {},
                  userName: userName,
                  userEmail: userEmail,
                  userRole: 'Administrator',
                )
          : null,
      bottomNavigationBar: mobile
          ? widget.isSuperAdmin
              ? SuperAdminMobileBottomNav(
                  selectedIndex: _navIndex,
                  onItemSelected: (_) {},
                )
              : AdminMobileBottomNav(
                  selectedIndex: _navIndex,
                  onItemSelected: (_) {},
                )
          : null,
      body: mobile
          ? _mobileBody(userName.split(' ').first)
          : Row(
              children: [
                if (widget.isSuperAdmin)
                  SuperAdminSidebar(
                    selectedIndex: _navIndex,
                    onItemSelected: (_) {},
                    userName: userName,
                    userEmail: userEmail,
                    userRole: 'Super Administrator',
                  )
                else
                  ModernAdminSidebar(
                    selectedIndex: _navIndex,
                    onItemSelected: (_) {},
                    userName: userName,
                    userEmail: userEmail,
                    userRole: 'Administrator',
                  ),
                Expanded(child: _desktopBody(userName.split(' ').first)),
              ],
            ),
    );
  }

  Widget _mobileBody(String firstName) => Column(
        children: [
          ModernAdminHeader(
            userName: firstName,
            onMenuTap: () => _scaffoldKey.currentState?.openDrawer(),
            onProfileTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          Expanded(child: _scrollable(mobile: true)),
        ],
      );

  Widget _desktopBody(String firstName) => Column(
        children: [
          ModernAdminHeader(
            userName: firstName,
            onProfileTap: () => Navigator.pushNamed(context, '/profile'),
          ),
          Expanded(child: _scrollable(mobile: false)),
        ],
      );

  Widget _scrollable({required bool mobile}) => RefreshIndicator(
        onRefresh: _load,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: EdgeInsets.all(mobile ? AppSpacing.md : AppSpacing.xl),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _hero(mobile),
              const SizedBox(height: 20),
              if (_loading)
                const AdminDataSkeleton(rowCount: 5)
              else if (_error != null)
                _errorState()
              else ...[
                _metricGrid(mobile),
                const SizedBox(height: 20),
                _tabs(),
                const SizedBox(height: 16),
                if (_tab == 0) _products(mobile),
                if (_tab == 1) _experience(mobile),
                if (_tab == 2) _promotionList(mobile),
                if (_tab == 3) _analytics(mobile),
                if (_tab == 4) _feedbackList(mobile),
              ],
            ],
          ),
        ),
      );

  Widget _hero(bool mobile) => Container(
        width: double.infinity,
        padding: EdgeInsets.all(mobile ? 20 : 28),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 12,
                    offset: const Offset(0, 3),
                  ),
                ],
        ),
        child: Wrap(
          spacing: 18,
          runSpacing: 16,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Container(
              width: 54,
              height: 54,
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: .12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.qr_code_2_rounded,
                  color: AppColors.primary, size: 30),
            ),
            SizedBox(
              width: mobile ? MediaQuery.sizeOf(context).width - 100 : 560,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Product Traceability',
                    style: GoogleFonts.poppins(
                      fontSize: mobile ? 24 : 30,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Publish verified batch journeys, control the consumer experience, and measure product engagement.',
                    style: GoogleFonts.poppins(
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                      height: 1.5,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: Text('Refresh', style: GoogleFonts.poppins()),
            ),
          ],
        ),
      );

  Widget _metricGrid(bool mobile) {
    final items = [
      (
        'Published',
        _metrics['published_products'] ?? 0,
        Icons.verified_outlined,
        AppColors.primary
      ),
      (
        'Product checks',
        _metrics['total_scans'] ?? 0,
        Icons.qr_code_scanner_rounded,
        Colors.blue
      ),
      (
        'Unique visitors',
        _metrics['unique_visitors'] ?? 0,
        Icons.people_outline,
        Colors.teal
      ),
      (
        'Active promotions',
        _metrics['active_promotions'] ?? 0,
        Icons.campaign_outlined,
        Colors.orange
      ),
      (
        'Failed lookups',
        _metrics['failed_lookups'] ?? 0,
        Icons.search_off_rounded,
        Colors.red
      ),
      (
        'Open reports',
        _metrics['open_reports'] ?? 0,
        Icons.report_problem_outlined,
        Colors.deepOrange
      ),
    ];
    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = mobile ? 2 : (constraints.maxWidth < 900 ? 3 : 6);
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: mobile ? 1.55 : 1.7,
          ),
          itemBuilder: (_, index) {
            final item = items[index];
            return _MetricCard(
              label: item.$1,
              value: '${item.$2}',
              icon: item.$3,
              color: item.$4,
            );
          },
        );
      },
    );
  }

  Widget _tabs() {
    const tabs = [
      ('Products', Icons.inventory_2_outlined),
      ('Experience', Icons.palette_outlined),
      ('Promotions', Icons.campaign_outlined),
      ('Analytics', Icons.insights_outlined),
      ('Feedback', Icons.rate_review_outlined),
    ];
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: List.generate(tabs.length, (index) {
          final selected = index == _tab;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              onSelected: (_) => setState(() => _tab = index),
              avatar: Icon(tabs[index].$2,
                  size: 17, color: selected ? Colors.white : AppColors.primary),
              label: Text(tabs[index].$1, style: GoogleFonts.poppins()),
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: selected ? Colors.white : null),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        }),
      ),
    );
  }

  Widget _products(bool mobile) {
    final query = _searchController.text.trim().toLowerCase();
    final rows = _batches.where((item) {
      if (query.isEmpty) return true;
      return ['batch_number', 'product_name', 'variety', 'farm_name']
          .any((key) => '${item[key] ?? ''}'.toLowerCase().contains(query));
    }).toList();
    return Column(
      children: [
        _sectionHeader(
          title: 'Published product records',
          subtitle: '${rows.length} production batches available',
          action: SizedBox(
            width: mobile ? 190 : 280,
            child: TextField(
              controller: _searchController,
              style: GoogleFonts.poppins(fontSize: 13),
              decoration: _input('Search batches', Icons.search_rounded),
            ),
          ),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          _empty(Icons.inventory_2_outlined, 'No matching batches')
        else
          ...rows.map((batch) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _BatchCard(
                  batch: batch,
                  onConfigure: () => _openPublication(batch),
                  onCopy: () async {
                    await Clipboard.setData(
                        ClipboardData(text: '${batch['public_url'] ?? ''}'));
                    if (mounted) _notice('Public product link copied');
                  },
                ),
              )),
      ],
    );
  }

  Widget _experience(bool mobile) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _sectionHeader(
              title: 'Consumer experience',
              subtitle:
                  'Controls returned by the public configuration endpoint',
            ),
            const SizedBox(height: 20),
            _responsiveFields(mobile, [
              _field(_siteController, 'Public site URL', Icons.public_rounded),
              _field(_brandController, 'Brand name', Icons.storefront_outlined),
              _field(_headlineController, 'Consumer headline',
                  Icons.title_rounded),
              _field(_emailController, 'Support email',
                  Icons.alternate_email_rounded),
              _field(_primaryController, 'Primary color',
                  Icons.color_lens_outlined),
              _field(_secondaryController, 'Secondary color',
                  Icons.palette_outlined),
              _field(_logoController, 'Logo URL', Icons.image_outlined),
              _field(_privacyController, 'Privacy notice URL',
                  Icons.privacy_tip_outlined),
            ]),
            const SizedBox(height: 18),
            Row(
              children: [
                const Icon(
                  Icons.engineering_outlined,
                  color: Colors.orange,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Traceability maintenance mode',
                        style: GoogleFonts.poppins(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      Text(
                        'Temporarily pause public product verification while keeping this console available.',
                        style: GoogleFonts.poppins(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _settings['maintenance_mode'] == true,
                  onChanged: (value) => _toggle('maintenance_mode', value),
                ),
              ],
            ),
            const SizedBox(height: 14),
            Divider(
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withValues(alpha: .06)
                  : Colors.black.withValues(alpha: .06),
            ),
            const SizedBox(height: 14),
            Text('Public data visibility',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _settingSwitch('lookup_enabled', 'Product lookup'),
                _settingSwitch('show_farm', 'Farm name'),
                _settingSwitch('show_location', 'Farm location'),
                _settingSwitch('show_dates', 'Production dates'),
                _settingSwitch('show_quality', 'Quality status'),
                _settingSwitch('show_journey', 'Product journey'),
                _settingSwitch('analytics_enabled', 'Anonymous analytics'),
                _settingSwitch('promotions_enabled', 'Promotions'),
                _settingSwitch(
                    'feedback_enabled', 'Feedback and issue reports'),
              ],
            ),
            const SizedBox(height: 22),
            Align(
              alignment: Alignment.centerRight,
              child: FilledButton.icon(
                onPressed: _savingSettings ? null : _saveSettings,
                icon: _savingSettings
                    ? const SizedBox(
                        width: 17,
                        height: 17,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.save_outlined, size: 18),
                label: Text(_savingSettings ? 'Saving...' : 'Save experience',
                    style: GoogleFonts.poppins()),
              ),
            ),
          ],
        ),
      );

  Widget _promotionList(bool mobile) => Column(
        children: [
          _sectionHeader(
            title: 'Consumer promotions',
            subtitle: 'Structured campaigns shown after a verified lookup',
            action: FilledButton.icon(
              onPressed: () => _openPromotion(),
              icon: const Icon(Icons.add_rounded, size: 18),
              label: Text('New promotion', style: GoogleFonts.poppins()),
            ),
          ),
          const SizedBox(height: 12),
          if (_promotions.isEmpty)
            _empty(Icons.campaign_outlined, 'No promotions created')
          else
            ..._promotions.map((promotion) => Padding(
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _PromotionCard(
                    promotion: promotion,
                    onEdit: () => _openPromotion(promotion),
                    onDelete: widget.isSuperAdmin
                        ? () => _deletePromotion(promotion)
                        : null,
                  ),
                )),
        ],
      );

  Future<void> _deletePromotion(Map<String, dynamic> promotion) async {
    final user = ref.read(currentUserProvider);
    final confirmed = await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text('Delete promotion?', style: GoogleFonts.poppins()),
            content: Text(
              'This removes ${promotion['title']} from the consumer experience.',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(dialogContext, false),
                  child: const Text('Cancel')),
              FilledButton(
                  onPressed: () => Navigator.pop(dialogContext, true),
                  child: const Text('Delete')),
            ],
          ),
        ) ??
        false;
    if (!confirmed) return;
    try {
      await _api.deleteTraceabilityPromotion(
        id: '${promotion[r'$id']}',
        actorId: user?.id ?? 'system',
        actorRole: _role,
      );
      _notice('Promotion deleted');
      await _load();
    } catch (error) {
      if (mounted) _notice(error.toString(), error: true);
    }
  }

  Widget _analytics(bool mobile) {
    final byType = <String, int>{};
    final byRegion = <String, int>{};
    final byDevice = <String, int>{};
    for (final event in _events) {
      final type = '${event['event_type'] ?? 'unknown'}';
      byType[type] = (byType[type] ?? 0) + 1;
      final region = '${event['region'] ?? ''}'.trim();
      if (region.isNotEmpty) byRegion[region] = (byRegion[region] ?? 0) + 1;
      final device = '${event['device_type'] ?? 'unknown'}'.trim();
      byDevice[device] = (byDevice[device] ?? 0) + 1;
    }
    final maxValue = byType.values.fold<int>(1, (a, b) => a > b ? a : b);
    return _Panel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _sectionHeader(
            title: 'Engagement analytics',
            subtitle: 'Anonymous events from the public product experience',
          ),
          const SizedBox(height: 22),
          if (byType.isEmpty)
            _empty(Icons.insights_outlined, 'No consumer activity recorded yet')
          else ...[
            ...byType.entries.map((entry) => _AnalyticsBar(
                  label: _friendly(entry.key),
                  value: entry.value,
                  fraction: entry.value / maxValue,
                )),
            if (byRegion.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Top regions',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: byRegion.entries
                    .map((entry) => Chip(
                          label: Text('${entry.key}  ${entry.value}',
                              style: GoogleFonts.poppins(fontSize: 12)),
                        ))
                    .toList(),
              ),
            ],
            if (byDevice.isNotEmpty) ...[
              const SizedBox(height: 20),
              Text('Devices',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: byDevice.entries
                    .map((entry) => Chip(
                          avatar: Icon(_deviceIcon(entry.key), size: 16),
                          label: Text('${_friendly(entry.key)}  ${entry.value}',
                              style: GoogleFonts.poppins(fontSize: 12)),
                        ))
                    .toList(),
              ),
            ],
            const SizedBox(height: 24),
            Text('Recent visitors',
                style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
            const SizedBox(height: 4),
            Text(
              'Approximate IP location and server-detected device details',
              style: GoogleFonts.poppins(
                fontSize: 11,
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 10),
            ..._events.take(12).map((event) => _VisitorRow(event: event)),
          ],
        ],
      ),
    );
  }

  IconData _deviceIcon(String value) {
    switch (value.toLowerCase()) {
      case 'mobile':
        return Icons.smartphone_rounded;
      case 'tablet':
        return Icons.tablet_mac_rounded;
      default:
        return Icons.computer_rounded;
    }
  }

  Widget _feedbackList(bool mobile) {
    final rows = _feedback.where((item) {
      if (_feedbackFilter == 'all') return true;
      if (_feedbackFilter == 'open') {
        return item['status'] == 'new' || item['status'] == 'reviewing';
      }
      return item['feedback_type'] == _feedbackFilter;
    }).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionHeader(
          title: 'Consumer feedback',
          subtitle: 'Review product feedback and reported issues',
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: {
              'all': 'All',
              'open': 'Open',
              'feedback': 'Feedback',
              'issue': 'Issues',
            }
                .entries
                .map((entry) => Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: ChoiceChip(
                        label: Text(entry.value,
                            style: GoogleFonts.poppins(fontSize: 12)),
                        selected: _feedbackFilter == entry.key,
                        onSelected: (_) =>
                            setState(() => _feedbackFilter = entry.key),
                      ),
                    ))
                .toList(),
          ),
        ),
        const SizedBox(height: 12),
        if (rows.isEmpty)
          _empty(Icons.rate_review_outlined, 'No matching feedback or issues')
        else
          ...rows.map((item) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: _FeedbackCard(
                  feedback: item,
                  onTap: () => _openFeedback(item),
                ),
              )),
      ],
    );
  }

  String _friendly(String value) => value
      .split('_')
      .map((part) =>
          part.isEmpty ? part : '${part[0].toUpperCase()}${part.substring(1)}')
      .join(' ');

  Widget _errorState() => _Panel(
        child: Column(
          children: [
            const Icon(Icons.cloud_off_rounded, size: 38, color: Colors.red),
            const SizedBox(height: 10),
            Text(_error!,
                textAlign: TextAlign.center, style: GoogleFonts.poppins()),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: _load,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      );

  Widget _sectionHeader({
    required String title,
    required String subtitle,
    Widget? action,
  }) =>
      LayoutBuilder(
        builder: (context, constraints) {
          final copy = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                  style: GoogleFonts.poppins(
                      fontSize: 18, fontWeight: FontWeight.w600)),
              Text(subtitle,
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ],
          );
          if (action == null) return copy;
          if (constraints.maxWidth < 680) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [copy, const SizedBox(height: 12), action],
            );
          }
          return Row(
            children: [
              Expanded(child: copy),
              const SizedBox(width: 16),
              action,
            ],
          );
        },
      );

  Widget _responsiveFields(bool mobile, List<Widget> fields) => GridView.count(
        crossAxisCount: mobile ? 1 : 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: mobile ? 5.2 : 4.5,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        children: fields,
      );

  Widget _field(
          TextEditingController controller, String label, IconData icon) =>
      TextField(
        controller: controller,
        style: GoogleFonts.poppins(fontSize: 13),
        decoration: _input(label, icon),
      );

  InputDecoration _input(String label, IconData icon) => InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.poppins(fontSize: 12),
        prefixIcon: Icon(icon, size: 17),
        filled: true,
        fillColor: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: .04)
            : AppColors.neutral50,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: .06)
                : Colors.black.withValues(alpha: .06),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
        ),
      );

  Widget _settingSwitch(
    String key,
    String label, {
    bool defaultValue = true,
  }) =>
      Container(
        width: 220,
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: .03)
              : AppColors.neutral50,
          borderRadius: BorderRadius.circular(10),
        ),
        child: SwitchListTile.adaptive(
          dense: true,
          title: Text(label, style: GoogleFonts.poppins(fontSize: 12)),
          value: _settings[key] is bool ? _settings[key] as bool : defaultValue,
          onChanged: (value) => _toggle(key, value),
        ),
      );

  Widget _empty(IconData icon, String text) => Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 20),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: Column(
          children: [
            Icon(icon, size: 34, color: Theme.of(context).hintColor),
            const SizedBox(height: 10),
            Text(text, style: GoogleFonts.poppins()),
          ],
        ),
      );
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? AppColors.surfaceDark
              : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: Theme.of(context).brightness == Brightness.dark
                ? Colors.white.withValues(alpha: .06)
                : Colors.black.withValues(alpha: .04),
          ),
          boxShadow: Theme.of(context).brightness == Brightness.dark
              ? null
              : [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: .04),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
        ),
        child: child,
      );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.label,
      required this.value,
      required this.icon,
      required this.color});
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: color, size: 22),
            const Spacer(),
            Text(value,
                style: GoogleFonts.poppins(
                    fontSize: 22, fontWeight: FontWeight.w600)),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.poppins(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ),
      );
}

class _BatchCard extends StatelessWidget {
  const _BatchCard(
      {required this.batch, required this.onConfigure, required this.onCopy});
  final Map<String, dynamic> batch;
  final VoidCallback onConfigure;
  final VoidCallback onCopy;

  @override
  Widget build(BuildContext context) {
    final published = batch['published'] == true;
    return _Panel(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: (published ? AppColors.primary : Colors.grey)
                  .withValues(alpha: .12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(Icons.qr_code_2_rounded,
                color: published ? AppColors.primary : Colors.grey),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 5,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    Text('${batch['batch_number'] ?? 'No batch number'}',
                        style:
                            GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                    _StatusPill(
                      text: published ? 'Published' : 'Private',
                      color: published ? AppColors.primary : Colors.grey,
                    ),
                    if ('${batch['recall_status']}' != 'none')
                      _StatusPill(
                          text: '${batch['recall_status']}', color: Colors.red),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${batch['product_name'] ?? ''} - ${batch['variety'] ?? ''}  |  ${batch['farm_name'] ?? ''}',
                  style: GoogleFonts.poppins(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.onSurfaceVariant),
                ),
                if (published) ...[
                  const SizedBox(height: 6),
                  Text('${batch['scan_count'] ?? 0} product checks',
                      style: GoogleFonts.poppins(fontSize: 11)),
                ],
              ],
            ),
          ),
          if (published)
            IconButton(
              onPressed: onCopy,
              tooltip: 'Copy public link',
              icon: const Icon(Icons.copy_rounded, size: 19),
            ),
          IconButton(
            onPressed: onConfigure,
            tooltip: 'Configure publication',
            icon: const Icon(Icons.tune_rounded, size: 20),
          ),
        ],
      ),
    );
  }
}

class _PromotionCard extends StatelessWidget {
  const _PromotionCard(
      {required this.promotion, required this.onEdit, this.onDelete});
  final Map<String, dynamic> promotion;
  final VoidCallback onEdit;
  final VoidCallback? onDelete;

  @override
  Widget build(BuildContext context) => _Panel(
        child: Row(
          children: [
            const Icon(Icons.campaign_outlined, color: Colors.orange, size: 28),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: 8,
                    children: [
                      Text('${promotion['title'] ?? ''}',
                          style:
                              GoogleFonts.poppins(fontWeight: FontWeight.w600)),
                      _StatusPill(
                        text: '${promotion['status'] ?? 'draft'}',
                        color: promotion['status'] == 'active'
                            ? AppColors.primary
                            : Colors.grey,
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text('${promotion['message'] ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                          fontSize: 12,
                          color:
                              Theme.of(context).colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
            IconButton(
                onPressed: onEdit, icon: const Icon(Icons.edit_outlined)),
            if (onDelete != null)
              IconButton(
                  onPressed: onDelete,
                  icon: const Icon(Icons.delete_outline, color: Colors.red)),
          ],
        ),
      );
}

class _FeedbackCard extends StatelessWidget {
  const _FeedbackCard({required this.feedback, required this.onTap});
  final Map<String, dynamic> feedback;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isIssue = feedback['feedback_type'] == 'issue';
    final rating = (feedback['rating'] as num?)?.toInt() ?? 0;
    final location = [
      '${feedback['city'] ?? ''}'.trim(),
      '${feedback['region'] ?? ''}'.trim(),
      '${feedback['country'] ?? ''}'.trim(),
    ].where((value) => value.isNotEmpty).join(', ');
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: _Panel(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: (isIssue ? Colors.deepOrange : AppColors.primary)
                      .withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  isIssue
                      ? Icons.report_problem_outlined
                      : Icons.rate_review_outlined,
                  color: isIssue ? Colors.deepOrange : AppColors.primary,
                  size: 21,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 7,
                      runSpacing: 5,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          isIssue ? 'Issue report' : 'Product feedback',
                          style: GoogleFonts.poppins(
                              fontSize: 13, fontWeight: FontWeight.w600),
                        ),
                        _StatusPill(
                          text: '${feedback['status'] ?? 'new'}',
                          color: _feedbackStatusColor(
                              '${feedback['status'] ?? 'new'}'),
                        ),
                        if (rating > 0)
                          Text('$rating/5',
                              style: GoogleFonts.poppins(
                                  fontSize: 11,
                                  color: Colors.amber.shade800,
                                  fontWeight: FontWeight.w600)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${feedback['message'] ?? ''}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 7),
                    Wrap(
                      spacing: 12,
                      runSpacing: 4,
                      children: [
                        _MetaText(Icons.qr_code_rounded,
                            '${feedback['batch_number'] ?? 'No batch'}'),
                        _MetaText(
                            Icons.location_on_outlined,
                            location.isEmpty
                                ? 'Location unavailable'
                                : location),
                        _MetaText(Icons.devices_outlined,
                            '${feedback['device_type'] ?? 'unknown'}'),
                        _MetaText(Icons.schedule_rounded,
                            _formatTraceDate(feedback['created_at'])),
                      ],
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right_rounded, size: 21),
            ],
          ),
        ),
      ),
    );
  }
}

class _VisitorRow extends StatelessWidget {
  const _VisitorRow({required this.event});
  final Map<String, dynamic> event;

  @override
  Widget build(BuildContext context) {
    final location = [
      '${event['city'] ?? ''}'.trim(),
      '${event['region'] ?? ''}'.trim(),
      '${event['country'] ?? ''}'.trim(),
    ].where((value) => value.isNotEmpty).join(', ');
    final device = [
      '${event['device_type'] ?? ''}'.trim(),
      '${event['browser'] ?? ''}'.trim(),
      '${event['operating_system'] ?? ''}'.trim(),
    ].where((value) => value.isNotEmpty && value != 'Unknown').join(' | ');
    final latitude = (event['latitude'] as num?)?.toDouble() ?? 0;
    final longitude = (event['longitude'] as num?)?.toDouble() ?? 0;
    final coordinates = latitude == 0 && longitude == 0
        ? ''
        : '${latitude.toStringAsFixed(3)}, ${longitude.toStringAsFixed(3)}';
    final network = [
      '${event['timezone'] ?? ''}'.trim(),
      '${event['isp'] ?? ''}'.trim(),
      coordinates,
    ].where((value) => value.isNotEmpty).join(' | ');
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white.withValues(alpha: .03)
            : AppColors.neutral50,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          const Icon(Icons.public_rounded, size: 19, color: AppColors.primary),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  location.isEmpty ? 'Location unavailable' : location,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 12, fontWeight: FontWeight.w500),
                ),
                Text(
                  '${event['ip_masked'] ?? 'unknown'}  |  ${device.isEmpty ? 'Unknown device' : device}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
                if (network.isNotEmpty)
                  Text(
                    network,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            _formatTraceDate(event['occurred_at']),
            style: GoogleFonts.poppins(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

class _MetaText extends StatelessWidget {
  const _MetaText(this.icon, this.text);
  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 13,
                color: Theme.of(context).colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.poppins(
                      fontSize: 10,
                      color: Theme.of(context).colorScheme.onSurfaceVariant)),
            ),
          ],
        ),
      );
}

Color _feedbackStatusColor(String status) {
  switch (status) {
    case 'resolved':
      return AppColors.primary;
    case 'reviewing':
      return Colors.blue;
    case 'closed':
      return Colors.grey;
    default:
      return Colors.deepOrange;
  }
}

String _formatTraceDate(dynamic value) {
  final date = DateTime.tryParse('${value ?? ''}')?.toLocal();
  if (date == null) return 'Unknown time';
  String two(int part) => part.toString().padLeft(2, '0');
  return '${two(date.day)}/${two(date.month)}/${date.year} ${two(date.hour)}:${two(date.minute)}';
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: color.withValues(alpha: .12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(text,
            style: GoogleFonts.poppins(
                fontSize: 10, color: color, fontWeight: FontWeight.w500)),
      );
}

class _AnalyticsBar extends StatelessWidget {
  const _AnalyticsBar(
      {required this.label, required this.value, required this.fraction});
  final String label;
  final int value;
  final double fraction;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          children: [
            Row(
              children: [
                Expanded(
                    child:
                        Text(label, style: GoogleFonts.poppins(fontSize: 12))),
                Text('$value',
                    style: GoogleFonts.poppins(fontWeight: FontWeight.w600)),
              ],
            ),
            const SizedBox(height: 6),
            LinearProgressIndicator(
              value: fraction,
              minHeight: 8,
              borderRadius: BorderRadius.circular(4),
              color: AppColors.primary,
              backgroundColor: AppColors.primary.withValues(alpha: .1),
            ),
          ],
        ),
      );
}

class _FeedbackReviewPanel extends StatefulWidget {
  const _FeedbackReviewPanel({
    required this.feedback,
    required this.onSubmit,
  });
  final Map<String, dynamic> feedback;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSubmit;

  @override
  State<_FeedbackReviewPanel> createState() => _FeedbackReviewPanelState();
}

class _FeedbackReviewPanelState extends State<_FeedbackReviewPanel> {
  late final TextEditingController _notes;
  late String _status;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _status = '${widget.feedback['status'] ?? 'new'}';
    _notes =
        TextEditingController(text: '${widget.feedback['admin_notes'] ?? ''}');
  }

  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit({
        'status': _status,
        'admin_notes': _notes.text.trim(),
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.feedback;
    final isIssue = item['feedback_type'] == 'issue';
    final rating = (item['rating'] as num?)?.toInt() ?? 0;
    final location = [item['city'], item['region'], item['country']]
        .map((value) => '${value ?? ''}'.trim())
        .where((value) => value.isNotEmpty)
        .join(', ');
    final contactAllowed = item['consent_to_contact'] == true;
    return _ModalFrame(
      title: isIssue ? 'Review issue report' : 'Review product feedback',
      subtitle:
          '${item['batch_number'] ?? 'No batch supplied'} - ${_formatTraceDate(item['created_at'])}',
      icon:
          isIssue ? Icons.report_problem_outlined : Icons.rate_review_outlined,
      saving: _saving,
      error: _error,
      onSave: _submit,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: (isIssue ? Colors.deepOrange : AppColors.primary)
                  .withValues(alpha: .07),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: 8,
                  runSpacing: 6,
                  children: [
                    _StatusPill(
                        text: '${item['category'] ?? 'other'}',
                        color: isIssue ? Colors.deepOrange : AppColors.primary),
                    if (rating > 0)
                      _StatusPill(
                          text: '$rating / 5 stars', color: Colors.amber),
                  ],
                ),
                const SizedBox(height: 10),
                Text('${item['message'] ?? ''}',
                    style: GoogleFonts.poppins(fontSize: 13, height: 1.5)),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _ReviewInfo(
                  icon: Icons.location_on_outlined,
                  label: location.isEmpty ? 'Location unavailable' : location),
              _ReviewInfo(
                  icon: Icons.devices_outlined,
                  label:
                      '${item['device_type'] ?? 'unknown'} | ${item['browser'] ?? 'Unknown'} | ${item['operating_system'] ?? 'Unknown'}'),
              _ReviewInfo(
                  icon: Icons.shield_outlined,
                  label: 'IP ${item['ip_masked'] ?? 'unknown'}'),
              if ('${item['timezone'] ?? ''}'.isNotEmpty ||
                  '${item['isp'] ?? ''}'.isNotEmpty)
                _ReviewInfo(
                    icon: Icons.language_rounded,
                    label:
                        '${item['timezone'] ?? ''}${'${item['timezone'] ?? ''}'.isNotEmpty && '${item['isp'] ?? ''}'.isNotEmpty ? ' | ' : ''}${item['isp'] ?? ''}'),
            ],
          ),
          if (contactAllowed) ...[
            const SizedBox(height: 12),
            _ReviewInfo(
              icon: Icons.alternate_email_rounded,
              label:
                  '${item['contact_name'] ?? 'Consumer'} - ${item['contact_email'] ?? ''}',
            ),
          ],
          const SizedBox(height: 16),
          _modalDropdown(
            label: 'Review Status',
            icon: Icons.fact_check_outlined,
            value: _status,
            values: const {
              'new': 'New',
              'reviewing': 'Reviewing',
              'resolved': 'Resolved',
              'closed': 'Closed',
            },
            onChanged: (value) => setState(() => _status = value),
          ),
          const SizedBox(height: 12),
          _modalField(
            _notes,
            'Internal Notes',
            'Record the investigation or resolution for your team',
            Icons.edit_note_rounded,
            lines: 4,
          ),
        ],
      ),
    );
  }
}

class _ReviewInfo extends StatelessWidget {
  const _ReviewInfo({required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) => Container(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width < 600
              ? MediaQuery.sizeOf(context).width - 88
              : 480,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: .04)
              : AppColors.neutral50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(
          children: [
            Icon(icon, size: 15, color: AppColors.primary),
            const SizedBox(width: 6),
            Expanded(
              child: Text(label,
                  style: GoogleFonts.poppins(fontSize: 10),
                  overflow: TextOverflow.ellipsis),
            ),
          ],
        ),
      );
}

class _PublicationPanel extends StatefulWidget {
  const _PublicationPanel({required this.batch, required this.onSubmit});
  final Map<String, dynamic> batch;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSubmit;

  @override
  State<_PublicationPanel> createState() => _PublicationPanelState();
}

class _PublicationPanelState extends State<_PublicationPanel> {
  late final TextEditingController _region;
  late final TextEditingController _packaging;
  late final TextEditingController _quality;
  late final TextEditingController _message;
  late bool _published;
  late String _recall;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _region =
        TextEditingController(text: '${widget.batch['farm_region'] ?? ''}');
    _packaging =
        TextEditingController(text: '${widget.batch['packaging_label'] ?? ''}');
    _quality = TextEditingController(
        text: '${widget.batch['quality_status'] ?? 'Verified'}');
    _message =
        TextEditingController(text: '${widget.batch['public_message'] ?? ''}');
    _published = widget.batch['published'] == true;
    _recall = '${widget.batch['recall_status'] ?? 'none'}';
  }

  @override
  void dispose() {
    _region.dispose();
    _packaging.dispose();
    _quality.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit({
        'published': _published,
        'farm_region': _region.text.trim(),
        'packaging_label': _packaging.text.trim(),
        'quality_status': _quality.text.trim(),
        'public_message': _message.text.trim(),
        'recall_status': _recall,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ModalFrame(
        title: 'Publish product record',
        subtitle:
            '${widget.batch['batch_number']} - ${widget.batch['product_name']}',
        icon: Icons.qr_code_2_rounded,
        saving: _saving,
        error: _error,
        onSave: _submit,
        child: Column(
          children: [
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: Text('Available to consumers',
                  style: GoogleFonts.poppins(fontWeight: FontWeight.w500)),
              subtitle: Text('Creates a stable public token and product URL',
                  style: GoogleFonts.poppins(fontSize: 11)),
              value: _published,
              onChanged: (value) => setState(() => _published = value),
            ),
            const SizedBox(height: 12),
            _modalPair(
              context,
              _modalField(_region, 'Farm Region', 'e.g. Greater Accra',
                  Icons.location_on_outlined),
              _modalField(_packaging, 'Packaging Label',
                  'e.g. 500g sealed pack', Icons.inventory_2_outlined),
            ),
            const SizedBox(height: 12),
            _modalPair(
              context,
              _modalField(_quality, 'Quality Status', 'e.g. Verified',
                  Icons.verified_outlined),
              _modalDropdown(
                label: 'Consumer Safety Status',
                icon: Icons.health_and_safety_outlined,
                value: _recall,
                values: const {
                  'none': 'No recall',
                  'advisory': 'Advisory',
                  'recalled': 'Recalled',
                },
                onChanged: (value) => setState(() => _recall = value),
              ),
            ),
            const SizedBox(height: 12),
            _modalField(
                _message,
                'Public Message',
                'Message shown with this verified product',
                Icons.message_outlined,
                lines: 3),
          ],
        ),
      );
}

class _PromotionPanel extends StatefulWidget {
  const _PromotionPanel(
      {required this.promotion, required this.batches, required this.onSubmit});
  final Map<String, dynamic>? promotion;
  final List<Map<String, dynamic>> batches;
  final Future<Map<String, dynamic>> Function(Map<String, dynamic>) onSubmit;

  @override
  State<_PromotionPanel> createState() => _PromotionPanelState();
}

class _PromotionPanelState extends State<_PromotionPanel> {
  late final TextEditingController _title;
  late final TextEditingController _message;
  late final TextEditingController _image;
  late final TextEditingController _destination;
  late final TextEditingController _region;
  late String _status;
  String _batchId = '';
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final p = widget.promotion ?? {};
    _title = TextEditingController(text: '${p['title'] ?? ''}');
    _message = TextEditingController(text: '${p['message'] ?? ''}');
    _image = TextEditingController(text: '${p['image_url'] ?? ''}');
    _destination = TextEditingController(text: '${p['destination_url'] ?? ''}');
    _region = TextEditingController(text: '${p['target_region'] ?? ''}');
    _status = '${p['status'] ?? 'draft'}';
    _batchId = '${p['target_batch_id'] ?? ''}';
  }

  @override
  void dispose() {
    _title.dispose();
    _message.dispose();
    _image.dispose();
    _destination.dispose();
    _region.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_title.text.trim().isEmpty || _message.text.trim().isEmpty) {
      setState(() => _error = 'Title and message are required.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSubmit({
        'title': _title.text.trim(),
        'message': _message.text.trim(),
        'image_url': _image.text.trim(),
        'destination_url': _destination.text.trim(),
        'target_region': _region.text.trim(),
        'target_batch_id': _batchId,
        'status': _status,
        'priority': 0,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) => _ModalFrame(
        title: widget.promotion == null ? 'Create promotion' : 'Edit promotion',
        subtitle: 'Shown only after a consumer verifies a published product',
        icon: Icons.campaign_outlined,
        saving: _saving,
        error: _error,
        onSave: _submit,
        child: Column(
          children: [
            _modalPair(
              context,
              _modalField(_title, 'Campaign Title', 'e.g. Harvest Week Offer',
                  Icons.title_rounded),
              _modalDropdown(
                label: 'Status',
                icon: Icons.toggle_on_outlined,
                value: _status,
                values: const {
                  'draft': 'Draft',
                  'active': 'Active',
                  'paused': 'Paused',
                  'expired': 'Expired',
                },
                onChanged: (value) => setState(() => _status = value),
              ),
            ),
            const SizedBox(height: 12),
            _modalField(
                _message,
                'Consumer Message',
                'Promotion text shown after verification',
                Icons.message_outlined,
                lines: 3),
            const SizedBox(height: 12),
            _modalPair(
              context,
              _modalDropdown(
                label: 'Target Batch',
                icon: Icons.qr_code_rounded,
                value: widget.batches
                        .any((item) => '${item['batch_id']}' == _batchId)
                    ? _batchId
                    : '',
                values: {
                  '': 'All published batches',
                  for (final batch in widget.batches)
                    '${batch['batch_id']}':
                        '${batch['batch_number']} - ${batch['product_name']}',
                },
                onChanged: (value) => setState(() => _batchId = value),
              ),
              _modalField(_region, 'Target Region', 'Optional region filter',
                  Icons.location_on_outlined),
            ),
            const SizedBox(height: 12),
            _modalPair(
              context,
              _modalField(_image, 'Campaign Image URL', 'https://...',
                  Icons.image_outlined),
              _modalField(_destination, 'Action URL', 'https://...',
                  Icons.open_in_new_rounded),
            ),
          ],
        ),
      );
}

class _ModalFrame extends StatelessWidget {
  const _ModalFrame(
      {required this.title,
      required this.subtitle,
      required this.icon,
      required this.saving,
      required this.onSave,
      required this.child,
      this.error});
  final String title;
  final String subtitle;
  final IconData icon;
  final bool saving;
  final String? error;
  final VoidCallback onSave;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mobile = MediaQuery.sizeOf(context).width < 600;
    return Material(
      color: Theme.of(context).brightness == Brightness.dark
          ? AppColors.surfaceDark
          : Colors.white,
      borderRadius: mobile
          ? const BorderRadius.vertical(top: Radius.circular(18))
          : BorderRadius.circular(16),
      clipBehavior: Clip.antiAlias,
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: mobile ? MediaQuery.sizeOf(context).height * .9 : null,
          child: Column(
            children: [
              if (mobile)
                Container(
                  width: 42,
                  height: 4,
                  margin: const EdgeInsets.only(top: 10),
                  decoration: BoxDecoration(
                      color: Colors.grey.shade400,
                      borderRadius: BorderRadius.circular(4)),
                ),
              Padding(
                padding: EdgeInsets.fromLTRB(24, mobile ? 16 : 24, 16, 16),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary,
                            AppColors.primary.withValues(alpha: .75),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(title,
                              style: GoogleFonts.poppins(
                                  fontSize: 16, fontWeight: FontWeight.w700)),
                          Text(subtitle,
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.poppins(
                                  fontSize: 12,
                                  color: Theme.of(context)
                                      .colorScheme
                                      .onSurfaceVariant)),
                        ],
                      ),
                    ),
                    IconButton(
                        onPressed: saving ? null : () => Navigator.pop(context),
                        icon: const Icon(Icons.close_rounded, size: 18)),
                  ],
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: .05)
                    : Colors.black.withValues(alpha: .05),
              ),
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      if (error != null) ...[
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: .08),
                              border: Border.all(
                                  color: Colors.red.withValues(alpha: .2)),
                              borderRadius: BorderRadius.circular(10)),
                          child: Text(error!,
                              style: GoogleFonts.poppins(
                                  fontSize: 12, color: Colors.red.shade700)),
                        ),
                        const SizedBox(height: 14),
                      ],
                      child,
                    ],
                  ),
                ),
              ),
              Divider(
                height: 1,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white.withValues(alpha: .05)
                    : Colors.black.withValues(alpha: .05),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
                child: Row(
                  children: [
                    Expanded(
                        child: OutlinedButton(
                            onPressed:
                                saving ? null : () => Navigator.pop(context),
                            child:
                                Text('Cancel', style: GoogleFonts.poppins()))),
                    const SizedBox(width: 8),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: saving ? null : onSave,
                        icon: saving
                            ? const SizedBox(
                                width: 17,
                                height: 17,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2, color: Colors.white))
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(saving ? 'Saving...' : 'Save',
                            style: GoogleFonts.poppins()),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
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
    );
  }
}

Widget _modalPair(BuildContext context, Widget first, Widget second) {
  if (MediaQuery.sizeOf(context).width < 600) {
    return Column(
      children: [first, const SizedBox(height: 12), second],
    );
  }
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Expanded(child: first),
      const SizedBox(width: 10),
      Expanded(child: second),
    ],
  );
}

Widget _modalField(
  TextEditingController controller,
  String label,
  String hint,
  IconData icon, {
  int lines = 1,
}) =>
    Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modalLabel(context, label),
          const SizedBox(height: 6),
          TextFormField(
            controller: controller,
            maxLines: lines,
            style: GoogleFonts.poppins(fontSize: 12),
            decoration: _modalDecoration(context, hint, icon),
          ),
        ],
      ),
    );

Widget _modalDropdown({
  required String label,
  required IconData icon,
  required String value,
  required Map<String, String> values,
  required ValueChanged<String> onChanged,
}) =>
    Builder(
      builder: (context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _modalLabel(context, label),
          const SizedBox(height: 6),
          DropdownButtonFormField<String>(
            initialValue: values.containsKey(value) ? value : values.keys.first,
            isExpanded: true,
            style: GoogleFonts.poppins(
              fontSize: 12,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : AppColors.textPrimary,
            ),
            dropdownColor: Theme.of(context).brightness == Brightness.dark
                ? AppColors.surfaceDark
                : Colors.white,
            decoration: _modalDecoration(context, '', icon),
            items: values.entries
                .map((entry) => DropdownMenuItem(
                      value: entry.key,
                      child: Text(entry.value, overflow: TextOverflow.ellipsis),
                    ))
                .toList(),
            onChanged: (selected) {
              if (selected != null) onChanged(selected);
            },
          ),
        ],
      ),
    );

Widget _modalLabel(BuildContext context, String label) => Text(
      label,
      style: GoogleFonts.poppins(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white54
            : AppColors.textSecondary,
      ),
    );

InputDecoration _modalDecoration(
        BuildContext context, String hint, IconData icon) =>
    InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.poppins(
        fontSize: 12,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white24
            : AppColors.textSecondary,
      ),
      prefixIcon: Icon(
        icon,
        size: 16,
        color: Theme.of(context).brightness == Brightness.dark
            ? Colors.white24
            : AppColors.textSecondary,
      ),
      filled: true,
      fillColor: Theme.of(context).brightness == Brightness.dark
          ? Colors.white.withValues(alpha: .04)
          : AppColors.neutral50,
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: .06)
              : Colors.black.withValues(alpha: .06),
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: BorderSide(
          color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withValues(alpha: .06)
              : Colors.black.withValues(alpha: .06),
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(10),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
    );
