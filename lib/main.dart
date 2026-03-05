import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uni_links/uni_links.dart';
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

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();
  await NotificationService().initNotification();

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
  StreamSubscription? _sub;
  String? _initialLink;
  bool _initialized = false;
  AppRouteState? _routeState;

  @override
  void initState() {
    super.initState();
    _resolveInitialRoute();
    _initDeepLinks();
  }

  /// Resolves onboarding + auth state at startup. No artificial delay.
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

  void _handleLink(String link) {
    final uri = Uri.parse(link);
    final host = uri.host;
    final path = uri.path;

    if (host == 'auth' && path == '/callback') {
      final token = uri.queryParameters['token'];
      if (token != null && token.isNotEmpty && mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => MainScreen(token: null)),
          (route) => false,
        );
      }
      return;
    }

    if (host == 'auth' && path == '/reset') {
      final resetToken = uri.queryParameters['resettoken'];
      if (resetToken != null && resetToken.isNotEmpty && mounted) {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ResetPasswordPage(resetToken: resetToken),
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
    // Show minimal loader only while resolving route (typically < 100ms)
    if (!_initialized || _routeState == null) {
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
        routes: {
          '/checkout': (context) => const CheckoutConfirmationPage(),
        },
        home: AppRouter.buildInitialScreen(
          state: _routeState!,
          onOnboardingComplete: _onOnboardingComplete,
        ),
      ),
    );
  }
}
