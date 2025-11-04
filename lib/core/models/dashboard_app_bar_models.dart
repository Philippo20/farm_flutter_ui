import 'package:flutter/material.dart';

enum GlobalSearchCategory { dashboard, user, farm, sensor, settings, other }

typedef SearchAction = void Function();

typedef QuickActionCallback = void Function();

typedef TenantChangedCallback = void Function(String tenant);

enum SystemStatusLevel { ok, warning, error }

class GlobalSearchItem {
  final String label;
  final GlobalSearchCategory category;
  final IconData icon;
  final SearchAction? onSelected;
  final String? description;

  const GlobalSearchItem({
    required this.label,
    required this.category,
    required this.icon,
    this.onSelected,
    this.description,
  });
}

class QuickActionItem {
  final String label;
  final IconData icon;
  final QuickActionCallback onSelected;

  const QuickActionItem({
    required this.label,
    required this.icon,
    required this.onSelected,
  });
}

class SystemStatusIndicator {
  final String label;
  final SystemStatusLevel level;
  final String? tooltip;

  const SystemStatusIndicator({
    required this.label,
    required this.level,
    this.tooltip,
  });
}
