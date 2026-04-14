import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config.dart';

class LeaderboardService {  static Future<Map<String, dynamic>> getLeaderboard() async {
    try {
      final response = await http.get(
        Uri.parse('${Config.baseUrl}/leaderboard'),
        headers: {
          'Accept': 'application/json',
        },
      );

      final dynamic data =
          response.body.isNotEmpty ? jsonDecode(response.body) : [];

      if (response.statusCode == 200) {
        return {
          'success': true,
          'data': data,
        };
      } else {
        return {
          'success': false,
          'message': data is Map && data['detail'] != null
              ? data['detail'].toString()
              : 'Failed to fetch leaderboard',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': e.toString(),
      };
    }
  }
}