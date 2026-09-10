import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../theme/app_colors.dart';
import 'app_dialog.dart';

class SensorDateRangeModal extends StatefulWidget {
  const SensorDateRangeModal({super.key, this.initialRange});
  final DateTimeRange? initialRange;
  @override
  State<SensorDateRangeModal> createState() => _SensorDateRangeModalState();
}

class _SensorDateRangeModalState extends State<SensorDateRangeModal> {
  final _controller = DateRangePickerController();
  DateTime? _start, _end;
  DateTime get _today => DateUtils.dateOnly(DateTime.now());
  @override
  void initState() {
    super.initState();
    _start = widget.initialRange?.start;
    _end = widget.initialRange?.end;
    if (_start != null) {
      _controller.selectedRange = PickerDateRange(_start, _end);
      _controller.displayDate = _end ?? _start;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _preset(int days) {
    final end = _today;
    final start = DateTime(end.year, end.month, end.day - days + 1);
    setState(() {
      _start = start;
      _end = end;
    });
    _controller.selectedRange = PickerDateRange(start, end);
    _controller.displayDate = end;
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final surface = dark ? AppColors.surfaceDark : Colors.white;
    final foreground = dark ? Colors.white : AppColors.textPrimary;
    final secondary = dark ? Colors.white60 : AppColors.textSecondary;
    TextStyle text(double size, {bool bold = false, Color? color}) =>
        GoogleFonts.inter(
            fontSize: size,
            fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
            color: color ?? foreground);
    Widget dateBox(String title, DateTime? date) => Expanded(
        child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: dark
                    ? Colors.white.withValues(alpha: .04)
                    : AppColors.neutral50,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: dark ? Colors.white10 : AppColors.neutral200)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(title, style: text(11, bold: true, color: secondary)),
              const SizedBox(height: 6),
              Text(
                  date == null
                      ? 'Select date'
                      : DateFormat('d MMM yyyy').format(date),
                  style: text(12))
            ])));
    final buttons = ButtonStyle(
        padding:
            const WidgetStatePropertyAll(EdgeInsets.symmetric(vertical: 12)),
        textStyle: WidgetStatePropertyAll(text(13, bold: true)),
        shape: WidgetStatePropertyAll(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(10))));
    return AppDialog(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
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
                        child: const Icon(Icons.date_range_outlined,
                            size: 20, color: Colors.white)),
                    const SizedBox(width: 12),
                    Expanded(
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                          Text('Reading period',
                              style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                  color: foreground)),
                          const SizedBox(height: 4),
                          Text('Choose a day or date range',
                              style: text(12, color: secondary))
                        ])),
                    IconButton(
                        tooltip: 'Close',
                        visualDensity: VisualDensity.compact,
                        onPressed: () => Navigator.pop(context),
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
                            Wrap(spacing: 8, runSpacing: 6, children: [
                              for (final preset in [
                                ('Today', 1),
                                ('Last 7 days', 7),
                                ('Last 30 days', 30)
                              ])
                                OutlinedButton(
                                    onPressed: () => _preset(preset.$2),
                                    style: OutlinedButton.styleFrom(
                                        textStyle: text(11)),
                                    child: Text(preset.$1))
                            ]),
                            const SizedBox(height: 14),
                            Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  dateBox('From', _start),
                                  const SizedBox(width: 10),
                                  dateBox('To', _end ?? _start)
                                ]),
                            const SizedBox(height: 14),
                            SizedBox(
                                height: 290,
                                child: SfDateRangePicker(
                                  controller: _controller,
                                  selectionMode:
                                      DateRangePickerSelectionMode.range,
                                  minDate: DateTime(2000),
                                  maxDate: _today,
                                  showNavigationArrow: true,
                                  backgroundColor: surface,
                                  todayHighlightColor: AppColors.primary,
                                  startRangeSelectionColor: AppColors.primary,
                                  endRangeSelectionColor: AppColors.primary,
                                  rangeSelectionColor:
                                      AppColors.primary.withValues(alpha: .12),
                                  selectionTextStyle:
                                      text(12, color: Colors.white),
                                  rangeTextStyle: text(12),
                                  headerStyle: DateRangePickerHeaderStyle(
                                      backgroundColor: surface,
                                      textStyle: text(13, bold: true)),
                                  monthViewSettings:
                                      DateRangePickerMonthViewSettings(
                                          firstDayOfWeek: 1,
                                          viewHeaderStyle:
                                              DateRangePickerViewHeaderStyle(
                                                  textStyle: text(11,
                                                      color: secondary))),
                                  monthCellStyle: DateRangePickerMonthCellStyle(
                                      textStyle: text(12),
                                      todayTextStyle: text(12, bold: true),
                                      disabledDatesTextStyle: text(12,
                                          color:
                                              secondary.withValues(alpha: .4))),
                                  yearCellStyle: DateRangePickerYearCellStyle(
                                      textStyle: text(12),
                                      todayTextStyle: text(12, bold: true)),
                                  onSelectionChanged: (args) {
                                    if (args.value is PickerDateRange) {
                                      final range =
                                          args.value as PickerDateRange;
                                      setState(() {
                                        _start = range.startDate;
                                        _end = range.endDate;
                                      });
                                    }
                                  },
                                )),
                            Text(
                                'The selected end date includes the whole day.',
                                style: text(11, color: secondary)),
                          ]))),
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
                            onPressed: _start == null
                                ? null
                                : () => Navigator.pop(
                                    context,
                                    DateTimeRange(
                                        start: _start!, end: _end ?? _start!)),
                            child: const Text('Apply range'))),
                  ])),
            ])));
  }
}
