import 'dart:convert';
import 'dart:async';
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

  /// Utility retry sederhana: menjalankan [action] hingga [retries] kali.
  Future<T> _withRetry<T>(
    Future<T> Function() action, {
    int retries = 2,
    Duration delay = const Duration(milliseconds: 500),
  }) async {
    late Object lastError;
    for (int i = 0; i <= retries; i++) {
      try {
        return await action();
      } catch (e) {
        lastError = e;
        if (i == retries) rethrow;
        await Future.delayed(delay);
      }
    }
    throw lastError;
  }

  /// Ambil data berdasarkan lokasi saat ini (lat/lon opsional)
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
        throw HttpException('HTTP ${r.statusCode} saat menghubungi AirVisual');
      }

      final decoded = jsonDecode(r.body);
      if (decoded is! Map<String, dynamic>) {
        throw FormatException('Response AirVisual bukan JSON object');
      }

      // Debug: print(decoded);
      final status = decoded['status'];
      if (status == 'success') {
        return decoded;
      } else {
        // Ambil pesan jika ada
        final msg =
            (decoded['data'] is Map && decoded['data']['message'] != null)
            ? decoded['data']['message']
            : 'Status: $status';
        throw Exception('AirVisual error: $msg');
      }
    } on TimeoutException {
      throw TimeoutException(
        'Timeout: AirVisual tidak merespons dalam 10 detik',
      );
    } on SocketException {
      throw SocketException(
        'Tidak ada koneksi internet saat mengakses AirVisual',
      );
    } on FormatException {
      throw FormatException('Format response AirVisual tidak valid');
    } catch (e) {
      rethrow;
    }
  }

  /// Ambil data berdasarkan nama kota (pakai Nominatim -> nearest_city)
  Future<Map<String, dynamic>> fetchByCity(String city) async {
    city = city.trim();
    if (city.isEmpty) throw Exception('Nama kota kosong');

    // Build Nominatim URI dengan queryParameters agar ter-encode aman
    final geoUri = Uri(
      scheme: 'https',
      host: 'nominatim.openstreetmap.org',
      path: '/search',
      queryParameters: {'q': city, 'format': 'json', 'limit': '1'},
    );

    try {
      // 1) Ambil koordinat dari Nominatim (dengan retry kecil)
      final geoResponse = await _withRetry<http.Response>(
        () {
          return http
              .get(
                geoUri,
                headers: {
                  'User-Agent': 'ParuGuardApp/1.0 (your_email@example.com)',
                },
              )
              .timeout(const Duration(seconds: 8));
        },
        retries: 2,
        delay: const Duration(milliseconds: 600),
      );

      if (geoResponse.statusCode != 200) {
        throw HttpException(
          'Gagal mendapatkan koordinat kota (HTTP ${geoResponse.statusCode})',
        );
      }

      final geoJson = jsonDecode(geoResponse.body);
      if (geoJson is! List || geoJson.isEmpty) {
        throw Exception(
          'Kota "$city" tidak ditemukan oleh geocoding (Nominatim)',
        );
      }

      final first = geoJson[0];
      if (first == null || first['lat'] == null || first['lon'] == null) {
        throw Exception('Koordinat untuk kota "$city" tidak lengkap');
      }

      final lat = double.tryParse(first['lat'].toString());
      final lon = double.tryParse(first['lon'].toString());
      if (lat == null || lon == null) {
        throw FormatException('Nilai lat/lon tidak valid dari Nominatim');
      }

      // 2) Panggil AirVisual nearest_city berdasarkan koordinat (dengan retry)
      final key = await _getKey();
      final airUri = Uri.parse('$_baseNearest?lat=$lat&lon=$lon&key=$key');

      final airResponse = await _withRetry<http.Response>(
        () {
          return http.get(airUri).timeout(const Duration(seconds: 10));
        },
        retries: 2,
        delay: const Duration(milliseconds: 700),
      );

      if (airResponse.statusCode != 200) {
        throw HttpException('AirVisual HTTP ${airResponse.statusCode}');
      }

      final airJson = jsonDecode(airResponse.body);
      if (airJson is! Map<String, dynamic>) {
        throw FormatException(
          'Response AirVisual tidak dalam format yang diharapkan',
        );
      }

      if (airJson['status'] == 'success') {
        return airJson;
      } else {
        final message =
            (airJson['data'] is Map && airJson['data']['message'] != null)
            ? airJson['data']['message']
            : 'AirVisual returned status ${airJson['status']}';
        throw Exception('AirVisual gagal: $message');
      }
    } on TimeoutException {
      throw TimeoutException(
        'Timeout: gagal mendapat koordinat atau data AQI (cek koneksi)',
      );
    } on SocketException {
      throw SocketException(
        'Tidak ada koneksi internet saat mencoba mencari kota "$city"',
      );
    } on FormatException catch (e) {
      throw FormatException('Response tidak valid: ${e.message}');
    } catch (e) {
      // Jangan bungkus terlalu generic agar panggilannya tetap dapat pesan aslinya
      throw Exception('Gagal mendapatkan data AQI untuk "$city": $e');
    }
  }
}
