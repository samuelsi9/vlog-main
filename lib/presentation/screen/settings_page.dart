import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vlog/presentation/auth/login_page.dart';
import 'package:vlog/Data/apiservices.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  bool _pushNotifications = true;
  bool _emailNotifications = true;
  bool _orderUpdates = true;
  bool _promotionalUpdates = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _pushNotifications = prefs.getBool('push_notifications') ?? true;
      _emailNotifications = prefs.getBool('email_notifications') ?? true;
      _orderUpdates = prefs.getBool('order_updates') ?? true;
      _promotionalUpdates = prefs.getBool('promotional_updates') ?? false;
    });
  }

  Future<void> _saveSetting(String key, dynamic value) async {
    final prefs = await SharedPreferences.getInstance();
    if (value is String) {
      await prefs.setString(key, value);
    } else if (value is bool) {
      await prefs.setBool(key, value);
    }
  }

  void _showPrivacyPolicy() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Privacy Policy"),
        content: const SingleChildScrollView(
          child: Text(
            "Privacy Policy\n\n"
            "Last Updated: January 2024\n\n"
            "We respect your privacy and are committed to protecting your personal data. This privacy policy explains how we collect, use, and safeguard your information when you use our app.\n\n"
            "Information We Collect:\n"
            "- Personal information (name, email, address)\n"
            "- Payment information\n"
            "- Device information\n"
            "- Usage data\n\n"
            "How We Use Your Information:\n"
            "- To process your orders\n"
            "- To improve our services\n"
            "- To send you updates (with your consent)\n"
            "- To comply with legal obligations\n\n"
            "Data Security:\n"
            "We implement appropriate security measures to protect your personal data.\n\n"
            "Your Rights:\n"
            "You have the right to access, update, or delete your personal information at any time.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  void _showLegalInformation() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Legal Information"),
        content: const SingleChildScrollView(
          child: Text(
            "Legal Information\n\n"
            "Terms of Service\n\n"
            "By using this app, you agree to the following terms:\n"
            "- You must be at least 18 years old to make purchases\n"
            "- All products are subject to availability\n"
            "- Prices are subject to change without notice\n"
            "- We reserve the right to refuse service\n\n"
            "Refund Policy:\n"
            "Items can be returned within 30 days of purchase with receipt.\n\n"
            "Warranty:\n"
            "All products come with manufacturer's warranty.\n\n"
            "Limitation of Liability:\n"
            "Our liability is limited to the purchase price of products.",
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
        ],
      ),
    );
  }

  Future<void> _signOut() async {
    // Get navigator context before showing dialog
    final navigator = Navigator.of(context);
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Sign Out"),
        content: const Text("Are you sure you want to sign out?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, true),
            child: const Text("Sign Out", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (shouldLogout != true) return;

    // Show loading indicator
    if (!mounted) return;
    
    try {
      final authService = AuthService();
      await authService.logout();
      
      if (!mounted) return;
      
      // Navigate to login page
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      
      // Show success message after navigation
      scaffoldMessenger.showSnackBar(
        const SnackBar(
          content: Text('Logged out successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      // Even if logout fails, clear storage and navigate to login
      if (!mounted) return;
      
      navigator.pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const LoginPage()),
        (route) => false,
      );
      
      scaffoldMessenger.showSnackBar(
        SnackBar(
          content: Text('Logged out: ${e.toString()}'),
          backgroundColor: Colors.orange,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _deleteAccount() async {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.red[700], size: 28),
            const SizedBox(width: 12),
            const Expanded(
              child: Text(
                "Delete Account",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 20,
                ),
              ),
            ),
          ],
        ),
        content: const Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "Are you sure you want to delete your account?",
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 12),
            Text(
              "This action cannot be undone. All your data including:",
              style: TextStyle(fontSize: 14, color: Colors.black87),
            ),
            SizedBox(height: 8),
            Padding(
              padding: EdgeInsets.only(left: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("• Your profile information", style: TextStyle(fontSize: 13)),
                  Text("• Order history", style: TextStyle(fontSize: 13)),
                  Text("• Saved addresses", style: TextStyle(fontSize: 13)),
                  Text("• Wishlist items", style: TextStyle(fontSize: 13)),
                ],
              ),
            ),
            SizedBox(height: 12),
            Text(
              "will be permanently deleted.",
              style: TextStyle(
                fontSize: 14,
                color: Colors.red,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              "Cancel",
              style: TextStyle(color: Colors.grey[700]),
            ),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              // Show confirmation dialog
              final confirm = await showDialog<bool>(
                context: context,
                builder: (context) => AlertDialog(
                  title: const Text("Final Confirmation"),
                  content: const Text(
                    "This is your last chance. Are you absolutely sure you want to delete your account?",
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context, false),
                      child: const Text("Cancel"),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(context, true),
                      child: const Text(
                        "Delete Forever",
                        style: TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              );

              if (confirm == true && mounted) {
                // Delete all user data
                final prefs = await SharedPreferences.getInstance();
                await prefs.clear();
                
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Your account has been deleted successfully"),
                      backgroundColor: Colors.green,
                      duration: Duration(seconds: 2),
                    ),
                  );
                  
                  // Navigate to login page
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => LoginPage()),
                    (route) => false,
                  );
                }
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.red,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                "Delete Account",
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          "Settings",
          style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
      ),
      body: ListView(
        children: [
          // Notifications
          _buildSection(
            title: "Notifications",
            children: [
              SwitchListTile(
                secondary: const Icon(Icons.notifications_active),
                title: const Text("Push Notifications"),
                subtitle: const Text("Receive push notifications"),
                value: _pushNotifications,
                onChanged: (value) {
                  setState(() => _pushNotifications = value);
                  _saveSetting('push_notifications', value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.email),
                title: const Text("Email Notifications"),
                subtitle: const Text("Receive email updates"),
                value: _emailNotifications,
                onChanged: (value) {
                  setState(() => _emailNotifications = value);
                  _saveSetting('email_notifications', value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.shopping_bag),
                title: const Text("Order Updates"),
                subtitle: const Text("Get notified about your orders"),
                value: _orderUpdates,
                onChanged: (value) {
                  setState(() => _orderUpdates = value);
                  _saveSetting('order_updates', value);
                },
              ),
              SwitchListTile(
                secondary: const Icon(Icons.local_offer),
                title: const Text("Promotional Updates"),
                subtitle: const Text("Receive offers and discounts"),
                value: _promotionalUpdates,
                onChanged: (value) {
                  setState(() => _promotionalUpdates = value);
                  _saveSetting('promotional_updates', value);
                },
              ),
            ],
          ),

          // Legal & About
          _buildSection(
            title: "Legal & About",
            children: [
              _buildTile(
                icon: Icons.privacy_tip,
                title: "Privacy Policy",
                onTap: _showPrivacyPolicy,
              ),
              _buildTile(
                icon: Icons.description,
                title: "Legal Information",
                onTap: _showLegalInformation,
              ),
              _buildTile(
                icon: Icons.info,
                title: "App Version",
                subtitle: "1.0.0",
                onTap: () {},
              ),
            ],
          ),

          // Account Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // Sign Out Button - Red with white outline
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.white,
                      width: 2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _signOut,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(
                              Icons.logout,
                              color: Colors.white,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Sign Out",
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                // Delete Account Button - Outlined red
                Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red,
                      width: 2,
                    ),
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _deleteAccount,
                      borderRadius: BorderRadius.circular(12),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Stack(
                              alignment: Alignment.center,
                              children: [
                                const Icon(
                                  Icons.delete_outline,
                                  color: Colors.red,
                                  size: 20,
                                ),
                                Positioned(
                                  top: 2,
                                  right: 2,
                                  child: Container(
                                    width: 6,
                                    height: 6,
                                    decoration: const BoxDecoration(
                                      color: Colors.red,
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Center(
                                      child: Text(
                                        '×',
                                        style: TextStyle(
                                          color: Colors.white,
                                          fontSize: 8,
                                          fontWeight: FontWeight.bold,
                                          height: 1,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              "Delete Account",
                              style: TextStyle(
                                color: Colors.red,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 10),
          child: Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey.shade600,
            ),
          ),
        ),
        Container(
          color: Colors.white,
          child: Column(children: children),
        ),
        Divider(height: 1, color: Colors.grey.shade200),
      ],
    );
  }

  Widget _buildTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.black87),
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle) : null,
      trailing:
          trailing ?? (onTap != null ? const Icon(Icons.chevron_right) : null),
      onTap: onTap,
    );
  }
}
