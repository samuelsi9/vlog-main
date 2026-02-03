import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class NotificationService {
 
  final notificationService=FlutterLocalNotificationsPlugin();
  
  bool _isInitialized=false;
  //INITIALIZATION]
  Future<void> initNotification() async{
    if(_isInitialized) return; //prevent re-initialization
    //prepare android init settings
  const initSettingsAndroid=AndroidInitializationSettings('@mipmap/ic_launcher');
    //prepare ios init settings

 const initSettingsIos=DarwinInitializationSettings(
   requestAlertPermission: true,
   requestBadgePermission: true,
   requestSoundPermission: true,
 );
 // init settings
 const initSettings=InitializationSettings(android: initSettingsAndroid, iOS: initSettingsIos);
 //Notifications details setup


    // Show Notification
    await notificationService.initialize(
      settings: initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        // ON NOTI TAP – handle when user taps the notification
      },
    );

    _isInitialized = true;
  }


NotificationDetails get notificationDetails => const NotificationDetails(
  android: AndroidNotificationDetails(
    "daily_channel",
    "Daily Notifications",
    channelDescription: "This channel is used for daily notifications",
    importance: Importance.max,
    priority: Priority.high,
  ),
  iOS: DarwinNotificationDetails(),
);
  Future<void> showNotification(String title, String body) async {
  return notificationService.show(
    id: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    title: title,
    body: body,
    notificationDetails: notificationDetails,
  );
}
}







// import 'package:firebase_messaging/firebase_messaging.dart';
// import 'package:flutter_local_notifications/flutter_local_notifications.dart';
// import 'apiservices.dart';

// class NotificationService {
//   static final FirebaseMessaging _messaging = FirebaseMessaging.instance;
//   static final FlutterLocalNotificationsPlugin _local =
//       FlutterLocalNotificationsPlugin();

//   /// ENTRY POINT
//   static Future<void> init() async {
//     // Request permission
//     await _messaging.requestPermission(
//       alert: true,
//       badge: true,
//       sound: true,
//     );

//     // Init local notifications
//     const androidInit =
//         AndroidInitializationSettings('@mipmap/ic_launcher');
//     const initSettings = InitializationSettings(android: androidInit);
//     await _local.initialize(settings: initSettings);

//     _listenToMessages();
//     await _sendTokenToBackend();
//   }

//   /// LISTEN TO FIREBASE
//   static void _listenToMessages() {
//     // Foreground
//     FirebaseMessaging.onMessage.listen((RemoteMessage message) {
//       final title = message.notification?.title ?? 'Order Update';
//       final body = message.notification?.body ?? '';

//       _showNotification(title, body);
//     });

//     // When clicked
//     FirebaseMessaging.onMessageOpenedApp.listen((message) {
//       print('Notification clicked');
//     });
//   }

//   /// SHOW LOCAL NOTIFICATION
//   static Future<void> _showNotification(
//       String title, String body) async {
//     const androidDetails = AndroidNotificationDetails(
//       'orders_channel',
//       'Order Notifications',
//       importance: Importance.max,
//       priority: Priority.high,
//     );

//     const details = NotificationDetails(android: androidDetails);

//     await _local.show(0, title, body, details);
//   }

//   /// SEND TOKEN TO LARAVEL
//   static Future<void> _sendTokenToBackend() async {
//     final token = await _messaging.getToken();
//     if (token == null) return;

//     try {
//       await ApiServices().dio.post(
//         '/save-fcm-token',
//         data: {'fcm_token': token},
//       );
//     } catch (e) {
//       print('Error sending FCM token: $e');
//     }
//   }
// }