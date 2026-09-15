import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

class BuyerAccountCard extends StatelessWidget {
  const BuyerAccountCard(
      {super.key,
      required this.item,
      required this.isSalesPersonnel,
      required this.hasPendingUpdate,
      required this.onEdit,
      required this.onDelete});
  final Map<String, dynamic> item;
  final bool isSalesPersonnel, hasPendingUpdate;
  final VoidCallback onEdit, onDelete;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    String value(String key, String fallback) {
      final text = (item[key] ?? '').toString().trim();
      return text.isEmpty ? fallback : text;
    }

    final status = value('status', 'Active');
    final accent = status == 'Active'
        ? AppColors.success
        : status == 'Prospect'
            ? AppColors.info
            : AppColors.warning;
    Widget badge(String text, IconData icon, Color color) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
          decoration: BoxDecoration(
              color: color.withValues(alpha: .1),
              borderRadius: BorderRadius.circular(8)),
          child: Row(mainAxisSize: MainAxisSize.min, children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 6),
            Flexible(
                child: Text(text,
                    style: AppTypography.caption.copyWith(color: color))),
          ]),
        );
    Widget detail(String label, String text, IconData icon) => Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, size: 16, color: colors.onSurfaceVariant),
            const SizedBox(width: 8),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: AppTypography.label
                          .copyWith(color: colors.onSurfaceVariant)),
                  const SizedBox(height: 4),
                  Text(text,
                      style: AppTypography.bodySmall
                          .copyWith(color: colors.onSurface)),
                ])),
          ],
        );
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant)),
      child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(12)),
                  child: const Icon(Icons.storefront_outlined,
                      size: 22, color: AppColors.primary)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(value('name', 'Unnamed buyer'),
                        style: AppTypography.titleSmall
                            .copyWith(color: colors.onSurface)),
                    const SizedBox(height: 4),
                    Text(value('business_type', 'Business type not provided'),
                        style: AppTypography.bodySmall
                            .copyWith(color: colors.onSurfaceVariant)),
                  ])),
            ]),
            const SizedBox(height: 12),
            Wrap(spacing: 8, runSpacing: 8, children: [
              badge(status, Icons.circle_outlined, accent),
              if (hasPendingUpdate)
                badge('Update pending', Icons.schedule_outlined,
                    AppColors.warning),
            ]),
            const SizedBox(height: 16),
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                  child: detail(
                      'Contact person',
                      value('contact_person', 'Not provided'),
                      Icons.person_outline)),
              const SizedBox(width: 12),
              Expanded(
                  child: detail('Phone', value('phone', 'Not provided'),
                      Icons.phone_outlined)),
            ]),
            const SizedBox(height: 14),
            detail('Email', value('email', 'Not provided'), Icons.mail_outline),
            const SizedBox(height: 14),
            detail('Location', value('location', 'Not provided'),
                Icons.location_on_outlined),
            const SizedBox(height: 18),
            Row(children: [
              if (!isSalesPersonnel) ...[
                Expanded(
                    child: OutlinedButton.icon(
                        onPressed: onDelete,
                        style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.error,
                            minimumSize: const Size(0, 44)),
                        icon: const Icon(Icons.delete_outline, size: 16),
                        label: const Text('Delete'))),
                const SizedBox(width: 10),
              ],
              Expanded(
                  child: FilledButton.icon(
                      onPressed: onEdit,
                      style: FilledButton.styleFrom(
                          minimumSize: const Size(0, 44)),
                      icon: const Icon(Icons.edit_outlined, size: 16),
                      label: Text(
                          isSalesPersonnel ? 'Request update' : 'Edit buyer'))),
            ]),
          ]),
    );
  }
}
