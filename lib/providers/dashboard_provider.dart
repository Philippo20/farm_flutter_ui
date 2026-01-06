import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../constants/colors.dart';

class DashboardStats {
  final String title;
  final String value;
  final String change;
  final bool isPositive;
  final IconData icon;
  final Color color;

  DashboardStats({
    required this.title,
    required this.value,
    required this.change,
    required this.isPositive,
    required this.icon,
    required this.color,
  });
}

final dashboardStatsProvider = StateNotifierProvider<DashboardNotifier, List<DashboardStats>>((ref) {
  return DashboardNotifier();
});

class DashboardNotifier extends StateNotifier<List<DashboardStats>> {
  DashboardNotifier() : super([]) {
    fetchDashboardStats();
  }

  void fetchDashboardStats() {
    // In a real app, you'd fetch this data from an API
    state = [
      DashboardStats(
        title: 'Total Farms',
        value: '24',
        change: '+12%',
        isPositive: true,
        icon: Icons.agriculture_rounded,
        color: AppColors.primary,
      ),
      DashboardStats(
        title: 'Active Batches',
        value: '156',
        change: '+8%',
        isPositive: true,
        icon: Icons.inventory_2_rounded,
        color: AppColors.secondary,
      ),
      DashboardStats(
        title: 'Total Revenue',
        value: '\$48.5K',
        change: '+23%',
        isPositive: true,
        icon: Icons.attach_money_rounded,
        color: AppColors.warning,
      ),
      DashboardStats(
        title: 'Active Sensors',
        value: '342',
        change: '-2%',
        isPositive: false,
        icon: Icons.sensors_rounded,
        color: AppColors.danger,
      ),
    ];
  }
}
