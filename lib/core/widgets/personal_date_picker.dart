import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../theme/app_typography.dart';

/// Syncfusion paints calendar text with a single scale(1) multiplier. Apply
/// the inherited scaler to each font size first, then prevent double scaling
/// inside the picker. The rest of the dialog keeps its normal inherited scale.
class PersonalDatePicker extends StatelessWidget {
  const PersonalDatePicker({super.key, required this.picker});
  final SfDateRangePicker picker;

  @override
  Widget build(BuildContext context) {
    final scaler = MediaQuery.textScalerOf(context);
    TextStyle font(TextStyle? style,
            [double size = AppTypography.actionSize]) =>
        (style ?? const TextStyle())
            .copyWith(fontSize: scaler.scale(style?.fontSize ?? size));
    final p = picker;
    final month = p.monthCellStyle;
    final year = p.yearCellStyle;
    final settings = p.monthViewSettings;
    final headerSize =
        p.headerStyle.textStyle?.fontSize ?? AppTypography.cardTitleSize;
    final viewHeaderSize =
        settings.viewHeaderStyle.textStyle?.fontSize ?? AppTypography.bodySize;
    final theme = Theme.of(context);
    final texts = theme.textTheme;
    return MediaQuery(
      data: MediaQuery.of(context).copyWith(textScaler: TextScaler.noScaling),
      child: Theme(
        data: theme.copyWith(
            textTheme: texts.copyWith(
          labelLarge: font(texts.labelLarge, AppTypography.actionSize),
          bodyMedium: font(texts.bodyMedium, AppTypography.bodySize),
        )),
        child: SfDateRangePicker(
          key: p.key,
          view: p.view,
          selectionMode: p.selectionMode,
          headerHeight: p.headerHeight +
              (scaler.scale(headerSize) - headerSize).clamp(0, double.infinity),
          todayHighlightColor: p.todayHighlightColor,
          backgroundColor: p.backgroundColor,
          initialSelectedDate: p.initialSelectedDate,
          initialSelectedDates: p.initialSelectedDates,
          initialSelectedRange: p.initialSelectedRange,
          initialSelectedRanges: p.initialSelectedRanges,
          initialDisplayDate: p.initialDisplayDate,
          toggleDaySelection: p.toggleDaySelection,
          enablePastDates: p.enablePastDates,
          showNavigationArrow: p.showNavigationArrow,
          confirmText: p.confirmText,
          cancelText: p.cancelText,
          showActionButtons: p.showActionButtons,
          selectionShape: p.selectionShape,
          navigationDirection: p.navigationDirection,
          allowViewNavigation: p.allowViewNavigation,
          navigationMode: p.navigationMode,
          enableMultiView: p.enableMultiView,
          controller: p.controller,
          onViewChanged: p.onViewChanged,
          onSelectionChanged: p.onSelectionChanged,
          onCancel: p.onCancel,
          onSubmit: p.onSubmit,
          minDate: p.minDate,
          maxDate: p.maxDate,
          viewSpacing: p.viewSpacing,
          selectionRadius: p.selectionRadius,
          selectionColor: p.selectionColor,
          startRangeSelectionColor: p.startRangeSelectionColor,
          endRangeSelectionColor: p.endRangeSelectionColor,
          rangeSelectionColor: p.rangeSelectionColor,
          selectionTextStyle: font(p.selectionTextStyle),
          rangeTextStyle: font(p.rangeTextStyle),
          monthFormat: p.monthFormat,
          cellBuilder: p.cellBuilder == null
              ? null
              : (cellContext, details) => MediaQuery(
                  data: MediaQuery.of(cellContext).copyWith(textScaler: scaler),
                  child: Builder(
                      builder: (context) => p.cellBuilder!(context, details))),
          showTodayButton: p.showTodayButton,
          selectableDayPredicate: p.selectableDayPredicate,
          extendableRangeSelectionDirection:
              p.extendableRangeSelectionDirection,
          headerStyle: DateRangePickerHeaderStyle(
            textAlign: p.headerStyle.textAlign,
            backgroundColor: p.headerStyle.backgroundColor,
            textStyle:
                font(p.headerStyle.textStyle, AppTypography.cardTitleSize),
          ),
          monthViewSettings: DateRangePickerMonthViewSettings(
            numberOfWeeksInView: settings.numberOfWeeksInView,
            firstDayOfWeek: settings.firstDayOfWeek,
            dayFormat: settings.dayFormat,
            viewHeaderHeight: settings.viewHeaderHeight +
                (scaler.scale(viewHeaderSize) - viewHeaderSize)
                    .clamp(0, double.infinity),
            showTrailingAndLeadingDates: settings.showTrailingAndLeadingDates,
            enableSwipeSelection: settings.enableSwipeSelection,
            blackoutDates: settings.blackoutDates,
            specialDates: settings.specialDates,
            weekendDays: settings.weekendDays,
            showWeekNumber: settings.showWeekNumber,
            weekNumberStyle: DateRangePickerWeekNumberStyle(
                backgroundColor: settings.weekNumberStyle.backgroundColor,
                textStyle: font(settings.weekNumberStyle.textStyle,
                    AppTypography.actionSize)),
            viewHeaderStyle: DateRangePickerViewHeaderStyle(
                backgroundColor: settings.viewHeaderStyle.backgroundColor,
                textStyle: font(settings.viewHeaderStyle.textStyle,
                    AppTypography.bodySize)),
          ),
          monthCellStyle: DateRangePickerMonthCellStyle(
            textStyle: font(month.textStyle),
            todayTextStyle: font(month.todayTextStyle,
                month.textStyle?.fontSize ?? AppTypography.actionSize),
            trailingDatesTextStyle: font(month.trailingDatesTextStyle,
                month.textStyle?.fontSize ?? AppTypography.actionSize),
            leadingDatesTextStyle: font(month.leadingDatesTextStyle,
                month.textStyle?.fontSize ?? AppTypography.actionSize),
            disabledDatesTextStyle: font(month.disabledDatesTextStyle,
                month.textStyle?.fontSize ?? AppTypography.actionSize),
            blackoutDateTextStyle: font(month.blackoutDateTextStyle,
                month.textStyle?.fontSize ?? AppTypography.actionSize),
            weekendTextStyle: font(month.weekendTextStyle,
                month.textStyle?.fontSize ?? AppTypography.actionSize),
            specialDatesTextStyle: font(month.specialDatesTextStyle,
                month.textStyle?.fontSize ?? AppTypography.actionSize),
            specialDatesDecoration: month.specialDatesDecoration,
            blackoutDatesDecoration: month.blackoutDatesDecoration,
            cellDecoration: month.cellDecoration,
            todayCellDecoration: month.todayCellDecoration,
            disabledDatesDecoration: month.disabledDatesDecoration,
            trailingDatesDecoration: month.trailingDatesDecoration,
            leadingDatesDecoration: month.leadingDatesDecoration,
            weekendDatesDecoration: month.weekendDatesDecoration,
          ),
          yearCellStyle: DateRangePickerYearCellStyle(
            textStyle: font(year.textStyle),
            todayTextStyle: font(year.todayTextStyle,
                year.textStyle?.fontSize ?? AppTypography.actionSize),
            leadingDatesTextStyle: font(year.leadingDatesTextStyle,
                year.textStyle?.fontSize ?? AppTypography.actionSize),
            disabledDatesTextStyle: font(year.disabledDatesTextStyle,
                year.textStyle?.fontSize ?? AppTypography.actionSize),
            cellDecoration: year.cellDecoration,
            todayCellDecoration: year.todayCellDecoration,
            disabledDatesDecoration: year.disabledDatesDecoration,
            leadingDatesDecoration: year.leadingDatesDecoration,
          ),
        ),
      ),
    );
  }
}
