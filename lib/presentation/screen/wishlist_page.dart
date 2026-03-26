import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vlog/Utils/parse_utils.dart';
import 'package:vlog/Utils/wishlist_service.dart';
import 'package:vlog/presentation/screen/detail_screen.dart';

// ── Brand palette ────────────────────────────────────────────
const Color _red        = Color(0xFFE53E3E);
const Color _redLight   = Color(0xFFFC8181);
const Color _cream      = Color(0xFFFAF8F5);
const Color _charcoal   = Color(0xFF1A1A2E);
const Color _slate      = Color(0xFF6B7280);
const Color _cardBg     = Color(0xFFFFFFFF);

// ── Snackbar ─────────────────────────────────────────────────
enum _SnackType { success, warning, error, info }

void _showSnack(BuildContext context, String message, {
  _SnackType type = _SnackType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final configs = {
    _SnackType.success: (icon: Icons.check_circle_rounded,  bg: const Color(0xFF1B5E20), accent: const Color(0xFF4CAF50)),
    _SnackType.warning: (icon: Icons.info_rounded,           bg: const Color(0xFF4A3000), accent: const Color(0xFFFFC107)),
    _SnackType.error:   (icon: Icons.error_rounded,          bg: const Color(0xFF5C0A0A), accent: const Color(0xFFEF5350)),
    _SnackType.info:    (icon: Icons.info_outline_rounded,   bg: const Color(0xFF0D2340), accent: const Color(0xFF42A5F5)),
  };
  final c = configs[type]!;
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(SnackBar(
      duration: duration,
      behavior: SnackBarBehavior.floating,
      backgroundColor: Colors.transparent,
      elevation: 0,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      content: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: c.bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: c.accent.withOpacity(0.4), width: 1),
          boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6))],
        ),
        child: Row(children: [
          Container(width: 36, height: 36,
            decoration: BoxDecoration(color: c.accent.withOpacity(0.15), shape: BoxShape.circle),
            child: Icon(c.icon, color: c.accent, size: 20)),
          const SizedBox(width: 12),
          Expanded(child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4))),
        ]),
      ),
    ));
}

String _friendlyError(Object e) {
  final raw = e.toString().toLowerCase();
  if (raw.contains('network') || raw.contains('connection') || raw.contains('socket') || raw.contains('timeout') || raw.contains('statuscode: null')) {
    return "No internet connection.\nPlease check your network and try again.";
  }
  if (raw.contains('401') || raw.contains('unauthorized')) return "Your session has expired. Please log in again.";
  if (raw.contains('403') || raw.contains('forbidden'))    return "You don't have permission to do that.";
  if (raw.contains('404'))                                  return "We couldn't find what you were looking for.";
  if (raw.contains('500') || raw.contains('server'))        return "Our servers are having a moment.\nPlease try again shortly.";
  return "Something went wrong. Please try again.";
}

// ─────────────────────────────────────────────────────────────

class WishlistPage extends StatefulWidget {
  const WishlistPage({super.key});
  @override
  State<WishlistPage> createState() => _WishlistPageState();
}

class _WishlistPageState extends State<WishlistPage> with SingleTickerProviderStateMixin {
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 500))..forward();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<WishlistService>().fetchWishlist();
    });
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  Widget _buildImage(String imageUrl, {double? height, double? width}) {
    if (imageUrl.isEmpty) return _imageFallback(height: height, width: width);
    final trimmed = imageUrl.trim();
    if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
      return Image.network(trimmed, height: height, width: width, fit: BoxFit.cover,
        errorBuilder: (_, _, _) => _imageFallback(height: height, width: width));
    }
    return Image.asset(trimmed, height: height, width: width, fit: BoxFit.cover,
      errorBuilder: (_, _, _) => _imageFallback(height: height, width: width));
  }

  Widget _imageFallback({double? height, double? width}) => Container(
    height: height, width: width, color: const Color(0xFFF0EDE8),
    child: Icon(Icons.image_not_supported_outlined, color: Colors.grey[400], size: 28));

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.canPop(context);
    return Scaffold(
      backgroundColor: _cream,
      appBar: _buildAppBar(canPop),
      body: Consumer<WishlistService>(
        builder: (context, ws, _) {
          if (ws.loading && ws.wishlist.isEmpty) return _buildLoader();
          if (ws.error != null && ws.wishlist.isEmpty) return _buildError(ws);
          if (ws.wishlist.isEmpty) return _buildEmpty();
          return _buildList(ws);
        },
      ),
    );
  }

  // ── AppBar ────────────────────────────────────────────────
  PreferredSizeWidget _buildAppBar(bool canPop) {
    return AppBar(
      backgroundColor: _cream,
      elevation: 0,
      scrolledUnderElevation: 0,
      leading: canPop
          ? IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.06), blurRadius: 8, offset: const Offset(0, 2))],
                ),
                child: const Icon(Icons.arrow_back_ios_new, color: _charcoal, size: 16),
              ),
              onPressed: () => Navigator.pop(context),
            )
          : null,
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _red.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.favorite_rounded, color: _red, size: 20),
          ),
          const SizedBox(width: 10),
          const Text(
            "My Wishlist",
            style: TextStyle(
              color: _charcoal,
              fontWeight: FontWeight.w800,
              fontSize: 20,
              letterSpacing: -0.5,
            ),
          ),
        ],
      ),
      actions: [
        Consumer<WishlistService>(
          builder: (_, ws, _) {
            if (!ws.loading) return const SizedBox.shrink();
            return const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Center(child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: _red))),
            );
          },
        ),
      ],
    );
  }

  // ── Loading ───────────────────────────────────────────────
  Widget _buildLoader() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(width: 56, height: 56,
        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        child: const Padding(padding: EdgeInsets.all(14), child: CircularProgressIndicator(strokeWidth: 2.5, color: _red))),
      const SizedBox(height: 16),
      Text("Loading your wishlist...", style: TextStyle(color: _slate, fontSize: 14, fontWeight: FontWeight.w500)),
    ]),
  );

  // ── Error ─────────────────────────────────────────────────
  Widget _buildError(WishlistService ws) {
    final isNetwork = ws.error!.toLowerCase().contains('network') ||
        ws.error!.toLowerCase().contains('connection') ||
        ws.error!.toLowerCase().contains('statuscode: null');
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
          Container(width: 90, height: 90,
            decoration: BoxDecoration(color: Colors.red.shade50, shape: BoxShape.circle),
            child: Icon(isNetwork ? Icons.wifi_off_rounded : Icons.error_outline_rounded, size: 40, color: Colors.red.shade300)),
          const SizedBox(height: 20),
          Text(isNetwork ? "No internet connection" : "Couldn't load your wishlist",
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: _charcoal)),
          const SizedBox(height: 8),
          Text(_friendlyError(ws.error!), textAlign: TextAlign.center,
            style: TextStyle(color: _slate, fontSize: 14, height: 1.6)),
          const SizedBox(height: 28),
          SizedBox(width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () { ws.clearError(); ws.fetchWishlist(); },
              icon: const Icon(Icons.refresh_rounded, size: 18),
              label: const Text("Try again", style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600)),
              style: ElevatedButton.styleFrom(
                backgroundColor: _red, foregroundColor: Colors.white,
                elevation: 0, padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
          ),
        ]),
      ),
    );
  }

  // ── Empty ─────────────────────────────────────────────────
  Widget _buildEmpty() => Center(
    child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
      Container(
        width: 110, height: 110,
        decoration: BoxDecoration(
          gradient: RadialGradient(colors: [_red.withOpacity(0.12), _red.withOpacity(0.03)]),
          shape: BoxShape.circle,
        ),
        child: Icon(Icons.favorite_border_rounded, size: 52, color: _red.withOpacity(0.5)),
      ),
      const SizedBox(height: 24),
      const Text("Nothing saved yet",
        style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _charcoal, letterSpacing: -0.3)),
      const SizedBox(height: 8),
      Text("Tap the ♥ on any product to save it here",
        style: TextStyle(fontSize: 14, color: _slate)),
    ]),
  );

  // ── List ──────────────────────────────────────────────────
  Widget _buildList(WishlistService ws) {
    return RefreshIndicator(
      color: _red,
      backgroundColor: Colors.white,
      onRefresh: () => ws.fetchWishlist(),
      child: CustomScrollView(
        physics: const BouncingScrollPhysics(parent: AlwaysScrollableScrollPhysics()),
        slivers: [
          // ── Header count pill ──
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
              child: Row(children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: _red.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    "${ws.wishlist.length} saved item${ws.wishlist.length == 1 ? '' : 's'}",
                    style: const TextStyle(color: _red, fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                ),
              ]),
            ),
          ),
          // ── Cards ──
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 100),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final item = ws.wishlist[index];
                  final p = item.product;
                  return FadeTransition(
                    opacity: CurvedAnimation(
                      parent: _fadeCtrl,
                      curve: Interval(
                        (index * 0.08).clamp(0.0, 0.7),
                        ((index * 0.08) + 0.4).clamp(0.0, 1.0),
                        curve: Curves.easeOut,
                      ),
                    ),
                    child: SlideTransition(
                      position: Tween<Offset>(begin: const Offset(0, 0.12), end: Offset.zero).animate(
                        CurvedAnimation(
                          parent: _fadeCtrl,
                          curve: Interval(
                            (index * 0.08).clamp(0.0, 0.7),
                            ((index * 0.08) + 0.4).clamp(0.0, 1.0),
                            curve: Curves.easeOut,
                          ),
                        ),
                      ),
                      child: _buildCard(context, ws, item, p),
                    ),
                  );
                },
                childCount: ws.wishlist.length,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Single Card ───────────────────────────────────────────
  Widget _buildCard(BuildContext context, WishlistService ws, dynamic item, dynamic p) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 16, offset: const Offset(0, 4)),
          BoxShadow(color: Colors.black.withOpacity(0.03), blurRadius: 4, offset: const Offset(0, 1)),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => Detail(productId: p.id))),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              // ── Product image ──
              Stack(children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: _buildImage(p.image, width: 90, height: 90),
                ),
                // subtle red gradient overlay bottom
                Positioned(
                  bottom: 0, left: 0, right: 0,
                  child: ClipRRect(
                    borderRadius: const BorderRadius.vertical(bottom: Radius.circular(14)),
                    child: Container(
                      height: 30,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [_red.withOpacity(0.18), Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                ),
              ]),
              const SizedBox(width: 14),
              // ── Info ──
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  // name
                  Text(p.name,
                    maxLines: 2, overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700,
                      color: _charcoal, height: 1.3, letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // rating row
                  Row(children: [
                    const Icon(Icons.star_rounded, color: Colors.amber, size: 14),
                    const SizedBox(width: 3),
                    Text(p.rating.toString(), style: TextStyle(color: _slate, fontSize: 12, fontWeight: FontWeight.w500)),
                  ]),
                  const SizedBox(height: 8),
                  // price + unit
                  Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
                    Text("₺${p.price.toStringAsFixed(2)}",
                      style: const TextStyle(color: _red, fontWeight: FontWeight.w800, fontSize: 17, letterSpacing: -0.3)),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: Colors.amber.shade50,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(color: Colors.amber.shade200, width: 1),
                      ),
                      child: Text("1${getDisplayUnit(p.unitType)}",
                        style: TextStyle(fontSize: 11, color: Colors.amber.shade800, fontWeight: FontWeight.w600)),
                    ),
                  ]),
                ]),
              ),
              const SizedBox(width: 4),
              // ── Remove button ──
              _RemoveButton(
                onTap: () async {
                  try {
                    await ws.removeFromWishlist(item.id);
                    if (context.mounted) {
                      _showSnack(context, '"${p.name}" removed from wishlist',
                        type: _SnackType.success, duration: const Duration(seconds: 2));
                    }
                  } catch (e) {
                    if (context.mounted) {
                      _showSnack(context, _friendlyError(e), type: _SnackType.error);
                    }
                  }
                },
              ),
            ]),
          ),
        ),
      ),
    );
  }
}

// ── Animated remove button ────────────────────────────────────
class _RemoveButton extends StatefulWidget {
  final VoidCallback onTap;
  const _RemoveButton({required this.onTap});
  @override
  State<_RemoveButton> createState() => _RemoveButtonState();
}

class _RemoveButtonState extends State<_RemoveButton> with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _scale;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 120), lowerBound: 0.85, upperBound: 1.0, value: 1.0);
    _scale = _ctrl;
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _ctrl.reverse(),
      onTapUp: (_) { _ctrl.forward(); widget.onTap(); },
      onTapCancel: () => _ctrl.forward(),
      child: ScaleTransition(
        scale: _scale,
        child: Container(
          width: 38, height: 38,
          decoration: BoxDecoration(
            color: _red.withOpacity(0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.favorite_rounded, color: _red, size: 18),
        ),
      ),
    );
  }
}



// import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';
// import 'package:vlog/Utils/parse_utils.dart';
// import 'package:vlog/Utils/wishlist_service.dart';
// import 'package:vlog/presentation/screen/detail_screen.dart';

// const Color _primaryRed = Color(0xFFE53E3E);

// // ─────────────────────────────────────────────
// //  Beautiful snackbar helper
// // ─────────────────────────────────────────────
// enum _SnackType { success, warning, error, info }

// void _showSnack(
//   BuildContext context,
//   String message, {
//   _SnackType type = _SnackType.info,
//   Duration duration = const Duration(seconds: 3),
// }) {
//   final config = {
//     _SnackType.success: (
//       icon: Icons.check_circle_rounded,
//       bg: const Color(0xFF1B5E20),     // ✅ fixed: was wrong navy blue
//       accent: const Color(0xFF4CAF50), // ✅ fixed: was near-white
//     ),
//     _SnackType.warning: (
//       icon: Icons.info_rounded,
//       bg: const Color(0xFF4A3000),
//       accent: const Color(0xFFFFC107),
//     ),
//     _SnackType.error: (
//       icon: Icons.error_rounded,
//       bg: const Color(0xFF5C0A0A),
//       accent: const Color(0xFFEF5350),
//     ),
//     _SnackType.info: (
//       icon: Icons.info_outline_rounded,
//       bg: const Color(0xFF0D2340),
//       accent: const Color(0xFF42A5F5),
//     ),
//   }[type]!;

//   ScaffoldMessenger.of(context)
//     ..hideCurrentSnackBar()
//     ..showSnackBar(
//       SnackBar(
//         duration: duration,
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
//         content: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           decoration: BoxDecoration(
//             color: config.bg,
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: config.accent.withOpacity(0.4), width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.25),
//                 blurRadius: 16,
//                 offset: const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: config.accent.withOpacity(0.15),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(config.icon, color: config.accent, size: 20),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   message,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     height: 1.4,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
// }

// // ─────────────────────────────────────────────
// //  Network / API error classifier
// //  Maps raw ApiException strings to friendly user messages.
// //  Original dev errors are documented in comments per branch.
// // ─────────────────────────────────────────────
// String _friendlyError(Object e) {
//   final raw = e.toString().toLowerCase();

//   // dev: ApiException(statusCode: null, errorCode: null, message: Network/connection error)
//   if (raw.contains('network') ||
//       raw.contains('connection') ||
//       raw.contains('socket') ||
//       raw.contains('timeout') ||
//       raw.contains('statuscode: null')) {
//     return "No internet connection.\nPlease check your network and try again.";
//   }

//   // dev: ApiException with statusCode 401 / unauthorized
//   if (raw.contains('401') || raw.contains('unauthorized')) {
//     return "Your session has expired. Please log in again.";
//   }

//   // dev: ApiException with statusCode 403 / forbidden
//   if (raw.contains('403') || raw.contains('forbidden')) {
//     return "You don't have permission to do that.";
//   }

//   // dev: ApiException with statusCode 404
//   if (raw.contains('404')) {
//     return "We couldn't find what you were looking for.";
//   }

//   // dev: ApiException with statusCode 500 or generic server error
//   if (raw.contains('500') || raw.contains('server')) {
//     return "Our servers are having a moment.\nPlease try again shortly.";
//   }

//   // dev: any other unknown exception – e.toString()
//   return "Something went wrong. Please try again.";
// }

// // ─────────────────────────────────────────────

// class WishlistPage extends StatefulWidget {
//   const WishlistPage({super.key});

//   @override
//   State<WishlistPage> createState() => _WishlistPageState();
// }

// class _WishlistPageState extends State<WishlistPage> {
//   @override
//   void initState() {
//     super.initState();
//     WidgetsBinding.instance.addPostFrameCallback((_) {
//       context.read<WishlistService>().fetchWishlist();
//     });
//   }

//   Widget _buildImage(String imageUrl, {double? height, double? width}) {
//     if (imageUrl.isEmpty) {
//       return Container(
//         height: height,
//         width: width,
//         color: Colors.grey[200],
//         child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
//       );
//     }
//     final trimmed = imageUrl.trim();
//     if (trimmed.startsWith('http://') || trimmed.startsWith('https://')) {
//       return Image.network(
//         trimmed,
//         height: height,
//         width: width,
//         fit: BoxFit.cover,
//         errorBuilder: (_, __, ___) => Container(
//           height: height,
//           width: width,
//           color: Colors.grey[200],
//           child: Icon(Icons.broken_image, color: Colors.grey[400], size: 30),
//         ),
//       );
//     }
//     return Image.asset(
//       trimmed,
//       height: height,
//       width: width,
//       fit: BoxFit.cover,
//       errorBuilder: (_, __, ___) => Container(
//         height: height,
//         width: width,
//         color: Colors.grey[200],
//         child: Icon(Icons.image_not_supported, color: Colors.grey[400], size: 30),
//       ),
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     final canPop = Navigator.canPop(context);

//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         title: const Text(
//           "My Wishlist",
//           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
//         ),
//         leading: canPop
//             ? IconButton(
//                 icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
//                 onPressed: () => Navigator.pop(context),
//               )
//             : null,
//         actions: [
//           Consumer<WishlistService>(
//             builder: (context, ws, _) {
//               if (!ws.loading) return const SizedBox.shrink();
//               return const Padding(
//                 padding: EdgeInsets.only(right: 16),
//                 child: Center(
//                   child: SizedBox(
//                     width: 24,
//                     height: 24,
//                     child: CircularProgressIndicator(strokeWidth: 2, color: _primaryRed),
//                   ),
//                 ),
//               );
//             },
//           ),
//         ],
//       ),
//       body: Consumer<WishlistService>(
//         builder: (context, wishlistService, child) {

//           // ── Loading state ──
//           if (wishlistService.loading && wishlistService.wishlist.isEmpty) {
//             return const Center(child: CircularProgressIndicator(color: _primaryRed));
//           }

//           // ── Error state ──
//           // dev: wishlistService.error holds the raw exception string from WishlistService.
//           // Triggered by: ApiException(statusCode: null, errorCode: null, message: Network/connection error)
//           // _friendlyError() maps that to a user-readable message based on the error content.
//           if (wishlistService.error != null && wishlistService.wishlist.isEmpty) {
//             final raw = wishlistService.error!.toLowerCase();
//             final isNetworkError = raw.contains('network') ||
//                 raw.contains('connection') ||
//                 raw.contains('socket') ||
//                 raw.contains('statuscode: null');

//             return Center(
//               child: Padding(
//                 padding: const EdgeInsets.all(32),
//                 child: Column(
//                   mainAxisAlignment: MainAxisAlignment.center,
//                   children: [
//                     Container(
//                       width: 80,
//                       height: 80,
//                       decoration: BoxDecoration(
//                         color: Colors.red.shade50,
//                         shape: BoxShape.circle,
//                       ),
//                       // wifi_off for network errors, error_outline for server/other errors
//                       child: Icon(
//                         isNetworkError
//                             ? Icons.wifi_off_rounded
//                             : Icons.error_outline_rounded,
//                         size: 38,
//                         color: Colors.red.shade300,
//                       ),
//                     ),
//                     const SizedBox(height: 20),
//                     Text(
//                       isNetworkError
//                           ? "No internet connection"
//                           : "Couldn't load your wishlist",
//                       style: const TextStyle(
//                         fontSize: 17,
//                         fontWeight: FontWeight.bold,
//                         color: Colors.black87,
//                       ),
//                     ),
//                     const SizedBox(height: 10),
//                     Text(
//                       // dev: wishlistService.error → mapped via _friendlyError()
//                       _friendlyError(wishlistService.error!),
//                       textAlign: TextAlign.center,
//                       style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
//                     ),
//                     const SizedBox(height: 24),
//                     ElevatedButton.icon(
//                       onPressed: () {
//                         wishlistService.clearError();
//                         wishlistService.fetchWishlist();
//                       },
//                       icon: const Icon(Icons.refresh_rounded, size: 18),
//                       label: const Text('Try again'),
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: _primaryRed,
//                         foregroundColor: Colors.white,
//                         shape: RoundedRectangleBorder(
//                           borderRadius: BorderRadius.circular(10),
//                         ),
//                         elevation: 0,
//                         padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//             );
//           }

//           final wishlist = wishlistService.wishlist;

//           // ── Empty state ──
//           if (wishlist.isEmpty) {
//             return Center(
//               child: Column(
//                 mainAxisAlignment: MainAxisAlignment.center,
//                 children: [
//                   Container(
//                     width: 100,
//                     height: 100,
//                     decoration: BoxDecoration(
//                       color: Colors.red.shade50,
//                       shape: BoxShape.circle,
//                     ),
//                     child: Icon(
//                       Icons.favorite_border_rounded,
//                       size: 48,
//                       color: Colors.red.shade200,
//                     ),
//                   ),
//                   const SizedBox(height: 20),
//                   const Text(
//                     "Nothing saved yet",
//                     style: TextStyle(
//                       fontSize: 18,
//                       color: Colors.black87,
//                       fontWeight: FontWeight.w600,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Text(
//                     "Tap the heart on any item to save it here",
//                     style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
//                   ),
//                 ],
//               ),
//             );
//           }

//           // ── List ──
//           return RefreshIndicator(
//             color: _primaryRed,
//             onRefresh: () => wishlistService.fetchWishlist(),
//             child: ListView.builder(
//               padding: const EdgeInsets.all(16),
//               itemCount: wishlist.length,
//               itemBuilder: (context, index) {
//                 final item = wishlist[index];
//                 final p = item.product;
//                 return Card(
//                   margin: const EdgeInsets.only(bottom: 12),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(12),
//                   ),
//                   elevation: 2,
//                   child: InkWell(
//                     borderRadius: BorderRadius.circular(12),
//                     onTap: () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                           builder: (context) => Detail(productId: p.id),
//                         ),
//                       );
//                     },
//                     child: Padding(
//                       padding: const EdgeInsets.all(12),
//                       child: Row(
//                         children: [
//                           ClipRRect(
//                             borderRadius: BorderRadius.circular(8),
//                             child: _buildImage(p.image, width: 80, height: 80),
//                           ),
//                           const SizedBox(width: 12),
//                           Expanded(
//                             child: Column(
//                               crossAxisAlignment: CrossAxisAlignment.start,
//                               children: [
//                                 Text(
//                                   p.name,
//                                   style: const TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 16,
//                                   ),
//                                   maxLines: 2,
//                                   overflow: TextOverflow.ellipsis,
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Row(
//                                   children: [
//                                     const Icon(Icons.star_rounded, color: Colors.amber, size: 16),
//                                     const SizedBox(width: 4),
//                                     Text(
//                                       p.rating.toString(),
//                                       style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
//                                     ),
//                                   ],
//                                 ),
//                                 const SizedBox(height: 4),
//                                 Row(
//                                   crossAxisAlignment: CrossAxisAlignment.baseline,
//                                   textBaseline: TextBaseline.alphabetic,
//                                   children: [
//                                     Text(
//                                       "₺${p.price.toStringAsFixed(2)}",
//                                       style: const TextStyle(
//                                         color: Colors.pink,
//                                         fontWeight: FontWeight.w600,
//                                         fontSize: 18,
//                                       ),
//                                     ),
//                                     const SizedBox(width: 8),
//                                     Container(
//                                       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
//                                       decoration: BoxDecoration(
//                                         color: Colors.amber.shade100,
//                                         borderRadius: BorderRadius.circular(6),
//                                       ),
//                                       child: Text(
//                                         "1${getDisplayUnit(p.unitType)}",
//                                         style: TextStyle(
//                                           fontSize: 12,
//                                           color: Colors.amber.shade900,
//                                           fontWeight: FontWeight.w500,
//                                         ),
//                                       ),
//                                     ),
//                                   ],
//                                 ),
//                               ],
//                             ),
//                           ),
//                           // ── Remove from wishlist ──
//                           IconButton(
//                             icon: const Icon(Icons.favorite_rounded, color: _primaryRed),
//                             tooltip: 'Remove from wishlist',
//                             onPressed: () async {
//                               try {
//                                 await wishlistService.removeFromWishlist(item.id);
//                                 // dev: removed item.id from wishlist successfully
//                                 if (context.mounted) {
//                                   _showSnack(
//                                     context,
//                                     '"${p.name}" was removed from your wishlist.',
//                                     type: _SnackType.success,
//                                     duration: const Duration(seconds: 2),
//                                   );
//                                 }
//                               } catch (e) {
//                                 // dev error: e.toString() – removeFromWishlist(item.id) failed
//                                 if (context.mounted) {
//                                   _showSnack(
//                                     context,
//                                     _friendlyError(e),
//                                     type: _SnackType.error,
//                                   );
//                                 }
//                               }
//                             },
//                           ),
//                         ],
//                       ),
//                     ),
//                   ),
//                 );
//               },
//             ),
//           );
//         },
//       ),
//     );
//   }
// }
