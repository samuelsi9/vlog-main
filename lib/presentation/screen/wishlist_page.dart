import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Utils/parse_utils.dart';
import 'package:vlog/Utils/wishlist_service.dart';
import 'package:vlog/presentation/screen/detail_screen.dart';

const Color _primaryRed = Color(0xFFE53E3E);

// ─────────────────────────────────────────────
//  Beautiful snackbar helper
// ─────────────────────────────────────────────
enum _SnackType { success, warning, error, info }

void _showSnack(
  BuildContext context,
  String message, {
  _SnackType type = _SnackType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final config = {
    _SnackType.success: (
      icon: Icons.check_circle_rounded,
      bg: const Color(0xFF1B5E20),     // ✅ fixed: was wrong navy blue
      accent: const Color(0xFF4CAF50), // ✅ fixed: was near-white
    ),
    _SnackType.warning: (
      icon: Icons.info_rounded,
      bg: const Color(0xFF4A3000),
      accent: const Color(0xFFFFC107),
    ),
    _SnackType.error: (
      icon: Icons.error_rounded,
      bg: const Color(0xFF5C0A0A),
      accent: const Color(0xFFEF5350),
    ),
    _SnackType.info: (
      icon: Icons.info_outline_rounded,
      bg: const Color(0xFF0D2340),
      accent: const Color(0xFF42A5F5),
    ),
  }[type]!;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: config.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: config.accent.withOpacity(0.4), width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.25),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: config.accent.withOpacity(0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(config.icon, color: config.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
}

// ─────────────────────────────────────────────
//  Network / API error classifier
//  Maps raw ApiException strings to friendly user messages.
//  Original dev errors are documented in comments per branch.
// ─────────────────────────────────────────────
String _friendlyError(Object e) {
  final raw = e.toString().toLowerCase();

  // dev: ApiException(statusCode: null, errorCode: null, message: Network/connection error)
  if (raw.contains('network') ||
      raw.contains('connection') ||
      raw.contains('socket') ||
      raw.contains('timeout') ||
      raw.contains('statuscode: null')) {
    return "No internet connection.\nPlease check your network and try again.";
  }

  // dev: ApiException with statusCode 401 / unauthorized
  if (raw.contains('401') || raw.contains('unauthorized')) {
    return "Your session has expired. Please log in again.";
  }

  // dev: ApiException with statusCode 403 / forbidden
  if (raw.contains('403') || raw.contains('forbidden')) {
    return "You don't have permission to do that.";
  }

  // dev: ApiException with statusCode 404
  if (raw.contains('404')) {
    return "We couldn't find what you were looking for.";
  }

  // dev: ApiException with statusCode 500 or generic server error
  if (raw.contains('500') || raw.contains('server')) {
    return "Our servers are having a moment.\nPlease try again shortly.";
  }

  // dev: any other unknown exception – e.toString()
  return "Something went wrong. Please try again.";
}

// ─────────────────────────────────────────────

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});

  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistService>().fetchWishlist();
    });
  }

  Widget _buildImage(String imageUrl, {double? height, double? width}) {
    if (imageUrl.isEmpty) {
      return Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
      );
    }
    final trimmed = imageUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(
        trimmed,
        height: height,
        width: width,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: height,
          width: width,
          color: Colors.grey[200],
          child: Icon(Icons.broken_image, color: Colors.grey[400], size: 30),
        ),
      );
    }
    return Image.asset(
      trimmed,
      height: height,
      width: width,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => Container(
        height: height,
        width: width,
        color: Colors.grey[200],
        child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "My Wishlist",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        leading: canPop
            ? IconButton(
                icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        actions: [
          Consumer<WishlistService>(
            builder: (context, ws, _) {
              if (!ws.loading) return const SizedBox.shrink();
              return const Padding(
                padding: EdgeInsets.only(right: 16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2, color: _primaryRed),
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<WishlistService>(
        builder: (context, wishlistService, child) {

          // ── Loading state ──
          if (wishlistService.loading && wishlistService.wishlist.isEmpty) {
            return const Center(child: CircularProgressIndicator(color: _primaryRed));
          }

          // ── Error state ──
          // dev: wishlistService.error holds the raw exception string from WishlistService.
          // Triggered by: ApiException(statusCode: null, errorCode: null, message: Network/connection error)
          // _friendlyError() maps that to a user-readable message based on the error content.
          if (wishlistService.error != null && wishlistService.wishlist.isEmpty) {
            final raw = wishlistService.error!.toLowerCase();
            final isNetworkError = raw.contains('network') ||
                raw.contains('connection') ||
                raw.contains('socket') ||
                raw.contains('statuscode: null');

            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        shape: BoxShape.circle,
                      ),
                      // wifi_off for network errors, error_outline for server/other errors
                      child: Icon(
                        isNetworkError
                            ? Icons.wifi_off_rounded
                            : Icons.error_outline_rounded,
                        size: 38,
                        color: Colors.red.shade300,
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      isNetworkError
                          ? "No internet connection"
                          : "Couldn't load your wishlist",
                      style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      // dev: wishlistService.error → mapped via _friendlyError()
                      _friendlyError(wishlistService.error!),
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 24),
                    ElevatedButton.icon(
                      onPressed: () {
                        wishlistService.clearError();
                        wishlistService.fetchWishlist();
                      },
                      icon: const Icon(Icons.refresh_rounded, size: 18),
                      label: const Text('Try again'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _primaryRed,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }

          final wishlist = wishlistService.wishlist;

          // ── Empty state ──
          if (wishlist.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.favorite_border_rounded,
                      size: 48,
                      color: Colors.red.shade200,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Text(
                    "Nothing saved yet",
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.black87,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Tap the heart on any item to save it here",
                    style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                  ),
                ],
              ),
            );
          }

          // ── List ──
          return RefreshIndicator(
            color: _primaryRed,
            onRefresh: () => wishlistService.fetchWishlist(),
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: wishlist.length,
              itemBuilder: (context, index) {
                final item = wishlist[index];
                final p = item.product;
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 2,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => Detail(productId: p.id),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: _buildImage(p.image, width: 80, height: 80),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  p.name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                                    const SizedBox(width: 4),
                                    Text(
                                      p.rating.toString(),
                                      style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.baseline,
                                  textBaseline: TextBaseline.alphabetic,
                                  children: [
                                    Text(
                                      "₺${p.price.toStringAsFixed(2)}",
                                      style: const TextStyle(
                                        color: Colors.pink,
                                        fontWeight: FontWeight.w600,
                                        fontSize: 18,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade100,
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: Text(
                                        "1${getDisplayUnit(p.unitType)}",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.amber.shade900,
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          // ── Remove from wishlist ──
                          IconButton(
                            icon: const Icon(Icons.favorite_rounded, color: _primaryRed),
                            tooltip: 'Remove from wishlist',
                            onPressed: () async {
                              try {
                                await wishlistService.removeFromWishlist(item.id);
                                // dev: removed item.id from wishlist successfully
                                if (context.mounted) {
                                  _showSnack(
                                    context,
                                    '"${p.name}" was removed from your wishlist.',
                                    type: _SnackType.success,
                                    duration: const Duration(seconds: 2),
                                  );
                                }
                              } catch (e) {
                                // dev error: e.toString() – removeFromWishlist(item.id) failed
                                if (context.mounted) {
                                  _showSnack(
                                    context,
                                    _friendlyError(e),
                                    type: _SnackType.error,
                                  );
                                }
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}
