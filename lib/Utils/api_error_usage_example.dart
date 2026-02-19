// ignore_for_file: unused_element, unused_local_variable
// Example usage of ApiException, ApiErrorHandler, and UserErrorMapper.
// Copy these patterns into your repository and UI code.

import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/api_exception.dart';

// =============================================================================
// REPOSITORY LAYER
// =============================================================================

/// Example: repository catches DioException via ApiErrorHandler, logs developer
/// data, then rethrows ApiException so the UI can show a user message.
class WishlistRepositoryExample {
  final AuthService _api = AuthService();

  Future<void> addToWishlist(int productId) async {
    try {
      await _api.addToWishlist(productId);
    } on ApiException catch (e) {
      // Developer: log full details (do not show to user)
      debugPrint(e.logMessage);
      debugPrint('rawError: ${e.rawError}');
      rethrow;
    }
    // DioException is converted to ApiException inside AuthService,
    // so we only see ApiException here.
  }
}

/// Example: repository that returns Result-like outcome and logs errors.
class LoginRepositoryExample {
  final AuthService _api = AuthService();

  Future<Map<String, dynamic>?> login(String email, String password) async {
    try {
      final data = await _api.login(email: email, password: password);
      return data.isNotEmpty ? data : null;
    } on ApiException catch (e) {
      debugPrint('Login failed: ${e.logMessage}');
      rethrow;
    }
  }
}

// =============================================================================
// UI: SnackBar
// =============================================================================

/// Example: show user-friendly error in SnackBar. Never use e.message or
/// e.rawError in the UI.
void _showErrorSnackBar(BuildContext context, ApiException e) {
  final userMessage = UserErrorMapper.toUserMessage(e);
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(userMessage),
      backgroundColor: Colors.red,
      duration: const Duration(seconds: 4),
      behavior: SnackBarBehavior.floating,
    ),
  );
}

/// Example: full flow in a widget (e.g. Add to wishlist button).
Future<void> _onAddToWishlistPressed(BuildContext context, int productId) async {
  try {
    final auth = AuthService();
    await auth.addToWishlist(productId);
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added to wishlist'),
        backgroundColor: Colors.green,
      ),
    );
  } on ApiException catch (e) {
    if (!context.mounted) return;
    _showErrorSnackBar(context, e);
  } catch (e) {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Something went wrong. Please try again later.'),
        backgroundColor: Colors.red,
      ),
    );
  }
}

// =============================================================================
// UI: Dialog
// =============================================================================

/// Example: show error in a dialog (e.g. for critical flows).
Future<void> _showErrorDialog(BuildContext context, ApiException e) async {
  final userMessage = UserErrorMapper.toUserMessage(e);
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: const Text('Error'),
      content: Text(userMessage),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: const Text('OK'),
        ),
      ],
    ),
  );
}

/// Example: login flow with dialog on error.
Future<void> _onLoginPressed(BuildContext context, String email, String password) async {
  try {
    final auth = AuthService();
    final data = await auth.login(email: email, password: password);
    if (data.isNotEmpty && data['user'] != null && context.mounted) {
      Navigator.of(context).pushReplacementNamed('/home');
    }
  } on ApiException catch (e) {
    if (!context.mounted) return;
    await _showErrorDialog(context, e);
  }
}

// =============================================================================
// DEVELOPER: Logging only
// =============================================================================

void _logApiException(ApiException e) {
  debugPrint(e.logMessage);
  if (e.rawError != null) {
    debugPrint('rawError: ${e.rawError}');
  }
  if (e.errors != null && e.errors!.isNotEmpty) {
    debugPrint('validation errors: ${e.errors}');
  }
}
