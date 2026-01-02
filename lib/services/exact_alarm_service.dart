import 'package:flutter/services.dart';

class ExactAlarmService {
  static const MethodChannel _channel = MethodChannel(
    'rpg_selfimprove_app/alarm_manager',
  );

  /// Returns true if the platform allows scheduling exact alarms for this app.
  /// On Android < 12 we assume exact alarms are permitted.
  static Future<bool> canScheduleExactAlarms() async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'canScheduleExactAlarms',
      );
      return result ?? false;
    } on PlatformException {
      return false;
    } catch (_) {
      return false;
    }
  }
}
