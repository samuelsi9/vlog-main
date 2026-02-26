import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/api_exception.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:vlog/presentation/addressess/addresses.dart';
import 'package:vlog/presentation/home.dart';
import 'package:vlog/presentation/auth/complete_phone_screen.dart';
import 'package:vlog/presentation/auth/login_page.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart';

// Design colors: red & white (match login)
const Color _primaryRed = Color(0xFFE53E3E);
const Color _primaryRedDark = Color(0xFFC62828);
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
  String _completePhoneNumber = '';
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

  Future<void> _signUpWithApple() async {
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
    _formKey.currentState!.save();
    if (_formKey.currentState!.validate()) {
      // Call API; show success only after API succeeds, error only on failure
      try {
        final authService = AuthService();
        final result = await authService.register(
          name: '${firstNameController.text} ${lastNameController.text}',
          email: emailController.text,
          phone: _completePhoneNumber,
          password: passwordController.text,
          role: "2",
        );

        if (result.isNotEmpty && result['user'] != null) {
          if (mounted) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const Addresses(showWelcomeOverlay: true),
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

  InputDecoration _inputDecoration(String hint, {IconData? icon}) => InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: _lightGrey, fontSize: 15),
        prefixIcon: icon != null ? Icon(icon, color: _lightGrey, size: 22) : null,
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
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      );

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
              // Gradient header: Vlog + Create Account
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
                      'Create Account',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 26,
                        fontWeight: FontWeight.bold,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Join us today and start enjoying fast delivery.',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontSize: 14,
                      ),
                      textAlign: TextAlign.center,
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

              // Or continue with + Social buttons
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
                          child: _RegisterSocialButton(
                            imageAsset: 'assets/googleLogo.png',
                            label: 'Google',
                            color: const Color(0xFF4285F4),
                            onTap: _signUpWithGoogle,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _RegisterSocialButton(
                            icon: Icons.apple,
                            label: 'Apple',
                            color: Colors.black,
                            onTap: _signUpWithApple,
                          ),
                        ),
                      ],
                    ),
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
                            decoration: _inputDecoration('First Name', icon: Icons.person_outline),
                            validator: _validateFirstName,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: lastNameController,
                            decoration: _inputDecoration('Last Name', icon: Icons.person_outline),
                            validator: _validateLastName,
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: emailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: _inputDecoration('Email Address', icon: Icons.email_outlined),
                            validator: _validateEmail,
                          ),
                          const SizedBox(height: 14),
                          IntlPhoneField(
                            controller: phoneController,
                            decoration: _inputDecoration('Phone Number'),
                            initialCountryCode: 'US',
                            onChanged: (phone) {
                              _completePhoneNumber = phone.completeNumber;
                            },
                            onSaved: (phone) {
                              if (phone != null) _completePhoneNumber = phone.completeNumber;
                            },
                            validator: (value) {
                              if (value == null || value.number.isEmpty) {
                                return 'Phone number is required';
                              }
                              if (value.number.length < 8) {
                                return 'Enter a valid phone number';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: passwordController,
                            obscureText: _obscurePassword,
                            decoration: _inputDecoration('Password', icon: Icons.lock_outline).copyWith(
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
                            decoration: _inputDecoration('Confirm your password', icon: Icons.lock_outline).copyWith(
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
                              onPressed: signUserUp,
                              child: const Text(
                                'Sign Up',
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
                                "Already have an account? ",
                                style: TextStyle(color: _lightGrey, fontSize: 14),
                              ),
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
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
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

class _RegisterSocialButton extends StatelessWidget {
  final IconData? icon;
  final String? imageAsset;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _RegisterSocialButton({
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
