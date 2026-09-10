import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_dialog.dart';
import 'audit_data_table.dart';

class AuditEventDetailsModal extends StatefulWidget {
  const AuditEventDetailsModal(
      {super.key,
      required this.id,
      required this.action,
      required this.details,
      required this.previous,
      required this.current,
      required this.copyText});
  final String id, action, previous, current, copyText;
  final Map<String, String> details;
  @override
  State<AuditEventDetailsModal> createState() => _AuditEventDetailsModalState();
}

class _AuditEventDetailsModalState extends State<AuditEventDetailsModal> {
  bool copied = false;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final buttons = ButtonStyle(
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
        textStyle: WidgetStatePropertyAll(
            AppTypography.font(fontSize: AppTypography.actionSize)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    return AppDialog(
        backgroundColor: Colors.transparent,
        elevation: 0,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
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
            child: Material(
                color: Colors.transparent,
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
                            child: const Icon(Icons.history_rounded,
                                size: 20, color: Colors.white)),
                        const SizedBox(width: 12),
                        Expanded(
                            child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                              Text('Event details',
                                  style: AppTypography.titleSmall),
                              Text(widget.id,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTypography.caption.copyWith(
                                      color: colors.onSurfaceVariant)),
                            ])),
                        IconButton(
                            tooltip: 'Close',
                            onPressed: () => Navigator.pop(context),
                            padding: const EdgeInsets.all(6),
                            constraints: const BoxConstraints(
                                minWidth: 28, minHeight: 28),
                            icon: const Icon(Icons.close_rounded, size: 16)),
                      ])),
                  Flexible(
                      child: SingleChildScrollView(
                          padding: const EdgeInsets.symmetric(horizontal: 24),
                          physics: const BouncingScrollPhysics(),
                          keyboardDismissBehavior:
                              ScrollViewKeyboardDismissBehavior.onDrag,
                          child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                Text(widget.action,
                                    style: AppTypography.body.copyWith(
                                        fontWeight:
                                            AppTypography.headingWeight)),
                                const SizedBox(height: 14),
                                for (final item in widget.details.entries)
                                  Padding(
                                      padding:
                                          const EdgeInsets.only(bottom: 10),
                                      child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Expanded(
                                                child: Text(item.key,
                                                    style: AppTypography.label
                                                        .copyWith(
                                                            color: colors
                                                                .onSurfaceVariant))),
                                            const SizedBox(width: 12),
                                            Expanded(
                                                flex: 2,
                                                child: SelectableText(
                                                    item.value,
                                                    style: AppTypography
                                                        .bodySmall)),
                                          ])),
                                const SizedBox(height: 10),
                                AuditDataTable(
                                    previous: widget.previous,
                                    current: widget.current),
                                const SizedBox(height: 4),
                              ]))),
                  Padding(
                      padding: const EdgeInsets.all(24),
                      child: Row(children: [
                        Expanded(
                            child: OutlinedButton(
                                style: buttons,
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Close'))),
                        const SizedBox(width: 12),
                        Expanded(
                            child: FilledButton(
                                style: buttons,
                                onPressed: () async {
                                  await Clipboard.setData(
                                      ClipboardData(text: widget.copyText));
                                  if (mounted) setState(() => copied = true);
                                },
                                child: Text(copied ? 'Copied' : 'Copy event'))),
                      ])),
                ]))));
  }
}
