// lib/services/weather_service.dart
import 'dart:convert';
import 'dart:async';
import 'package:http/http.dart' as http;
import 'secure_store.dart';

/// WeatherService
/// - Menggunakan OpenWeatherMap Current Weather (by lat/lon or city name)
/// - Simpan API key di SecureStore under 'openweather_key'
class WeatherService {
  final String _base = 'https://api.openweathermap.org/data/2.5/weather';

  Future<String?> _getKey() async {
    return await SecureStore.readEncrypted('openweather_key');
  }

  /// Get weather by coordinates (lat, lon)
  Future<Map<String, dynamic>> getWeatherByCoords(
    double lat,
    double lon,
  ) async {
    final key = await _getKey();
    if (key == null) {
      throw Exception('OpenWeather key not set. Simpan ke SecureStore.');
    }
    final uri = Uri.parse('$_base?lat=$lat&lon=$lon&appid=$key&units=metric');

    try {
      final r = await http.get(uri).timeout(const Duration(seconds: 8));
      if (r.statusCode == 200) {
        return jsonDecode(r.body) as Map<String, dynamic>;
      } else {
        throw Exception('Weather HTTP ${r.statusCode}');
      }
    } on TimeoutException {
      throw Exception('Timeout: Weather API tidak merespons');
    } catch (e) {
      rethrow;
    }
  }

  /// Option: get by city name
  Future<Map<String, dynamic>> getWeatherByCity(String city) async {
    final key = await _getKey();
    if (key == null) throw Exception('OpenWeather key not set.');
    final uri = Uri.parse(
      '$_base?q=${Uri.encodeComponent(city)}&appid=$key&units=metric',
    );
    final r = await http.get(uri).timeout(const Duration(seconds: 8));
    if (r.statusCode == 200) return jsonDecode(r.body) as Map<String, dynamic>;
    throw Exception('Weather HTTP ${r.statusCode}');
  }
}
