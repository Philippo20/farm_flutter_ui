import 'dart:convert';
import 'package:http/http.dart' as http;

Future<Map<String, dynamic>?> fetchWeatherData({
  required double latitude,
  required double longitude,
  required String apiKey,
}) async {
  final url =
      'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$apiKey&units=metric';

  final response = await http.get(Uri.parse(url));
  if (response.statusCode == 200) {
    final json = jsonDecode(response.body);
    return {
      'temperature': json['main']['temp'],
      'condition': json['weather'][0]['main'], // e.g., 'Rain', 'Clear', 'Clouds'
      'description': json['weather'][0]['description'],
    };
  } else {
    return null;
  }
}
