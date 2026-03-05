import 'package:flutter/material.dart';
import 'package:vlog/presentation/home.dart';
import 'package:vlog/presentation/auth/register_page.dart';
import 'package:vlog/presentation/onboarding/onboarding_page.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Centralized app routing logic.
/// Determines the initial screen based on onboarding and auth state.
class AppRouter {
  AppRouter._();

  /// Resolves the initial screen to show at app startup.
  /// - First launch: Onboarding
  /// - Onboarding done + not logged in: Login
  /// - Onboarding done + logged in: Main (home)
  static Future<AppRouteState> resolveInitialRoute() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final onboardingCompleted = await OnboardingPage.hasSeenOnboarding();
      final hasStorageToken = await StorageService.isLoggedIn();
      final hasPrefsToken = (prefs.getString('auth_token') ?? '').isNotEmpty;
      final isAuthenticated = hasStorageToken || hasPrefsToken;

      return AppRouteState(
        onboardingCompleted: onboardingCompleted,
        isAuthenticated: isAuthenticated,
      );
    } catch (_) {
      return const AppRouteState(
        onboardingCompleted: false,
        isAuthenticated: false,
      );
    }
  }

  /// Returns the appropriate initial widget based on route state.
  static Widget buildInitialScreen({
    required AppRouteState state,
    required VoidCallback onOnboardingComplete,
  }) {
    if (!state.onboardingCompleted) {
      return OnboardingPage(onComplete: onOnboardingComplete);
    }
    if (state.isAuthenticated) {
      return MainScreen(token: null);
    }
    return const RegisterPage();
  }
}

/// Represents the app's routing state at startup.
class AppRouteState {
  final bool onboardingCompleted;
  final bool isAuthenticated;

  const AppRouteState({
    required this.onboardingCompleted,
    required this.isAuthenticated,
  });
}
