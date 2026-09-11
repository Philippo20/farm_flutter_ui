import '../theme/app_typography.dart';
import 'sensor_date_range_modal.dart';
import 'app_dialog.dart';
import 'sensor_readings_chart.dart';
import 'dart:async';
import 'package:flutter/material.dart';
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
  bool _fetching = false;
  int _requestId = 0;
  String? _error;
  List<Map<String, dynamic>> _readings = [];
  int _visible = 20;
  bool _showRecords = false;
  DateTimeRange? _range;
  bool _hasMore = false;
  int _pages = 1;
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

  Future<void> _load({bool more = false, bool silent = false}) async {
    if (widget.serialNumber.isEmpty || (silent && _fetching)) return;
    final requestId = ++_requestId;
    final range = _range;
    _fetching = true;
    if (!silent)
      setState(() {
        _loading = true;
        _error = null;
      });
    try {
      final end = range == null
          ? null
          : DateTime(range.end.year, range.end.month, range.end.day + 1);
      final rows = <Map<String, dynamic>>[];
      var hasMore = false;
      final targetPages = more ? _pages + 1 : _pages;
      if (widget.loadReadings != null) {
        rows.addAll(await widget.loadReadings!(widget.serialNumber));
      } else {
        for (var page = more ? _pages : 0; page < targetPages; page++) {
          final batch = await _api.getSensorReadingsForPeriod(
              widget.serialNumber,
              start: range?.start,
              end: end,
              offset: page * 500);
          rows.addAll(batch);
          hasMore = batch.length == 500;
          if (!hasMore) break;
        }
      }
      final filtered = rows.where((row) {
        if (range == null) return true;
        final time = DateTime.tryParse(row['timestamp'].toString());
        return time != null &&
            !time.isBefore(range!.start) &&
            time.isBefore(end!);
      }).toList();
      filtered.sort((a, b) => (DateTime.tryParse('${b['timestamp']}') ??
              DateTime(1970))
          .compareTo(DateTime.tryParse('${a['timestamp']}') ?? DateTime(1970)));
      if (mounted && requestId == _requestId)
        setState(() {
          _error = null;
          _readings = more ? [..._readings, ...filtered] : filtered;
          _hasMore = hasMore;
          _pages = targetPages;
        });
    } catch (_) {
      if (mounted && requestId == _requestId && !silent)
        setState(
            () => _error = 'Unable to refresh readings. Please try again.');
    } finally {
      if (requestId == _requestId) {
        _fetching = false;
        if (mounted && !silent) setState(() => _loading = false);
      }
    }
  }

  Future<void> _selectRange() async {
    final selected = await showAppDialog<DateTimeRange>(
      context: context,
      builder: (_) => SensorDateRangeModal(initialRange: _range),
    );
    if (selected == null || !mounted) return;
    setState(() {
      _range = selected;
      _pages = 1;
      _readings = [];
      _visible = 20;
      _hasMore = false;
    });
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final secondary = Theme.of(context).colorScheme.onSurfaceVariant;
    final style = AppTypography.font(fontSize: AppTypography.captionSize);
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Row(children: [
        Expanded(
            child: Text(widget.compact ? 'Recent trend' : 'Reading history',
                style: AppTypography.font(
                    fontSize: AppTypography.captionSize, fontWeight: AppTypography.labelWeight))),
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
      Wrap(spacing: 8, runSpacing: 4, children: [
        OutlinedButton.icon(
            onPressed: _loading ? null : _selectRange,
            icon: const Icon(Icons.date_range, size: 16),
            label: Text(_range == null
                ? 'Select date range'
                : DateFormat('d MMM yy').format(_range!.start) +
                    ' – ' +
                    DateFormat('d MMM yy').format(_range!.end))),
        if (_range != null)
          TextButton(
              onPressed: _loading
                  ? null
                  : () {
                      setState(() {
                        _range = null;
                        _pages = 1;
                        _readings = [];
                        _visible = 20;
                      });
                      _load();
                    },
              child: const Text('Clear dates')),
      ]),
      Text(
          'Showing ' +
              _readings.length.toString() +
              ' readings · updates every 30 seconds',
          style: AppTypography.font(fontSize: AppTypography.fieldLabelSize, color: secondary)),
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
        Text(
            _range == null
                ? 'No readings recorded yet.'
                : 'No readings in the selected date range.',
            style: style),
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
                            style: style.copyWith(fontWeight: AppTypography.labelWeight)),
                        Text('${reading['status'] ?? 'Unknown'}',
                            style: style.copyWith(color: secondary))
                      ]),
                  const SizedBox(height: 5),
                  Text(_timestamp(reading['timestamp']),
                      style: AppTypography.font(fontSize: AppTypography.fieldLabelSize, color: secondary)),
                  if ('${reading['source'] ?? ''}'.isNotEmpty)
                    Text('Source: ${reading['source']}',
                        style:
                            AppTypography.font(fontSize: AppTypography.fieldLabelSize, color: secondary)),
                ])),
      if (_hasMore)
        TextButton(
            onPressed: _loading ? null : () => _load(more: true),
            child: const Text('Load more readings')),
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
        : DateFormat('d MMM yyyy, h:mm:ss a').format(time.toLocal());
  }
}
