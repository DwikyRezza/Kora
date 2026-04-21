import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_foreground_task/flutter_foreground_task.dart';
import 'running_task_handler.dart'; // untuk startRunningTaskCallback

class LocationService {
  /// Inisialisasi foreground task — panggil SEKALI di awal app (biasanya di main()).
  static void initialize() {
    FlutterForegroundTask.init(
      androidNotificationOptions: AndroidNotificationOptions(
        channelId: 'running_tracker_channel_v2',
        channelName: 'Running Tracker',
        channelDescription: 'Notifikasi aktif selama sesi lari berlangsung.',
        channelImportance: NotificationChannelImportance.DEFAULT,
        priority: NotificationPriority.DEFAULT,
        onlyAlertOnce: true,
      ),
      iosNotificationOptions: const IOSNotificationOptions(
        showNotification: false,
        playSound: false,
      ),
      foregroundTaskOptions: ForegroundTaskOptions(
        // Setiap 1 detik TaskHandler.onRepeatEvent dipanggil
        eventAction: ForegroundTaskEventAction.repeat(1000),
        autoRunOnBoot: false,
        allowWakeLock: true,  // CPU tetap aktif saat layar mati
        allowWifiLock: true,  // WiFi tetap aktif untuk map
      ),
    );
  }

  /// Request semua izin yang diperlukan (notif + battery optimization).
  static Future<void> requestPermissions() async {
    // 1. Izin notifikasi (Android 13+)
    final notifPerm = await FlutterForegroundTask.checkNotificationPermission();
    if (notifPerm != NotificationPermission.granted) {
      await FlutterForegroundTask.requestNotificationPermission();
    }

    if (Platform.isAndroid) {
      // 2. Abaikan optimasi baterai agar service tidak di-kill saat background
      if (!await FlutterForegroundTask.isIgnoringBatteryOptimizations) {
        await FlutterForegroundTask.requestIgnoreBatteryOptimization();
      }
    }
  }

  /// Mulai foreground service dengan TaskHandler yang berjalan di dalam service.
  static Future<bool> startService() async {
    // Jika service masih jalan, stop dulu dan tunggu sampai benar-benar berhenti
    if (await FlutterForegroundTask.isRunningService) {
      debugPrint('⚠️ [LocationService] Service masih jalan, stop dulu...');
      await FlutterForegroundTask.stopService();
      // Tunggu sampai service benar-benar berhenti
      for (int i = 0; i < 10; i++) {
        await Future.delayed(const Duration(milliseconds: 300));
        if (!await FlutterForegroundTask.isRunningService) break;
      }
    }

    debugPrint('🚀 [LocationService] Memulai foreground service...');
    final result = await FlutterForegroundTask.startService(
      serviceId: 256,
      notificationTitle: 'Run · 0:00 · 0.00 km',
      notificationText: 'GPS aktif',
      notificationButtons: const [
        NotificationButton(id: 'pause_btn', text: 'Pause'),
        NotificationButton(id: 'finish_btn', text: 'Stop'),
      ],
      callback: startRunningTaskCallback,
    );

    if (result is ServiceRequestSuccess) {
      debugPrint('✅ [LocationService] Foreground service berhasil dimulai!');
      return true;
    } else if (result is ServiceRequestFailure) {
      debugPrint('❌ [LocationService] Service GAGAL start!');
      debugPrint('❌ [LocationService] Error detail: ${result.error}');
      return false;
    } else {
      debugPrint('❌ [LocationService] Service GAGAL start (unknown): $result');
      return false;
    }
  }

  /// Kirim perintah ke TaskHandler di dalam service.
  static Future<void> sendCommand(Map<String, dynamic> command) async {
    FlutterForegroundTask.sendDataToTask(command);
  }

  /// Update teks notifikasi (fallback kalau tidak pakai TaskHandler).
  static Future<void> updateNotification({
    required String distance,
    required String time,
  }) async {
    await FlutterForegroundTask.updateService(
      notificationTitle: 'Sesi Lari Aktif ',
      notificationText: '$distance km · $time',
    );
  }

  /// Stop foreground service.
  static Future<void> stopService() async {
    await FlutterForegroundTask.stopService();
  }

  /// Cek apakah service sedang berjalan.
  static Future<bool> isRunning() async {
    return await FlutterForegroundTask.isRunningService;
  }
}
