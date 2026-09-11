import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';

/// Shared experience editor for the Admin and Super Admin consoles.
class TraceabilityExperienceEditor extends StatelessWidget {
  const TraceabilityExperienceEditor(
      {super.key,
      required this.controllers,
      required this.settings,
      required this.onToggle,
      required this.onSave,
      required this.saving});
  final Map<String, TextEditingController> controllers;
  final Map<String, dynamic> settings;
  final void Function(String, bool) onToggle;
  final VoidCallback onSave;
  final bool saving;

  Widget _grid(List<Widget> children, {double minimumWidth = 280}) =>
      LayoutBuilder(
        builder: (context, box) {
          final paired = box.maxWidth >= minimumWidth * 2 + 16 &&
              MediaQuery.textScalerOf(context).scale(12) <= 18;
          final width = paired ? (box.maxWidth - 16) / 2 : box.maxWidth;
          return Wrap(
              spacing: 16,
              runSpacing: 14,
              children: children
                  .map((child) => SizedBox(width: width, child: child))
                  .toList());
        },
      );

  Widget _card(BuildContext context, String title, String subtitle,
      IconData icon, List<Widget> children) {
    final colors = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.outlineVariant)),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                  color: colors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, size: 20, color: AppColors.primary)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text(title,
                    style: AppTypography.titleSmall
                        .copyWith(color: colors.onSurface)),
                const SizedBox(height: 4),
                Text(subtitle,
                    style: AppTypography.bodySmall
                        .copyWith(color: colors.onSurfaceVariant)),
              ])),
        ]),
        const SizedBox(height: 18),
        ...children,
      ]),
    );
  }

  Widget _field(BuildContext context, String key, String label, IconData icon,
      {TextInputType? keyboard, String? hint, bool color = false}) {
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label,
          style: AppTypography.label.copyWith(color: colors.onSurfaceVariant)),
      const SizedBox(height: 6),
      TextField(
        controller: controllers[key],
        enabled: !saving,
        style: AppTypography.bodySmall.copyWith(color: colors.onSurface),
        keyboardType: keyboard,
        textInputAction: TextInputAction.next,
        decoration: InputDecoration(
          hintText: hint,
          hintStyle:
              AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant),
          prefixIcon: Icon(icon, size: 16),
          suffixIcon: color
              ? ValueListenableBuilder<TextEditingValue>(
                  valueListenable: controllers[key]!,
                  builder: (_, value, __) {
                    final hex = value.text.trim().replaceFirst('#', '');
                    final parsed = RegExp(r'^[0-9a-fA-F]{6}$').hasMatch(hex)
                        ? int.tryParse('ff$hex', radix: 16)
                        : null;
                    return Padding(
                        padding: const EdgeInsets.all(12),
                        child: Container(
                            width: 18,
                            height: 18,
                            decoration: BoxDecoration(
                                color: parsed == null
                                    ? colors.surface
                                    : Color(parsed),
                                border: Border.all(color: colors.outline),
                                borderRadius: BorderRadius.circular(5))));
                  },
                )
              : null,
          filled: true,
          fillColor: colors.surfaceContainerLow,
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
                  const BorderSide(color: AppColors.primary, width: 1.5)),
        ),
      ),
    ]);
  }

  Widget _toggle(BuildContext context, String key, String title,
      String description, IconData icon,
      {bool defaultValue = true}) {
    final colors = Theme.of(context).colorScheme;
    final enabled =
        settings[key] is bool ? settings[key] as bool : defaultValue;
    return Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Padding(
          padding: const EdgeInsets.only(top: 3),
          child: Icon(icon, size: 18, color: colors.onSurfaceVariant)),
      const SizedBox(width: 10),
      Expanded(
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title,
            style: AppTypography.labelLarge.copyWith(color: colors.onSurface)),
        const SizedBox(height: 4),
        Text(description,
            style: AppTypography.bodySmall
                .copyWith(color: colors.onSurfaceVariant)),
      ])),
      const SizedBox(width: 8),
      Semantics(
          label: title,
          child: Switch.adaptive(
              value: enabled,
              onChanged: saving ? null : (value) => onToggle(key, value))),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
      Text('Consumer experience',
          style: AppTypography.titleMedium.copyWith(color: colors.onSurface)),
      const SizedBox(height: 4),
      Text('Customize what customers see when they scan a product.',
          style:
              AppTypography.bodySmall.copyWith(color: colors.onSurfaceVariant)),
      const SizedBox(height: 16),
      _card(
          context,
          'Brand & appearance',
          'Set the identity of your public traceability page.',
          Icons.palette_outlined, [
        _grid([
          _field(context, 'brand', 'Brand name', Icons.storefront_outlined),
          _field(context, 'headline', 'Consumer headline', Icons.title_rounded),
          _field(context, 'logo', 'Logo URL', Icons.image_outlined,
              keyboard: TextInputType.url, hint: 'https://'),
          _field(context, 'site', 'Public site URL', Icons.public_outlined,
              keyboard: TextInputType.url, hint: 'https://'),
          _field(context, 'primary', 'Primary color', Icons.color_lens_outlined,
              hint: '#4CAF50', color: true),
          _field(
              context, 'secondary', 'Secondary color', Icons.palette_outlined,
              hint: '#29B6F6', color: true),
        ]),
      ]),
      const SizedBox(height: 16),
      _card(
          context,
          'Public access & support',
          'Manage verification access and customer contact details.',
          Icons.language_outlined, [
        _grid([
          _field(context, 'email', 'Support email', Icons.alternate_email,
              keyboard: TextInputType.emailAddress),
          _field(context, 'privacy', 'Privacy notice URL',
              Icons.privacy_tip_outlined,
              keyboard: TextInputType.url, hint: 'https://'),
        ]),
        const SizedBox(height: 20),
        _grid([
          _toggle(
              context,
              'lookup_enabled',
              'Product lookup',
              'Let customers verify a product using its code.',
              Icons.qr_code_scanner),
          _toggle(
              context,
              'maintenance_mode',
              'Maintenance mode',
              'Pause public verification while keeping this console available.',
              Icons.engineering_outlined,
              defaultValue: false),
        ]),
      ]),
      const SizedBox(height: 16),
      _card(
          context,
          'Product information',
          'Choose which details appear after product verification.',
          Icons.fact_check_outlined, [
        _grid([
          _toggle(
              context,
              'show_farm',
              'Farm name',
              'Identify the farm that grew the product.',
              Icons.agriculture_outlined),
          _toggle(context, 'show_location', 'Farm location',
              'Show where the product was grown.', Icons.location_on_outlined),
          _toggle(context, 'show_dates', 'Production dates',
              'Display the batch production dates.', Icons.date_range_outlined),
          _toggle(context, 'show_quality', 'Quality status',
              'Show the product quality status.', Icons.verified_outlined),
          _toggle(
              context,
              'show_journey',
              'Product journey',
              'Display the stages of the product journey.',
              Icons.route_outlined),
        ]),
      ]),
      const SizedBox(height: 16),
      _card(
          context,
          'Customer engagement',
          'Control feedback, promotions, and anonymous usage insights.',
          Icons.forum_outlined, [
        _grid([
          _toggle(
              context,
              'promotions_enabled',
              'Promotions',
              'Show your published customer promotions.',
              Icons.campaign_outlined),
          _toggle(
              context,
              'feedback_enabled',
              'Feedback & issue reports',
              'Allow customers to send feedback or report an issue.',
              Icons.feedback_outlined),
          _toggle(
              context,
              'analytics_enabled',
              'Anonymous analytics',
              'Measure engagement with the public product page.',
              Icons.insights_outlined),
        ]),
      ]),
      const SizedBox(height: 16),
      LayoutBuilder(builder: (context, box) {
        final action = FilledButton.icon(
          onPressed: saving ? null : onSave,
          style: FilledButton.styleFrom(
              textStyle: AppTypography.labelLarge,
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10))),
          icon: saving
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2))
              : const Icon(Icons.save_outlined, size: 18),
          label: Text(saving ? 'Saving changes...' : 'Save experience'),
        );
        final caption = Text('Changes take effect after saving.',
            style: AppTypography.bodySmall
                .copyWith(color: colors.onSurfaceVariant));
        if (box.maxWidth < 600) {
          return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [caption, const SizedBox(height: 10), action]);
        }
        return Row(children: [
          Expanded(child: caption),
          const SizedBox(width: 16),
          action
        ]);
      }),
    ]);
  }
}
