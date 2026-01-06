import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Global Search Screen
/// Search across batches, records, inventory, and more
class GlobalSearchScreen extends ConsumerStatefulWidget {
  const GlobalSearchScreen({super.key});

  @override
  ConsumerState<GlobalSearchScreen> createState() => _GlobalSearchScreenState();
}

class _GlobalSearchScreenState extends ConsumerState<GlobalSearchScreen> {
  final _searchController = TextEditingController();
  String _searchQuery = '';
  String _selectedFilter = 'all';
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: TextField(
          controller: _searchController,
          autofocus: true,
          decoration: InputDecoration(
            hintText: 'Search batches, records, inventory...',
            border: InputBorder.none,
            hintStyle: TextStyle(
              color: isDark ? Colors.white60 : Colors.black54,
            ),
          ),
          style: AppTypography.bodyLarge.copyWith(
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
          onChanged: (value) {
            setState(() {
              _searchQuery = value;
              _isSearching = value.isNotEmpty;
            });
          },
        ),
        actions: [
          if (_searchQuery.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                _searchController.clear();
                setState(() {
                  _searchQuery = '';
                  _isSearching = false;
                });
              },
            ),
        ],
      ),
      body: Column(
        children: [
          // Filter Chips
          _buildFilterChips(isDark),
          const Divider(height: 1),

          // Search Results
          Expanded(
            child: _isSearching
                ? _buildSearchResults(isDark)
                : _buildRecentSearches(isDark),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChips(bool isDark) {
    final filters = [
      {'id': 'all', 'label': 'All', 'icon': Icons.search},
      {'id': 'batches', 'label': 'Batches', 'icon': Icons.inventory_2},
      {'id': 'records', 'label': 'Records', 'icon': Icons.description},
      {'id': 'inventory', 'label': 'Inventory', 'icon': Icons.warehouse},
      {'id': 'maintenance', 'label': 'Maintenance', 'icon': Icons.build},
    ];

    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((filter) {
            final isSelected = _selectedFilter == filter['id'];
            return Padding(
              padding: const EdgeInsets.only(right: AppSpacing.sm),
              child: FilterChip(
                selected: isSelected,
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      filter['icon'] as IconData,
                      size: 16,
                      color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textSecondary),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    Text(filter['label'] as String),
                  ],
                ),
                onSelected: (selected) {
                  setState(() => _selectedFilter = filter['id'] as String);
                },
                selectedColor: AppColors.primary,
                backgroundColor: isDark ? Colors.grey[850] : Colors.grey[200],
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : (isDark ? Colors.white70 : AppColors.textPrimary),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _buildSearchResults(bool isDark) {
    // Mock search results
    final results = _getMockResults();

    if (results.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'No results found',
              style: AppTypography.h6.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Try different keywords or filters',
              style: AppTypography.bodyMedium.copyWith(
                color: isDark ? Colors.white.withOpacity(0.4) : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.all(AppSpacing.md),
      itemCount: results.length,
      separatorBuilder: (context, index) => const SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        final result = results[index];
        return _buildResultCard(result, isDark);
      },
    );
  }

  Widget _buildResultCard(Map<String, dynamic> result, bool isDark) {
    return InkWell(
      onTap: () => _openResult(result),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? Colors.grey[850] : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: _getTypeColor(result['type'] as String).withOpacity(0.1),
                borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
              ),
              child: Icon(
                _getTypeIcon(result['type'] as String),
                color: _getTypeColor(result['type'] as String),
              ),
            ),
            const SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    result['title'] as String,
                    style: AppTypography.bodyLarge.copyWith(
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    result['subtitle'] as String,
                    style: AppTypography.bodySmall.copyWith(
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: isDark ? Colors.white30 : Colors.black26,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentSearches(bool isDark) {
    final recentSearches = [
      'Batch LE-20241101',
      'Lettuce inventory',
      'Maintenance schedule',
      'October records',
    ];

    return ListView(
      padding: const EdgeInsets.all(AppSpacing.md),
      children: [
        Text(
          'Recent Searches',
          style: AppTypography.h6.copyWith(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        ...recentSearches.map((search) => ListTile(
              leading: Icon(
                Icons.history,
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
              title: Text(
                search,
                style: AppTypography.bodyMedium.copyWith(
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              trailing: IconButton(
                icon: const Icon(Icons.north_west, size: 16),
                onPressed: () {
                  _searchController.text = search;
                  setState(() {
                    _searchQuery = search;
                    _isSearching = true;
                  });
                },
              ),
              onTap: () {
                _searchController.text = search;
                setState(() {
                  _searchQuery = search;
                  _isSearching = true;
                });
              },
            )),
      ],
    );
  }

  List<Map<String, dynamic>> _getMockResults() {
    if (_searchQuery.isEmpty) return [];

    final allResults = [
      {
        'type': 'batch',
        'title': 'Batch LE-20241101-20241201',
        'subtitle': 'Lettuce • Green Valley Farm • Growing',
      },
      {
        'type': 'batch',
        'title': 'Batch TO-20241015-20241115',
        'subtitle': 'Tomatoes • Sunny Acres • Harvesting',
      },
      {
        'type': 'inventory',
        'title': 'Lettuce Seeds (Buttercrunch)',
        'subtitle': '8.0 kg • Low Stock Alert',
      },
      {
        'type': 'record',
        'title': 'Environmental Record - Oct 31',
        'subtitle': 'Green Valley Farm • Temperature: 24°C',
      },
      {
        'type': 'maintenance',
        'title': 'Irrigation System Maintenance',
        'subtitle': 'Scheduled • Tomorrow • High Priority',
      },
    ];

    // Simple filter by search query and selected filter
    return allResults.where((result) {
      final matchesQuery = result['title']!.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          result['subtitle']!.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesFilter = _selectedFilter == 'all' || result['type'] == _selectedFilter;
      return matchesQuery && matchesFilter;
    }).toList();
  }

  IconData _getTypeIcon(String type) {
    switch (type) {
      case 'batch':
        return Icons.inventory_2;
      case 'record':
        return Icons.description;
      case 'inventory':
        return Icons.warehouse;
      case 'maintenance':
        return Icons.build;
      default:
        return Icons.search;
    }
  }

  Color _getTypeColor(String type) {
    switch (type) {
      case 'batch':
        return AppColors.primary;
      case 'record':
        return AppColors.info;
      case 'inventory':
        return AppColors.warning;
      case 'maintenance':
        return AppColors.error;
      default:
        return AppColors.textSecondary;
    }
  }

  void _openResult(Map<String, dynamic> result) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Opening ${result['title']}...'),
        backgroundColor: AppColors.info,
      ),
    );
  }
}
