// app_config.dart
import 'package:flutter/foundation.dart';

class AppConfig {
  /// Temporarily set this to true to simulate Release Mode while debugging.
  static const bool simulateRelease = false;

  /// Use this instead of kDebugMode across your app.
  static bool get isDebug => kDebugMode && !simulateRelease;
}