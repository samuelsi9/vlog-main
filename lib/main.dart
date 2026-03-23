import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';
import 'dart:async';
import 'package:vlog/presentation/home.dart';
import 'package:vlog/presentation/screen/checkout_confirmation_page.dart';
import 'package:vlog/presentation/auth/reset_password_page.dart';
import 'package:vlog/core/app_router.dart';
import 'package:vlog/Utils/wishlist_service.dart';
import 'package:vlog/Utils/cart_service.dart';
import 'package:vlog/Utils/delivery_tracking_service.dart';
import 'package:vlog/Utils/order_service.dart';
import 'package:vlog/presentation/skeleton_loader.dart';
import 'package:vlog/Data/notification_service.dart';
import 'package:vlog/core/app_lifecycle_handler.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:vlog/firebase_options.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

   await NotificationService().initNotification();

 
   // Enable verbose logging for debugging (remove in production)
  OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
  // Initialize with your OneSignal App ID
  OneSignal.initialize("9bda19f1-38fd-403e-8491-18edf4409b5c");
  // Use this method to prompt for push notifications.
  // We recommend removing this method after testing and instead use In-App Messages to prompt for notification permission.
  //OneSignal.Notifications.requestPermission(false);

  // ✅ Listen for when the subscription ID becomes available
OneSignal.User.pushSubscription.addObserver((state) {
  String? playerId = state.current.id;
  
  if (playerId != null && playerId.isNotEmpty) {
    print("Player ID ready: $playerId");
     // your API call here
  }
});
  
  

  // Initialize Firebase
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } on FirebaseException catch (e) {
    if (e.code != 'duplicate-app') rethrow;
  }

  // Your custom notification service
 

  final lifecycleHandler = AppLifecycleHandler();
  WidgetsBinding.instance.addObserver(lifecycleHandler);
  Future.microtask(() {
    lifecycleHandler.triggerNotificationCheck();
    lifecycleHandler.startPolling();
  });

  runApp(const MyApp());
 
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppLinks _appLinks = AppLinks();
  StreamSubscription<Uri>? _sub;

  bool _initialized = false;
  AppRouteState? _routeState;

  @override
  void initState() {
    super.initState();
    _resolveInitialRoute();
    _initDeepLinks();
  }

  Future<void> _resolveInitialRoute() async {
    if (_initialized) return;

    final state = await AppRouter.resolveInitialRoute();

    if (!mounted) return;

    setState(() {
      _routeState = state;
      _initialized = true;
    });
  }

  Future<void> _initDeepLinks() async {
    try {
      final initialUri = await _appLinks.getInitialLink();
      if (initialUri != null) {
        _handleLink(initialUri.toString());
      }
    } catch (_) {}

    _sub = _appLinks.uriLinkStream.listen(
      (Uri uri) {
        _handleLink(uri.toString());
      },
      onError: (err) {},
    );
  }

  void _handleLink(String link) {
    final uri = Uri.parse(link);

    if (uri.host == 'auth' && uri.path == '/callback') {
      final token = uri.queryParameters['token'];

      if (token != null && token.isNotEmpty && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(
            builder: (_) => MainScreen(token: token),
          ),
          (route) => false,
        );
      }
      return;
    }

    if (uri.host == 'auth' && uri.path == '/reset') {
      final resetToken = uri.queryParameters['resettoken'];

      if (resetToken != null && resetToken.isNotEmpty && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) =>
                ResetPasswordPage(resetToken: resetToken),
          ),
        );
      }
      return;
    }
  }

  void _onOnboardingComplete() {
    setState(() {
      _routeState = AppRouteState(
        onboardingCompleted: true,
        isAuthenticated: _routeState?.isAuthenticated ?? false,
      );
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized || _routeState == null) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: HomeSkeletonLoader(),
      );
    }

    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => WishlistService()),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => DeliveryTrackingService()),
        ChangeNotifierProvider(create: (_) => OrderService()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        routes: {
          '/checkout': (context) =>
              const CheckoutConfirmationPage(),
        },
        home: AppRouter.buildInitialScreen(
          state: _routeState!,
          onOnboardingComplete: _onOnboardingComplete,
        ),
      ),
    );
  }
}