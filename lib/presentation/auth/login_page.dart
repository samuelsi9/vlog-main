import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/api_exception.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:vlog/presentation/home.dart';
import 'package:vlog/presentation/auth/complete_phone_screen.dart';
import 'package:vlog/presentation/auth/register_page.dart';
import 'package:vlog/presentation/auth/forgot_password_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Design colors: red & white (DishDash / EcoThrive style)
const Color _primaryRed = Color(0xFFE53E3E);
const Color _primaryRedDark = Color(0xFFC62828);
const Color _lightGrey = Color(0xFF9E9E9E);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final usernameController = TextEditingController();
  final passwordController = TextEditingController();
  bool _obscurePassword = true;
  late AnimationController _textKoliagoController;
  late Animation<double> _textKoliagoScale;
  late AnimationController _pageController;
  late Animation<double> _fadeKoliago;
  late Animation<double> _slideTabs;
  late Animation<double> _slideOr;
  late Animation<double> _slideSocial;
  late Animation<double> _slideForm;

  @override
  void initState() {
    super.initState();
    _textKoliagoController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _textKoliagoScale = Tween<double>(begin: 1.0, end: 1.08).animate(
      CurvedAnimation(parent: _textKoliagoController, curve: Curves.easeInOut),
    );
    _pageController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..forward();
    _fadeKoliago = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.0, 0.2, curve: Curves.easeOut),
      ),
    );
    _slideTabs = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.1, 0.35, curve: Curves.elasticOut),
      ),
    );
    _slideOr = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.25, 0.45, curve: Curves.easeOut),
      ),
    );
    _slideSocial = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.35, 0.6, curve: Curves.easeOutBack),
      ),
    );
    _slideForm = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(
        parent: _pageController,
        curve: const Interval(0.45, 0.85, curve: Curves.easeOutCubic),
      ),
    );
  }

  @override
  void dispose() {
    _textKoliagoController.dispose();
    _pageController.dispose();
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  void signUserIn() async {
    if (!_formKey.currentState!.validate()) return;
    final email = usernameController.text.trim();
    final password = passwordController.text;

    try {
      final auth = AuthService();
      final data = await auth.login(email: email, password: password);

      if (data.isNotEmpty && data['user'] != null) {
        final user = data['user'] as Map<String, dynamic>;
        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => MainScreen(
              token: user['id']?.toString(),
              showWelcomeOverlay: true,
            ),
          ),
        );
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Invalid credentials'),
          backgroundColor: Colors.red,
        ));
      }
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(UserErrorMapper.toUserMessage(e)),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 5),
      ));
    } catch (e) {
      if (!mounted) return;
      final String errorMessage = e.toString().contains('network') ||
              e.toString().contains('Network') ||
              e.toString().contains('SocketException')
          ? 'Network error. Please check your connection.'
          : 'Login failed';
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(errorMessage),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 4),
      ));
    }
  }

  Future<void> _signInWithGoogle() async {
    try {
      await AuthService.signInWithGoogle();
      if (!mounted) return;
      final user = await StorageService.getUser();
      final userId = user?['id']?.toString();
      final phone = user?['phone'];
      final hasPhone = phone != null && phone.toString().trim().isNotEmpty;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => hasPhone
              ? MainScreen(token: userId, showWelcomeOverlay: true)
              : const CompletePhoneScreen(),
        ),
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) return;
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${e.description ?? e}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google sign-in failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _signInWithApple() async {
    try {
      await AuthService.signInWithApple();
      if (!mounted) return;
      final user = await StorageService.getUser();
      final userId = user?['id']?.toString();
      final phone = user?['phone'];
      final hasPhone = phone != null && phone.toString().trim().isNotEmpty;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => hasPhone
              ? MainScreen(token: userId, showWelcomeOverlay: true)
              : const CompletePhoneScreen(),
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple sign-in failed: ${e.message}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple sign-in failed: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              // —— Gradient header: logo + Welcome Back ——
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 44),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_primaryRed, _primaryRedDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(32),
                    bottomRight: Radius.circular(32),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _primaryRed.withOpacity(0.4),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeKoliago,
                      child: const Text(
                        'Vlog',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    const Text(
                      'Welcome Back',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Sign in to continue ordering your favorite meals.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),

              // —— Login / SignUp tabs ——
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.5),
                  end: Offset.zero,
                ).animate(_slideTabs),
                child: FadeTransition(
                  opacity: _slideTabs,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 24, 20, 0),
                    child: Row(
                  children: [
                    Expanded(
                      child: _TabChip(
                        label: 'Login',
                        selected: true,
                        onTap: () {},
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TabChip(
                        label: 'SignUp',
                        selected: false,
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterPage(),
                            ),
                          );
                        },
                      ),
                      ),
                    ],
                  ),
                ),
              ),
              ),

              // —— Or continue with + Social buttons ——
              FadeTransition(
                opacity: _slideOr,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  child: Row(
                    children: [
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: Text(
                          'Or continue with',
                          style: TextStyle(
                            color: _lightGrey,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                      Expanded(child: Divider(color: Colors.grey.shade300)),
                    ],
                  ),
                ),
              ),
              SlideTransition(
                position: Tween<Offset>(begin: const Offset(0, 0.2), end: Offset.zero).animate(_slideSocial),
                child: FadeTransition(
                  opacity: _slideSocial,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(
                          child: _SocialButton(
                            imageAsset: 'assets/googleLogo.png',
                            label: 'Google',
                            color: const Color(0xFF4285F4),
                            onTap: _signInWithGoogle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _SocialButton(
                            icon: Icons.apple,
                            label: 'Apple',
                            color: Colors.black,
                            onTap: _signInWithApple,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // —— White form section ——
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.2),
                  end: Offset.zero,
                ).animate(_slideForm),
                child: FadeTransition(
                  opacity: _slideForm,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 28, 24, 24),
                    child: Form(
                key: _formKey,
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TextFormField(
                      controller: usernameController,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                          hintText: 'Enter your email',
                          hintStyle: TextStyle(color: _lightGrey, fontSize: 15),
                          prefixIcon: Icon(Icons.email_outlined, color: _lightGrey, size: 22),
                        filled: true,
                          fillColor: Colors.grey.shade50,
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _primaryRed, width: 2),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                          ),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Email is required';
                        }
                        final regex = RegExp(
                          r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$',
                        );
                        if (!regex.hasMatch(v.trim())) {
                          return 'Enter a valid email';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 14),
                    TextFormField(
                      controller: passwordController,
                      obscureText: _obscurePassword,
                      decoration: InputDecoration(
                          hintText: 'Enter your password',
                          hintStyle: TextStyle(color: _lightGrey, fontSize: 15),
                          prefixIcon: Icon(Icons.lock_outline, color: _lightGrey, size: 22),
                          filled: true,
                          fillColor: Colors.grey.shade50,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: BorderSide(color: Colors.grey.shade200),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(color: _primaryRed, width: 2),
                          ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: _lightGrey,
                            ),
                            onPressed: () =>
                                setState(() => _obscurePassword = !_obscurePassword),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 18,
                            vertical: 16,
                        ),
                      ),
                      validator: (v) {
                        if (v == null || v.isEmpty) {
                          return 'Password is required';
                        }
                        if (v.length < 6) return 'Minimum 6 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ForgotPasswordPage(),
                            ),
                          );
                        },
                          child: Text(
                            'Forgot password?',
                            style: TextStyle(
                              color: _primaryRed,
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 56,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryRed,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16),
                            ),
                          ),
                          onPressed: signUserIn,
                          child: const Text(
                            'Sign In',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            "Don't have an account? ",
                            style: TextStyle(color: _lightGrey, fontSize: 14),
                          ),
                          GestureDetector(
                            onTap: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const RegisterPage(),
                                ),
                              );
                            },
                            child: Text(
                              'Sign up',
                              style: TextStyle(
                                color: _primaryRed,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    const SizedBox(height: 24),
                ],
              ),
                      ),
                    ),
                  ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateX(selected ? 0 : -0.02),
      alignment: Alignment.center,
      child: Material(
        color: selected ? _primaryRed : Colors.white,
        borderRadius: BorderRadius.circular(14),
        elevation: selected ? 4 : 6,
        shadowColor: Colors.black.withOpacity(0.3),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 14),
            alignment: Alignment.center,
            child: Text(
              label,
              style: TextStyle(
                color: selected ? Colors.white : _primaryRed,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _SocialButton extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _SocialButton({
    this.icon,
    this.imageAsset,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      elevation: 0,
      shadowColor: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: Colors.grey.shade300),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (imageAsset != null)
                Image.asset(imageAsset!, width: 22, height: 22, fit: BoxFit.contain)
              else if (icon != null)
                Icon(icon!, size: 22, color: color),
              const SizedBox(width: 8),
              Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: Colors.grey.shade800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
