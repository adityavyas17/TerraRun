import 'dart:convert';
import 'package:http/http.dart' as http;
import 'auth_service.dart';
import '../config.dart';

class StatsService {
  static Future<Map<String, dynamic>> getProfileStats() async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No auth token found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/stats'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final dynamic data =
          response.body.isNotEmpty ? jsonDecode(response.body) : {};

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      }

      return {
        'success': false,
        'message': data is Map && data['detail'] != null
            ? data['detail'].toString()
            : 'Failed to fetch stats',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Stats error: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> getAllRuns() async {
    try {
      final token = await AuthService.getToken();

      if (token == null || token.isEmpty) {
        return {
          'success': false,
          'message': 'No auth token found. Please log in again.',
        };
      }

      final response = await http.get(
        Uri.parse('${Config.baseUrl}/runs'),
        headers: {
          'Accept': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      final dynamic data =
          response.body.isNotEmpty ? jsonDecode(response.body) : [];

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      }

      return {
        'success': false,
        'message': data is Map && data['detail'] != null
            ? data['detail'].toString()
            : 'Failed to fetch runs',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Fetch runs error: $e',
      };
    }
  }
}