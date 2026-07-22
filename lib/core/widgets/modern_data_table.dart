import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';

/// Modern data table widget with sorting, filtering, and pagination
class ModernDataTable<T> extends StatefulWidget {
  final List<T> data;
  final List<DataTableColumn<T>> columns;
  final String title;
  final String? subtitle;
  final Widget? headerAction;
  final int itemsPerPage;
  final bool showSearch;
  final String searchHint;
  final Function(T)? onRowTap;
  final Function(String)? onSearch;
  final bool enablePagination;
  final bool enableSorting;
  final Color? headerColor;

  const ModernDataTable({
    super.key,
    required this.data,
    required this.columns,
    required this.title,
    this.subtitle,
    this.headerAction,
    this.itemsPerPage = 10,
    this.showSearch = true,
    this.searchHint = 'Search...',
    this.onRowTap,
    this.onSearch,
    this.enablePagination = true,
    this.enableSorting = true,
    this.headerColor,
  });

  @override
  State<ModernDataTable<T>> createState() => _ModernDataTableState<T>();
}

class _ModernDataTableState<T> extends State<ModernDataTable<T>> {
  int _currentPage = 0;
  int? _sortColumnIndex;
  bool _sortAscending = true;
  String _searchQuery = '';
  final TextEditingController _searchController = TextEditingController();

  List<T> get _filteredData {
    if (_searchQuery.isEmpty) return widget.data;

    return widget.data.where((item) {
      return widget.columns.any((column) {
        final value = column.value(item);
        return value
            .toString()
            .toLowerCase()
            .contains(_searchQuery.toLowerCase());
      });
    }).toList();
  }

  List<T> get _paginatedData {
    if (!widget.enablePagination) return _filteredData;

    final startIndex = _currentPage * widget.itemsPerPage;
    final endIndex =
        (startIndex + widget.itemsPerPage).clamp(0, _filteredData.length);

    if (startIndex >= _filteredData.length) return [];
    return _filteredData.sublist(startIndex, endIndex);
  }

  int get _totalPages => (_filteredData.length / widget.itemsPerPage).ceil();

  void _sort(int columnIndex) {
    if (!widget.enableSorting) return;

    setState(() {
      if (_sortColumnIndex == columnIndex) {
        _sortAscending = !_sortAscending;
      } else {
        _sortColumnIndex = columnIndex;
        _sortAscending = true;
      }

      final column = widget.columns[columnIndex];
      if (column.sortable) {
        widget.data.sort((a, b) {
          final aValue = column.value(a);
          final bValue = column.value(b);

          int comparison = 0;
          if (aValue is Comparable && bValue is Comparable) {
            comparison = aValue.compareTo(bValue);
          } else {
            comparison = aValue.toString().compareTo(bValue.toString());
          }

          return _sortAscending ? comparison : -comparison;
        });
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        side: BorderSide(
          color: colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          _buildHeader(colorScheme),

          // Search bar
          if (widget.showSearch) _buildSearchBar(colorScheme),

          // Table
          _buildTable(colorScheme),

          // Pagination
          if (widget.enablePagination && _totalPages > 1)
            _buildPagination(colorScheme),
        ],
      ),
    );
  }

  Widget _buildHeader(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: widget.headerColor ??
            colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(AppSpacing.radiusLg),
          topRight: Radius.circular(AppSpacing.radiusLg),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.title,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    widget.subtitle!,
                    style: AppTypography.bodySmall.copyWith(
                      color: colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (widget.headerAction != null) widget.headerAction!,
        ],
      ),
    );
  }

  Widget _buildSearchBar(ColorScheme colorScheme) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: TextField(
        controller: _searchController,
        onChanged: (value) {
          setState(() {
            _searchQuery = value;
            _currentPage = 0; // Reset to first page on search
          });
          widget.onSearch?.call(value);
        },
        decoration: InputDecoration(
          hintText: widget.searchHint,
          prefixIcon:
              Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.5)),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() {
                      _searchController.clear();
                      _searchQuery = '';
                      _currentPage = 0;
                    });
                  },
                )
              : null,
          filled: true,
          fillColor: colorScheme.surfaceContainerHighest.withOpacity(0.3),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm,
          ),
        ),
      ),
    );
  }

  Widget _buildTable(ColorScheme colorScheme) {
    if (_paginatedData.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.inbox_outlined,
                size: 64,
                color: colorScheme.onSurface.withOpacity(0.3),
              ),
              const SizedBox(height: AppSpacing.md),
              Text(
                _searchQuery.isNotEmpty
                    ? 'No results found'
                    : 'No data available',
                style: AppTypography.bodyLarge.copyWith(
                  color: colorScheme.onSurface.withOpacity(0.5),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        sortColumnIndex: _sortColumnIndex,
        sortAscending: _sortAscending,
        headingRowColor: WidgetStateProperty.all(
          colorScheme.surfaceContainerHighest.withOpacity(0.3),
        ),
        dataRowColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.hovered)) {
            return colorScheme.surfaceContainerHighest.withOpacity(0.5);
          }
          return null;
        }),
        columns: widget.columns.asMap().entries.map((entry) {
          final index = entry.key;
          final column = entry.value;

          return DataColumn(
            label: Row(
              children: [
                if (column.icon != null) ...[
                  Icon(column.icon,
                      size: 18, color: colorScheme.onSurface.withOpacity(0.7)),
                  const SizedBox(width: AppSpacing.xs),
                ],
                Text(
                  column.label,
                  style: AppTypography.labelLarge.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            numeric: column.numeric,
            onSort: column.sortable
                ? (columnIndex, ascending) => _sort(index)
                : null,
          );
        }).toList(),
        rows: _paginatedData.map((item) {
          return DataRow(
            onSelectChanged:
                widget.onRowTap != null ? (_) => widget.onRowTap!(item) : null,
            cells: widget.columns.map((column) {
              final value = column.value(item);

              return DataCell(
                column.builder != null
                    ? column.builder!(item, value)
                    : Text(
                        value.toString(),
                        style: AppTypography.bodyMedium,
                      ),
              );
            }).toList(),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPagination(ColorScheme colorScheme) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: colorScheme.outlineVariant.withOpacity(0.5),
            width: 1,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Showing ${_currentPage * widget.itemsPerPage + 1}-${((_currentPage + 1) * widget.itemsPerPage).clamp(0, _filteredData.length)} of ${_filteredData.length}',
            style: AppTypography.bodySmall.copyWith(
              color: colorScheme.onSurface.withOpacity(0.6),
            ),
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.chevron_left),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
                tooltip: 'Previous page',
              ),
              ...List.generate(
                _totalPages.clamp(0, 5),
                (index) {
                  final pageIndex =
                      _currentPage < 3 ? index : _currentPage + index - 2;

                  if (pageIndex >= _totalPages) return const SizedBox.shrink();

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 4),
                    child: Material(
                      color: pageIndex == _currentPage
                          ? AppColors.primary
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                      child: InkWell(
                        onTap: () => setState(() => _currentPage = pageIndex),
                        borderRadius:
                            BorderRadius.circular(AppSpacing.radiusSm),
                        child: Container(
                          width: 36,
                          height: 36,
                          alignment: Alignment.center,
                          child: Text(
                            '${pageIndex + 1}',
                            style: AppTypography.bodyMedium.copyWith(
                              color: pageIndex == _currentPage
                                  ? Colors.white
                                  : colorScheme.onSurface,
                              fontWeight: pageIndex == _currentPage
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right),
                onPressed: _currentPage < _totalPages - 1
                    ? () => setState(() => _currentPage++)
                    : null,
                tooltip: 'Next page',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Column definition for ModernDataTable
class DataTableColumn<T> {
  final String label;
  final dynamic Function(T) value;
  final Widget Function(T item, dynamic value)? builder;
  final bool sortable;
  final bool numeric;
  final IconData? icon;

  const DataTableColumn({
    required this.label,
    required this.value,
    this.builder,
    this.sortable = true,
    this.numeric = false,
    this.icon,
  });
}
