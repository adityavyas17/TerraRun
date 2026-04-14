import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config.dart';

class RunService {
    static Future<Map<String, dynamic>> saveRun({
    required double distanceKm,
    required int durationSeconds,
    required double avgSpeed,
  }) async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No auth token found. Please log in again.',
        };
      }

      final uri = Uri.parse('${Config.baseUrl}/runs');

      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'distance_km': distanceKm,
          'duration_seconds': durationSeconds,
          'avg_speed': avgSpeed,
        }),
      );

      final data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': 'Run saved',
          'data': data,
        };
      }

      return {
        'success': false,
        'message': data['detail'] ?? 'Failed to save run',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Save run error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getRuns() async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No auth token found. Please log in again.',
        };
      }

      final uri = Uri.parse('${Config.baseUrl}/runs');

      final response = await http.get(
        uri,
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final data =
          response.body.isNotEmpty ? jsonDecode(response.body) : [];

      if (response.statusCode == 200) {
        return {
          'success': true,
          'runs': data,
        };
      }

      return {
        'success': false,
        'message': data['detail'] ?? 'Failed to fetch runs',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Fetch runs error: $e',
      };
    }
  }
}