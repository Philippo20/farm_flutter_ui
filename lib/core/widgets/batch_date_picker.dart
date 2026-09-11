import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import 'app_dialog.dart';

Future<DateTime?> showBatchDatePicker({
  required BuildContext context,
  required DateTime initialDate,
  required DateTime firstDate,
  required DateTime lastDate,
}) =>
    showAppDialog<DateTime>(
      context: context,
      builder: (_) => BatchDatePicker(
          initialDate: initialDate, firstDate: firstDate, lastDate: lastDate),
    );

class BatchDatePicker extends StatefulWidget {
  const BatchDatePicker(
      {super.key,
      required this.initialDate,
      required this.firstDate,
      required this.lastDate});
  final DateTime initialDate, firstDate, lastDate;
  @override
  State<BatchDatePicker> createState() => _BatchDatePickerState();
}

class _BatchDatePickerState extends State<BatchDatePicker> {
  late DateTime _selected;
  @override
  void initState() {
    super.initState();
    final date = DateUtils.dateOnly(widget.initialDate);
    final first = DateUtils.dateOnly(widget.firstDate);
    final last = DateUtils.dateOnly(widget.lastDate);
    _selected =
        date.isBefore(first) ? first : (date.isAfter(last) ? last : date);
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final foreground = colors.onSurface;
    final secondary = colors.onSurfaceVariant;
    final body = AppTypography.bodySmall.copyWith(color: foreground);
    final buttons = ButtonStyle(
      textStyle: WidgetStatePropertyAll(AppTypography.labelLarge),
      padding: const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
      shape: WidgetStatePropertyAll(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))),
    );
    return AppDialog(
      backgroundColor: colors.surface,
      surfaceTintColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
            maxWidth: 500, maxHeight: MediaQuery.sizeOf(context).height * .9),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                      colors: [AppColors.primary, Color(0xff15803d)]),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.calendar_today_outlined,
                    size: 20, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Batch start date',
                        style: AppTypography.titleSmall
                            .copyWith(color: foreground)),
                    const SizedBox(height: 4),
                    Text('Choose when this batch begins',
                        style:
                            AppTypography.bodySmall.copyWith(color: secondary)),
                  ])),
              IconButton(
                  tooltip: 'Close',
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close, size: 16)),
            ]),
          ),
          Flexible(
              child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                        color: colors.surfaceContainerLow,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: colors.outlineVariant)),
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Selected date',
                              style: AppTypography.label
                                  .copyWith(color: secondary)),
                          const SizedBox(height: 6),
                          Text(DateFormat('EEE, d MMM yyyy').format(_selected),
                              style: body),
                        ]),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                      height: 300,
                      child: SfDateRangePicker(
                        initialSelectedDate: _selected,
                        initialDisplayDate: _selected,
                        minDate: DateUtils.dateOnly(widget.firstDate),
                        maxDate: DateUtils.dateOnly(widget.lastDate),
                        selectionMode: DateRangePickerSelectionMode.single,
                        showNavigationArrow: true,
                        backgroundColor: colors.surface,
                        selectionColor: AppColors.primary,
                        todayHighlightColor: AppColors.primary,
                        selectionTextStyle: body.copyWith(color: Colors.white),
                        headerStyle: DateRangePickerHeaderStyle(
                            backgroundColor: colors.surface,
                            textStyle: AppTypography.labelLarge
                                .copyWith(color: foreground)),
                        monthViewSettings: DateRangePickerMonthViewSettings(
                            firstDayOfWeek: 1,
                            viewHeaderStyle: DateRangePickerViewHeaderStyle(
                                textStyle: AppTypography.label
                                    .copyWith(color: secondary))),
                        monthCellStyle: DateRangePickerMonthCellStyle(
                            textStyle: body,
                            todayTextStyle:
                                body.copyWith(color: AppColors.primary),
                            disabledDatesTextStyle: body.copyWith(
                                color: colors.onSurface.withValues(alpha: .3))),
                        yearCellStyle: DateRangePickerYearCellStyle(
                            textStyle: body,
                            todayTextStyle:
                                body.copyWith(color: AppColors.primary),
                            disabledDatesTextStyle: body.copyWith(
                                color: colors.onSurface.withValues(alpha: .3))),
                        onSelectionChanged: (args) {
                          if (args.value is DateTime) {
                            setState(() => _selected = args.value as DateTime);
                          }
                        },
                      )),
                  Text('The harvest date is calculated from the crop variety.',
                      style:
                          AppTypography.bodySmall.copyWith(color: secondary)),
                ]),
          )),
          Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 24),
            child: Row(children: [
              Expanded(
                  child: OutlinedButton(
                      style: buttons,
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancel'))),
              const SizedBox(width: 12),
              Expanded(
                  child: FilledButton(
                      style: buttons,
                      onPressed: () => Navigator.pop(context, _selected),
                      child: const Text('Apply date'))),
            ]),
          ),
        ]),
      ),
    );
  }
}
