// lib/config/app_config.dart

import 'package:flutter/foundation.dart';

class AppConfig {
  // API Base URL (Render) - bật lại khi push code
  static const String apiBaseUrl =
      'https://minisocial-api-ldl3.onrender.com/api/v1';

  // API Base URL (Local) - để test xem log
  // static const String apiBaseUrl = 'http://localhost:3001/api/v1';

  static const String appName = 'MiniSocial';
  static const String appVersion = '1.0.0';
}
