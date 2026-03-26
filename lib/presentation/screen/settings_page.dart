
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vlog/presentation/auth/login_page.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:vlog/presentation/home.dart';

const Color _red       = Color(0xFFE53E3E);
const Color _redSoft   = Color(0xFFFFF0F0);
const Color _cream     = Color(0xFFFAF8F5);
const Color _charcoal  = Color(0xFF1A1A2E);
const Color _slate     = Color(0xFF6B7280);
const Color _divider   = Color(0xFFF0EDE8);

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with SingleTickerProviderStateMixin {
  bool _pushNotifications    = true;
  bool _emailNotifications   = true;
  bool _orderUpdates         = true;
  bool _promotionalUpdates   = false;

  // ✅ Loading state
  bool _isLoading = false;
  String _loadingMessage = 'Please wait…';

  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    )..forward();
    _loadSettings();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  // ✅ Loading helper
  void _setLoading(bool value, {String message = 'Please wait…'}) {
    if (!mounted) return;
    setState(() {
      _isLoading = value;
      _loadingMessage = message;
    });
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications   = prefs.getBool('push_notifications')   ?? true;
      _emailNotifications  = prefs.getBool('email_notifications')  ?? true;
      _orderUpdates        = prefs.getBool('order_updates')        ?? true;
      _promotionalUpdates  = prefs.getBool('promotional_updates')  ?? false;
    });
  }

  Future<void> _saveSetting(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  Future<void> _handlePushToggle(bool value) async {
    if (value) {
      final accepted = await OneSignal.Notifications.requestPermission(true);
      setState(() => _pushNotifications = accepted);
      await _saveSetting('push_notifications', accepted);
      if (!accepted && mounted) {
        _showSnack(
          "Permission denied. Enable in phone Settings → Notifications.",
          isError: true,
        );
      }
    } else {
      setState(() => _pushNotifications = false);
      await _saveSetting('push_notifications', false);
      if (mounted) {
        _showSnack("To fully disable, go to phone Settings → Notifications.");
      }
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg, style: const TextStyle(fontSize: 13)),
      backgroundColor: isError ? _red : _charcoal,
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      duration: const Duration(seconds: 3),
    ));
  }

  void _showPrivacyPolicy() => _showInfoDialog(
    title: "Privacy Policy",
    content:
        "Last Updated: January 2026\n\n"
        "We respect your privacy and are committed to protecting your personal data.\n\n"
        "Information We Collect:\n"
        "• Personal information (name, email, address)\n"
        "• Payment information\n"
        "• Device information\n"
        "• Usage data\n\n"
        "How We Use Your Information:\n"
        "• To process your orders\n"
        "• To improve our services\n"
        "• To send you updates (with your consent)\n"
        "• To comply with legal obligations\n\n"
        "Data Security:\n"
        "We implement appropriate security measures to protect your personal data.\n\n"
        "© 2026 CODIGO. All rights reserved.",
  );

  void _showLegalInformation() => _showInfoDialog(
    title: "Legal Information",
    content:
        "Terms of Service\n\n"
        "By using this app, you agree to the following terms:\n"
        "• You must be at least 18 years old to make purchases\n"
        "• All products are subject to availability\n"
        "• Prices are subject to change without notice\n\n"
        "Refund Policy:\n"
        "Items can be returned within 30 days of purchase with receipt.\n\n"
        "Warranty:\n"
        "All products come with manufacturer's warranty.\n\n"
        "© 2026 CODIGO. All rights reserved.",
  );

  void _showInfoDialog({required String title, required String content}) {
    showDialog(
      context: context,
      builder: (_) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title,
                style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.w800,
                  color: _charcoal, letterSpacing: -0.3,
                )),
              const SizedBox(height: 16),
              ConstrainedBox(
                constraints: const BoxConstraints(maxHeight: 360),
                child: SingleChildScrollView(
                  child: Text(content,
                    style: TextStyle(fontSize: 13, color: _slate, height: 1.6)),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _charcoal,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: const Text("Close",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ✅ Sign out with loading
  Future<void> _signOut() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: "Sign Out",
        message: "Are you sure you want to sign out?",
        confirmLabel: "Sign Out",
        confirmColor: _red,
      ),
    );
    if (confirm != true) return;
    if (!mounted) return;

    _setLoading(true, message: 'Signing out…'); // ✅

    try {
      await AuthService().logout();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (r) => false,
      );
      messenger.showSnackBar(const SnackBar(
        content: Text("Logged out successfully"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      if (!mounted) return;
      _setLoading(false); // ✅
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const MainScreen(token: null)),
        (r) => false,
      );
    }
  }

  // ✅ Delete account with loading
  Future<void> _deleteAccount() async {
    final navigator = Navigator.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final step1 = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: "Delete Account",
        message:
            "This will permanently delete your profile, orders, addresses, and wishlist. This cannot be undone.",
        confirmLabel: "Continue",
        confirmColor: _red,
        icon: Icons.warning_amber_rounded,
      ),
    );
    if (step1 != true || !mounted) return;

    final step2 = await showDialog<bool>(
      context: context,
      builder: (_) => _ConfirmDialog(
        title: "Final Confirmation",
        message: "Are you absolutely sure? Your account will be gone forever.",
        confirmLabel: "Delete Forever",
        confirmColor: _red,
      ),
    );
    if (step2 != true || !mounted) return;

    _setLoading(true, message: 'Deleting account…'); // ✅

    try {
      final user = await StorageService.getUser();
      final userId = user?['id'];
      if (userId == null) {
        _setLoading(false);
        _showSnack("Could not get user info. Please sign in again.", isError: true);
        return;
      }
      final userIdInt = userId is int ? userId : int.tryParse(userId.toString());
      if (userIdInt == null) {
        _setLoading(false);
        _showSnack("Invalid user ID.", isError: true);
        return;
      }
      await AuthService().deleteAccount(userIdInt);
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      if (!mounted) return;
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (r) => false,
      );
      messenger.showSnackBar(const SnackBar(
        content: Text("Account deleted successfully"),
        backgroundColor: Colors.green,
        duration: Duration(seconds: 2),
      ));
    } catch (e) {
      if (mounted) {
        _setLoading(false); // ✅
        _showSnack("Failed to delete account. Please try again.", isError: true);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _cream,
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          // ── Main content ──────────────────────────────────────
          FadeTransition(
            opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
              children: [
                _buildNotificationsSection(),
                const SizedBox(height: 16),
                _buildLegalSection(),
                const SizedBox(height: 16),
                _buildAppInfoSection(),
                const SizedBox(height: 24),
                _buildAccountActions(),
              ],
            ),
          ),

          // ✅ Loading overlay — same as LoginPage
          if (_isLoading)
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 3, sigmaY: 3),
                child: Container(
                  color: Colors.black.withOpacity(0.45),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 36, vertical: 32),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.15),
                            blurRadius: 30,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          SizedBox(
                            width: 52,
                            height: 52,
                            child: CircularProgressIndicator(
                              strokeWidth: 3.5,
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(_red),
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            _loadingMessage,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Please wait…',
                            style: TextStyle(
                              fontSize: 13,
                              color: _slate,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar() => AppBar(
    backgroundColor: _cream,
    elevation: 0,
    scrolledUnderElevation: 0,
    leading: IconButton(
      icon: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 8, offset: const Offset(0, 2))],
        ),
        child: const Icon(Icons.arrow_back_ios_new, color: _charcoal, size: 16),
      ),
      onPressed: () => Navigator.pop(context),
    ),
    title: const Text(
      "Settings",
      style: TextStyle(
        color: _charcoal, fontWeight: FontWeight.w800,
        fontSize: 20, letterSpacing: -0.5,
      ),
    ),
  );

  Widget _buildNotificationsSection() => _Section(
    icon: Icons.notifications_rounded,
    iconColor: _red,
    iconBg: _redSoft,
    title: "Notifications",
    children: [
      _SwitchRow(
        icon: Icons.phone_android_rounded,
        iconBg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        title: "Push Notifications",
        subtitle: "Alerts on your device",
        value: _pushNotifications,
        onChanged: _handlePushToggle,
      ),
      _dividerLine(),
      _SwitchRow(
        icon: Icons.email_rounded,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1565C0),
        title: "Email Notifications",
        subtitle: "Updates to your inbox",
        value: _emailNotifications,
        onChanged: (v) {
          setState(() => _emailNotifications = v);
          _saveSetting('email_notifications', v);
        },
      ),
      _dividerLine(),
      _SwitchRow(
        icon: Icons.shopping_bag_rounded,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFE65100),
        title: "Order Updates",
        subtitle: "Track your orders",
        value: _orderUpdates,
        onChanged: (v) {
          setState(() => _orderUpdates = v);
          _saveSetting('order_updates', v);
        },
      ),
      _dividerLine(),
      _SwitchRow(
        icon: Icons.local_offer_rounded,
        iconBg: const Color(0xFFF3E5F5),
        iconColor: const Color(0xFF6A1B9A),
        title: "Promotional",
        subtitle: "Offers and discounts",
        value: _promotionalUpdates,
        onChanged: (v) {
          setState(() => _promotionalUpdates = v);
          _saveSetting('promotional_updates', v);
        },
      ),
    ],
  );

  Widget _buildLegalSection() => _Section(
    icon: Icons.gavel_rounded,
    iconColor: const Color(0xFF1565C0),
    iconBg: const Color(0xFFE3F2FD),
    title: "Legal & Privacy",
    children: [
      _TileRow(
        icon: Icons.privacy_tip_rounded,
        iconBg: const Color(0xFFE8F5E9),
        iconColor: const Color(0xFF2E7D32),
        title: "Privacy Policy",
        onTap: _showPrivacyPolicy,
      ),
      _dividerLine(),
      _TileRow(
        icon: Icons.description_rounded,
        iconBg: const Color(0xFFFFF3E0),
        iconColor: const Color(0xFFE65100),
        title: "Legal Information",
        onTap: _showLegalInformation,
      ),
    ],
  );

  Widget _buildAppInfoSection() => _Section(
    icon: Icons.info_rounded,
    iconColor: _slate,
    iconBg: const Color(0xFFF5F5F5),
    title: "About",
    children: [
      _TileRow(
        icon: Icons.verified_rounded,
        iconBg: const Color(0xFFE3F2FD),
        iconColor: const Color(0xFF1565C0),
        title: "App Version",
        trailing: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: _divider,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text("1.0.0",
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _slate)),
        ),
        onTap: () {},
      ),
    ],
  );

  Widget _buildAccountActions() => Column(
    children: [
      _ActionButton(
        label: "Sign Out",
        icon: Icons.logout_rounded,
        background: _red,
        foreground: Colors.white,
        onTap: _signOut,
      ),
      const SizedBox(height: 12),
      _ActionButton(
        label: "Delete Account",
        icon: Icons.delete_forever_rounded,
        background: Colors.white,
        foreground: _red,
        border: _red,
        onTap: _deleteAccount,
      ),
    ],
  );

  Widget _dividerLine() => Divider(
    height: 1, thickness: 1,
    color: _divider,
    indent: 58, endIndent: 0,
  );
}

// ── Reusable section card ─────────────────────────────────────────────────────
class _Section extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final List<Widget> children;

  const _Section({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.children,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 10),
          child: Row(children: [
            Container(
              width: 28, height: 28,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
              child: Icon(icon, color: iconColor, size: 16),
            ),
            const SizedBox(width: 8),
            Text(title,
              style: const TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: _slate, letterSpacing: 0.3,
              ),
            ),
          ]),
        ),
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.04),
                blurRadius: 12, offset: const Offset(0, 4)),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(18),
            child: Column(children: children),
          ),
        ),
      ],
    );
  }
}

// ── Switch row ────────────────────────────────────────────────────────────────
class _SwitchRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SwitchRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(children: [
        Container(
          width: 36, height: 36,
          decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
          child: Icon(icon, color: iconColor, size: 18),
        ),
        const SizedBox(width: 14),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _charcoal)),
            const SizedBox(height: 2),
            Text(subtitle,
              style: const TextStyle(fontSize: 12, color: _slate)),
          ],
        )),
        Switch.adaptive(
          value: value,
          onChanged: onChanged,
          activeColor: _red,
        ),
      ]),
    );
  }
}

// ── Tile row ──────────────────────────────────────────────────────────────────
class _TileRow extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final Color iconBg;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  const _TileRow({
    required this.icon,
    required this.iconColor,
    required this.iconBg,
    required this.title,
    this.trailing,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(children: [
            Container(
              width: 36, height: 36,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(child: Text(title,
              style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _charcoal))),
            trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
          ]),
        ),
      ),
    );
  }
}

// ── Action button ─────────────────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color background;
  final Color foreground;
  final Color? border;
  final VoidCallback onTap;

  const _ActionButton({
    required this.label,
    required this.icon,
    required this.background,
    required this.foreground,
    this.border,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(16),
        border: border != null ? Border.all(color: border!, width: 1.5) : null,
        boxShadow: background != Colors.white
            ? [BoxShadow(color: background.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(icon, color: foreground, size: 20),
                const SizedBox(width: 8),
                Text(label,
                  style: TextStyle(
                    color: foreground, fontSize: 16,
                    fontWeight: FontWeight.w700,
                  )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Confirm dialog ────────────────────────────────────────────────────────────
class _ConfirmDialog extends StatelessWidget {
  final String title;
  final String message;
  final String confirmLabel;
  final Color confirmColor;
  final IconData? icon;

  const _ConfirmDialog({
    required this.title,
    required this.message,
    required this.confirmLabel,
    required this.confirmColor,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(
                  color: confirmColor.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: confirmColor, size: 28),
              ),
              const SizedBox(height: 16),
            ],
            Text(title,
              style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800,
                color: _charcoal, letterSpacing: -0.3,
              )),
            const SizedBox(height: 10),
            Text(message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: _slate, height: 1.5)),
            const SizedBox(height: 24),
            Row(children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: () => Navigator.pop(context, false),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _slate,
                    side: BorderSide(color: Colors.grey[300]!),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Cancel",
                    style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context, true),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: confirmColor,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  ),
                  child: Text(confirmLabel,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:shared_preferences/shared_preferences.dart';
// import 'package:vlog/presentation/auth/login_page.dart';
// import 'package:vlog/Data/apiservices.dart';
// import 'package:vlog/Utils/storage_service.dart';
// import 'package:onesignal_flutter/onesignal_flutter.dart';
// import 'package:vlog/presentation/home.dart';

// // ── Palette ──────────────────────────────────────────────────
// const Color _red       = Color(0xFFE53E3E);
// const Color _redSoft   = Color(0xFFFFF0F0);
// const Color _cream     = Color(0xFFFAF8F5);
// const Color _charcoal  = Color(0xFF1A1A2E);
// const Color _slate     = Color(0xFF6B7280);
// const Color _divider   = Color(0xFFF0EDE8);

// class SettingsPage extends StatefulWidget {
//   const SettingsPage({super.key});
//   @override
//   State<SettingsPage> createState() => _SettingsPageState();
// }

// class _SettingsPageState extends State<SettingsPage>
//     with SingleTickerProviderStateMixin {
//   bool _pushNotifications    = true;
//   bool _emailNotifications   = true;
//   bool _orderUpdates         = true;
//   bool _promotionalUpdates   = false;

//   late final AnimationController _fadeCtrl;

//   @override
//   void initState() {
//     super.initState();
//     _fadeCtrl = AnimationController(
//       vsync: this,
//       duration: const Duration(milliseconds: 500),
//     )..forward();
//     _loadSettings();
//   }

//   @override
//   void dispose() {
//     _fadeCtrl.dispose();
//     super.dispose();
//   }

//   Future<void> _loadSettings() async {
//     final prefs = await SharedPreferences.getInstance();
//     setState(() {
//       _pushNotifications   = prefs.getBool('push_notifications')   ?? true;
//       _emailNotifications  = prefs.getBool('email_notifications')  ?? true;
//       _orderUpdates        = prefs.getBool('order_updates')        ?? true;
//       _promotionalUpdates  = prefs.getBool('promotional_updates')  ?? false;
//     });
//   }

//   Future<void> _saveSetting(String key, bool value) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setBool(key, value);
//   }

//   // ── Push notification toggle with OS permission request ───
//   Future<void> _handlePushToggle(bool value) async {
//     if (value) {
//       final accepted = await OneSignal.Notifications.requestPermission(true);
//       setState(() => _pushNotifications = accepted);
//       await _saveSetting('push_notifications', accepted);
//       if (!accepted && mounted) {
//         _showSnack(
//           "Permission denied. Enable in phone Settings → Notifications.",
//           isError: true,
//         );
//       }
//     } else {
//       setState(() => _pushNotifications = false);
//       await _saveSetting('push_notifications', false);
//       if (mounted) {
//         _showSnack(
//           "To fully disable, go to phone Settings → Notifications.",
//         );
//       }
//     }
//   }

//   void _showSnack(String msg, {bool isError = false}) {
//     ScaffoldMessenger.of(context).showSnackBar(SnackBar(
//       content: Text(msg, style: const TextStyle(fontSize: 13)),
//       backgroundColor: isError ? _red : _charcoal,
//       behavior: SnackBarBehavior.floating,
//       margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
//       duration: const Duration(seconds: 3),
//     ));
//   }

//   // ── Privacy policy dialog ─────────────────────────────────
//   void _showPrivacyPolicy() => _showInfoDialog(
//     title: "Privacy Policy",
//     content:
//         "Last Updated: January 2026\n\n"
//         "We respect your privacy and are committed to protecting your personal data.\n\n"
//         "Information We Collect:\n"
//         "• Personal information (name, email, address)\n"
//         "• Payment information\n"
//         "• Device information\n"
//         "• Usage data\n\n"
//         "How We Use Your Information:\n"
//         "• To process your orders\n"
//         "• To improve our services\n"
//         "• To send you updates (with your consent)\n"
//         "• To comply with legal obligations\n\n"
//         "Data Security:\n"
//         "We implement appropriate security measures to protect your personal data.\n\n"
//         "© 2026 CODIGO. All rights reserved.",
//   );

//   void _showLegalInformation() => _showInfoDialog(
//     title: "Legal Information",
//     content:
//         "Terms of Service\n\n"
//         "By using this app, you agree to the following terms:\n"
//         "• You must be at least 18 years old to make purchases\n"
//         "• All products are subject to availability\n"
//         "• Prices are subject to change without notice\n\n"
//         "Refund Policy:\n"
//         "Items can be returned within 30 days of purchase with receipt.\n\n"
//         "Warranty:\n"
//         "All products come with manufacturer's warranty.\n\n"
//         "© 2026 CODIGO. All rights reserved.",
//   );

//   void _showInfoDialog({required String title, required String content}) {
//     showDialog(
//       context: context,
//       builder: (_) => Dialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//         child: Padding(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(title,
//                 style: const TextStyle(
//                   fontSize: 18, fontWeight: FontWeight.w800,
//                   color: _charcoal, letterSpacing: -0.3,
//                 )),
//               const SizedBox(height: 16),
//               ConstrainedBox(
//                 constraints: const BoxConstraints(maxHeight: 360),
//                 child: SingleChildScrollView(
//                   child: Text(content,
//                     style: TextStyle(fontSize: 13, color: _slate, height: 1.6)),
//                 ),
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _charcoal,
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                   ),
//                   child: const Text("Close",
//                     style: TextStyle(fontWeight: FontWeight.w600)),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   // ── Sign out ──────────────────────────────────────────────
//   Future<void> _signOut() async {
//     final navigator = Navigator.of(context);
//     final messenger = ScaffoldMessenger.of(context);

//     final confirm = await showDialog<bool>(
//       context: context,
//       builder: (_) => _ConfirmDialog(
//         title: "Sign Out",
//         message: "Are you sure you want to sign out?",
//         confirmLabel: "Sign Out",
//         confirmColor: _red,
//       ),
//     );
//     if (confirm != true) return;
//     if (!mounted) return;

//     try {
//       await AuthService().logout();
//       if (!mounted) return;
//       navigator.pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const LoginPage()),
//         (r) => false,
//       );
//       messenger.showSnackBar(const SnackBar(
//         content: Text("Logged out successfully"),
//         backgroundColor: Colors.green,
//         duration: Duration(seconds: 2),
//       ));
//     } catch (e) {
//       if (!mounted) return;
//       navigator.pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const MainScreen(token: null)), //LoginPage()),
//         (r) => false,
//       );
//     }
//   }

//   // ── Delete account ────────────────────────────────────────
//   Future<void> _deleteAccount() async {
//     final navigator = Navigator.of(context);
//     final messenger = ScaffoldMessenger.of(context);

//     final step1 = await showDialog<bool>(
//       context: context,
//       builder: (_) => _ConfirmDialog(
//         title: "Delete Account",
//         message:
//             "This will permanently delete your profile, orders, addresses, and wishlist. This cannot be undone.",
//         confirmLabel: "Continue",
//         confirmColor: _red,
//         icon: Icons.warning_amber_rounded,
//       ),
//     );
//     if (step1 != true || !mounted) return;

//     final step2 = await showDialog<bool>(
//       context: context,
//       builder: (_) => _ConfirmDialog(
//         title: "Final Confirmation",
//         message: "Are you absolutely sure? Your account will be gone forever.",
//         confirmLabel: "Delete Forever",
//         confirmColor: _red,
//       ),
//     );
//     if (step2 != true || !mounted) return;

//     try {
//       final user = await StorageService.getUser();
//       final userId = user?['id'];
//       if (userId == null) {
//         _showSnack("Could not get user info. Please sign in again.", isError: true);
//         return;
//       }
//       final userIdInt = userId is int ? userId : int.tryParse(userId.toString());
//       if (userIdInt == null) {
//         _showSnack("Invalid user ID.", isError: true);
//         return;
//       }
//       await AuthService().deleteAccount(userIdInt);
//       final prefs = await SharedPreferences.getInstance();
//       await prefs.clear();
//       if (!mounted) return;
//       navigator.pushAndRemoveUntil(
//         MaterialPageRoute(builder: (_) => const LoginPage()),
//         (r) => false,
//       );
//       messenger.showSnackBar(const SnackBar(
//         content: Text("Account deleted successfully"),
//         backgroundColor: Colors.green,
//         duration: Duration(seconds: 2),
//       ));
//     } catch (e) {
//       if (mounted) _showSnack("Failed to delete account. Please try again.", isError: true);
//     }
//   }

//   // ── Build ─────────────────────────────────────────────────
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: _cream,
//       appBar: _buildAppBar(),
//       body: FadeTransition(
//         opacity: CurvedAnimation(parent: _fadeCtrl, curve: Curves.easeOut),
//         child: ListView(
//           padding: const EdgeInsets.fromLTRB(16, 8, 16, 40),
//           children: [
//             _buildNotificationsSection(),
//             const SizedBox(height: 16),
//             _buildLegalSection(),
//             const SizedBox(height: 16),
//             _buildAppInfoSection(),
//             const SizedBox(height: 24),
//             _buildAccountActions(),
//           ],
//         ),
//       ),
//     );
//   }

//   PreferredSizeWidget _buildAppBar() => AppBar(
//     backgroundColor: _cream,
//     elevation: 0,
//     scrolledUnderElevation: 0,
//     leading: IconButton(
//       icon: Container(
//         padding: const EdgeInsets.all(8),
//         decoration: BoxDecoration(
//           color: Colors.white,
//           shape: BoxShape.circle,
//           boxShadow: [BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 8, offset: const Offset(0, 2))],
//         ),
//         child: const Icon(Icons.arrow_back_ios_new, color: _charcoal, size: 16),
//       ),
//       onPressed: () => Navigator.pop(context),
//     ),
//     title: const Text(
//       "Settings",
//       style: TextStyle(
//         color: _charcoal, fontWeight: FontWeight.w800,
//         fontSize: 20, letterSpacing: -0.5,
//       ),
//     ),
//   );

//   // ── Notifications section ─────────────────────────────────
//   Widget _buildNotificationsSection() => _Section(
//     icon: Icons.notifications_rounded,
//     iconColor: _red,
//     iconBg: _redSoft,
//     title: "Notifications",
//     children: [
//       _SwitchRow(
//         icon: Icons.phone_android_rounded,
//         iconBg: const Color(0xFFE8F5E9),
//         iconColor: const Color(0xFF2E7D32),
//         title: "Push Notifications",
//         subtitle: "Alerts on your device",
//         value: _pushNotifications,
//         onChanged: _handlePushToggle,
//       ),
//       _dividerLine(),
//       _SwitchRow(
//         icon: Icons.email_rounded,
//         iconBg: const Color(0xFFE3F2FD),
//         iconColor: const Color(0xFF1565C0),
//         title: "Email Notifications",
//         subtitle: "Updates to your inbox",
//         value: _emailNotifications,
//         onChanged: (v) {
//           setState(() => _emailNotifications = v);
//           _saveSetting('email_notifications', v);
//         },
//       ),
//       _dividerLine(),
//       _SwitchRow(
//         icon: Icons.shopping_bag_rounded,
//         iconBg: const Color(0xFFFFF3E0),
//         iconColor: const Color(0xFFE65100),
//         title: "Order Updates",
//         subtitle: "Track your orders",
//         value: _orderUpdates,
//         onChanged: (v) {
//           setState(() => _orderUpdates = v);
//           _saveSetting('order_updates', v);
//         },
//       ),
//       _dividerLine(),
//       _SwitchRow(
//         icon: Icons.local_offer_rounded,
//         iconBg: const Color(0xFFF3E5F5),
//         iconColor: const Color(0xFF6A1B9A),
//         title: "Promotional",
//         subtitle: "Offers and discounts",
//         value: _promotionalUpdates,
//         onChanged: (v) {
//           setState(() => _promotionalUpdates = v);
//           _saveSetting('promotional_updates', v);
//         },
//       ),
//     ],
//   );

//   // ── Legal section ─────────────────────────────────────────
//   Widget _buildLegalSection() => _Section(
//     icon: Icons.gavel_rounded,
//     iconColor: const Color(0xFF1565C0),
//     iconBg: const Color(0xFFE3F2FD),
//     title: "Legal & Privacy",
//     children: [
//       _TileRow(
//         icon: Icons.privacy_tip_rounded,
//         iconBg: const Color(0xFFE8F5E9),
//         iconColor: const Color(0xFF2E7D32),
//         title: "Privacy Policy",
//         onTap: _showPrivacyPolicy,
//       ),
//       _dividerLine(),
//       _TileRow(
//         icon: Icons.description_rounded,
//         iconBg: const Color(0xFFFFF3E0),
//         iconColor: const Color(0xFFE65100),
//         title: "Legal Information",
//         onTap: _showLegalInformation,
//       ),
//     ],
//   );

//   // ── App info section ──────────────────────────────────────
//   Widget _buildAppInfoSection() => _Section(
//     icon: Icons.info_rounded,
//     iconColor: _slate,
//     iconBg: const Color(0xFFF5F5F5),
//     title: "About",
//     children: [
//       _TileRow(
//         icon: Icons.verified_rounded,
//         iconBg: const Color(0xFFE3F2FD),
//         iconColor: const Color(0xFF1565C0),
//         title: "App Version",
//         trailing: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
//           decoration: BoxDecoration(
//             color: _divider,
//             borderRadius: BorderRadius.circular(8),
//           ),
//           child: const Text("1.0.0",
//             style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: _slate)),
//         ),
//         onTap: () {},
//       ),
//     ],
//   );

//   // ── Account action buttons ────────────────────────────────
//   Widget _buildAccountActions() => Column(
//     children: [
//       // Sign Out
//       _ActionButton(
//         label: "Sign Out",
//         icon: Icons.logout_rounded,
//         background: _red,
//         foreground: Colors.white,
//         onTap: _signOut,
//       ),
//       const SizedBox(height: 12),
//       // Delete Account
//       _ActionButton(
//         label: "Delete Account",
//         icon: Icons.delete_forever_rounded,
//         background: Colors.white,
//         foreground: _red,
//         border: _red,
//         onTap: _deleteAccount,
//       ),
//     ],
//   );

//   Widget _dividerLine() => Divider(
//     height: 1, thickness: 1,
//     color: _divider,
//     indent: 58, endIndent: 0,
//   );
// }

// // ── Reusable section card ─────────────────────────────────────
// class _Section extends StatelessWidget {
//   final IconData icon;
//   final Color iconColor;
//   final Color iconBg;
//   final String title;
//   final List<Widget> children;

//   const _Section({
//     required this.icon,
//     required this.iconColor,
//     required this.iconBg,
//     required this.title,
//     required this.children,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Column(
//       crossAxisAlignment: CrossAxisAlignment.start,
//       children: [
//         // Section header
//         Padding(
//           padding: const EdgeInsets.only(left: 4, bottom: 10),
//           child: Row(children: [
//             Container(
//               width: 28, height: 28,
//               decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(8)),
//               child: Icon(icon, color: iconColor, size: 16),
//             ),
//             const SizedBox(width: 8),
//             Text(title,
//               style: const TextStyle(
//                 fontSize: 13, fontWeight: FontWeight.w700,
//                 color: _slate, letterSpacing: 0.3,
//               ),
//             ),
//           ]),
//         ),
//         // Card
//         Container(
//           decoration: BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.circular(18),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.04),
//                 blurRadius: 12, offset: const Offset(0, 4)),
//             ],
//           ),
//           child: ClipRRect(
//             borderRadius: BorderRadius.circular(18),
//             child: Column(children: children),
//           ),
//         ),
//       ],
//     );
//   }
// }

// // ── Switch row ────────────────────────────────────────────────
// class _SwitchRow extends StatelessWidget {
//   final IconData icon;
//   final Color iconColor;
//   final Color iconBg;
//   final String title;
//   final String subtitle;
//   final bool value;
//   final ValueChanged<bool> onChanged;

//   const _SwitchRow({
//     required this.icon,
//     required this.iconColor,
//     required this.iconBg,
//     required this.title,
//     required this.subtitle,
//     required this.value,
//     required this.onChanged,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//       child: Row(children: [
//         Container(
//           width: 36, height: 36,
//           decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
//           child: Icon(icon, color: iconColor, size: 18),
//         ),
//         const SizedBox(width: 14),
//         Expanded(child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Text(title,
//               style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _charcoal)),
//             const SizedBox(height: 2),
//             Text(subtitle,
//               style: const TextStyle(fontSize: 12, color: _slate)),
//           ],
//         )),
//         Switch.adaptive(
//           value: value,
//           onChanged: onChanged,
//           activeColor: _red,
//         ),
//       ]),
//     );
//   }
// }

// // ── Tile row ──────────────────────────────────────────────────
// class _TileRow extends StatelessWidget {
//   final IconData icon;
//   final Color iconColor;
//   final Color iconBg;
//   final String title;
//   final Widget? trailing;
//   final VoidCallback? onTap;

//   const _TileRow({
//     required this.icon,
//     required this.iconColor,
//     required this.iconBg,
//     required this.title,
//     this.trailing,
//     this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Material(
//       color: Colors.transparent,
//       child: InkWell(
//         onTap: onTap,
//         child: Padding(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           child: Row(children: [
//             Container(
//               width: 36, height: 36,
//               decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
//               child: Icon(icon, color: iconColor, size: 18),
//             ),
//             const SizedBox(width: 14),
//             Expanded(child: Text(title,
//               style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600, color: _charcoal))),
//             trailing ?? Icon(Icons.chevron_right_rounded, color: Colors.grey[400], size: 20),
//           ]),
//         ),
//       ),
//     );
//   }
// }

// // ── Action button ─────────────────────────────────────────────
// class _ActionButton extends StatelessWidget {
//   final String label;
//   final IconData icon;
//   final Color background;
//   final Color foreground;
//   final Color? border;
//   final VoidCallback onTap;

//   const _ActionButton({
//     required this.label,
//     required this.icon,
//     required this.background,
//     required this.foreground,
//     this.border,
//     required this.onTap,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Container(
//       width: double.infinity,
//       decoration: BoxDecoration(
//         color: background,
//         borderRadius: BorderRadius.circular(16),
//         border: border != null ? Border.all(color: border!, width: 1.5) : null,
//         boxShadow: background != Colors.white
//             ? [BoxShadow(color: background.withOpacity(0.3), blurRadius: 12, offset: const Offset(0, 4))]
//             : null,
//       ),
//       child: Material(
//         color: Colors.transparent,
//         borderRadius: BorderRadius.circular(16),
//         child: InkWell(
//           onTap: onTap,
//           borderRadius: BorderRadius.circular(16),
//           child: Padding(
//             padding: const EdgeInsets.symmetric(vertical: 16),
//             child: Row(
//               mainAxisAlignment: MainAxisAlignment.center,
//               children: [
//                 Icon(icon, color: foreground, size: 20),
//                 const SizedBox(width: 8),
//                 Text(label,
//                   style: TextStyle(
//                     color: foreground, fontSize: 16,
//                     fontWeight: FontWeight.w700,
//                   )),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }

// // ── Confirm dialog ────────────────────────────────────────────
// class _ConfirmDialog extends StatelessWidget {
//   final String title;
//   final String message;
//   final String confirmLabel;
//   final Color confirmColor;
//   final IconData? icon;

//   const _ConfirmDialog({
//     required this.title,
//     required this.message,
//     required this.confirmLabel,
//     required this.confirmColor,
//     this.icon,
//   });

//   @override
//   Widget build(BuildContext context) {
//     return Dialog(
//       shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
//       child: Padding(
//         padding: const EdgeInsets.all(24),
//         child: Column(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             if (icon != null) ...[
//               Container(
//                 width: 56, height: 56,
//                 decoration: BoxDecoration(
//                   color: confirmColor.withOpacity(0.1),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(icon, color: confirmColor, size: 28),
//               ),
//               const SizedBox(height: 16),
//             ],
//             Text(title,
//               style: const TextStyle(
//                 fontSize: 18, fontWeight: FontWeight.w800,
//                 color: _charcoal, letterSpacing: -0.3,
//               )),
//             const SizedBox(height: 10),
//             Text(message,
//               textAlign: TextAlign.center,
//               style: const TextStyle(fontSize: 14, color: _slate, height: 1.5)),
//             const SizedBox(height: 24),
//             Row(children: [
//               Expanded(
//                 child: OutlinedButton(
//                   onPressed: () => Navigator.pop(context, false),
//                   style: OutlinedButton.styleFrom(
//                     foregroundColor: _slate,
//                     side: BorderSide(color: Colors.grey[300]!),
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: const Text("Cancel",
//                     style: TextStyle(fontWeight: FontWeight.w600)),
//                 ),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: ElevatedButton(
//                   onPressed: () => Navigator.pop(context, true),
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: confirmColor,
//                     foregroundColor: Colors.white,
//                     elevation: 0,
//                     padding: const EdgeInsets.symmetric(vertical: 14),
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12)),
//                   ),
//                   child: Text(confirmLabel,
//                     style: const TextStyle(fontWeight: FontWeight.w700)),
//                 ),
//               ),
//             ]),
//           ],
//         ),
//       ),
//     );
//   }
// }

// // import 'package:flutter/material.dart';
// // import 'package:shared_preferences/shared_preferences.dart';
// // import 'package:vlog/presentation/auth/login_page.dart';
// // import 'package:vlog/Data/apiservices.dart';
// // import 'package:vlog/Utils/storage_service.dart';

// // class SettingsPage extends StatefulWidget {
// //   const SettingsPage({super.key});

// //   @override
// //   State<SettingsPage> createState() => _SettingsPageState();
// // }

// // class _SettingsPageState extends State<SettingsPage> {
// //   bool _pushNotifications = true;
// //   bool _emailNotifications = true;
// //   bool _orderUpdates = true;
// //   bool _promotionalUpdates = false;

// //   @override
// //   void initState() {
// //     super.initState();
// //     _loadSettings();
// //   }

// //   Future<void> _loadSettings() async {
// //     final prefs = await SharedPreferences.getInstance();
// //     setState(() {
// //       _pushNotifications = prefs.getBool('push_notifications') ?? true;
// //       _emailNotifications = prefs.getBool('email_notifications') ?? true;
// //       _orderUpdates = prefs.getBool('order_updates') ?? true;
// //       _promotionalUpdates = prefs.getBool('promotional_updates') ?? false;
// //     });
// //   }

// //   Future<void> _saveSetting(String key, dynamic value) async {
// //     final prefs = await SharedPreferences.getInstance();
// //     if (value is String) {
// //       await prefs.setString(key, value);
// //     } else if (value is bool) {
// //       await prefs.setBool(key, value);
// //     }
// //   }

// //   void _showPrivacyPolicy() {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: const Text("Privacy Policy"),
// //         content: const SingleChildScrollView(
// //           child: Text(
// //             "Privacy Policy\n\n"
// //             "Last Updated: January 2026\n\n"
// //             "We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and safeguard your information when you use our app.\n\n"
// //             "Information We Collect:\n"
// //             "- Personal information (name, email, address)\n"
// //             "- Payment information\n"
// //             "- Device information\n"
// //             "- Usage data\n\n"
// //             "How We Use Your Information:\n"
// //             "- To process your orders\n"
// //             "- To improve our services\n"
// //             "- To send you updates (with your consent)\n"
// //             "- To comply with legal obligations\n\n"
// //             "Data Security:\n"
// //             "We implement appropriate security measures to protect your personal data.\n\n"
// //             "Your Rights:\n"
// //             "You have the right to access, update, or delete your personal information at any time.\n\n"
// //              "© 2026 CODIGO. All rights reserved."
// //             ,
// //           ),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text("Close"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   void _showLegalInformation() {
// //     showDialog(
// //       context: context,
// //       builder: (context) => AlertDialog(
// //         title: const Text("Legal Information"),
// //         content: const SingleChildScrollView(
// //           child: Text(
// //             "Legal Information\n\n"
// //             "Terms of Service\n\n"
// //             "By using this app, you agree to the following terms:\n"
// //             "- You must be at least 18 years old to make purchases\n"
// //             "- All products are subject to availability\n"
// //             "- Prices are subject to change without notice\n"
// //             "- We reserve the right to refuse service\n\n"
// //             "Refund Policy:\n"
// //             "Items can be returned within 30 days of purchase with receipt.\n\n"
// //             "Warranty:\n"
// //             "All products come with manufacturer's warranty.\n\n"
// //             "Limitation of Liability:\n"
// //             "Our liability is limited to the purchase price of products.\n\n"
// //             "© 2026 CODIGO. All rights reserved."
// //             ,
// //           ),
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(context),
// //             child: const Text("Close"),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Future<void> _signOut() async {
// //     // Get navigator context before showing dialog
// //     final navigator = Navigator.of(context);
// //     final scaffoldMessenger = ScaffoldMessenger.of(context);
    
// //     final shouldLogout = await showDialog<bool>(
// //       context: context,
// //       builder: (dialogContext) => AlertDialog(
// //         title: const Text("Sign Out"),
// //         content: const Text("Are you sure you want to sign out?"),
// //         actions: [
// //           TextButton(
// //             onPressed: () => Navigator.pop(dialogContext, false),
// //             child: const Text("Cancel"),
// //           ),
// //           TextButton(
// //             onPressed: () => Navigator.pop(dialogContext, true),
// //             child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
// //           ),
// //         ],
// //       ),
// //     );

// //     if (shouldLogout != true) return;

// //     // Show loading indicator
// //     if (!mounted) return;
    
// //     try {
// //       final authService = AuthService();
// //       await authService.logout();
      
// //       if (!mounted) return;
      
// //       // Navigate to login page
// //       navigator.pushAndRemoveUntil(
// //         MaterialPageRoute(builder: (_) => const LoginPage()),
// //         (route) => false,
// //       );
      
// //       // Show success message after navigation
// //       scaffoldMessenger.showSnackBar(
// //         const SnackBar(
// //           content: Text('Logged out successfully'),
// //           backgroundColor: Colors.green,
// //           duration: Duration(seconds: 2),
// //         ),
// //       );
// //     } catch (e) {
// //       // Even if logout fails, clear storage and navigate to login
// //       if (!mounted) return;
      
// //       navigator.pushAndRemoveUntil(
// //         MaterialPageRoute(builder: (_) => const LoginPage()),
// //         (route) => false,
// //       );
      
// //       scaffoldMessenger.showSnackBar(
// //         SnackBar(
// //           content: Text('Logged out: ${e.toString()}'),
// //           backgroundColor: Colors.orange,
// //           duration: const Duration(seconds: 2),
// //         ),
// //       );
// //     }
// //   }

// //   Future<void> _deleteAccount() async {
// //     final navigator = Navigator.of(context);
// //     final scaffoldMessenger = ScaffoldMessenger.of(context);
// //     final scaffoldContext = context;

// //     showDialog(
// //       context: scaffoldContext,
// //       builder: (dialogContext) => AlertDialog(
// //         shape: RoundedRectangleBorder(
// //           borderRadius: BorderRadius.circular(16),
// //         ),
// //         title: Row(
// //           children: [
// //             Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
// //             const SizedBox(width: 12),
// //             const Expanded(
// //               child: Text(
// //                 "Delete Account",
// //                 style: TextStyle(
// //                   fontWeight: FontWeight.bold,
// //                   fontSize: 20,
// //                 ),
// //               ),
// //             ),
// //           ],
// //         ),
// //         content: const Column(
// //           mainAxisSize: MainAxisSize.min,
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             Text(
// //               "Are you sure you want to delete your account?",
// //               style: TextStyle(fontSize: 16),
// //             ),
// //             SizedBox(height: 12),
// //             Text(
// //               "This action cannot be undone. All your data including:",
// //               style: TextStyle(fontSize: 14, color: Colors.black87),
// //             ),
// //             SizedBox(height: 8),
// //             Padding(
// //               padding: EdgeInsets.only(left: 16),
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text("• Your profile information", style: TextStyle(fontSize: 13)),
// //                   Text("• Order history", style: TextStyle(fontSize: 13)),
// //                   Text("• Saved addresses", style: TextStyle(fontSize: 13)),
// //                   Text("• Wishlist items", style: TextStyle(fontSize: 13)),
// //                 ],
// //               ),
// //             ),
// //             SizedBox(height: 12),
// //             Text(
// //               "will be permanently deleted.",
// //               style: TextStyle(
// //                 fontSize: 14,
// //                 color: Colors.red,
// //                 fontWeight: FontWeight.bold,
// //               ),
// //             ),
// //           ],
// //         ),
// //         actions: [
// //           TextButton(
// //             onPressed: () => navigator.pop(),
// //             child: Text(
// //               "Cancel",
// //               style: TextStyle(color: Colors.grey[700]),
// //             ),
// //           ),
// //           TextButton(
// //             onPressed: () async {
// //               navigator.pop();
// //               // Show confirmation dialog
// //               final confirm = await showDialog<bool>(
// //                 context: scaffoldContext,
// //                 builder: (ctx2) => AlertDialog(
// //                   title: const Text("Final Confirmation"),
// //                   content: const Text(
// //                     "This is your last chance. Are you absolutely sure you want to delete your account?",
// //                   ),
// //                   actions: [
// //                     TextButton(
// //                       onPressed: () => Navigator.pop(ctx2, false),
// //                       child: const Text("Cancel"),
// //                     ),
// //                     TextButton(
// //                       onPressed: () => Navigator.pop(ctx2, true),
// //                       child: const Text(
// //                         "Delete Forever",
// //                         style: TextStyle(color: Colors.red),
// //                       ),
// //                     ),
// //                   ],
// //                 ),
// //               );

// //               if (confirm == true && mounted) {
// //                 // Get user ID for API call
// //                 final user = await StorageService.getUser();
// //                 final userId = user?['id'];
// //                 if (userId == null) {
// //                   if (mounted) {
// //                     scaffoldMessenger.showSnackBar(
// //                       const SnackBar(
// //                         content: Text("Could not get user info. Please sign in again."),
// //                         backgroundColor: Colors.red,
// //                         duration: Duration(seconds: 2),
// //                       ),
// //                     );
// //                   }
// //                   return;
// //                 }

// //                 final userIdInt = userId is int ? userId : int.tryParse(userId.toString());
// //                 if (userIdInt == null) {
// //                   if (mounted) {
// //                     scaffoldMessenger.showSnackBar(
// //                       const SnackBar(
// //                         content: Text("Invalid user ID. Please sign in again."),
// //                         backgroundColor: Colors.red,
// //                         duration: Duration(seconds: 2),
// //                       ),
// //                     );
// //                   }
// //                   return;
// //                 }

// //                 try {
// //                   final authService = AuthService();
// //                   await authService.deleteAccount(userIdInt);

// //                   // Clear local preferences
// //                   final prefs = await SharedPreferences.getInstance();
// //                   await prefs.clear();

// //                   if (mounted) {
// //                     scaffoldMessenger.showSnackBar(
// //                       const SnackBar(
// //                         content: Text("Your account has been deleted successfully"),
// //                         backgroundColor: Colors.green,
// //                         duration: Duration(seconds: 2),
// //                       ),
// //                     );

// //                     navigator.pushAndRemoveUntil(
// //                       MaterialPageRoute(builder: (_) => const LoginPage()),
// //                       (route) => false,
// //                     );
// //                   }
// //                 } catch (e) {
// //                   if (mounted) {
// //                     scaffoldMessenger.showSnackBar(
// //                       SnackBar(
// //                         content: Text("Failed to delete account: ${e.toString()}"),
// //                         backgroundColor: Colors.red,
// //                         duration: const Duration(seconds: 3),
// //                       ),
// //                     );
// //                   }
// //                 }
// //               }
// //             },
// //             child: Container(
// //               padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
// //               decoration: BoxDecoration(
// //                 color: Colors.red,
// //                 borderRadius: BorderRadius.circular(8),
// //               ),
// //               child: const Text(
// //                 "Delete Account",
// //                 style: TextStyle(
// //                   color: Colors.white,
// //                   fontWeight: FontWeight.bold,
// //                 ),
// //               ),
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         backgroundColor: Colors.white,
// //         elevation: 0,
// //         leading: IconButton(
// //           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
// //           onPressed: () => Navigator.pop(context),
// //         ),
// //         title: const Text(
// //           "Settings",
// //           style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
// //         ),
// //       ),
// //       body: ListView(
// //         children: [
// //           // Notifications
// //           _buildSection(
// //             title: "Notifications",
// //             children: [
// //               SwitchListTile(
// //                 secondary: const Icon(Icons.notifications_active),
// //                 title: const Text("Push Notifications"),
// //                 subtitle: const Text("Receive push notifications"),
// //                 value: _pushNotifications,
// //                 onChanged: (value) {
// //                   setState(() => _pushNotifications = value);
// //                   _saveSetting('push_notifications', value);
// //                 },
// //               ),
// //               SwitchListTile(
// //                 secondary: const Icon(Icons.email),
// //                 title: const Text("Email Notifications"),
// //                 subtitle: const Text("Receive email updates"),
// //                 value: _emailNotifications,
// //                 onChanged: (value) {
// //                   setState(() => _emailNotifications = value);
// //                   _saveSetting('email_notifications', value);
// //                 },
// //               ),
// //               SwitchListTile(
// //                 secondary: const Icon(Icons.shopping_bag),
// //                 title: const Text("Order Updates"),
// //                 subtitle: const Text("Get notified about your orders"),
// //                 value: _orderUpdates,
// //                 onChanged: (value) {
// //                   setState(() => _orderUpdates = value);
// //                   _saveSetting('order_updates', value);
// //                 },
// //               ),
// //               SwitchListTile(
// //                 secondary: const Icon(Icons.local_offer),
// //                 title: const Text("Promotional Updates"),
// //                 subtitle: const Text("Receive offers and discounts"),
// //                 value: _promotionalUpdates,
// //                 onChanged: (value) {
// //                   setState(() => _promotionalUpdates = value);
// //                   _saveSetting('promotional_updates', value);
// //                 },
// //               ),
// //             ],
// //           ),

// //           // Legal & About
// //           _buildSection(
// //             title: "Legal & About",
// //             children: [
// //               _buildTile(
// //                 icon: Icons.privacy_tip,
// //                 title: "Privacy Policy",
// //                 onTap: _showPrivacyPolicy,
// //               ),
// //               _buildTile(
// //                 icon: Icons.description,
// //                 title: "Legal Information",
// //                 onTap: _showLegalInformation,
// //               ),
// //               _buildTile(
// //                 icon: Icons.info,
// //                 title: "App Version",
// //                 subtitle: "1.0.0",
// //                 onTap: () {},
// //               ),
// //             ],
// //           ),

// //           // Account Actions
// //           Padding(
// //             padding: const EdgeInsets.all(20),
// //             child: Column(
// //               children: [
// //                 // Sign Out Button - Red with white outline
// //                 Container(
// //                   width: double.infinity,
// //                   decoration: BoxDecoration(
// //                     color: Colors.red,
// //                     borderRadius: BorderRadius.circular(12),
// //                     border: Border.all(
// //                       color: Colors.white,
// //                       width: 2,
// //                     ),
// //                   ),
// //                   child: Material(
// //                     color: Colors.transparent,
// //                     child: InkWell(
// //                       onTap: _signOut,
// //                       borderRadius: BorderRadius.circular(12),
// //                       child: Padding(
// //                         padding: const EdgeInsets.symmetric(vertical: 16),
// //                         child: Row(
// //                           mainAxisAlignment: MainAxisAlignment.center,
// //                           children: [
// //                             const Icon(
// //                               Icons.logout,
// //                               color: Colors.white,
// //                               size: 20,
// //                             ),
// //                             const SizedBox(width: 8),
// //                             const Text(
// //                               "Sign Out",
// //                               style: TextStyle(
// //                                 color: Colors.white,
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.w600,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //                 const SizedBox(height: 12),
// //                 // Delete Account Button - Outlined red
// //                 Container(
// //                   width: double.infinity,
// //                   decoration: BoxDecoration(
// //                     borderRadius: BorderRadius.circular(12),
// //                     border: Border.all(
// //                       color: Colors.red,
// //                       width: 2,
// //                     ),
// //                   ),
// //                   child: Material(
// //                     color: Colors.transparent,
// //                     child: InkWell(
// //                       onTap: _deleteAccount,
// //                       borderRadius: BorderRadius.circular(12),
// //                       child: Padding(
// //                         padding: const EdgeInsets.symmetric(vertical: 16),
// //                         child: Row(
// //                           mainAxisAlignment: MainAxisAlignment.center,
// //                           children: [
// //                             Stack(
// //                               alignment: Alignment.center,
// //                               children: [
// //                                 const Icon(
// //                                   Icons.delete_outline,
// //                                   color: Colors.red,
// //                                   size: 20,
// //                                 ),
// //                                 Positioned(
// //                                   top: 2,
// //                                   right: 2,
// //                                   child: Container(
// //                                     width: 6,
// //                                     height: 6,
// //                                     decoration: const BoxDecoration(
// //                                       color: Colors.red,
// //                                       shape: BoxShape.circle,
// //                                     ),
// //                                     child: const Center(
// //                                       child: Text(
// //                                         '×',
// //                                         style: TextStyle(
// //                                           color: Colors.white,
// //                                           fontSize: 8,
// //                                           fontWeight: FontWeight.bold,
// //                                           height: 1,
// //                                         ),
// //                                       ),
// //                                     ),
// //                                   ),
// //                                 ),
// //                               ],
// //                             ),
// //                             const SizedBox(width: 8),
// //                             const Text(
// //                               "Delete Account",
// //                               style: TextStyle(
// //                                 color: Colors.red,
// //                                 fontSize: 16,
// //                                 fontWeight: FontWeight.w600,
// //                               ),
// //                             ),
// //                           ],
// //                         ),
// //                       ),
// //                     ),
// //                   ),
// //                 ),
// //               ],
// //             ),
// //           ),
// //         ],
// //       ),
// //     );
// //   }

// //   Widget _buildSection({
// //     required String title,
// //     required List<Widget> children,
// //   }) {
// //     return Column(
// //       crossAxisAlignment: CrossAxisAlignment.start,
// //       children: [
// //         Padding(
// //           padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
// //           child: Text(
// //             title,
// //             style: TextStyle(
// //               fontSize: 14,
// //               fontWeight: FontWeight.bold,
// //               color: Colors.grey.shade600,
// //             ),
// //           ),
// //         ),
// //         Container(
// //           color: Colors.white,
// //           child: Column(children: children),
// //         ),
// //         Divider(height: 1, color: Colors.grey.shade200),
// //       ],
// //     );
// //   }

// //   Widget _buildTile({
// //     required IconData icon,
// //     required String title,
// //     String? subtitle,
// //     Widget? trailing,
// //     VoidCallback? onTap,
// //   }) {
// //     return ListTile(
// //       leading: Icon(icon, color: Colors.black87),
// //       title: Text(title),
// //       subtitle: subtitle != null ? Text(subtitle) : null,
// //       trailing:
// //           trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
// //       onTap: onTap,
// //     );
// //   }
// // }
