import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/api_exception.dart';
import 'package:vlog/presentation/addressess/addresses.dart';
import 'package:vlog/presentation/auth/login_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Design colors: red & white (same as login page)
const Color _primaryRed = Color(0xFFD32F2F);
const Color _lightGrey = Color(0xFF9E9E9E);

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage>
    with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
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
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _signUpWithGoogle() async {
    try {
      const String iosClientId =
          '262189303234-ff2c12r8mcfjhmh9gk3dk0k1fl9igs7e.apps.googleusercontent.com';
      await GoogleSignIn.instance.initialize(clientId: iosClientId);
      final GoogleSignInAccount googleUser =
          await GoogleSignIn.instance.authenticate();

      final String? idToken = googleUser.authentication.idToken;
      if (idToken == null) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Google sign-in: no ID token')),
        );
        return;
      }

      String? accessToken;
      try {
        final authz = await googleUser.authorizationClient.authorizeScopes(
          <String>[
            'openid',
            'https://www.googleapis.com/auth/userinfo.email',
            'https://www.googleapis.com/auth/userinfo.profile',
          ],
        );
        accessToken = authz.accessToken;
      } catch (_) {
        // Firebase can work with idToken only
      }

      final credential = GoogleAuthProvider.credential(
        idToken: idToken,
        accessToken: accessToken,
      );

      final UserCredential userCredential =
          await FirebaseAuth.instance.signInWithCredential(credential);

      if (userCredential.user != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('auth_token', userCredential.user!.uid);
        await prefs.setString('auth_user', jsonEncode({
          'id': userCredential.user!.uid,
          'email': userCredential.user!.email,
          'name': userCredential.user!.displayName,
        }));

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Registration with Google successful!')),
        );
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) => const Addresses(),
          ),
        );
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        return; // User cancelled
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text('Google registration failed: ${e.description ?? e}')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Google registration failed: ${e.toString()}')),
      );
    }
  }

  Future<void> _signUpWithApple() async {
    try {
      await AuthService.signInWithApple();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registration with Apple successful!'), backgroundColor: Colors.green),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const Addresses(),
        ),
      );
    } on SignInWithAppleAuthorizationException catch (e) {
      if (e.code == AuthorizationErrorCode.canceled) return;
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple registration failed: ${e.message}'), backgroundColor: Colors.red),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Apple registration failed: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  String? _validateFirstName(String? value) {
    if (value == null || value.isEmpty) {
      return 'First name is required';
    }
    if (value.length < 2) {
      return 'First name must be at least 2 characters';
    }
    return null;
  }

  String? _validateLastName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Last name is required';
    }
    if (value.length < 2) {
      return 'Last name must be at least 2 characters';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    if (digitsOnly.length < 8) {
      return 'Enter a valid phone number';
    }
    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  // String? _validateRole(String? value) {
  //   if (value == null || value.isEmpty) {
  //     return 'Role is required';
  //   }
  //   final validRoles = ['seller', 'buyer'];
  //   if (!validRoles.contains(value.toLowerCase())) {
  //     return 'Role must be: seller or buyer';
  //   }
  //   return null;
  // }

  void signUserUp() async {
    if (_formKey.currentState!.validate()) {
      // Call API; show success only after API succeeds, error only on failure
      try {
        final authService = AuthService();
        final result = await authService.register(
          name: '${firstNameController.text} ${lastNameController.text}',
          email: emailController.text,
          phone: phoneController.text.trim(),
          password: passwordController.text,
          role: "2",
        );

        if (result.isNotEmpty && result['user'] != null) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Registration successful!'),
                backgroundColor: Colors.green,
              ),
            );
            // Navigate to Addresses screen, then user can save address and go to real home
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Addresses(),
              ),
            );
          }
        }
      } on ApiException catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(UserErrorMapper.toUserMessage(e)),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      } catch (e) {
        if (mounted) {
          final String errorMessage = e.toString().contains('network') ||
                  e.toString().contains('Network') ||
                  e.toString().contains('SocketException')
              ? 'Network error. Please check your connection.'
              : 'Registration failed';
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 4),
            ),
          );
        }
      }
    }
  }

  InputDecoration _inputDecoration(String hint) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _lightGrey, fontSize: 15),
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // Top red section: logo + app name (3D effect)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 24),
                decoration: BoxDecoration(
                  color: _primaryRed,
                  borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(28),
                    bottomRight: Radius.circular(28),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.2),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    FadeTransition(
                      opacity: _fadeKoliago,
                      child: SlideTransition(
                        position: Tween<Offset>(
                          begin: const Offset(0, 0.5),
                          end: Offset.zero,
                        ).animate(_fadeKoliago),
                        child: ScaleTransition(
                          scale: Tween<double>(begin: 0.5, end: 1.0).animate(
                            CurvedAnimation(
                              parent: _pageController,
                              curve: const Interval(0.0, 0.25, curve: Curves.easeOutBack),
                            ),
                          ),
                          child: AnimatedBuilder(
                            animation: _textKoliagoScale,
                            builder: (context, child) {
                              return Transform.scale(
                                scale: _textKoliagoScale.value,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 28,
                                    vertical: 18,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: Colors.white.withOpacity(0.9),
                                      width: 1.5,
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.08),
                                        blurRadius: 20,
                                        offset: const Offset(0, 6),
                                        spreadRadius: 0,
                                      ),
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.04),
                                        blurRadius: 8,
                                        offset: const Offset(0, 2),
                                        spreadRadius: 0,
                                      ),
                                    ],
                                  ),
                                  child: Image.asset(
                                    'assets/koliago_logo.png',
                                    height: 64,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // Login / SignUp tabs (SignUp selected)
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
                          child: _RegisterTabChip(
                            label: 'Login',
                        selected: false,
                        onTap: () => Navigator.pushReplacement(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const LoginPage(),
                          ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RegisterTabChip(
                            label: 'SignUp',
                            selected: true,
                            onTap: () {},
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // FadeTransition(
              //   opacity: _slideOr,
              //   child: Padding(
              //     padding: const EdgeInsets.symmetric(vertical: 20),
              //     child: Text(
              //       'or',
              //       style: TextStyle(color: _lightGrey, fontSize: 15),
              //     ),
              //   ),
              // ),

              // Social icons (Google, Apple)
              SlideTransition(
                position: Tween<Offset>(
                  begin: const Offset(0, 0.3),
                  end: Offset.zero,
                ).animate(_slideSocial),
                child: FadeTransition(
                  opacity: _slideSocial,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _RegisterSocialIcon(
                        icon: Icons.g_mobiledata,
                        color: const Color(0xFF4285F4),
                        onTap: _signUpWithGoogle,
                      ),
                      const SizedBox(width: 20),
                      _RegisterSocialIcon(
                        icon: Icons.apple,
                        color: Colors.black,
                        onTap: _signUpWithApple,
                      ),
                    ],
                  ),
                ),
              ),

              // Form section
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
                            controller: firstNameController,
                            decoration: _inputDecoration('First Name'),
                            validator: _validateFirstName,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: lastNameController,
                            decoration: _inputDecoration('Last Name'),
                            validator: _validateLastName,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration('Enter Email'),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: phoneController,
                            keyboardType: TextInputType.phone,
                            decoration: _inputDecoration('Phone Number'),
                            validator: _validatePhone,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration('Enter Password').copyWith(
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
                            ),
                            validator: _validatePassword,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: confirmPasswordController,
                            obscureText: _obscureConfirmPassword,
                            decoration: _inputDecoration('Confirm Password').copyWith(
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscureConfirmPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: _lightGrey,
                                ),
                                onPressed: () => setState(
                                    () => _obscureConfirmPassword =
                                        !_obscureConfirmPassword),
                              ),
                            ),
                            validator: _validateConfirmPassword,
                          ),
                          const SizedBox(height: 20),
                          Text(
                            "Already have an account? ",
                            style: TextStyle(color: _lightGrey, fontSize: 14),
                          ),
                          const SizedBox(height: 4),
                          GestureDetector(
                            onTap: () => Navigator.pushReplacement(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const LoginPage(),
                              ),
                            ),
                            child: Text(
                              'Sign in',
                              style: TextStyle(
                                color: _primaryRed,
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                          Transform(
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateX(-0.02),
                            alignment: Alignment.center,
                            child: SizedBox(
                              height: 54,
                              child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryRed,
                              foregroundColor: Colors.white,
                              elevation: 8,
                              shadowColor: Colors.black.withOpacity(0.4),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                                onPressed: signUserUp,
                                child: const Text(
                                  'Continue',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
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
      ),
    );
  }
}

class _RegisterTabChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _RegisterTabChip({
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

class _RegisterSocialIcon extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _RegisterSocialIcon({
    required this.icon,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Transform(
      transform: Matrix4.identity()
        ..setEntry(3, 2, 0.002)
        ..rotateY(-0.05),
      alignment: Alignment.center,
      child: Material(
        color: Colors.white,
        shape: const CircleBorder(),
        elevation: 6,
        shadowColor: Colors.black.withOpacity(0.35),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: Container(
            width: 52,
            height: 52,
            alignment: Alignment.center,
            child: Icon(icon, size: 28, color: color),
          ),
        ),
      ),
    );
  }
}
