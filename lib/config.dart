import 'package:flutter/foundation.dart';

class Config {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }

    return 'http://172.22.194.117:8000';
  }
}