import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
import 'dart:async';
import 'package:vlog/presentation/home.dart';
import 'package:vlog/presentation/auth/login_page.dart';
import 'package:vlog/presentation/onboarding/onboarding_page.dart';
import 'package:vlog/presentation/screen/checkout_confirmation_page.dart';
import 'package:vlog/presentation/auth/reset_password_page.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:vlog/Utils/wishlist_service.dart';
import 'package:vlog/Utils/cart_service.dart';
import 'package:vlog/Utils/delivery_tracking_service.dart';
import 'package:vlog/Utils/order_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vlog/presentation/skeleton_loader.dart';
import 'package:vlog/Data/notification_service.dart';
import 'package:vlog/core/app_lifecycle_handler.dart';
import 'package:firebase_core/firebase_core.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  //await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  NotificationService().initNotification();

  final lifecycleHandler = AppLifecycleHandler();
  WidgetsBinding.instance.addObserver(lifecycleHandler);
  Future.microtask(() {
    lifecycleHandler.triggerNotificationCheck();
    lifecycleHandler.startPolling();
  });

  // Note: To enable Google/Apple authentication, you need to:
  // 1. Set up Firebase: flutter pub add firebase_core && flutterfire configure
  // 2. Initialize Firebase here: await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // 3. Configure Google Sign-In and Apple Sign-In in Firebase Console
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  StreamSubscription? _sub;
  String? _initialLink;
  bool _initialized = false;
  bool _isAuthenticated = false;
  bool _onboardingSeen = false;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  Future<void> _initDeepLinks() async {
    try {
      _initialLink = await getInitialLink();
      if (_initialLink != null) {
        _handleLink(_initialLink!);
      }
    } catch (_) {}

    _sub = linkStream.listen((String? link) {
      if (link != null) {
        _handleLink(link);
      }
    }, onError: (err) {});
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    if (_initialized) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasStorageToken = await StorageService.isLoggedIn();
      final hasPrefsToken = (prefs.getString('auth_token') ?? '').isNotEmpty;
      final onboardingSeen = await OnboardingPage.hasSeenOnboarding();
      await Future.delayed(const Duration(milliseconds: 800));
      if (!mounted) return;
      setState(() {
        _isAuthenticated = hasStorageToken || hasPrefsToken;
        _onboardingSeen = onboardingSeen;
        _initialized = true;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _isAuthenticated = false;
        _onboardingSeen = false;
        _initialized = true;
      });
    }
  }

  void _handleLink(String link) {
    // Supported:
    // - OAuth: vlog://auth/callback?token=...&provider=google|facebook
    // - Reset: vlog://auth/reset?resettoken=...
    final uri = Uri.parse(link);
    final host = uri.host; // 'auth'
    final path = uri.path; // '/callback' or '/reset'

    if (host == 'auth' && path == '/callback') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty) {
        if (!mounted) return;
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainScreen(token: null)),
          (route) => false,
        );
      }
      return;
    }

    if (host == 'auth' && path == '/reset') {
      final resetToken = uri.queryParameters['resettoken'];
      if (resetToken != null && resetToken.isNotEmpty) {
        if (!mounted) return;
        // Navigate to reset password screen
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(resetToken: resetToken),
          ),
        );
      }
      return;
    }
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return MaterialApp(
        debugShowCheckedModeBanner: false,
        home: const HomeSkeletonLoader(),
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
        routes: {'/checkout': (context) => const CheckoutConfirmationPage()},
        home: _onboardingSeen
            ? (_isAuthenticated ? MainScreen(token: null) : const LoginPage())
            : OnboardingPage(
                onComplete: () {
                  setState(() => _onboardingSeen = true);
                },
              ),
      ),
    );
  }
}
