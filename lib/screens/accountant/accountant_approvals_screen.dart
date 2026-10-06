import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../core/providers/live_workspace_provider.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/accountant_screen_shell.dart';
import '../../core/widgets/app_dialog.dart';

String _money(Map<String, dynamic> item) =>
    '${item['currency'] ?? 'GHS'} ${NumberFormat('#,##0.00').format(num.tryParse('${item['amount']}') ?? 0)}';
String _date(dynamic value) {
  final date = DateTime.tryParse(value?.toString() ?? '');
  return date == null
      ? 'Not recorded'
      : DateFormat('d MMM yyyy, h:mm a').format(date.toLocal());
}

class AccountantApprovalsScreen extends StatelessWidget {
  const AccountantApprovalsScreen({super.key});
  @override
  Widget build(BuildContext context) => const AccountantScreenShell(
      selectedIndex: 3, child: ApprovalQueueContent());
}

class ApprovalQueueContent extends ConsumerStatefulWidget {
  const ApprovalQueueContent({super.key});
  @override
  ConsumerState<ApprovalQueueContent> createState() =>
      _ApprovalQueueContentState();
}

class _ApprovalQueueContentState extends ConsumerState<ApprovalQueueContent> {
  String _status = 'Pending';
  String _kind = 'All types';
  String _search = '';

  Future<void> _open(Map<String, dynamic> item) async {
    final saved = await showAppDialog<bool>(
        context: context,
        barrierDismissible: false,
        builder: (_) => ApprovalReviewDialog(item: item));
    if (saved == true && mounted) ref.invalidate(approvalQueueProvider);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(approvalQueueProvider);
    final items = state.valueOrNull ?? [];
    final pending = items.where((r) => r['status'] == 'Pending').toList();
    final totals = <String, num>{};
    for (final item in pending) {
      final currency = '${item['currency'] ?? 'GHS'}';
      totals[currency] =
          (totals[currency] ?? 0) + (num.tryParse('${item['amount']}') ?? 0);
    }
    final filtered = items
        .where((r) =>
            (_status == 'All statuses' || r['status'] == _status) &&
            (_kind == 'All types' ||
                r['kind'] ==
                    (_kind == 'Fund requests'
                        ? 'fund_request'
                        : 'withdrawal')) &&
            [r['reference'], r['title'], r['requester'], r['farm_name']]
                .join(' ')
                .toLowerCase()
                .contains(_search.toLowerCase()))
        .toList();
    final color = Theme.of(context).colorScheme;
    Widget metric(String title, String value) => Container(
        width: 220,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
            color: color.surface,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: color.outlineVariant)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppTypography.bodySmall),
          const SizedBox(height: 8),
          Text(value, style: AppTypography.h5)
        ]));
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(children: [
        Expanded(
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text('Fund approvals', style: AppTypography.h5),
          const SizedBox(height: 4),
          Text('Review farm funding and owner withdrawal requests.',
              style: AppTypography.bodySmall)
        ])),
        IconButton(
            tooltip: 'Refresh approvals',
            onPressed: state.isLoading
                ? null
                : () => ref.invalidate(approvalQueueProvider),
            icon: const Icon(Icons.refresh))
      ]),
      const SizedBox(height: 16),
      if (state.isLoading) const LinearProgressIndicator(),
      if (state.hasError)
        Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text('Could not load approvals. Refresh to try again.',
                style: AppTypography.bodySmall.copyWith(color: color.error))),
      if (state.hasValue)
        Wrap(spacing: 12, runSpacing: 12, children: [
          metric('Awaiting decision', '${pending.length}'),
          metric(
              'Pending amount',
              totals.isEmpty
                  ? '0'
                  : totals.entries
                      .map((e) =>
                          '${e.key} ${NumberFormat('#,##0.00').format(e.value)}')
                      .join('\n')),
          metric('Approved requests',
              '${items.where((r) => r['status'] == 'Approved').length}')
        ]),
      const SizedBox(height: 16),
      TextField(
          onChanged: (text) => setState(() => _search = text),
          style: AppTypography.bodySmall,
          decoration: const InputDecoration(
              hintText: 'Search reference, requester or farm',
              prefixIcon: Icon(Icons.search))),
      const SizedBox(height: 12),
      Wrap(spacing: 12, runSpacing: 8, children: [
        SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
                initialValue: _status,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Status'),
                items: [
                  'All statuses',
                  'Pending',
                  'Approved',
                  'Rejected',
                  'Disbursed',
                  'Paid'
                ]
                    .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v, style: AppTypography.bodySmall)))
                    .toList(),
                onChanged: (v) => setState(() => _status = v!))),
        SizedBox(
            width: 190,
            child: DropdownButtonFormField<String>(
                initialValue: _kind,
                isExpanded: true,
                decoration: const InputDecoration(labelText: 'Request type'),
                items: ['All types', 'Fund requests', 'Withdrawals']
                    .map((v) => DropdownMenuItem(
                        value: v,
                        child: Text(v, style: AppTypography.bodySmall)))
                    .toList(),
                onChanged: (v) => setState(() => _kind = v!)))
      ]),
      const SizedBox(height: 16),
      if (filtered.isEmpty && !state.isLoading && !state.hasError)
        const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Text('No requests match these filters.')),
      LayoutBuilder(builder: (context, constraints) {
        final columns = constraints.maxWidth >= 1100
            ? 3
            : constraints.maxWidth >= 660
                ? 2
                : 1;
        final width = (constraints.maxWidth - (columns - 1) * 12) / columns;
        return Wrap(
            spacing: 12,
            runSpacing: 12,
            children: filtered
                .map((item) => SizedBox(
                    width: width,
                    child: Material(
                        color: color.surface,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                            side: BorderSide(color: color.outlineVariant)),
                        child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => _open(item),
                            child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Icon(
                                            item['kind'] == 'withdrawal'
                                                ? Icons
                                                    .account_balance_wallet_outlined
                                                : Icons.request_quote_outlined,
                                            color: AppColors.primary),
                                        const SizedBox(width: 10),
                                        Expanded(
                                            child: Text('${item['reference']}',
                                                style:
                                                    AppTypography.bodySmall)),
                                        const Icon(Icons.chevron_right,
                                            size: 18)
                                      ]),
                                      const SizedBox(height: 12),
                                      Text('${item['title'] ?? 'Fund request'}',
                                          style: AppTypography.bodyMedium),
                                      const SizedBox(height: 6),
                                      Text(_money(item),
                                          style: AppTypography.h5),
                                      const SizedBox(height: 8),
                                      Text(
                                          '${item['requester']} • ${item['farm_name']}',
                                          style: AppTypography.bodySmall),
                                      const SizedBox(height: 6),
                                      Text(_date(item['requested_at']),
                                          style: AppTypography.caption),
                                      const SizedBox(height: 10),
                                      Text(
                                          '${item['status']} · ${item['kind'] == 'withdrawal' ? 'Withdrawal' : 'Fund request'}',
                                          style: AppTypography.bodySmall
                                              .copyWith(
                                                  color: AppColors.primary)),
                                    ]))))))
                .toList());
      }),
    ]);
  }
}

class ApprovalReviewDialog extends ConsumerStatefulWidget {
  const ApprovalReviewDialog({super.key, required this.item});
  final Map<String, dynamic> item;
  @override
  ConsumerState<ApprovalReviewDialog> createState() =>
      _ApprovalReviewDialogState();
}

class _ApprovalReviewDialogState extends ConsumerState<ApprovalReviewDialog> {
  late final _notes = TextEditingController(
      text: widget.item['decision_notes']?.toString() ?? '');
  String _decision = 'Approved';
  String? _error;
  bool _saving = false;
  @override
  void dispose() {
    _notes.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving) return;
    if (_decision == 'Rejected' && _notes.text.trim().isEmpty) {
      setState(() => _error = 'Enter the reason for rejection.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await ref
          .read(liveWorkspaceApiProvider)
          .reviewApproval(widget.item, _decision, _notes.text.trim());
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (mounted) {
        setState(() {
          _error = error.toString();
          _saving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;
    final actor = ref.watch(approvalReviewerProvider);
    final editable = item['status'] == 'Pending' &&
        actor != null &&
        item['requester_id'] != actor.id;
    final colors = Theme.of(context).colorScheme;
    TextStyle text(double size, {FontWeight weight = FontWeight.w400}) =>
        AppTypography.font(
            fontSize: size, fontWeight: weight, color: colors.onSurface);
    Widget field(String label, String value) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(label, style: text(11, weight: FontWeight.w600)),
          const SizedBox(height: 6),
          SelectableText(value.isEmpty ? 'Not recorded' : value,
              style: text(12))
        ]));
    return PopScope(
        canPop: !_saving,
        child: AppDialog(
            backgroundColor: Colors.transparent,
            elevation: 0,
            insetPadding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
            child: Container(
                constraints: BoxConstraints(
                    maxWidth: 500,
                    maxHeight: MediaQuery.sizeOf(context).height * .9),
                decoration: BoxDecoration(
                    color: colors.surface,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: const [
                      BoxShadow(
                          color: Colors.black26,
                          blurRadius: 24,
                          offset: Offset(0, 12))
                    ]),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  Padding(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                      child: Row(children: [
                        Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                                gradient: const LinearGradient(colors: [
                                  AppColors.primary,
                                  Color(0xff15803d)
                                ]),
                                borderRadius: BorderRadius.circular(10)),
                            child: const Icon(Icons.approval_outlined,
                                size: 20, color: Colors.white)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Review request',
                                  style: text(16, weight: FontWeight.bold)),
                              const SizedBox(height: 4),
                              Text('${item['reference']}', style: text(12))
                            ])),
                        IconButton(
                            onPressed:
                                _saving ? null : () => Navigator.pop(context),
                            icon: const Icon(Icons.close, size: 16))
                      ])),
                  Flexible(
                      child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                field('Purpose', '${item['title'] ?? ''}'),
                                field('Amount', _money(item)),
                                LayoutBuilder(builder: (context, constraints) {
                                  final fields = [
                                    field('Requested by',
                                        '${item['requester'] ?? ''}'),
                                    field('Farm', '${item['farm_name'] ?? ''}')
                                  ];
                                  return MediaQuery.sizeOf(context).width < 600
                                      ? Column(children: fields)
                                      : Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                              Expanded(child: fields[0]),
                                              const SizedBox(width: 10),
                                              Expanded(child: fields[1])
                                            ]);
                                }),
                                field('Requested', _date(item['requested_at'])),
                                field('Status', '${item['status']}'),
                                field('Description',
                                    '${item['description'] ?? ''}'),
                                if (editable) ...[
                                  Text('Decision',
                                      style: text(11, weight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  DropdownButtonFormField<String>(
                                      initialValue: _decision,
                                      isExpanded: true,
                                      style: text(12),
                                      decoration:
                                          _input(context, Icons.rule_outlined),
                                      items: ['Approved', 'Rejected']
                                          .map((value) => DropdownMenuItem(
                                              value: value, child: Text(value)))
                                          .toList(),
                                      onChanged: _saving
                                          ? null
                                          : (v) =>
                                              setState(() => _decision = v!)),
                                  const SizedBox(height: 14),
                                  Text('Decision notes',
                                      style: text(11, weight: FontWeight.w600)),
                                  const SizedBox(height: 6),
                                  TextField(
                                      controller: _notes,
                                      enabled: !_saving,
                                      maxLines: 3,
                                      maxLength: 1000,
                                      style: text(12),
                                      decoration: _input(context, Icons.notes)),
                                  const SizedBox(height: 14),
                                  Text(
                                      'Approval records a review decision. Payment is handled separately.',
                                      style: text(12)),
                                ] else ...[
                                  field('Decision notes',
                                      '${item['decision_notes'] ?? ''}'),
                                  if (item['reviewed_at']
                                          ?.toString()
                                          .isNotEmpty ==
                                      true)
                                    field(
                                        'Reviewed', _date(item['reviewed_at'])),
                                  if (item['requester_id'] == actor?.id)
                                    Text(
                                        'Another reviewer must review your own request.',
                                        style: text(12))
                                ],
                                if (_error != null)
                                  Padding(
                                      padding: const EdgeInsets.only(top: 12),
                                      child: Text(_error!,
                                          style: text(12)
                                              .copyWith(color: colors.error))),
                                const SizedBox(height: 16),
                              ]))),
                  Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(children: [
                        Expanded(
                            child: OutlinedButton(
                                style: OutlinedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                        vertical: 12),
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(10))),
                                onPressed: _saving
                                    ? null
                                    : () => Navigator.pop(context),
                                child: Text(editable ? 'Cancel' : 'Close',
                                    style: text(13)))),
                        if (editable) ...[
                          const SizedBox(width: 12),
                          Expanded(
                              child: ElevatedButton(
                                  style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                          vertical: 12),
                                      shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(10))),
                                  onPressed: _saving ? null : _save,
                                  child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.center,
                                      children: [
                                        if (_saving) ...[
                                          const SizedBox(
                                              width: 14,
                                              height: 14,
                                              child: CircularProgressIndicator(
                                                  strokeWidth: 2)),
                                          const SizedBox(width: 8)
                                        ],
                                        Flexible(
                                            child: Text(
                                                _saving
                                                    ? 'Saving…'
                                                    : 'Save decision',
                                                style: text(13).copyWith(
                                                    color: Colors.white)))
                                      ])))
                        ]
                      ])),
                ]))));
  }

  InputDecoration _input(BuildContext context, IconData icon) {
    final colors = Theme.of(context).colorScheme;
    return InputDecoration(
        filled: true,
        fillColor: colors.surfaceContainerHighest.withValues(alpha: .4),
        prefixIcon: Icon(icon, size: 16),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.outlineVariant)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide: BorderSide(color: colors.outlineVariant)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
            borderSide:
                const BorderSide(color: AppColors.primary, width: 1.5)));
  }
}
