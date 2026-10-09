import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/typography_preferences.dart';
import '../../providers/auth_provider.dart';
import '../providers/personal_appearance_provider.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_bottom_sheet.dart';
import 'app_dialog.dart';

class PersonalTypographyCard extends ConsumerWidget {
  const PersonalTypographyCard({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userId = ref.watch(authProvider.select((auth) => auth.user?.id));
    if (userId == null) return const SizedBox.shrink();
    final state = ref.watch(personalAppearanceProvider(userId));
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
          Icon(Icons.text_fields_rounded, color: colors.primary, size: 22),
          const SizedBox(width: 10),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                Text('Personal text sizes',
                    style: AppTypography.titleSmall
                        .copyWith(color: colors.onSurface)),
                const SizedBox(height: 4),
                Text(
                    'Adjust headings, titles, body text and labels. Only your account, across all your devices.',
                    style: AppTypography.bodySmall
                        .copyWith(color: colors.onSurfaceVariant)),
              ])),
        ]),
        const SizedBox(height: 12),
        if (state.error != null) ...[
          Text(state.error!,
              style: AppTypography.bodySmall.copyWith(color: colors.error)),
          const SizedBox(height: 8),
        ],
        Wrap(spacing: 10, runSpacing: 8, children: [
          OutlinedButton.icon(
              onPressed: state.ready
                  ? () => showPersonalTypographyModal(context,
                      initial: state.value,
                      onSave: (value) => ref
                          .read(personalAppearanceProvider(userId).notifier)
                          .save(value))
                  : null,
              icon: state.loading
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.tune_rounded, size: 16),
              label: Text(
                  state.loading ? 'Loading text sizes…' : 'Preview & adjust')),
          if (state.error != null)
            TextButton.icon(
                onPressed: () => ref
                    .read(personalAppearanceProvider(userId).notifier)
                    .refresh(),
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Retry sync')),
        ]),
      ]),
    );
  }
}

Future<bool?> showPersonalTypographyModal(
  BuildContext context, {
  required TypographyPreferences initial,
  required Future<void> Function(TypographyPreferences) onSave,
}) {
  final mobile = MediaQuery.sizeOf(context).width < 600 ||
      Theme.of(context).platform == TargetPlatform.android;
  final modal =
      _TypographyModal(initial: initial, onSave: onSave, mobile: mobile);
  if (mobile) {
    return showAppBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        useSafeArea: true,
        isDismissible: false,
        enableDrag: false,
        backgroundColor: Colors.transparent,
        builder: (_) => modal);
  }
  return showAppDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => AppDialog(
          backgroundColor: Colors.transparent,
          insetPadding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: modal));
}

class _TypographyModal extends StatefulWidget {
  const _TypographyModal(
      {required this.initial, required this.onSave, required this.mobile});
  final TypographyPreferences initial;
  final Future<void> Function(TypographyPreferences) onSave;
  final bool mobile;
  @override
  State<_TypographyModal> createState() => _TypographyModalState();
}

class _TypographyModalState extends State<_TypographyModal> {
  late TypographyPreferences _draft = widget.initial;
  bool _saving = false;
  String? _error;
  final _scroll = ScrollController();
  TextStyle font(double size, {FontWeight weight = FontWeight.w400}) =>
      AppTypography.font(fontSize: size, fontWeight: weight);

  Future<void> _save() async {
    if (_saving) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave(_draft);
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = error.toString().replaceFirst('Exception: ', '');
      });
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted && _scroll.hasClients)
          _scroll.animateTo(_scroll.position.maxScrollExtent,
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeOut);
      });
    }
  }

  Widget _slider(String key, String title, String description) {
    final value = (_draft.toJson()[key] as num).toDouble();
    return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Expanded(
                child: Text(title, style: font(11, weight: FontWeight.w600))),
            const SizedBox(width: 8),
            Text('${(value * 100).round()}%', style: font(12)),
          ]),
          const SizedBox(height: 6),
          Text(description,
              style: font(12).copyWith(
                  color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Slider(
              key: ValueKey('font-$key'),
              value: value,
              min: .85,
              max: 1.35,
              divisions: 10,
              label: '${(value * 100).round()}%',
              onChanged: _saving
                  ? null
                  : (next) =>
                      setState(() => _draft = _draft.withValue(key, next))),
        ]));
  }

  Widget _pair(Widget left, Widget right) => widget.mobile
      ? Column(children: [left, right])
      : Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Expanded(child: left),
          const SizedBox(width: 10),
          Expanded(child: right)
        ]);

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = Theme.of(context).brightness == Brightness.dark;
    final shell = Container(
        constraints: BoxConstraints(
            maxWidth: widget.mobile ? double.infinity : 500,
            maxHeight: MediaQuery.sizeOf(context).height * .9),
        decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: dark ? .3 : .12),
                  blurRadius: 24,
                  offset: const Offset(0, 12))
            ]),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
              padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
              child: Row(children: [
                Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        gradient: const LinearGradient(
                            colors: [AppColors.primary, AppColors.primaryDark]),
                        borderRadius: BorderRadius.circular(10)),
                    child: const Icon(Icons.text_fields_rounded,
                        size: 20, color: Colors.white)),
                const SizedBox(width: 12),
                Expanded(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                      Text('Personal text sizes',
                          style: font(16, weight: FontWeight.bold)),
                      const SizedBox(height: 4),
                      Text('Preview changes before saving.',
                          style: font(12)
                              .copyWith(color: colors.onSurfaceVariant)),
                    ])),
                IconButton(
                    onPressed:
                        _saving ? null : () => Navigator.pop(context, false),
                    tooltip: 'Close',
                    icon: const Icon(Icons.close, size: 16)),
              ])),
          Flexible(
              child: SingleChildScrollView(
                  controller: _scroll,
                  physics: const BouncingScrollPhysics(),
                  keyboardDismissBehavior:
                      ScrollViewKeyboardDismissBehavior.onDrag,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                            'Your choices apply to this account on web, desktop and Android. Device accessibility settings are still respected.',
                            style: font(12)
                                .copyWith(color: colors.onSurfaceVariant)),
                        const SizedBox(height: 16),
                        _pair(
                            _slider('headings', 'Page headings & large values',
                                'Dashboard headings and prominent numbers'),
                            _slider('titles', 'Section & card titles',
                                'Section headings, card titles and dialog titles')),
                        _pair(
                            _slider('body', 'Body text & actions',
                                'Descriptions, messages and most actions'),
                            _slider('labels', 'Labels & small text',
                                'Field labels, compact inputs and captions')),
                        Text('Live preview',
                            style: font(11, weight: FontWeight.w600)),
                        const SizedBox(height: 6),
                        MediaQuery(
                            data: MediaQuery.of(context).copyWith(
                                textScaler: PersonalTextScaler(
                                    _draft, systemTextScalerOf(context))),
                            child: Container(
                                key: const ValueKey('font-preview'),
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                    color: colors.surfaceContainerLow,
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                        color: colors.outlineVariant)),
                                child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text('Your dashboard',
                                          style: font(24,
                                              weight: FontWeight.w600)),
                                      const SizedBox(height: 12),
                                      Text('Farm overview',
                                          style: font(18,
                                              weight: FontWeight.w600)),
                                      const SizedBox(height: 8),
                                      Text(
                                          'Review your latest updates and farm activity.',
                                          style: font(14)),
                                      const SizedBox(height: 8),
                                      Text('Last updated just now',
                                          style: font(12).copyWith(
                                              color: colors.onSurfaceVariant)),
                                    ]))),
                        const SizedBox(height: 10),
                        TextButton.icon(
                            onPressed: _saving
                                ? null
                                : () => setState(() =>
                                    _draft = TypographyPreferences.defaults),
                            icon:
                                const Icon(Icons.restart_alt_rounded, size: 16),
                            label: Text('Reset to default sizes',
                                style: font(13))),
                        if (_error != null)
                          Padding(
                              padding:
                                  const EdgeInsets.only(top: 8, bottom: 14),
                              child: Text(_error!,
                                  style:
                                      font(12).copyWith(color: colors.error))),
                      ]))),
          Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 24, 20),
              child: Row(children: [
                Expanded(
                    child: OutlinedButton(
                        onPressed: _saving
                            ? null
                            : () => Navigator.pop(context, false),
                        style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: Text('Cancel', style: font(13)))),
                const SizedBox(width: 12),
                Expanded(
                    child: FilledButton(
                        onPressed: _saving ? null : _save,
                        style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10))),
                        child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_saving) ...[
                                const SizedBox(
                                    width: 14,
                                    height: 14,
                                    child: CircularProgressIndicator(
                                        strokeWidth: 2, color: Colors.white)),
                                const SizedBox(width: 8)
                              ],
                              Flexible(
                                  child: Text(
                                      _saving ? 'Saving…' : 'Save sizes',
                                      style: font(13))),
                            ]))),
              ])),
        ]));
    return PopScope(
        canPop: !_saving,
        child: Padding(
            padding: EdgeInsets.only(
                bottom: MediaQuery.viewInsetsOf(context).bottom),
            child: widget.mobile ? SafeArea(top: false, child: shell) : shell));
  }

  @override
  void dispose() {
    _scroll.dispose();
    super.dispose();
  }
}
