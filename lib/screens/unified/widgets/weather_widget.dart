import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/theme/app_spacing.dart';

/// Weather widget displaying current conditions and forecast
class WeatherWidget extends StatelessWidget {
  final Map<String, dynamic> weatherData;
  final bool compact;
  
  const WeatherWidget({
    super.key,
    required this.weatherData,
    this.compact = false,
  });
  
  IconData _getWeatherIcon(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Icons.wb_sunny;
      case 'partly cloudy':
        return Icons.wb_cloudy;
      case 'cloudy':
        return Icons.cloud;
      case 'rainy':
        return Icons.umbrella;
      case 'stormy':
        return Icons.thunderstorm;
      default:
        return Icons.wb_sunny;
    }
  }
  
  Color _getWeatherColor(String condition) {
    switch (condition.toLowerCase()) {
      case 'sunny':
      case 'clear':
        return Colors.orange;
      case 'partly cloudy':
        return Colors.blueGrey;
      case 'cloudy':
        return Colors.grey;
      case 'rainy':
        return Colors.blue;
      case 'stormy':
        return Colors.deepPurple;
      default:
        return Colors.orange;
    }
  }
  
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    if (compact) {
      return _buildCompactView(isDark);
    }
    
    return _buildExpandedView(isDark);
  }
  
  Widget _buildCompactView(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _getWeatherColor(weatherData['condition']).withOpacity(0.2),
            _getWeatherColor(weatherData['condition']).withOpacity(0.1),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _getWeatherIcon(weatherData['condition']),
            color: _getWeatherColor(weatherData['condition']),
            size: 32,
          ),
          const SizedBox(width: AppSpacing.md),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${weatherData['temperature']}°C',
                style: AppTypography.h5.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : AppColors.textPrimary,
                ),
              ),
              Text(
                weatherData['condition'],
                style: AppTypography.bodySmall.copyWith(
                  color: isDark
                      ? Colors.white.withOpacity(0.7)
                      : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
  
  Widget _buildExpandedView(bool isDark) {
    return Container(
      width: 320,
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            _getWeatherColor(weatherData['condition']).withOpacity(0.15),
            _getWeatherColor(weatherData['condition']).withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(AppSpacing.radiusXl),
        border: Border.all(
          color: isDark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.1),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Current weather
          Row(
            children: [
              TweenAnimationBuilder<double>(
                tween: Tween(begin: 0.0, end: 1.0),
                duration: const Duration(milliseconds: 1000),
                curve: Curves.elasticOut,
                builder: (context, value, child) {
                  return Transform.scale(
                    scale: value,
                    child: Icon(
                      _getWeatherIcon(weatherData['condition']),
                      color: _getWeatherColor(weatherData['condition']),
                      size: 48,
                    ),
                  );
                },
              ),
              const SizedBox(width: AppSpacing.lg),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${weatherData['temperature']}',
                          style: AppTypography.h3.copyWith(
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : AppColors.textPrimary,
                          ),
                        ),
                        Text(
                          '°C',
                          style: AppTypography.h5.copyWith(
                            color: isDark
                                ? Colors.white.withOpacity(0.7)
                                : AppColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      weatherData['condition'],
                      style: AppTypography.bodyMedium.copyWith(
                        color: isDark
                            ? Colors.white.withOpacity(0.8)
                            : AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Weather details
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildWeatherDetail(
                icon: Icons.water_drop,
                label: 'Humidity',
                value: '${weatherData['humidity']}%',
                isDark: isDark,
              ),
              _buildWeatherDetail(
                icon: Icons.air,
                label: 'Wind',
                value: '${weatherData['windSpeed']} km/h',
                isDark: isDark,
              ),
              _buildWeatherDetail(
                icon: Icons.wb_sunny,
                label: 'UV Index',
                value: '${weatherData['uvIndex']}',
                isDark: isDark,
              ),
            ],
          ),
          
          const SizedBox(height: AppSpacing.lg),
          
          // Mini forecast
          Text(
            '7-Day Forecast',
            style: AppTypography.bodyMedium.copyWith(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          SizedBox(
            height: 60,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: (weatherData['forecast'] as List).length,
              itemBuilder: (context, index) {
                final day = weatherData['forecast'][index];
                return Container(
                  width: 50,
                  margin: const EdgeInsets.only(right: AppSpacing.xs),
                  padding: const EdgeInsets.all(AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: isDark
                        ? Colors.white.withOpacity(0.05)
                        : Colors.black.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(AppSpacing.radiusMd),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        day['day'].toString().substring(0, 3),
                        style: AppTypography.caption.copyWith(
                          color: isDark
                              ? Colors.white.withOpacity(0.6)
                              : AppColors.textSecondary,
                        ),
                      ),
                      Icon(
                        _getWeatherIcon(day['condition']),
                        size: 16,
                        color: _getWeatherColor(day['condition']),
                      ),
                      Text(
                        '${day['high']}°',
                        style: AppTypography.caption.copyWith(
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : AppColors.textPrimary,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildWeatherDetail({
    required IconData icon,
    required String label,
    required String value,
    required bool isDark,
  }) {
    return Column(
      children: [
        Icon(
          icon,
          size: 20,
          color: isDark
              ? Colors.white.withOpacity(0.5)
              : AppColors.textSecondary,
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(
          value,
          style: AppTypography.bodySmall.copyWith(
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white : AppColors.textPrimary,
          ),
        ),
        Text(
          label,
          style: AppTypography.caption.copyWith(
            color: isDark
                ? Colors.white.withOpacity(0.5)
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
