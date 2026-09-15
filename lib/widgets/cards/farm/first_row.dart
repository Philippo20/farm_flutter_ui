import 'dart:async';
import '../../../services/light_switch_service.dart';
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

class _FirstRowState extends State<FirstRow> {
  late final _switchService = widget.lightSwitchService ?? LightSwitchService();
  final _lightStates = <String, Map<String, dynamic>>{};
  final _lightErrors = <String, String>{};
  final _submitting = <String>{};
  final _revision = <String, int>{};
  final _clock = Stopwatch()..start();
  final _receivedAt = <String, int>{};
  Timer? _pollLights;
  bool _polling = false;
  List<Map<String, dynamic>> get _lights => widget.devices
      .where((d) => '${d['sensortype'] ?? d['type']}' == 'light_switch')
      .toList()
    ..sort(
        (a, b) => '${a['serial_number']}'.compareTo('${b['serial_number']}'));
  @override
  void initState() {
    super.initState();
    _refreshLights();
    _pollLights =
        Timer.periodic(const Duration(seconds: 2), (_) => _refreshLights());
  }

  @override
  void didUpdateWidget(covariant FirstRow oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_lights.any((d) => !_lightStates.containsKey('${d['serial_number']}')))
      _refreshLights();
  }

  @override
  void dispose() {
    _pollLights?.cancel();
    _switchService.dispose();
    _clock.stop();
    super.dispose();
  }

  Future<void> _refreshLights() async {
    if (_polling || !mounted) return;
    _polling = true;
    try {
      await Future.wait(_lights.map((device) async {
        final serial = '${device['serial_number']}';
        if (_submitting.contains(serial)) return;
        final revision = _revision[serial] ?? 0;
        try {
          final state = await _switchService.state(serial);
          if (!mounted ||
              _submitting.contains(serial) ||
              revision != (_revision[serial] ?? 0)) return;
          setState(() {
            _lightStates[serial] = state;
            _receivedAt[serial] = _clock.elapsedMilliseconds;
            _lightErrors.remove(serial);
          });
        } catch (error) {
          if (mounted &&
              !_submitting.contains(serial) &&
              revision == (_revision[serial] ?? 0))
            setState(() => _lightErrors[serial] = '$error');
        }
      }));
    } finally {
      _polling = false;
    }
  }

  bool _lightOnline(String serial) {
    final state = _lightStates[serial];
    if (state == null ||
        state['online'] != true ||
        _lightErrors.containsKey(serial)) return false;
    final server = DateTime.tryParse('${state['server_time']}');
    final seen = DateTime.tryParse('${state['seen_at']}');
    if (server == null || seen == null) return false;
    return server.difference(seen).inMilliseconds +
            _clock.elapsedMilliseconds -
            (_receivedAt[serial] ?? 0) <=
        15000;
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
      _revision[serial] = (_revision[serial] ?? 0) + 1;
      _lightStates[serial] = {...state, 'desired_on': desired};
    });
    try {
      final result = await _switchService.command(
          serial, desired, _switchService.requestId());
      if (!mounted) return;
      setState(() {
        _lightStates[serial] = result;
        _receivedAt[serial] = _clock.elapsedMilliseconds;
        _lightErrors.remove(serial);
      });
    } catch (error) {
      if (mounted) setState(() => _lightErrors[serial] = '$error');
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
        if (_lights.isEmpty)
          Padding(
              padding: const EdgeInsets.all(8),
              child: Text('No light switches registered for your farms.',
                  style: AppTypography.bodySmall)),
        _equipmentCardRow([
          for (final device in _lights) _registeredLightCard(device, isDark)
        ]),
        if (_lightErrors.isNotEmpty)
          Padding(
              padding: const EdgeInsets.all(8),
              child: Text(
                  _lightErrors.values.first.replaceFirst('Exception: ', ''),
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
          _pumpStatusCard("Water Pump", true, isDark),
          _pumpStatusCard("Air Pump", false, isDark),
          _pumpStatusCard("Nut Pump", true, isDark),
        ]),
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
          _phAirStatusCard("pH Up", true, Icons.arrow_upward, isDark),
          _phAirStatusCard("pH Down", false, Icons.arrow_downward, isDark),
          _phAirStatusCard("Air Condition", true, Icons.air, isDark),
        ]),
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
        : _lightErrors.containsKey(serial)
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

//pump
  Widget _pumpStatusCard(String name, bool isActive, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
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
            Icons.water, // You can customize per pump if needed
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
            isActive ? "ACTIVE" : "NOT ACTIVE",
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

//
  Widget _phAirStatusCard(
      String name, bool isActive, IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(5, 10, 5, 5),
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
            icon,
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
            isActive ? "ACTIVE" : "NOT ACTIVE",
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
