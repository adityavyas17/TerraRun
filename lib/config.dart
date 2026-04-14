import 'package:flutter/foundation.dart';

class Config {
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:8000';
    }
    return 'http://YOUR_LOCAL_IP:8000';
  }
}
