import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config.dart';

class AuthService {
  static const _tokenKey = 'auth_token';
  static const _userNameKey = 'user_name';
  static const _userEmailKey = 'user_email';

  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/auth/login'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'email': email.trim(),
        'password': password,
      }),
    );

    final dynamic data =
        response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode != 200) {
      throw Exception(
        data is Map && data['detail'] != null
            ? data['detail']
            : 'Login failed',
      );
    }

    await saveSession(
      token: data['access_token'],
      userName: data['user_name'],
      userEmail: data['user_email'],
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<Map<String, dynamic>> signup({
    required String name,
    required String email,
    required String password,
  }) async {
    final response = await http.post(
      Uri.parse('${Config.baseUrl}/auth/signup'),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
      body: jsonEncode({
        'name': name.trim(),
        'email': email.trim(),
        'password': password,
      }),
    );

    final dynamic data =
        response.body.isNotEmpty ? jsonDecode(response.body) : {};

    if (response.statusCode != 200) {
      throw Exception(
        data is Map && data['detail'] != null
            ? data['detail']
            : 'Signup failed',
      );
    }

    await saveSession(
      token: data['access_token'],
      userName: data['user_name'],
      userEmail: data['user_email'],
    );

    return Map<String, dynamic>.from(data);
  }

  static Future<void> saveSession({
    required String token,
    required String userName,
    required String userEmail,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_userNameKey, userName);
    await prefs.setString(_userEmailKey, userEmail);
  }

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userNameKey);
  }

  static Future<String?> getUserEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_userEmailKey);
  }

  static Future<bool> isLoggedIn() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }

  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_userNameKey);
    await prefs.remove(_userEmailKey);
  }
}