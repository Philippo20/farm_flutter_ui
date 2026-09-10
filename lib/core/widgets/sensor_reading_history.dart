import 'sensor_readings_chart.dart';
import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../services/superadmin_api_service.dart';

class SensorReadingHistory extends StatefulWidget {
  const SensorReadingHistory(
      {super.key,
      required this.serialNumber,
      this.loadReadings,
      this.sensor = const {},
      this.compact = false});
  final bool compact;
  final String serialNumber;
  final Map<String, dynamic> sensor;
  final Future<List<Map<String, dynamic>>> Function(String)? loadReadings;
  @override
  State<SensorReadingHistory> createState() => _SensorReadingHistoryState();
}

class _SensorReadingHistoryState extends State<SensorReadingHistory> {
  final _api = SuperAdminApiService();
  Timer? _timer;
  bool _loading = false;
  String? _error;
  List<Map<String, dynamic>> _readings = [];
  int _visible = 20;
  bool _showRecords = false;
  @override
  void initState() {
    super.initState();
    _load();
    _timer = Timer.periodic(const Duration(seconds: 30), (_) => _load());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _load() async {
    if (_loading || widget.serialNumber.isEmpty) return;
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await (widget.loadReadings ??
          _api.getSensorReadings)(widget.serialNumber);
      rows.sort((a, b) => (DateTime.tryParse('${b['timestamp']}') ??
              DateTime(1970))
          .compareTo(DateTime.tryParse('${a['timestamp']}') ?? DateTime(1970)));
      if (mounted) setState(() => _readings = rows);
    } catch (_) {
      if (mounted)
        setState(
            () => _error = 'Unable to refresh readings. Please try again.');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = GoogleFonts.inter(fontSize: 12);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
            child: Text(widget.compact ? 'Recent trend' : 'Reading history',
                style: GoogleFonts.inter(
                    fontSize: 12, fontWeight: FontWeight.w600))),
        IconButton(
            tooltip: 'Refresh readings',
            onPressed: _loading || widget.serialNumber.isEmpty ? null : _load,
            icon: _loading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2))
                : const Icon(Icons.refresh, size: 18))
      ]),
      Text(
          widget.compact
              ? 'Updates every 30 seconds'
              : 'Latest 500 saved readings · refreshes every 30 seconds',
          style: GoogleFonts.inter(fontSize: 11, color: secondary)),
      const SizedBox(height: 12),
      if (widget.serialNumber.isEmpty)
        Text(
            'Reading history is unavailable: this sensor has no serial number.',
            style: style)
      else if (_error != null)
        Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Text(_error!,
                style:
                    style.copyWith(color: Theme.of(context).colorScheme.error)))
      else if (!_loading && _readings.isEmpty)
        Text('No readings recorded yet.', style: style),
      if (_readings.isNotEmpty) ...[
        SensorReadingsChart(
            readings: _readings,
            sensor: widget.sensor,
            compact: widget.compact),
        if (!widget.compact)
          TextButton.icon(
            onPressed: () => setState(() => _showRecords = !_showRecords),
            icon: Icon(_showRecords ? Icons.expand_less : Icons.list_alt,
                size: 16),
            label: Text(
                _showRecords ? 'Hide reading records' : 'Show reading records'),
          ),
      ],
      for (final reading in (_showRecords
          ? _readings.take(_visible)
          : <Map<String, dynamic>>[]))
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      spacing: 12,
                      runSpacing: 6,
                      children: [
                        Text(
                            '${reading['value'] ?? '—'} ${reading['unit'] ?? ''}',
                            style: style.copyWith(fontWeight: FontWeight.w600)),
                        Text('${reading['status'] ?? 'Unknown'}',
                            style: style.copyWith(color: secondary))
                      ]),
                  const SizedBox(height: 5),
                  Text(_timestamp(reading['timestamp']),
                      style: GoogleFonts.inter(fontSize: 11, color: secondary)),
                  if ('${reading['source'] ?? ''}'.isNotEmpty)
                    Text('Source: ${reading['source']}',
                        style:
                            GoogleFonts.inter(fontSize: 11, color: secondary)),
                ])),
      if (_showRecords && _visible < _readings.length)
        TextButton(
            onPressed: () => setState(() => _visible += 20),
            child: const Text('Show more readings')),
    ]);
  }

  String _timestamp(dynamic raw) {
    final time = DateTime.tryParse('$raw');
    return time == null
        ? 'Timestamp unavailable'
        : DateFormat('d MMM yyyy, HH:mm:ss').format(time.toLocal());
  }
}
