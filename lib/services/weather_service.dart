import 'dart:convert';
import 'dart:async';
import 'dart:io';
import 'package:http/http.dart' as http;

class WeatherService {
  final String _apiKey = "3e3ad1e41c07f236c1f5b7a6e8fb4dfa";

  Future<Map<String, dynamic>> fetchWeather(double lat, double lon) async {
    final url = Uri.https("api.openweathermap.org", "/data/2.5/weather", {
      "lat": lat.toString(),
      "lon": lon.toString(),
      "appid": _apiKey,
      "units": "metric",
    });

    try {
      final r = await http.get(url).timeout(const Duration(seconds: 10));

      if (r.statusCode != 200) {
        throw HttpException("OpenWeather HTTP ${r.statusCode}");
      }

      final decoded = jsonDecode(r.body);
      if (decoded is! Map) {
        throw Exception("Format cuaca tidak valid");
      }

      return decoded as Map<String, dynamic>;
    } on TimeoutException {
      throw TimeoutException("Timeout mengambil data cuaca");
    } on SocketException {
      throw SocketException("Tidak ada koneksi internet");
    }
  }
}
