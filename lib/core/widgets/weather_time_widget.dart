import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/app_colors.dart';
import '../theme/app_typography.dart';
import '../theme/app_spacing.dart';
import '../services/weather_service.dart';

/// Weather and Time Widget
/// Displays current time, date, and live weather information
class WeatherTimeWidget extends StatefulWidget {
  const WeatherTimeWidget({super.key});

  @override
  State<WeatherTimeWidget> createState() => _WeatherTimeWidgetState();
}

class _WeatherTimeWidgetState extends State<WeatherTimeWidget> {
  late String _currentTime;
  late String _currentDate;
  WeatherData? _weatherData;
  Timer? _timeTimer;
  StreamSubscription? _weatherSubscription;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _updateTime();
    _startTimeUpdates();
    _startWeatherUpdates();
  }

  @override
  void dispose() {
    _timeTimer?.cancel();
    _weatherSubscription?.cancel();
    super.dispose();
  }

  void _startTimeUpdates() {
    // Update time every minute
    _timeTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) {
        setState(() {
          _updateTime();
        });
      }
    });
  }

  void _startWeatherUpdates() {
    // Fetch initial weather
    WeatherService.fetchWeather().then((data) {
      if (mounted) {
        setState(() {
          _weatherData = data;
          _isLoading = false;
        });
      }
    });

    // Subscribe to weather updates (every 10 minutes)
    _weatherSubscription = WeatherService.weatherStream().listen((data) {
      if (mounted) {
        setState(() {
          _weatherData = data;
        });
      }
    });
  }

  void _updateTime() {
    final now = DateTime.now();
    _currentTime = DateFormat('HH:mm').format(now);
    _currentDate = DateFormat('EEEE, MMM d, yyyy').format(now);
  }

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }

  Widget _buildMobileLayout(bool isDark, WeatherData? weather) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Weather Icon
            Container(
              padding: const EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.warning.withOpacity(0.12),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.wb_sunny,
                color: AppColors.warning,
                size: 28,
              ),
            ),
            const SizedBox(width: AppSpacing.sm),
            // Weather Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          '${weather?.temperature.toStringAsFixed(1) ?? '28'}°C',
                          style: AppTypography.h5.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                            fontSize: 20,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: AppSpacing.xs),
                      Flexible(
                        child: Text(
                          weather?.description ?? 'Sunny',
                          style: AppTypography.bodyMedium.copyWith(
                            color: isDark ? Colors.white70 : AppColors.textSecondary,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            // Time
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.access_time,
                      size: 14,
                      color: isDark ? Colors.white70 : AppColors.textSecondary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      _currentTime,
                      style: AppTypography.h6.copyWith(
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : AppColors.textPrimary,
                        fontSize: 16,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.xs),
        // Date row
        Text(
          _currentDate,
          style: AppTypography.bodySmall.copyWith(
            color: isDark ? Colors.white60 : AppColors.textSecondary,
            fontSize: 10,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildDesktopLayout(bool isDark, WeatherData? weather) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Weather Icon & Temp
        Container(
          padding: const EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: AppColors.warning.withOpacity(0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.wb_sunny,
            color: AppColors.warning,
            size: 32,
          ),
        ),
        
        const SizedBox(width: AppSpacing.md),
        
        // Weather Details
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Text(
                    '${weather?.temperature.toStringAsFixed(1) ?? '28'}°C',
                    style: AppTypography.h5.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.sm),
                  Flexible(
                    child: Text(
                      weather?.description ?? 'Sunny',
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark ? Colors.white70 : AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
  
        const SizedBox(width: AppSpacing.md),
        
        // Time & Date
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.access_time,
                  size: 16,
                  color: isDark ? Colors.white70 : AppColors.textSecondary,
                ),
                const SizedBox(width: 4),
                Text(
                  _currentTime,
                  style: AppTypography.h6.copyWith(
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : AppColors.textPrimary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Text(
              _currentDate,
              style: AppTypography.bodySmall.copyWith(
                color: isDark ? Colors.white60 : AppColors.textSecondary,
                fontSize: 11,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ],
    );
  }
}

/// Compact Weather Time Widget (for smaller spaces)
class CompactWeatherTimeWidget extends StatefulWidget {
  const CompactWeatherTimeWidget({super.key});

  @override
  State<CompactWeatherTimeWidget> createState() => _CompactWeatherTimeWidgetState();
}

class _CompactWeatherTimeWidgetState extends State<CompactWeatherTimeWidget> {
  late String _currentTime;

  @override
  void initState() {
    super.initState();
    _updateTime();
  }

  void _updateTime() {
    final now = DateTime.now();
    _currentTime = DateFormat('HH:mm').format(now);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: isDark ? Colors.white10 : Colors.black.withOpacity(0.05),
        borderRadius: BorderRadius.circular(AppSpacing.radiusSm),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.wb_sunny,
            color: AppColors.warning,
            size: 16,
          ),
          const SizedBox(width: 4),
          Text(
            '28°C',
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          Icon(
            Icons.access_time,
            size: 14,
            color: isDark ? Colors.white70 : AppColors.textSecondary,
          ),
          const SizedBox(width: 4),
          Text(
            _currentTime,
            style: AppTypography.bodySmall.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

