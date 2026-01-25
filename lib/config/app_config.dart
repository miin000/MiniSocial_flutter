// lib/config/app_config.dart

import 'package:flutter/foundation.dart';

class AppConfig {
  // API Base URL - thay đổi theo môi trường
  static String get apiBaseUrl {
    if (kIsWeb) {
      // Web browser
      return 'http://localhost:3001/api/v1';
    } else if (defaultTargetPlatform == TargetPlatform.android) {
      // Android emulator - 10.0.2.2 là địa chỉ localhost của máy host
      return 'http://10.0.2.2:3001/api/v1';
    } else if (defaultTargetPlatform == TargetPlatform.iOS) {
      // iOS simulator - localhost hoạt động bình thường
      return 'http://localhost:3001/api/v1';
    } else {
      // Desktop hoặc thiết bị thật - dùng IP của máy
      return 'http://192.168.2.30:3001/api/v1'; // Thay bằng IP thực của bạn
    }
  }

  static const String appName = 'MiniSocial';
  static const String appVersion = '1.0.0';
}
