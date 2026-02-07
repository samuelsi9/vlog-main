import 'dart:async';
import 'package:flutter/widgets.dart';
import 'package:vlog/Data/notification_service.dart';

/// Global app lifecycle observer. Triggers notification fetch on app start,
/// on resume, and periodically while in foreground so admin order updates
/// are shown as local notifications without leaving the screen.
class AppLifecycleHandler with WidgetsBindingObserver {
  final NotificationService _notificationService = NotificationService();
  bool _isFetching = false;
  Timer? _pollTimer;

  static const Duration _pollInterval = Duration(seconds: 5);

  /// Call to check and show notifications (e.g. on app start or on interval).
  /// Safe to call when user is not authenticated; NotificationService handles it.
  void triggerNotificationCheck() {
    if (_isFetching) return;
    _isFetching = true;
    _notificationService.fetchShowAndMarkRead().whenComplete(() {
      _isFetching = false;
    });
  }

  void startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(_pollInterval, (_) => triggerNotificationCheck());
  }

  void _stopPolling() {
    _pollTimer?.cancel();
    _pollTimer = null;
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    switch (state) {
      case AppLifecycleState.resumed:
        triggerNotificationCheck();
        startPolling();
        break;
      case AppLifecycleState.paused:
      case AppLifecycleState.inactive:
      case AppLifecycleState.detached:
      case AppLifecycleState.hidden:
        _stopPolling();
        break;
    }
  }
}
