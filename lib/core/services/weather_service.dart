import 'dart:async';
import '../../utils/weather_utils.dart';

/// Weather Service for fetching live weather data
class WeatherService {
  // OpenWeatherMap API key
  // Get your free key from: https://openweathermap.org/api
  static const String _apiKey = 'bd5e378503939ddaee76f12ad7a97608'; // Replace with your key
  
  // Default location (Accra, Ghana)
  static const double _defaultLat = 5.6037;
  static const double _defaultLon = -0.1870;
  
  // Cache
  static WeatherData? _cachedWeather;
  static DateTime? _lastFetch;
  static const Duration _cacheDuration = Duration(minutes: 10);
  
  /// Fetch current weather data
  static Future<WeatherData> fetchWeather({
    double? latitude,
    double? longitude,
  }) async {
    // Use cache if available and fresh
    if (_cachedWeather != null && 
        _lastFetch != null && 
        DateTime.now().difference(_lastFetch!) < _cacheDuration) {
      return _cachedWeather!;
    }
    
    try {
      final lat = latitude ?? _defaultLat;
      final lon = longitude ?? _defaultLon;
      
      final weatherData = await fetchWeatherData(
        latitude: lat,
        longitude: lon,
        apiKey: _apiKey,
      );
      
      if (weatherData != null) {
        _cachedWeather = WeatherData(
          temperature: weatherData['temperature'] as double,
          description: weatherData['condition'] as String,
          icon: weatherData['condition'] as String,
          humidity: 65, // Default value
          windSpeed: 3.5, // Default value
          location: 'Farm Location',
        );
        _lastFetch = DateTime.now();
        return _cachedWeather!;
      } else {
        return _getFallbackWeather();
      }
    } catch (e) {
      return _getFallbackWeather();
    }
  }
  
  /// Get fallback weather data (when API fails)
  static WeatherData _getFallbackWeather() {
    return WeatherData(
      temperature: 28.0,
      description: 'Sunny',
      icon: '01d',
      humidity: 65,
      windSpeed: 3.5,
      location: 'Farm Location',
    );
  }
  
  /// Stream that emits weather updates every 10 minutes
  static Stream<WeatherData> weatherStream({
    double? latitude,
    double? longitude,
  }) async* {
    while (true) {
      yield await fetchWeather(latitude: latitude, longitude: longitude);
      await Future.delayed(const Duration(minutes: 10));
    }
  }
}

/// Weather Data Model
class WeatherData {
  final double temperature;
  final String description;
  final String icon;
  final int humidity;
  final double windSpeed;
  final String location;
  
  WeatherData({
    required this.temperature,
    required this.description,
    required this.icon,
    required this.humidity,
    required this.windSpeed,
    required this.location,
  });
  
  factory WeatherData.fromJson(Map<String, dynamic> json) {
    return WeatherData(
      temperature: (json['main']['temp'] as num).toDouble(),
      description: json['weather'][0]['main'] as String,
      icon: json['weather'][0]['icon'] as String,
      humidity: json['main']['humidity'] as int,
      windSpeed: (json['wind']['speed'] as num).toDouble(),
      location: json['name'] as String,
    );
  }
  
  /// Get weather icon based on description
  String get weatherIcon {
    switch (description.toLowerCase()) {
      case 'clear':
      case 'sunny':
        return '☀️';
      case 'clouds':
      case 'cloudy':
        return '☁️';
      case 'rain':
      case 'drizzle':
        return '🌧️';
      case 'thunderstorm':
        return '⛈️';
      case 'snow':
        return '❄️';
      case 'mist':
      case 'fog':
        return '🌫️';
      default:
        return '🌤️';
    }
  }
  
  /// Get farming condition message
  String get farmingCondition {
    if (temperature > 35) {
      return 'Very hot - ensure adequate irrigation';
    } else if (temperature > 30) {
      return 'Hot - monitor plant stress';
    } else if (temperature >= 20 && temperature <= 30) {
      return 'Perfect for farming';
    } else if (temperature >= 15) {
      return 'Cool - good for most crops';
    } else {
      return 'Cold - protect sensitive plants';
    }
  }
}
