import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/theme/app_typography.dart';

/// Packaging Supervisor Dashboard - Limited to specified features only
/// Features: Packaging Records, Waste Tracking, Progress Tracking
class PackagingSupervisorDashboard extends ConsumerStatefulWidget {
  const PackagingSupervisorDashboard({super.key});

  @override
  ConsumerState<PackagingSupervisorDashboard> createState() =>
      _PackagingSupervisorDashboardState();
}

class _PackagingSupervisorDashboardState
    extends ConsumerState<PackagingSupervisorDashboard> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Packaging Supervisor'),
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code_scanner),
            onPressed: () {
              // Scan batch QR code
            },
          ),
          IconButton(
            icon: const Icon(Icons.account_circle_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Welcome Section
              _buildWelcomeSection(isDark),
              const SizedBox(height: AppSpacing.xl),

              // Today's Progress
              _buildTodayProgress(isDark),
              const SizedBox(height: AppSpacing.xl),

              // Main Features
              Text(
                'Packaging Operations',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: AppSpacing.md),
              _buildFeaturesGrid(isDark),

              const SizedBox(height: AppSpacing.xl),

              // Active Batches
              _buildActiveBatches(isDark),

              const SizedBox(height: AppSpacing.xl),

              // Waste Summary
              _buildWasteSummary(isDark),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/packaging/record');
        },
        backgroundColor: Colors.teal,
        icon: const Icon(Icons.add_box),
        label: const Text('Record Package'),
      ),
    );
  }

  Widget _buildWelcomeSection(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.teal,
            Colors.teal.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Packaging Station',
                  style: AppTypography.h5.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Packaging Supervisor',
                  style: AppTypography.bodyMedium.copyWith(
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(
                  '3 Active Batches â€¢ 720 kg Packaged Today',
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(AppSpacing.md),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.inventory_2,
              size: 40,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTodayProgress(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: Colors.teal.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.trending_up, color: Colors.teal, size: 20),
              const SizedBox(width: AppSpacing.sm),
              Text(
                'Today\'s Progress',
                style: AppTypography.bodyLarge.copyWith(
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: _buildProgressItem(
                    'Started', '3', 'batches', AppColors.info, isDark),
              ),
              Expanded(
                child: _buildProgressItem(
                    'In Progress', '2', 'batches', AppColors.warning, isDark),
              ),
              Expanded(
                child: _buildProgressItem(
                    'Completed', '1', 'batch', AppColors.success, isDark),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          LinearProgressIndicator(
            value: 0.65,
            backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
            valueColor: AlwaysStoppedAnimation<Color>(Colors.teal),
            minHeight: 8,
            borderRadius: BorderRadius.circular(4),
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            '65% of daily target completed',
            style: AppTypography.bodySmall.copyWith(
              color: isDark ? Colors.white70 : AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem(
      String label, String value, String unit, Color color, bool isDark) {
    return Column(
      children: [
        Text(
          value,
          style: AppTypography.h5.copyWith(
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
        Text(
          unit,
          style: AppTypography.bodySmall.copyWith(
            color: color,
            fontSize: 10,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white70 : AppColors.textSecondary,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildFeaturesGrid(bool isDark) {
    final features = [
      _FeatureItem(
        title: 'Packaging Records',
        subtitle: 'Record packaged items',
        icon: Icons.add_box,
        color: Colors.teal,
        route: '/packaging/records',
      ),
      _FeatureItem(
        title: 'Waste Tracking',
        subtitle: 'Record waste & reasons',
        icon: Icons.delete_outline,
        color: AppColors.error,
        route: '/packaging/waste',
      ),
      _FeatureItem(
        title: 'Progress Tracking',
        subtitle: 'Real-time status',
        icon: Icons.timeline,
        color: AppColors.info,
        route: '/packaging/progress',
      ),
      _FeatureItem(
        title: 'Batch Scanner',
        subtitle: 'Scan QR codes',
        icon: Icons.qr_code_scanner,
        color: Colors.purple,
        route: '/packaging/scanner',
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 1.2,
        crossAxisSpacing: AppSpacing.md,
        mainAxisSpacing: AppSpacing.md,
      ),
      itemCount: features.length,
      itemBuilder: (context, index) {
        final feature = features[index];
        return _buildFeatureCard(feature, isDark);
      },
    );
  }

  Widget _buildFeatureCard(_FeatureItem feature, bool isDark) {
    return InkWell(
      onTap: () => Navigator.pushNamed(context, feature.route),
      borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
      child: Container(
        padding: const EdgeInsets.all(AppSpacing.md),
        decoration: BoxDecoration(
          color: isDark ? AppColors.surfaceDark : Colors.white,
          borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
          border: Border.all(
            color: feature.color.withOpacity(0.3),
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(feature.icon, size: 32, color: feature.color),
            const SizedBox(height: AppSpacing.sm),
            Text(
              feature.title,
              style: AppTypography.bodyMedium.copyWith(
                fontWeight: FontWeight.w500,
                color: isDark ? Colors.white : AppColors.textPrimary,
              ),
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 2),
            Text(
              feature.subtitle,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontSize: 10,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActiveBatches(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Active Batches',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildBatchItem(
          'FA-20251001-20251101',
          'Lettuce - 250 kg',
          'In Progress',
          AppColors.warning,
          '65%',
          isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildBatchItem(
          'FB-20251002-20251102',
          'Tomatoes - 180 kg',
          'Started',
          AppColors.info,
          '20%',
          isDark,
        ),
        const SizedBox(height: AppSpacing.sm),
        _buildBatchItem(
          'FC-20251003-20251103',
          'Basil - 290 kg',
          'Completed',
          AppColors.success,
          '100%',
          isDark,
        ),
      ],
    );
  }

  Widget _buildBatchItem(
    String batchNumber,
    String details,
    String status,
    Color color,
    String progress,
    bool isDark,
  ) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : Colors.white,
        borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      batchNumber,
                      style: AppTypography.bodyMedium.copyWith(
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      details,
                      style: AppTypography.bodySmall.copyWith(
                        color:
                            isDark ? Colors.white60 : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
                ),
                child: Text(
                  status,
                  style: AppTypography.bodySmall.copyWith(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.sm),
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: double.parse(progress.replaceAll('%', '')) / 100,
                  backgroundColor: isDark ? Colors.white12 : Colors.grey[200],
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                progress,
                style: AppTypography.bodySmall.copyWith(
                  color: color,
                  fontWeight: FontWeight.w500,
                  fontSize: 11,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildWasteSummary(bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Waste Summary',
          style: AppTypography.h6.copyWith(
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        Container(
          padding: const EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: isDark ? AppColors.surfaceDark : Colors.white,
            borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
            border: Border.all(
              color: AppColors.error.withOpacity(0.3),
            ),
          ),
          child: Column(
            children: [
              _buildWasteReasonRow('Torn pack', '5 kg', '33%', isDark),
              const Divider(),
              _buildWasteReasonRow('Mislabelled', '7 kg', '47%', isDark),
              const Divider(),
              _buildWasteReasonRow('Contamination', '3 kg', '20%', isDark),
              const SizedBox(height: AppSpacing.md),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Total Waste Today',
                    style: AppTypography.bodyMedium.copyWith(
                      fontWeight: FontWeight.w500,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  Text(
                    '15 kg',
                    style: AppTypography.h6.copyWith(
                      fontWeight: FontWeight.w600,
                      color: AppColors.error,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildWasteReasonRow(
      String reason, String amount, String percentage, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Expanded(
            child: Text(
              reason,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white70 : AppColors.textSecondary,
              ),
            ),
          ),
          Text(
            amount,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w500,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Text(
            percentage,
            style: AppTypography.bodySmall.copyWith(
              color: AppColors.error,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final String route;

  _FeatureItem({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.route,
  });
}
