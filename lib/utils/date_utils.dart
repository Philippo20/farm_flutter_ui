
import 'package:flutter/material.dart';
import 'package:syncfusion_flutter_datepicker/datepicker.dart';
import '../../constants/colors.dart';


Future<void> showDateRangeDropdown({
  required BuildContext context,
  required DateTime? initialStart,
  required DateTime? initialEnd,
  required void Function(DateTime, DateTime) onSelected,
  required bool isDark,
  Rect? position, // for advanced positioning (optional)
  
}) async {
  OverlayEntry? overlayEntry;

  final screenWidth = MediaQuery.of(context).size.width;
  final isWide = screenWidth > 750;

  overlayEntry = OverlayEntry(
    builder: (context) {
      return GestureDetector(
        behavior: HitTestBehavior.translucent,
        onTap: () => overlayEntry?.remove(),
        child: Stack(
          children: [
            Positioned(
              right: isWide
                  ? position?.right ?? 200 
                  : null,                  
              left: isWide
                  ? null
                  : (MediaQuery.of(context).size.width - 270) / 2, // Center horizontally for small screens
              top: isWide
                  ? position?.bottom ?? 200 // Anchor under the pill
                  : MediaQuery.of(context).size.height * 0.27,     // Center-ish vertically for small screens
              child: Material(
                color: Colors.transparent,
                child: Container(
                  padding: EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: isDark ? Color(0xFF232635) : Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.15),
                        blurRadius: 22,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: SizedBox(
                    width: 250,
                    height: 300,
                    child: SfDateRangePicker(
                      backgroundColor: isDark ? Color(0xFF232635) : Colors.white,
                      headerStyle: DateRangePickerHeaderStyle(
                        backgroundColor: isDark ? Color(0xFF232635) : Colors.white,
                        textStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      monthCellStyle: DateRangePickerMonthCellStyle(
                        textStyle: TextStyle(
                          color: isDark ? Colors.white : Colors.black,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      yearCellStyle: DateRangePickerYearCellStyle(
                          textStyle: TextStyle(
                              fontWeight: FontWeight.w400, fontSize: 15,
                                    color: isDark ? Colors.white : Colors.black),
                          todayTextStyle: TextStyle(
                              fontStyle: FontStyle.italic,
                              fontSize: 15,
                              fontWeight: FontWeight.w500,
                              color: Colors.red),
                          leadingDatesDecoration: BoxDecoration(
                              color: const Color(0xFFDFDFDF),
                              border: Border.all(color: const Color(0xFFB6B6B6), width: 1),
                              shape: BoxShape.circle),
                          disabledDatesDecoration: BoxDecoration(
                              color: const Color(0xFFDFDFDF).withOpacity(0.2),
                              border: Border.all(color: const Color(0xFFB6B6B6), width: 1),
                              shape: BoxShape.circle),
                      ),
                      monthViewSettings: DateRangePickerMonthViewSettings(
                        showTrailingAndLeadingDates: true,
                        viewHeaderStyle: DateRangePickerViewHeaderStyle(
                          textStyle: TextStyle(
                            color: isDark ? Colors.white : AppColors.secondary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      startRangeSelectionColor: AppColors.primary,
                      endRangeSelectionColor: AppColors.primary,
                      selectionColor: AppColors.primary.withOpacity(0.15),
                      rangeSelectionColor: AppColors.primary.withOpacity(0.13),
                      todayHighlightColor: isDark ?  AppColors.primary : AppColors.darkBackground,
                      selectionMode: DateRangePickerSelectionMode.range,
                      initialSelectedRange: initialStart != null && initialEnd != null
                          ? PickerDateRange(initialStart, initialEnd)
                          : null,
                      onSubmit: (val) {
                        if (val is PickerDateRange && val.startDate != null && val.endDate != null) {
                          onSelected(val.startDate!, val.endDate!);
                          overlayEntry?.remove();
                        }
                      },
                      onCancel: () => overlayEntry?.remove(),
                      showActionButtons: true,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );


  Overlay.of(context).insert(overlayEntry);
}

