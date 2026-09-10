import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class DeliveryKpiGrid extends StatelessWidget {
  const DeliveryKpiGrid(
      {super.key,
      required this.mobile,
      required this.total,
      required this.pending,
      required this.inTransit,
      required this.delivered});
  final bool mobile;
  final int total, pending, inTransit, delivered;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final cards = [
      ('Deliveries', total, Icons.local_shipping, AppColors.primary),
      ('Pending Approval', pending, Icons.approval, AppColors.warning),
      ('In Transit', inTransit, Icons.route, AppColors.info),
      ('Delivered', delivered, Icons.check_circle, AppColors.success),
    ];
    return LayoutBuilder(builder: (context, constraints) {
      final columns = mobile ? 2 : (constraints.maxWidth > 1100 ? 4 : 2);
      final width = (constraints.maxWidth - 8 * (columns - 1)) / columns;
      return Wrap(
          spacing: 8,
          runSpacing: 8,
          children: cards.map((card) {
            final icon = Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                    color: card.$4.withValues(alpha: .12),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(card.$3, size: 22, color: card.$4));
            final content = Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(card.$2.toString(),
                      style: AppTypography.h6.copyWith(
                          color: dark ? Colors.white : AppColors.textPrimary,
                          fontWeight: AppTypography.headingWeight)),
                  const SizedBox(height: 2),
                  Text(card.$1,
                      style: AppTypography.caption.copyWith(
                          color:
                              dark ? Colors.white70 : AppColors.textSecondary,
                          fontWeight: AppTypography.labelWeight)),
                ]);
            return SizedBox(
                width: width,
                child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                        color: dark ? AppColors.surfaceDark : Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: dark
                                ? Colors.white10
                                : Colors.black.withValues(alpha: .06)),
                        boxShadow: [
                          BoxShadow(
                              color: Colors.black
                                  .withValues(alpha: dark ? .16 : .04),
                              blurRadius: 16,
                              offset: const Offset(0, 8))
                        ]),
                    child: width < 200
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                                icon,
                                const SizedBox(height: 12),
                                content
                              ])
                        : Row(children: [
                            icon,
                            const SizedBox(width: 16),
                            Expanded(child: content)
                          ])));
          }).toList());
    });
  }
}
