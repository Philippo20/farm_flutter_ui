import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';
import 'skeleton_loader.dart';

/// Data column configuration
class AppDataColumn {
  final String label;
  final double? width;
  final bool numeric;
  final TextAlign? textAlign;

  const AppDataColumn({
    required this.label,
    this.width,
    this.numeric = false,
    this.textAlign,
  });
}

/// Data row configuration
class AppDataRow<T> {
  final T data;
  final List<Widget> cells;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final bool isSelected;

  AppDataRow({
    required this.data,
    required this.cells,
    this.onTap,
    this.backgroundColor,
    this.isSelected = false,
  });
}

/// Sorting configuration
class AppSortInfo {
  final int columnIndex;
  final bool ascending;

  const AppSortInfo({
    required this.columnIndex,
    this.ascending = true,
  });
}

/// Pagination configuration
class AppPaginationInfo {
  final int currentPage;
  final int totalPages;
  final int itemsPerPage;
  final int totalItems;
  final ValueChanged<int>? onPageChanged;

  const AppPaginationInfo({
    this.currentPage = 1,
    this.totalPages = 1,
    this.itemsPerPage = 10,
    this.totalItems = 0,
    this.onPageChanged,
  });
}

/// Customizable Data Table Widget
class AppDataTable<T> extends StatefulWidget {
  final List<AppDataColumn> columns;
  final List<AppDataRow<T>> rows;
  final AppSortInfo? sortInfo;
  final ValueChanged<AppSortInfo>? onSort;
  final AppPaginationInfo? pagination;
  final bool selectable;
  final ValueChanged<List<T>>? onSelectionChanged;
  final bool striped;
  final bool showCheckboxes;
  final bool showHeader;
  final double? minWidth;
  final ScrollController? horizontalScrollController;
  final ScrollController? verticalScrollController;
  final bool shrinkWrap;
  final EdgeInsetsGeometry? padding;
  final Color? headerBackgroundColor;
  final Color? rowBackgroundColor;
  final Color? selectedRowColor;
  final BorderRadiusGeometry? borderRadius;
  final BoxBorder? border;
  final Widget? emptyWidget;
  final String? emptyMessage;
  final Widget? loadingWidget;
  final bool isLoading;
  final double? rowHeight;
  final bool showBorder;
  final bool fixedHeader;
  final Widget? trailingHeaderWidget;

  const AppDataTable({
    super.key,
    required this.columns,
    required this.rows,
    this.sortInfo,
    this.onSort,
    this.pagination,
    this.selectable = false,
    this.onSelectionChanged,
    this.striped = false,
    this.showCheckboxes = false,
    this.showHeader = true,
    this.minWidth,
    this.horizontalScrollController,
    this.verticalScrollController,
    this.shrinkWrap = false,
    this.padding,
    this.headerBackgroundColor,
    this.rowBackgroundColor,
    this.selectedRowColor,
    this.borderRadius,
    this.border,
    this.emptyWidget,
    this.emptyMessage,
    this.loadingWidget,
    this.isLoading = false,
    this.rowHeight,
    this.showBorder = true,
    this.fixedHeader = false,
    this.trailingHeaderWidget,
  });

  @override
  State<AppDataTable<T>> createState() => _AppDataTableState<T>();
}

class _AppDataTableState<T> extends State<AppDataTable<T>> {
  final List<T> _selectedItems = [];
  final ScrollController _horizontalScrollController = ScrollController();
  final ScrollController _verticalScrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    // Initialize selected items from rows
    if (widget.selectable) {
      _selectedItems.clear();
      for (final row in widget.rows) {
        if (row.isSelected) {
          _selectedItems.add(row.data);
        }
      }
    }
  }

  @override
  void didUpdateWidget(covariant AppDataTable<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Update selected items when rows change
    if (widget.selectable) {
      _selectedItems.clear();
      for (final row in widget.rows) {
        if (row.isSelected) {
          _selectedItems.add(row.data);
        }
      }
      _notifySelectionChanged();
    }
  }

  void _toggleRowSelection(T data, bool selected) {
    if (selected) {
      _selectedItems.add(data);
    } else {
      _selectedItems.remove(data);
    }
    _notifySelectionChanged();
    setState(() {});
  }

  void _toggleAllSelection(bool selected) {
    if (selected) {
      _selectedItems.clear();
      _selectedItems.addAll(widget.rows.map((row) => row.data));
    } else {
      _selectedItems.clear();
    }
    _notifySelectionChanged();
    setState(() {});
  }

  void _notifySelectionChanged() {
    widget.onSelectionChanged?.call(_selectedItems.toList());
  }

  bool _isRowSelected(T data) {
    return _selectedItems.contains(data);
  }

  bool get _allSelected {
    if (widget.rows.isEmpty) return false;
    return _selectedItems.length == widget.rows.length;
  }

  bool get _anySelected {
    return _selectedItems.isNotEmpty;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasData = widget.rows.isNotEmpty && !widget.isLoading;

    // Colors
    final headerBgColor = widget.headerBackgroundColor ??
        (isDark ? Colors.white.withOpacity(0.05) : AppColors.neutral50);
    final rowBgColor = widget.rowBackgroundColor ??
        (isDark ? AppColors.surfaceDark : Colors.white);
    final selectedColor = widget.selectedRowColor ??
        (isDark
            ? AppColors.primary.withOpacity(0.15)
            : AppColors.primary.withOpacity(0.08));
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200;

    // Empty State
    if (!hasData && !widget.isLoading) {
      return widget.emptyWidget ??
          Center(
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.xl),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.table_chart_outlined,
                    size: 64,
                    color: isDark
                        ? Colors.white.withOpacity(0.2)
                        : AppColors.neutral300,
                  ),
                  const SizedBox(height: AppSpacing.lg),
                  Text(
                    widget.emptyMessage ?? 'No data available',
                    style: AppTypography.bodyLarge.copyWith(
                      color: isDark
                          ? Colors.white.withOpacity(0.5)
                          : AppColors.neutral300,
                    ),
                  ),
                ],
              ),
            ),
          );
    }

    // Loading State
    if (widget.isLoading) {
      return widget.loadingWidget ??
          const Padding(
            padding: EdgeInsets.all(AppSpacing.md),
            child: AdminDataSkeleton(showStats: false, rowCount: 5),
          );
    }

    final tableContent = Column(
      children: [
        // Selection Header
        if (widget.selectable && _anySelected)
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.primary.withOpacity(0.1)
                  : AppColors.primary.withOpacity(0.05),
              border: Border(
                bottom: BorderSide(color: borderColor),
              ),
            ),
            child: Row(
              children: [
                Text(
                  '${_selectedItems.length} selected',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
                const Spacer(),
                TextButton(
                  onPressed: () => _toggleAllSelection(false),
                  child: Text(
                    'Clear',
                    style: AppTypography.bodySmall
                        .copyWith(color: AppColors.error),
                  ),
                ),
              ],
            ),
          ),

        // Table
        Expanded(
          child: SingleChildScrollView(
            controller:
                widget.verticalScrollController ?? _verticalScrollController,
            scrollDirection: Axis.vertical,
            child: SingleChildScrollView(
              controller: widget.horizontalScrollController ??
                  _horizontalScrollController,
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: widget.minWidth ?? 800,
                ),
                child: Table(
                  defaultColumnWidth: const IntrinsicColumnWidth(),
                  border: widget.showBorder
                      ? TableBorder(
                          horizontalInside: BorderSide(color: borderColor),
                          bottom: BorderSide(color: borderColor),
                        )
                      : null,
                  children: [
                    // Header Row
                    if (widget.showHeader)
                      TableRow(
                        decoration: BoxDecoration(
                          color: headerBgColor,
                          border: widget.showBorder
                              ? Border(
                                  bottom:
                                      BorderSide(color: borderColor, width: 2),
                                )
                              : null,
                        ),
                        children: [
                          if (widget.selectable && widget.showCheckboxes)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Checkbox(
                                value: _allSelected,
                                onChanged: (value) =>
                                    _toggleAllSelection(value ?? false),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                ),
                              ),
                            ),
                          for (var i = 0; i < widget.columns.length; i++)
                            _buildHeaderCell(widget.columns[i], i),
                        ],
                      ),

                    // Data Rows
                    for (var rowIndex = 0;
                        rowIndex < widget.rows.length;
                        rowIndex++)
                      TableRow(
                        decoration: BoxDecoration(
                          color: _isRowSelected(widget.rows[rowIndex].data)
                              ? selectedColor
                              : (widget.striped && rowIndex % 2 == 0
                                  ? (isDark
                                      ? Colors.white.withOpacity(0.02)
                                      : AppColors.neutral50)
                                  : rowBgColor),
                        ),
                        children: [
                          if (widget.selectable && widget.showCheckboxes)
                            Padding(
                              padding: const EdgeInsets.all(AppSpacing.md),
                              child: Checkbox(
                                value:
                                    _isRowSelected(widget.rows[rowIndex].data),
                                onChanged: (value) => _toggleRowSelection(
                                    widget.rows[rowIndex].data, value ?? false),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(
                                      AppSpacing.radiusSm),
                                ),
                              ),
                            ),
                          for (var cellIndex = 0;
                              cellIndex < widget.rows[rowIndex].cells.length;
                              cellIndex++)
                            GestureDetector(
                              onTap: widget.rows[rowIndex].onTap,
                              child: Container(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                constraints: BoxConstraints(
                                  minHeight: widget.rowHeight ?? 56,
                                ),
                                child: Align(
                                  alignment: widget.columns[cellIndex].numeric
                                      ? Alignment.centerRight
                                      : Alignment.centerLeft,
                                  child: widget.rows[rowIndex].cells[cellIndex],
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );

    return Container(
      decoration: BoxDecoration(
        color: rowBgColor,
        borderRadius:
            widget.borderRadius ?? BorderRadius.circular(AppSpacing.radiusLg),
        border: widget.border ??
            (widget.showBorder ? Border.all(color: borderColor) : null),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Optional Trailing Header Widget
          if (widget.trailingHeaderWidget != null)
            Container(
              padding: const EdgeInsets.all(AppSpacing.lg),
              decoration: BoxDecoration(
                color: headerBgColor,
                border: widget.showBorder
                    ? Border(bottom: BorderSide(color: borderColor))
                    : null,
              ),
              child: widget.trailingHeaderWidget,
            ),

          // Table with Fixed Header if needed
          if (widget.fixedHeader)
            Expanded(
              child: _FixedHeaderTable(
                header: widget.showHeader
                    ? Container(
                        decoration: BoxDecoration(
                          color: headerBgColor,
                          border: widget.showBorder
                              ? Border(
                                  bottom:
                                      BorderSide(color: borderColor, width: 2),
                                )
                              : null,
                        ),
                        child: Row(
                          children: [
                            if (widget.selectable && widget.showCheckboxes)
                              Padding(
                                padding: const EdgeInsets.all(AppSpacing.md),
                                child: Checkbox(
                                  value: _allSelected,
                                  onChanged: (value) =>
                                      _toggleAllSelection(value ?? false),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        AppSpacing.radiusSm),
                                  ),
                                ),
                              ),
                            for (var i = 0; i < widget.columns.length; i++)
                              Expanded(
                                child: _buildHeaderCell(widget.columns[i], i),
                              ),
                          ],
                        ),
                      )
                    : null,
                body: SingleChildScrollView(
                  controller: widget.verticalScrollController ??
                      _verticalScrollController,
                  child: SingleChildScrollView(
                    controller: widget.horizontalScrollController ??
                        _horizontalScrollController,
                    scrollDirection: Axis.horizontal,
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minWidth: widget.minWidth ?? 800,
                      ),
                      child: Table(
                        defaultColumnWidth: const IntrinsicColumnWidth(),
                        border: widget.showBorder
                            ? TableBorder(
                                horizontalInside:
                                    BorderSide(color: borderColor),
                              )
                            : null,
                        children: [
                          for (var rowIndex = 0;
                              rowIndex < widget.rows.length;
                              rowIndex++)
                            TableRow(
                              decoration: BoxDecoration(
                                color:
                                    _isRowSelected(widget.rows[rowIndex].data)
                                        ? selectedColor
                                        : (widget.striped && rowIndex % 2 == 0
                                            ? (isDark
                                                ? Colors.white.withOpacity(0.02)
                                                : AppColors.neutral50)
                                            : rowBgColor),
                              ),
                              children: [
                                if (widget.selectable && widget.showCheckboxes)
                                  Padding(
                                    padding:
                                        const EdgeInsets.all(AppSpacing.md),
                                    child: Checkbox(
                                      value: _isRowSelected(
                                          widget.rows[rowIndex].data),
                                      onChanged: (value) => _toggleRowSelection(
                                          widget.rows[rowIndex].data,
                                          value ?? false),
                                      shape: RoundedRectangleBorder(
                                        borderRadius: BorderRadius.circular(
                                            AppSpacing.radiusSm),
                                      ),
                                    ),
                                  ),
                                for (var cellIndex = 0;
                                    cellIndex <
                                        widget.rows[rowIndex].cells.length;
                                    cellIndex++)
                                  GestureDetector(
                                    onTap: widget.rows[rowIndex].onTap,
                                    child: Container(
                                      padding:
                                          const EdgeInsets.all(AppSpacing.md),
                                      constraints: BoxConstraints(
                                        minHeight: widget.rowHeight ?? 56,
                                      ),
                                      child: Align(
                                        alignment:
                                            widget.columns[cellIndex].numeric
                                                ? Alignment.centerRight
                                                : Alignment.centerLeft,
                                        child: widget
                                            .rows[rowIndex].cells[cellIndex],
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            )
          else
            Expanded(child: tableContent),

          // Pagination Footer
          if (widget.pagination != null)
            _buildPaginationFooter(widget.pagination!, isDark),
        ],
      ),
    );
  }

  Widget _buildHeaderCell(AppDataColumn column, int columnIndex) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isSorted = widget.sortInfo?.columnIndex == columnIndex;
    final sortAscending = widget.sortInfo?.ascending ?? true;

    return GestureDetector(
      onTap: widget.onSort != null
          ? () {
              final newSortInfo = AppSortInfo(
                columnIndex: columnIndex,
                ascending: isSorted ? !sortAscending : true,
              );
              widget.onSort!(newSortInfo);
            }
          : null,
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        constraints: const BoxConstraints(minHeight: 56),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Expanded(
              child: Text(
                column.label,
                style: AppTypography.labelLarge.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (widget.onSort != null) ...[
              const SizedBox(width: 4),
              if (isSorted)
                Icon(
                  sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                  size: 16,
                  color: AppColors.primary,
                )
              else
                Icon(
                  Icons.unfold_more,
                  size: 16,
                  color: isDark
                      ? Colors.white.withOpacity(0.5)
                      : AppColors.textSecondary,
                ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildPaginationFooter(AppPaginationInfo pagination, bool isDark) {
    final borderColor =
        isDark ? Colors.white.withOpacity(0.1) : AppColors.neutral200;

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? Colors.black.withOpacity(0.05) : AppColors.neutral50,
        border: Border(top: BorderSide(color: borderColor)),
      ),
      child: Row(
        children: [
          // Items per page info
          Text(
            'Showing ${((pagination.currentPage - 1) * pagination.itemsPerPage) + 1}'
            '-${(pagination.currentPage * pagination.itemsPerPage).clamp(0, pagination.totalItems)}'
            ' of ${pagination.totalItems}',
            style: AppTypography.bodySmall.copyWith(
              color: isDark
                  ? Colors.white.withOpacity(0.6)
                  : AppColors.textSecondary,
            ),
          ),
          const Spacer(),

          // Page navigation
          Row(
            children: [
              // First page
              IconButton(
                onPressed: pagination.currentPage > 1 &&
                        pagination.onPageChanged != null
                    ? () => pagination.onPageChanged!(1)
                    : null,
                icon: const Icon(Icons.first_page, size: 18),
                color: pagination.currentPage > 1
                    ? AppColors.primary
                    : (isDark
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.neutral400),
              ),
              const SizedBox(width: 4),

              // Previous page
              IconButton(
                onPressed: pagination.currentPage > 1 &&
                        pagination.onPageChanged != null
                    ? () =>
                        pagination.onPageChanged!(pagination.currentPage - 1)
                    : null,
                icon: const Icon(Icons.chevron_left, size: 18),
                color: pagination.currentPage > 1
                    ? AppColors.primary
                    : (isDark
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.neutral400),
              ),
              const SizedBox(width: 8),

              // Page number
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  '${pagination.currentPage}',
                  style: AppTypography.bodyMedium.copyWith(
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(width: 8),

              // Next page
              IconButton(
                onPressed: pagination.currentPage < pagination.totalPages &&
                        pagination.onPageChanged != null
                    ? () =>
                        pagination.onPageChanged!(pagination.currentPage + 1)
                    : null,
                icon: const Icon(Icons.chevron_right, size: 18),
                color: pagination.currentPage < pagination.totalPages
                    ? AppColors.primary
                    : (isDark
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.neutral400),
              ),
              const SizedBox(width: 4),

              // Last page
              IconButton(
                onPressed: pagination.currentPage < pagination.totalPages &&
                        pagination.onPageChanged != null
                    ? () => pagination.onPageChanged!(pagination.totalPages)
                    : null,
                icon: const Icon(Icons.last_page, size: 18),
                color: pagination.currentPage < pagination.totalPages
                    ? AppColors.primary
                    : (isDark
                        ? Colors.white.withOpacity(0.3)
                        : AppColors.neutral400),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Fixed Header Table for better UX with many rows
class _FixedHeaderTable extends StatefulWidget {
  final Widget? header;
  final Widget body;

  const _FixedHeaderTable({this.header, required this.body});

  @override
  State<_FixedHeaderTable> createState() => __FixedHeaderTableState();
}

class __FixedHeaderTableState extends State<_FixedHeaderTable> {
  final ScrollController _scrollController = ScrollController();
  bool _showHeaderShadow = false;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    super.dispose();
  }

  void _onScroll() {
    final showShadow = _scrollController.offset > 0;
    if (_showHeaderShadow != showShadow) {
      setState(() {
        _showHeaderShadow = showShadow;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.header != null)
          Material(
            elevation: _showHeaderShadow ? 2 : 0,
            child: widget.header!,
          ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: widget.body,
          ),
        ),
      ],
    );
  }
}
