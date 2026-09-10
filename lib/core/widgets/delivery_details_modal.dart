import '../theme/app_typography.dart';
import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'app_dialog.dart';

class DeliveryDetailSection {
  const DeliveryDetailSection(this.title, this.icon, this.fields);
  final String title;
  final IconData icon;
  final List<(String, String)> fields;
}

/// Shared read-only delivery view for administrators and farm managers.
class DeliveryDetailsModal extends StatelessWidget {
  const DeliveryDetailsModal(
      {super.key,
      required this.reference,
      required this.status,
      required this.statusColor,
      required this.priority,
      required this.sections,
      this.onEdit});
  final String reference, status, priority;
  final Color statusColor;
  final List<DeliveryDetailSection> sections;
  final VoidCallback? onEdit;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dark = theme.brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : Colors.white;
    final secondary = dark ? Colors.white60 : AppColors.textSecondary;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final close = () => Navigator.of(context).pop();
    final buttonStyle = ButtonStyle(
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
        textStyle: WidgetStatePropertyAll(
            AppTypography.font(fontSize: AppTypography.actionSize, fontWeight: AppTypography.headingWeight)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    return AppDialog(
        backgroundColor: surface,
        insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
            constraints: BoxConstraints(
                maxWidth: 500,
                maxHeight: MediaQuery.sizeOf(context).height * .9),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
                  child: Row(children: [
                    Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [AppColors.primary, Color(0xff15803d)]),
                            borderRadius: BorderRadius.circular(10)),
                        child: const Icon(Icons.local_shipping_outlined,
                            size: 20, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Delivery details',
                              style: AppTypography.font(
                                  fontSize: AppTypography.cardTitleSize,
                                  fontWeight: AppTypography.headingWeight,
                                  color: foreground)),
                          const SizedBox(height: 4),
                          Text('Shipment and delivery information',
                              style: AppTypography.font(
                                  fontSize: AppTypography.captionSize, color: secondary)),
                        ])),
                    IconButton(
                        tooltip: 'Close',
                        onPressed: close,
                        icon: const Icon(Icons.close, size: 16)),
                  ])),
              Flexible(
                  child: SingleChildScrollView(
                      physics: const BouncingScrollPhysics(),
                      keyboardDismissBehavior:
                          ScrollViewKeyboardDismissBehavior.onDrag,
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Container(
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                    color: statusColor.withValues(alpha: .07),
                                    borderRadius: BorderRadius.circular(12),
                                    border: Border.all(
                                        color: statusColor.withValues(
                                            alpha: .18))),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('DELIVERY REFERENCE',
                                          style: AppTypography.font(
                                              fontSize: AppTypography.microSize,
                                              fontWeight: AppTypography.headingWeight,
                                              letterSpacing: .7,
                                              color: secondary)),
                                      const SizedBox(height: 6),
                                      SelectableText(
                                          reference.isEmpty
                                              ? 'Not available'
                                              : reference,
                                          style: AppTypography.font(
                                              fontSize: AppTypography.actionSize,
                                              fontWeight: AppTypography.headingWeight,
                                              color: foreground)),
                                      const SizedBox(height: 12),
                                      Wrap(
                                          spacing: 8,
                                          runSpacing: 8,
                                          children: [
                                            _badge(
                                                status,
                                                Icons.local_shipping_outlined,
                                                statusColor),
                                            _badge('$priority priority',
                                                Icons.flag_outlined, secondary),
                                          ]),
                                    ])),
                            ...sections.map((section) => Padding(
                                padding: const EdgeInsets.only(top: 18),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Row(children: [
                                        Icon(section.icon,
                                            size: 16, color: AppColors.primary),
                                        const SizedBox(width: 8),
                                        Expanded(
                                            child: Text(section.title,
                                                style: AppTypography.font(
                                                    fontSize: AppTypography.captionSize,
                                                    fontWeight: AppTypography.headingWeight,
                                                    color: foreground)))
                                      ]),
                                      const SizedBox(height: 10),
                                      LayoutBuilder(
                                          builder: (context, constraints) {
                                        final paired =
                                            constraints.maxWidth >= 300 &&
                                                MediaQuery.textScalerOf(context)
                                                        .scale(12) <=
                                                    18;
                                        final width = paired
                                            ? (constraints.maxWidth - 10) / 2
                                            : constraints.maxWidth;
                                        return Wrap(
                                            spacing: 10,
                                            runSpacing: 10,
                                            children: section.fields
                                                .map((field) => SizedBox(
                                                    width: width,
                                                    child: Container(
                                                        padding:
                                                            const EdgeInsets
                                                                .all(12),
                                                        decoration: BoxDecoration(
                                                            color: dark
                                                                ? Colors.white
                                                                    .withValues(
                                                                        alpha:
                                                                            .04)
                                                                : AppColors
                                                                    .neutral50,
                                                            borderRadius:
                                                                BorderRadius.circular(
                                                                    10),
                                                            border: Border.all(
                                                                color: dark
                                                                    ? Colors
                                                                        .white10
                                                                    : AppColors
                                                                        .neutral200)),
                                                        child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(field.$1,
                                                                  style: AppTypography.font(
                                                                      fontSize:
                                                                          AppTypography.fieldLabelSize,
                                                                      color:
                                                                          secondary)),
                                                              const SizedBox(
                                                                  height: 5),
                                                              Text(
                                                                  field.$2
                                                                          .trim()
                                                                          .isEmpty
                                                                      ? 'Not provided'
                                                                      : field
                                                                          .$2,
                                                                  style: AppTypography.font(
                                                                      fontSize:
                                                                          AppTypography.captionSize,
                                                                      fontWeight:
                                                                          FontWeight
                                                                              .w500,
                                                                      color:
                                                                          foreground)),
                                                            ]))))
                                                .toList());
                                      }),
                                    ]))),
                            const SizedBox(height: 16),
                          ]))),
              Padding(
                  padding: const EdgeInsets.fromLTRB(24, 14, 24, 20),
                  child: Row(children: [
                    Expanded(
                        child: onEdit == null
                            ? FilledButton(
                                onPressed: close,
                                style: buttonStyle,
                                child: const Text('Close'))
                            : OutlinedButton(
                                onPressed: close,
                                style: buttonStyle,
                                child: const Text('Close'))),
                    if (onEdit != null) ...[
                      const SizedBox(width: 12),
                      Expanded(
                          child: FilledButton(
                              onPressed: () {
                                close();
                                onEdit!();
                              },
                              style: buttonStyle,
                              child: const Text('Edit delivery')))
                    ],
                  ])),
            ])));
  }

  Widget _badge(String label, IconData icon, Color color) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
          color: color.withValues(alpha: .09),
          borderRadius: BorderRadius.circular(8)),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 6),
        Flexible(
            child: Text(label,
                style: AppTypography.font(
                    fontSize: AppTypography.fieldLabelSize, fontWeight: AppTypography.headingWeight, color: color)))
      ]));
}
