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
            ? 'You do not have access to this farmâ€™s records.'
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
    _scroll.animateTo(0,
        duration: const Duration(milliseconds: 250), curve: Curves.easeOut);
  }

  String _value(Map<String, dynamic> r, String key) =>
      '${r[key] ?? ''}'.trim().isEmpty ? 'â€”' : '${r[key]}';
  String _date(Map<String, dynamic> r) {
    final date = DateTime.tryParse('${r['record_date']}');
    return date == null
        ? _value(r, 'record_date')
        : DateFormat('dd MMM yyyy, h:mm a').format(date.toLocal());
  }

  bool _hasIssues(Map<String, dynamic> r) =>
      r['has_issues'] == true || r['has_issues'] == 'true';
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
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
            ].any((k) =>
                '${r[k] ?? ''}'.toLowerCase().contains(_search.toLowerCase())))
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Caretaker records'), actions: [
        IconButton(
            onPressed: _loading ? null : _load,
            tooltip: 'Refresh records',
            icon: const Icon(Icons.refresh))
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
              : LayoutBuilder(
                  builder: (context, size) => ListView(
                          controller: _scroll,
                          padding: const EdgeInsets.all(16),
                          children: [
                            Text(widget.batchNumber,
                                style: AppTypography.titleMedium
                                    .copyWith(color: scheme.onSurface)),
                            const SizedBox(height: 4),
                            Text(
                                '${widget.farmName} Â· ${_records.length} records',
                                style: AppTypography.bodySmall
                                    .copyWith(color: scheme.onSurfaceVariant)),
                            const SizedBox(height: 16),
                            TextField(
                                onChanged: (v) => setState(() => _search = v),
                                decoration: const InputDecoration(
                                    prefixIcon: Icon(Icons.search),
                                    hintText:
                                        'Search caretaker, stage or observations',
                                    border: OutlineInputBorder())),
                            const SizedBox(height: 8),
                            Align(
                                alignment: Alignment.centerLeft,
                                child: FilterChip(
                                    label: const Text('Issues only'),
                                    selected: _issuesOnly,
                                    showCheckmark: false,
                                    onSelected: (v) =>
                                        setState(() => _issuesOnly = v))),
                            if (_selected != null) _details(_selected!),
                            if (rows.isEmpty)
                              Padding(
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 40),
                                  child: Text(
                                      _records.isEmpty
                                          ? 'No caretaker records have been submitted for this batch.'
                                          : 'No records match your filters.',
                                      textAlign: TextAlign.center)),
                            if (rows.isNotEmpty && size.maxWidth >= 900)
                              SingleChildScrollView(
                                  scrollDirection: Axis.horizontal,
                                  child: DataTable(
                                      columnSpacing: 24,
                                      horizontalMargin: 12,
                                      dataTextStyle: AppTypography.bodySmall
                                          .copyWith(color: scheme.onSurface),
                                      headingTextStyle: AppTypography.labelSmall
                                          .copyWith(color: scheme.onSurface),
                                      showCheckboxColumn: false,
                                      columns: const [
                                        DataColumn(label: Text('Recorded')),
                                        DataColumn(label: Text('Caretaker')),
                                        DataColumn(label: Text('Record type')),
                                        DataColumn(label: Text('Growth stage')),
                                        DataColumn(label: Text('Issues')),
                                        DataColumn(label: Text('Details'))
                                      ],
                                      rows: rows
                                          .map((r) => DataRow(
                                                  onSelectChanged: (_) =>
                                                      _select(r),
                                                  cells: [
                                                    DataCell(Text(_date(r))),
                                                    DataCell(Text(_value(
                                                        r, 'created_by_name'))),
                                                    DataCell(Text(_value(
                                                        r, 'record_type'))),
                                                    DataCell(Text(_value(
                                                        r, 'growth_stage'))),
                                                    DataCell(Text(_hasIssues(r)
                                                        ? _value(
                                                            r, 'issue_severity')
                                                        : 'None')),
                                                    DataCell(TextButton(
                                                        onPressed: () =>
                                                            _select(r),
                                                        child: const Text(
                                                            'View record')))
                                                  ]))
                                          .toList())),
                            if (size.maxWidth < 900)
                              ...rows.map((r) => Card(
                                  child: Padding(
                                      padding: const EdgeInsets.all(16),
                                      child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(_date(r),
                                                style:
                                                    AppTypography.titleSmall),
                                            const SizedBox(height: 6),
                                            Text(
                                                '${_value(r, 'created_by_name')} Â· ${_value(r, 'record_type')}',
                                                style: AppTypography.bodySmall),
                                            const SizedBox(height: 6),
                                            Text(
                                                'Stage: ${_value(r, 'growth_stage')}  Â·  Issues: ${_hasIssues(r) ? _value(r, 'issue_severity') : 'None'}',
                                                style: AppTypography.bodySmall),
                                            TextButton(
                                                onPressed: () => _select(r),
                                                child:
                                                    const Text('View record'))
                                          ])))),
                          ])),
    );
  }

  Widget _details(Map<String, dynamic> r) {
    const fields = {
      'record_id': 'Record number',
      'created_by_name': 'Recorded by',
      'record_type': 'Record type',
      'growth_stage': 'Growth stage',
      'plant_health': 'Plant health',
      'plant_count': 'Plant count',
      'temperature': 'Temperature (Â°C)',
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
    return Card(
        child: Padding(
            padding: const EdgeInsets.all(16),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text('Record details',
                        style: AppTypography.titleSmall)),
                IconButton(
                    onPressed: () => setState(() => _selected = null),
                    tooltip: 'Close details',
                    icon: const Icon(Icons.close))
              ]),
              Text(_date(r), style: AppTypography.caption),
              const SizedBox(height: 12),
              for (final field in fields.entries)
                if (_value(r, field.key) != 'â€”')
                  Padding(
                      padding: const EdgeInsets.only(bottom: 12),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(field.value, style: AppTypography.labelSmall),
                            const SizedBox(height: 4),
                            SelectableText(_value(r, field.key),
                                style: AppTypography.bodySmall)
                          ])),
            ])));
  }
}
