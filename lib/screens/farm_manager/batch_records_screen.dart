import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../services/api_connection.dart';
import '../../services/auth_service.dart';
import '../../services/superadmin_api_service.dart';
import '../../core/theme/app_typography.dart';

class BatchRecordsScreen extends StatefulWidget {
  const BatchRecordsScreen(
      {super.key,
      required this.batchId,
      required this.batchNumber,
      required this.farmName,
      this.loadRecords});
  final String batchId, batchNumber, farmName;
  final Future<List<Map<String, dynamic>>> Function()? loadRecords;
  @override
  State<BatchRecordsScreen> createState() => _BatchRecordsScreenState();
}

class _BatchRecordsScreenState extends State<BatchRecordsScreen> {
  final _scroll = ScrollController();
  final http.Client _client = ConnectedApiClient();
  List<Map<String, dynamic>> _records = [];
  bool _loading = true, _issuesOnly = false;
  String? _error;
  String _search = '';
  Map<String, dynamic>? _selected;
  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _scroll.dispose();
    _client.close();
    super.dispose();
  }

  Future<List<Map<String, dynamic>>> _fetch() async {
    final all = <Map<String, dynamic>>[];
    var refreshed = false;
    while (true) {
      final response = await _client.get(
          Uri.parse(
              '${SuperAdminApiService.baseUrl}/batches/${Uri.encodeComponent(widget.batchId)}/caretaker-records?limit=100&offset=${all.length}'),
          headers: {
            'Authorization': 'Bearer ${AuthService().jwt ?? ''}'
          }).timeout(const Duration(seconds: 20));
      if (response.statusCode == 401 && !refreshed) {
        refreshed = true;
        await AuthService().refreshSession();
        continue;
      }
      if (response.statusCode != 200) {
        throw Exception(response.statusCode == 403
            ? 'You do not have access to records for this farm.'
            : 'Unable to load records. Please retry.');
      }
      final body = jsonDecode(response.body) as Map;
      final rows = (body['documents'] as List)
          .map((r) => Map<String, dynamic>.from(r as Map))
          .toList();
      all.addAll(rows);
      if (rows.isEmpty || all.length >= (body['total'] as num)) return all;
    }
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final rows = await (widget.loadRecords?.call() ?? _fetch());
      if (mounted)
        setState(() {
          _records = rows;
          _loading = false;
          _selected = null;
        });
    } catch (error) {
      if (mounted)
        setState(() {
          _error = '$error'.replaceFirst('Exception: ', '');
          _loading = false;
        });
    }
  }

  void _select(Map<String, dynamic> record) {
    setState(() => _selected = record);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted && _detailsKey.currentContext != null) {
        Scrollable.ensureVisible(_detailsKey.currentContext!,
            duration: const Duration(milliseconds: 250), alignment: 0);
      }
    });
  }

  String _value(Map<String, dynamic> r, String key) {
    final value = '${r[key] ?? ''}'.trim();
    return value.isEmpty ? '\u2014' : value;
  }

  String _label(String value) => value
      .replaceAll('_', ' ')
      .split(' ')
      .map((word) =>
          word.isEmpty ? '' : '${word[0].toUpperCase()}${word.substring(1)}')
      .join(' ');
  String _date(Map<String, dynamic> r) {
    final date = DateTime.tryParse('${r['record_date']}');
    return date == null
        ? _value(r, 'record_date')
        : DateFormat('dd MMM yyyy, h:mm a').format(date.toLocal());
  }

  bool _hasIssues(Map<String, dynamic> r) =>
      r['has_issues'] == true || r['has_issues'] == 'true';
  ColorScheme get _colors => Theme.of(context).colorScheme;
  Widget _panel(Widget child,
          {EdgeInsets padding = const EdgeInsets.all(20)}) =>
      Container(
        padding: padding,
        decoration: BoxDecoration(
            color: _colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _colors.outlineVariant)),
        child: child,
      );
  Widget _pill(String text, {bool issue = false}) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
            color: issue
                ? _colors.errorContainer
                : _colors.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(8)),
        child: Text(text,
            style: AppTypography.caption.copyWith(
                color: issue
                    ? _colors.onErrorContainer
                    : _colors.onSurfaceVariant)),
      );
  @override
  Widget build(BuildContext context) {
    final rows = _records
        .where((r) =>
            (!_issuesOnly || _hasIssues(r)) &&
            [
              'created_by_name',
              'record_type',
              'growth_stage',
              'observations',
              'notes',
              'record_id'
            ].any((k) => _label('${r[k] ?? ''}')
                .toLowerCase()
                .contains(_search.toLowerCase())))
        .toList();
    return Scaffold(
      appBar: AppBar(
          title: Text('Caretaker records', style: AppTypography.titleMedium),
          actions: [
            IconButton(
                onPressed: _loading ? null : _load,
                tooltip: 'Refresh records',
                icon: const Icon(Icons.refresh_rounded)),
            const SizedBox(width: 12)
          ]),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(mainAxisSize: MainAxisSize.min, children: [
                        Text(_error!),
                        const SizedBox(height: 12),
                        FilledButton(
                            onPressed: _load, child: const Text('Retry'))
                      ])))
              : LayoutBuilder(builder: (context, viewport) {
                  final compact = viewport.maxWidth < 700;
                  return SingleChildScrollView(
                      controller: _scroll,
                      padding: EdgeInsets.fromLTRB(
                          compact ? 16 : 32, 20, compact ? 16 : 32, 16),
                      child: Center(
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 1440),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _summary(compact),
                                    const SizedBox(height: 20),
                                    _panel(Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.stretch,
                                        children: [
                                          Row(children: [
                                            Expanded(
                                                child: Text('Record history',
                                                    style: AppTypography
                                                        .titleSmall
                                                        .copyWith(
                                                            color: _colors
                                                                .onSurface))),
                                            Text(
                                                '${rows.length} of ${_records.length}',
                                                style: AppTypography.caption
                                                    .copyWith(
                                                        color: _colors
                                                            .onSurfaceVariant))
                                          ]),
                                          const SizedBox(height: 16),
                                          LayoutBuilder(
                                              builder: (context, constraints) {
                                            final search = TextField(
                                                style: AppTypography.bodySmall,
                                                onChanged: (v) =>
                                                    setState(() => _search = v),
                                                decoration: InputDecoration(
                                                    isDense: true,
                                                    filled: true,
                                                    fillColor: _colors
                                                        .surfaceContainerLow,
                                                    prefixIcon: const Icon(
                                                        Icons.search_rounded,
                                                        size: 20),
                                                    hintText:
                                                        'Search caretaker, stage or observations',
                                                    hintStyle:
                                                        AppTypography.bodySmall,
                                                    contentPadding:
                                                        const EdgeInsets.symmetric(
                                                            horizontal: 14,
                                                            vertical: 14),
                                                    border: OutlineInputBorder(
                                                        borderRadius:
                                                            BorderRadius.circular(
                                                                10),
                                                        borderSide: BorderSide(
                                                            color: _colors.outlineVariant)),
                                                    enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: BorderSide(color: _colors.outlineVariant))));
                                            final filter = FilterChip(
                                                avatar: Icon(
                                                    Icons.flag_outlined,
                                                    size: 16,
                                                    color: _issuesOnly
                                                        ? _colors
                                                            .onSecondaryContainer
                                                        : _colors
                                                            .onSurfaceVariant),
                                                label:
                                                    const Text('Issues only'),
                                                labelStyle:
                                                    AppTypography.caption,
                                                selected: _issuesOnly,
                                                showCheckmark: false,
                                                onSelected: (v) => setState(
                                                    () => _issuesOnly = v));
                                            return constraints.maxWidth < 600
                                                ? Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment
                                                            .start,
                                                    children: [
                                                        search,
                                                        const SizedBox(
                                                            height: 8),
                                                        filter
                                                      ])
                                                : Row(children: [
                                                    Expanded(child: search),
                                                    const SizedBox(width: 12),
                                                    filter
                                                  ]);
                                          }),
                                          const SizedBox(height: 16),
                                          if (rows.isEmpty)
                                            Padding(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        vertical: 36),
                                                child: Column(children: [
                                                  Icon(
                                                      Icons.fact_check_outlined,
                                                      size: 32,
                                                      color: _colors
                                                          .onSurfaceVariant),
                                                  const SizedBox(height: 12),
                                                  Text(
                                                      _records.isEmpty
                                                          ? 'No caretaker records have been submitted for this batch.'
                                                          : 'No records match your filters.',
                                                      textAlign:
                                                          TextAlign.center,
                                                      style: AppTypography
                                                          .bodySmall)
                                                ]))
                                          else if (viewport.maxWidth >= 1000)
                                            _table(rows)
                                          else
                                            ...rows.map(_mobileRecord),
                                        ])),
                                    if (_selected != null) ...[
                                      const SizedBox(height: 20),
                                      _details(_selected!)
                                    ],
                                  ]))));
                }),
    );
  }

  final _detailsKey = GlobalKey();
  Widget _summary(bool compact) {
    final caretakers = _records
        .map((r) => '${r['created_by'] ?? r['created_by_name'] ?? ''}')
        .where((v) => v.isNotEmpty)
        .toSet()
        .length;
    return _panel(
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: _colors.primaryContainer,
                borderRadius: BorderRadius.circular(12)),
            child: Icon(Icons.inventory_2_outlined,
                color: _colors.onPrimaryContainer, size: 24)),
        const SizedBox(width: 14),
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('BATCH RECORDS',
              style: AppTypography.caption
                  .copyWith(color: _colors.onSurfaceVariant, letterSpacing: 1)),
          const SizedBox(height: 5),
          Text(widget.batchNumber,
              style:
                  AppTypography.titleMedium.copyWith(color: _colors.onSurface)),
          const SizedBox(height: 6),
          Text(widget.farmName,
              style: AppTypography.bodySmall
                  .copyWith(color: _colors.onSurfaceVariant))
        ])),
      ]),
      const SizedBox(height: 20),
      Wrap(spacing: compact ? 20 : 48, runSpacing: 16, children: [
        _metric(
            'Total records', '${_records.length}', Icons.description_outlined),
        _metric('Caretakers', '$caretakers', Icons.people_outline),
        _metric('Records with issues', '${_records.where(_hasIssues).length}',
            Icons.flag_outlined),
      ]),
    ]));
  }

  Widget _metric(String label, String value, IconData icon) =>
      Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 18, color: _colors.onSurfaceVariant),
        const SizedBox(width: 10),
        Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(value,
              style:
                  AppTypography.titleMedium.copyWith(color: _colors.onSurface)),
          Text(label,
              style: AppTypography.caption
                  .copyWith(color: _colors.onSurfaceVariant))
        ])
      ]);
  Widget _table(List<Map<String, dynamic>> rows) => LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
              constraints: BoxConstraints(minWidth: constraints.maxWidth),
              child: DataTable(
                columnSpacing: 24,
                horizontalMargin: 16,
                headingRowHeight: 44,
                dataRowMinHeight: 64,
                dataRowMaxHeight: 80,
                headingRowColor:
                    WidgetStatePropertyAll(_colors.surfaceContainerLow),
                dividerThickness: .6,
                showCheckboxColumn: false,
                dataTextStyle:
                    AppTypography.bodySmall.copyWith(color: _colors.onSurface),
                headingTextStyle: AppTypography.labelSmall
                    .copyWith(color: _colors.onSurfaceVariant),
                columns: const [
                  DataColumn(label: Text('Recorded')),
                  DataColumn(label: Text('Caretaker')),
                  DataColumn(label: Text('Record type')),
                  DataColumn(label: Text('Growth stage')),
                  DataColumn(label: Text('Issues')),
                  DataColumn(label: Text(''))
                ],
                rows: rows
                    .map((r) =>
                        DataRow(onSelectChanged: (_) => _select(r), cells: [
                          DataCell(Text(_date(r))),
                          DataCell(SizedBox(
                              width: 150,
                              child: Text(_value(r, 'created_by_name'),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis))),
                          DataCell(_pill(_label(_value(r, 'record_type')))),
                          DataCell(Text(_label(_value(r, 'growth_stage')))),
                          DataCell(_pill(
                              _hasIssues(r)
                                  ? _label(_value(r, 'issue_severity'))
                                  : 'None',
                              issue: _hasIssues(r))),
                          DataCell(TextButton(
                              onPressed: () => _select(r),
                              child: const Text('View record'))),
                        ]))
                    .toList(),
              ))));
  Widget _mobileRecord(Map<String, dynamic> r) => Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: _panel(
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Wrap(spacing: 8, runSpacing: 8, children: [
              _pill(_label(_value(r, 'record_type'))),
              if (_hasIssues(r))
                _pill(_label(_value(r, 'issue_severity')), issue: true)
            ]),
            const SizedBox(height: 12),
            Text(_date(r),
                style: AppTypography.labelSmall
                    .copyWith(color: _colors.onSurface)),
            const SizedBox(height: 8),
            Text(_value(r, 'created_by_name'),
                style: AppTypography.bodySmall
                    .copyWith(color: _colors.onSurfaceVariant)),
            const SizedBox(height: 6),
            Text('Growth stage: ${_label(_value(r, 'growth_stage'))}',
                style: AppTypography.bodySmall
                    .copyWith(color: _colors.onSurfaceVariant)),
            Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                    onPressed: () => _select(r),
                    child: const Text('View record'))),
          ]),
          padding: const EdgeInsets.all(16)));
  Widget _details(Map<String, dynamic> r) {
    const fields = {
      'record_id': 'Record number',
      'growing_group_name': 'Growing group',
      'shared_observations': 'Shared observations',
      'created_by_name': 'Recorded by',
      'record_type': 'Record type',
      'growth_stage': 'Growth stage',
      'plant_health': 'Plant health',
      'plant_count': 'Plant count',
      'water_temperature': 'Water temperature (\u00b0C)',
      'water_bought_litres': 'Water bought (litres)',
      'water_bought_amount': 'Water purchase amount',
      'ac_water_litres': 'AC water added (litres)',
      'temperature': 'Temperature (\u00b0C)',
      'humidity': 'Humidity (%)',
      'ph': 'pH',
      'ec': 'EC',
      'light_intensity': 'Light intensity',
      'observations': 'Observations',
      'activities_performed': 'Activities performed',
      'issue_severity': 'Issue severity',
      'issue_description': 'Issue description',
      'notes': 'Notes'
    };
    return Container(
        key: _detailsKey,
        child: _panel(
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Icon(Icons.assignment_outlined, size: 20, color: _colors.primary),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Record details',
                    style: AppTypography.titleSmall
                        .copyWith(color: _colors.onSurface))),
            IconButton(
                onPressed: () => setState(() => _selected = null),
                tooltip: 'Close details',
                icon: const Icon(Icons.close, size: 20))
          ]),
          Text(_date(r),
              style: AppTypography.caption
                  .copyWith(color: _colors.onSurfaceVariant)),
          const SizedBox(height: 20),
          if (r['record_scope'] == 'shared') ...[
            Text('Shared readings · recorded once for the growing group', style: AppTypography.bodySmall.copyWith(color: _colors.primary)),
            const SizedBox(height: 10),
            ...((r['linked_batches'] as List?) ?? []).whereType<Map>().map((entry) => Padding(
              padding: const EdgeInsets.only(bottom: 8), child: Text(
                '${entry['batch_number']} · ${entry['growth_stage']} · ${entry['has_issues'] == true ? 'Issue: ${entry['issue_description']}' : 'No issues reported'}',
                style: AppTypography.bodySmall))),
            const SizedBox(height: 12),
          ],
          LayoutBuilder(
              builder: (context, constraints) =>
                  Wrap(spacing: 24, runSpacing: 20, children: [
                    for (final field in fields.entries)
                      if (_value(r, field.key) != '\u2014')
                        SizedBox(
                            width: constraints.maxWidth >= 700 &&
                                    ![
                                      'observations',
                                      'activities_performed',
                                      'issue_description',
                                      'notes'
                                    ].contains(field.key)
                                ? (constraints.maxWidth - 48) / 3
                                : constraints.maxWidth,
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(field.value,
                                      style: AppTypography.caption.copyWith(
                                          color: _colors.onSurfaceVariant)),
                                  const SizedBox(height: 6),
                                  SelectableText(
                                      [
                                        'record_type',
                                        'growth_stage',
                                        'plant_health',
                                        'issue_severity'
                                      ].contains(field.key)
                                          ? _label(_value(r, field.key))
                                          : _value(r, field.key),
                                      style: AppTypography.bodySmall
                                          .copyWith(color: _colors.onSurface))
                                ])),
                  ])),
        ])));
  }
}
