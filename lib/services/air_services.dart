import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'secure_store.dart';

class AirService {
  final String _fallbackKey = '12680eb5-d113-48f9-ae58-d591c4a9c7b6';
  final String _baseNearest = 'https://api.airvisual.com/v2/nearest_city';

  Future<String> _getKey() async {
    final stored = await SecureStore.readEncrypted('airvisual_key');
    return stored ?? _fallbackKey;
  }

  Future<T> _withRetry<T>(
    Future<T> Function() action, {
    int retries = 2,
    Duration delay = const Duration(milliseconds: 400),
  }) async {
    Object? lastError;

    for (int i = 0; i <= retries; i++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        if (i == retries) rethrow;
        await Future.delayed(delay);
      }
    }
    throw lastError ?? Exception("Unknown error");
  }

  /// Ambil AQI berdasarkan lokasi (GPS)
  Future<Map<String, dynamic>> fetchNearestCity({
    double? lat,
    double? lon,
  }) async {
    final key = await _getKey();
    final uri = (lat != null && lon != null)
        ? Uri.parse('$_baseNearest?lat=$lat&lon=$lon&key=$key')
        : Uri.parse('$_baseNearest?key=$key');

    try {
      final r = await http.get(uri).timeout(const Duration(seconds: 10));

      if (r.statusCode != 200) {
        throw HttpException("AirVisual HTTP ${r.statusCode}");
      }

      final data = jsonDecode(r.body);
      if (data is! Map || data['status'] != 'success') {
        throw Exception(
          data['data']?['message'] ?? 'AirVisual error: ${data['status']}',
        );
      }

      return data as Map<String, dynamic>;
    } on TimeoutException {
      throw TimeoutException("Timeout: AirVisual tidak merespons");
    } on SocketException {
      throw SocketException("Tidak ada koneksi internet");
    }
  }

  /// Ambil AQI berdasarkan nama kota
  Future<Map<String, dynamic>> fetchByCity(String city) async {
    city = city.trim();
    if (city.isEmpty) throw Exception("Nama kota tidak boleh kosong");

    final geoUri = Uri(
      scheme: "https",
      host: "nominatim.openstreetmap.org",
      path: "/search",
      queryParameters: {"q": city, "format": "json", "limit": "1"},
    );

    try {
      // 1) Geocoding Nominatim
      final geoResponse = await _withRetry(
        () => http
            .get(
              geoUri,
              headers: {"User-Agent": "ParuGuard/1.0 (contact@email.com)"},
            )
            .timeout(const Duration(seconds: 8)),
      );

      if (geoResponse.statusCode != 200) {
        throw HttpException("Geocoding HTTP ${geoResponse.statusCode}");
      }

      final geoData = jsonDecode(geoResponse.body);
      if (geoData is! List || geoData.isEmpty) {
        throw Exception("Kota '$city' tidak ditemukan");
      }

      final lat = double.parse(geoData[0]["lat"]);
      final lon = double.parse(geoData[0]["lon"]);

      // 2) AirVisual berdasarkan koordinat
      final key = await _getKey();
      final airUri = Uri.parse('$_baseNearest?lat=$lat&lon=$lon&key=$key');

      final airResponse = await _withRetry(
        () => http.get(airUri).timeout(const Duration(seconds: 10)),
      );

      if (airResponse.statusCode != 200) {
        throw HttpException("AirVisual HTTP ${airResponse.statusCode}");
      }

      final airJson = jsonDecode(airResponse.body);

      if (airJson['status'] != 'success') {
        throw Exception(
          airJson['data']?['message'] ??
              "AirVisual error: ${airJson['status']}",
        );
      }

      return airJson;
    } on TimeoutException {
      throw TimeoutException("Timeout saat mencari kota");
    } on SocketException {
      throw SocketException("Tidak ada koneksi internet");
    }
  }
}
