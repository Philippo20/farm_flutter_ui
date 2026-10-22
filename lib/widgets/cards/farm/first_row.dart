import 'dart:async';
import '../../../services/light_switch_service.dart';
import '../../../services/controller_equipment_monitor.dart';
import '../../../services/device_presence.dart';
import '../../../services/foreground_refresh.dart';
import '../../../core/widgets/controller_equipment_status.dart';
import 'batch_growth_tracker.dart';
import '../../../core/theme/app_typography.dart';
import 'package:flutter/material.dart';
import '../../../constants/colors.dart';
import 'package:intl/intl.dart';

class FirstRow extends StatefulWidget {
  final LightSwitchService? lightSwitchService;
  final bool isDark;
  final List<Map<String, dynamic>> devices;
  final List<Map<String, dynamic>> batches;
  final List<Map<String, dynamic>> records;
  final String userName;

  const FirstRow(
      {super.key,
      required this.isDark,
      this.lightSwitchService,
      this.devices = const [],
      this.userName = '',
      this.batches = const [],
      this.records = const []});

  @override
  State<FirstRow> createState() => _FirstRowState();
}

class _FirstRowState extends State<FirstRow> with WidgetsBindingObserver {
  late final _switchService = widget.lightSwitchService ?? LightSwitchService();
  final _lightStates = <String, Map<String, dynamic>>{};
  final _lightErrors = <String, String>{};
  final _lightCommandErrors = <String, String>{};
  final _submitting = <String>{};
  final _revision = <String, int>{};
  final _clock = Stopwatch()..start();
  final _presence = <String, DevicePresence>{};
  late final _equipment = ControllerEquipmentMonitor(presenceOnly: true);
  late final ForegroundRefresh _lightRefresh;
  Timer? _lightExpiry;
  bool _active = true;
  List<Map<String, dynamic>> get _lights => widget.devices
      .where((d) => '${d['sensortype'] ?? d['type']}' == 'light_switch')
      .toList()
    ..sort(
        (a, b) => '${a['serial_number']}'.compareTo('${b['serial_number']}'));
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _equipment.setDevices(widget.devices);
    _lightRefresh = ForegroundRefresh(
        fetch: _refreshLights,
        cancelFetch: _switchService.cancelPolling,
        interval: const Duration(seconds: 2));
    unawaited(_lightRefresh.refresh());
  }

  @override
  void didUpdateWidget(covariant FirstRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    _equipment.setDevices(widget.devices);
    if (_lights.any((d) => !_lightStates.containsKey('${d['serial_number']}')))
      unawaited(_lightRefresh.refresh());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _lightRefresh.dispose();
    _lightExpiry?.cancel();
    _equipment.dispose();
    if (widget.lightSwitchService == null) _switchService.dispose();
    _clock.stop();
    super.dispose();
  }

  Future<void> _refreshLights(RefreshTicket ticket) async {
    if (!mounted || !ticket.isCurrent) return;
    await Future.wait(_lights.map((device) async {
      final serial = '${device['serial_number']}';
      if (_submitting.contains(serial)) return;
      final revision = _revision[serial] ?? 0;
      try {
        final state = await _switchService.state(serial);
        if (!mounted ||
            !ticket.isCurrent ||
            _submitting.contains(serial) ||
            revision != (_revision[serial] ?? 0)) return;
        setState(() {
          _lightStates[serial] = state;
          (_presence[serial] ??=
                  DevicePresence(grace: const Duration(seconds: 15)))
              .accept(state, _clock.elapsedMilliseconds);
          _lightErrors.remove(serial);
        });
      } catch (error) {
        if (mounted &&
            ticket.isCurrent &&
            !_submitting.contains(serial) &&
            revision == (_revision[serial] ?? 0))
          setState(() => _lightErrors[serial] = '$error');
      }
    }));
    if (mounted && ticket.isCurrent) _scheduleLightExpiry();
  }

  bool _lightOnline(String serial) {
    return _active &&
        _presence[serial]?.online(_clock.elapsedMilliseconds) == true;
  }

  void _scheduleLightExpiry() {
    _lightExpiry?.cancel();
    if (!mounted || !_active) return;
    final deadlines = _presence.values
        .map((p) => p.expiresIn(_clock.elapsedMilliseconds))
        .whereType<int>()
        .toList()
      ..sort();
    if (deadlines.isEmpty) return;
    _lightExpiry = Timer(Duration(milliseconds: deadlines.first), () {
      if (!mounted || !_active) return;
      setState(() {});
      _scheduleLightExpiry();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive) return;
    final active = state == AppLifecycleState.resumed;
    if (active == _active) return;
    _active = active;
    _lightExpiry?.cancel();
    for (final serial in _presence.keys) {
      _presence[serial]!.reset();
      _revision[serial] = (_revision[serial] ?? 0) + 1;
    }
    _lightErrors.clear();
    _lightCommandErrors.clear();
    if (mounted) setState(() {});
  }

  Future<void> _toggleLight(String serial) async {
    final state = _lightStates[serial];
    if (!_lightOnline(serial) ||
        state?['pending'] == true ||
        state?['reported_on'] is! bool ||
        _submitting.contains(serial)) return;
    final desired = !(state!['reported_on'] as bool);
    setState(() {
      _submitting.add(serial);
      _lightCommandErrors.remove(serial);
      _revision[serial] = (_revision[serial] ?? 0) + 1;
      _lightStates[serial] = {...state, 'desired_on': desired};
    });
    final revision = _revision[serial];
    try {
      final result = await _switchService.command(
          serial, desired, _switchService.requestId());
      if (!mounted || !_active || revision != _revision[serial]) return;
      setState(() {
        _lightStates[serial] = result;
        (_presence[serial] ??=
                DevicePresence(grace: const Duration(seconds: 15)))
            .accept(result, _clock.elapsedMilliseconds);
        _lightErrors.remove(serial);
        _lightCommandErrors.remove(serial);
      });
    } catch (error) {
      if (mounted && _active && revision == _revision[serial])
        setState(() => _lightCommandErrors[serial] = '$error');
    } finally {
      if (mounted) setState(() => _submitting.remove(serial));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _buildGreetingContainer(),
        SizedBox(height: 16),
        _buildDateTime(),
        SizedBox(height: 16),
        _buildOutsideTemp(),
        SizedBox(height: 20),
        _buildTitle("Grow Stage Tracker", 30),
        SizedBox(height: 16),
        BatchGrowthTracker(batches: widget.batches, records: widget.records),
        SizedBox(height: 16),
        _buildTitle("Farm Equipment Status", 25),
        SizedBox(height: 16),
        _buildTabCard(isDark: widget.isDark),
      ],
    );
  }

  Widget _buildGreetingContainer() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[800] : Colors.white,
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
          // Home icon with rounded background
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: widget.isDark ? Colors.blueGrey[800] : Colors.green[100],
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.home,
              color: widget.isDark ? Colors.white : AppColors.primary,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Greeting text column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.userName.trim().isEmpty
                      ? 'Welcome back'
                      : 'Hello, ${widget.userName}',
                  style: AppTypography.font(
                    fontSize: AppTypography.cardTitleSize,
                    fontWeight: AppTypography.headingWeight,
                    color: widget.isDark ? Colors.white : Colors.black,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Good Afternoon',
                  style: AppTypography.font(
                    fontSize: AppTypography.captionSize,
                    color: widget.isDark ? Colors.grey[400] : Colors.grey[600],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDateTime() {
    final now = DateTime.now();
    final time = DateFormat('hh:mm a').format(now); // e.g., 02:07 PM
    final date = DateFormat('MMM d, yyyy').format(now); // e.g., Jul 2, 2025

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          // Clock icon
          Container(
            padding: const EdgeInsets.all(15),
            child: Icon(
              Icons.date_range,
              color: widget.isDark ? Colors.white : AppColors.primary,
              size: 20,
            ),
          ),
          const SizedBox(width: 16),

          // Time and date
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text("Date & Time",
                    style: AppTypography.font(
                        fontSize: AppTypography.cardTitleSize,
                        fontWeight: AppTypography.headingWeight,
                        color: widget.isDark ? Colors.white : Colors.black)),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 12,
                  runSpacing: 2,
                  children: [
                    Text(
                      time,
                      style: AppTypography.font(
                        fontSize: AppTypography.bodySize,
                        color:
                            widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                    Text(
                      date,
                      style: AppTypography.font(
                        fontSize: AppTypography.bodySize,
                        color:
                            widget.isDark ? Colors.grey[400] : Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOutsideTemp() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: widget.isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(12),
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
          // Weather icon
          Container(
            padding: const EdgeInsets.all(15),
            decoration: BoxDecoration(
              color: widget.isDark
                  ? Colors.blueGrey[700]
                  : Colors.orange.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.wb_sunny_rounded,
              color: widget.isDark ? Colors.yellow[200] : Colors.orange,
              size: 24,
            ),
          ),
          const SizedBox(width: 16),

          // Two columns inside Expanded
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Column 1: Weather Type + Outside Temp label
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Partly Cloudy",
                        style: AppTypography.font(
                          fontSize: AppTypography.sectionTitleSize,
                          fontWeight: AppTypography.headingWeight,
                          color: widget.isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Outside Temperature",
                        style: AppTypography.font(
                          fontSize: AppTypography.captionSize,
                          color: widget.isDark
                              ? Colors.grey[400]
                              : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                // Column 2: Temperature + Humidity
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      "28°C",
                      style: AppTypography.font(
                        fontSize: AppTypography.pageTitleSize,
                        fontWeight: AppTypography.headingWeight,
                        color: widget.isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.thermostat,
                          color: widget.isDark
                              ? Colors.yellow[200]
                              : Colors.orange,
                          size: 15,
                        ),
                        Text(
                          " 60%",
                          style: AppTypography.font(
                            fontSize: AppTypography.captionSize,
                            color: widget.isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTitle(String title, double fontSize) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Text(
        title,
        style: AppTypography.font(
          fontSize: AppTypography.resolveSize(fontSize),
          fontWeight: AppTypography.labelWeight,
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
                  _equipmentTab(
                    icon: Icons.lightbulb_outline,
                    label: 'Lights',
                    compact: compactTabs,
                  ),
                  _equipmentTab(
                    icon: Icons.water,
                    label: 'Pumps',
                    compact: compactTabs,
                  ),
                  _equipmentTab(
                    icon: Icons.science_outlined,
                    label: 'pH / Air',
                    compact: compactTabs,
                  ),
                ],
              );
            }),

            const SizedBox(height: 12),

            // Tab Content
            LayoutBuilder(builder: (context, constraints) {
              final compactContent = constraints.maxWidth < 340;
              return SizedBox(
                height: compactContent ? 280 : 210,
                child: TabBarView(
                  children: [
                    SingleChildScrollView(child: _tabCardContentLights(isDark)),
                    SingleChildScrollView(child: _tabCardContentPumps(isDark)),
                    SingleChildScrollView(child: _tabCardContentPhAir(isDark)),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _equipmentTab({
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
              style: const TextStyle(fontSize: AppTypography.bodySize),
            ),
          ),
        ],
      ),
    );
  }

  Widget _tabCardContentLights(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Text(
            "Rack Lights",
            style: AppTypography.font(
              fontSize: AppTypography.cardTitleSize,
              fontWeight: AppTypography.headingWeight,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        if (_lights.isEmpty &&
            !widget.devices.any((d) => d['sensortype'] == 'grow_light'))
          Padding(
              padding: const EdgeInsets.all(8),
              child: Text('No light switches registered for your farms.',
                  style: AppTypography.bodySmall)),
        _equipmentCardRow([
          for (final device in _lights) _registeredLightCard(device, isDark),
          for (final device
              in widget.devices.where((d) => d['sensortype'] == 'grow_light'))
            ControllerEquipmentStatus(
                key: ValueKey(device[r'$id']),
                device: device,
                monitor: _equipment,
                compact: true),
        ]),
        if (_active &&
            (_lightCommandErrors.isNotEmpty ||
                _lightErrors.entries.any((e) => !_lightOnline(e.key))))
          Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                  (_lightCommandErrors.isNotEmpty
                          ? _lightCommandErrors.values.first
                          : _lightErrors.entries
                              .firstWhere((e) => !_lightOnline(e.key))
                              .value)
                      .replaceFirst('Exception: ', ''),
                  style: AppTypography.bodySmall
                      .copyWith(color: Colors.redAccent))),
      ],
    );
  }

  Widget _tabCardContentPumps(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Text(
            "Pump Controls",
            style: AppTypography.font(
              fontSize: AppTypography.cardTitleSize,
              fontWeight: AppTypography.headingWeight,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        _equipmentCardRow([
          for (final device in widget.devices.where((d) =>
              ['feeding_pump', 'drainage_pump'].contains(d['sensortype'])))
            ControllerEquipmentStatus(
                key: ValueKey(device[r'$id']),
                device: device,
                monitor: _equipment,
                compact: true),
        ]),
        if (!widget.devices.any(
            (d) => ['feeding_pump', 'drainage_pump'].contains(d['sensortype'])))
          Padding(
              padding: const EdgeInsets.all(8),
              child: Text('No pumps registered for your farms.',
                  style: AppTypography.bodySmall)),
      ],
    );
  }

  Widget _tabCardContentPhAir(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 8.0),
          child: Text(
            "pH & Air Monitoring",
            style: AppTypography.font(
              fontSize: AppTypography.cardTitleSize,
              fontWeight: AppTypography.headingWeight,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
        _equipmentCardRow([
          for (final device in widget.devices.where(
              (d) => ['air_conditioner', 'pH Level'].contains(d['sensortype'])))
            Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: Theme.of(context).colorScheme.outlineVariant)),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                          device['sensortype'] == 'air_conditioner'
                              ? Icons.air
                              : Icons.science_outlined,
                          color: Theme.of(context).colorScheme.primary),
                      const SizedBox(height: 8),
                      Text('${device['model_number']}',
                          style: AppTypography.titleSmall),
                      Text('Serial: ${device['serial_number']}',
                          style: AppTypography.bodySmall),
                      Text('Condition: ${device['status']}',
                          style: AppTypography.bodySmall),
                      Text('Live output not linked',
                          style: AppTypography.bodySmall),
                    ])),
        ]),
        if (!widget.devices.any(
            (d) => ['air_conditioner', 'pH Level'].contains(d['sensortype'])))
          Padding(
              padding: const EdgeInsets.all(8),
              child: Text('No pH or air equipment registered for your farms.',
                  style: AppTypography.bodySmall)),
      ],
    );
  }

  Widget _equipmentCardRow(List<Widget> children) {
    return LayoutBuilder(builder: (context, constraints) {
      final gap = constraints.maxWidth < 340 ? 8.0 : 10.0;
      final columns = constraints.maxWidth >= 340 ? 3 : 2;
      final cardWidth =
          (constraints.maxWidth - ((columns - 1) * gap)) / columns;
      return Wrap(
        spacing: gap,
        runSpacing: gap,
        children: children
            .map((child) => SizedBox(width: cardWidth, child: child))
            .toList(),
      );
    });
  }

  /// TAB MORE FEATURES
  /// LIGHTS, PUMPS, PH/AIR
  Widget _registeredLightCard(Map<String, dynamic> device, bool isDark) {
    final serial = '${device['serial_number']}';
    final state = _lightStates[serial];
    final online = _lightOnline(serial);
    final pending = _submitting.contains(serial) || state?['pending'] == true;
    final label = pending
        ? (state?['desired_on'] == false ? 'TURNING OFF…' : 'TURNING ON…')
        : _lightErrors.containsKey(serial) && !online
            ? 'UNAVAILABLE'
            : state == null
                ? 'CONNECTING…'
                : !online
                    ? 'OFFLINE'
                    : state['reported_on'] == true
                        ? 'ON'
                        : 'OFF';
    return Tooltip(
        message: '$serial — $label',
        child: Semantics(
            button: true,
            enabled: online && !pending,
            label: '$serial, $label',
            child: InkWell(
              onTap: online && !pending ? () => _toggleLight(serial) : null,
              borderRadius: BorderRadius.circular(12),
              child: _lightStatusCard(
                  '${device['location'] ?? device['model_number'] ?? serial}',
                  online && state?['reported_on'] == true,
                  isDark,
                  statusLabel: label),
            )));
  }

  Widget _lightStatusCard(String name, bool isActive, bool isDark,
      {String? statusLabel}) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.grey[100],
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
          Icon(
            Icons.lightbulb,
            color: isActive
                ? (isDark ? Colors.greenAccent : Colors.green)
                : Colors.grey,
            size: 30,
          ),
          const SizedBox(height: 8),
          Text(
            name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.font(
              fontSize: AppTypography.bodySize,
              fontWeight: AppTypography.headingWeight,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            statusLabel ?? (isActive ? "ACTIVE" : "NOT ACTIVE"),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: AppTypography.font(
              fontSize: AppTypography.captionSize,
              fontWeight: AppTypography.labelWeight,
              color: isActive
                  ? (isDark ? Colors.greenAccent : Colors.green)
                  : Colors.redAccent,
            ),
          ),
        ],
      ),
    );
  }
}
