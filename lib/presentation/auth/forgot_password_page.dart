import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/presentation/auth/create_new_password_page.dart';

// Match app theme (red accent)
const Color _primary = Color(0xFFD32F2F);

class ForgotPasswordPage extends StatefulWidget {
  const ForgotPasswordPage({super.key});

  @override
  State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
}

class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Email is required';
    }
    final email = value.trim();
    final regex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    if (!regex.hasMatch(email)) {
      return 'Enter a valid email address';
    }
    return null;
  }

  Future<void> _submit() async {
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final email = _emailController.text.trim();
    if (email.isEmpty) return;
    if (!mounted) return;
    setState(() {
      _errorMessage = null;
      _submitting = true;
    });

    Map<String, dynamic> checkRes = {};
    try {
      final auth = AuthService();
      checkRes = await auth.checkEmail(email: email);
    } catch (e, stack) {
      debugPrint('ForgotPassword checkEmail error: $e');
      debugPrint('$stack');
      if (mounted) {
        setState(() {
          _errorMessage = 'Request failed. Please check the email and try again.';
        });
      }
      if (mounted) setState(() => _submitting = false);
      return;
    }

    if (!mounted) return;
    final exists = checkRes['exists'] == true;
    if (!exists) {
      setState(() {
        _errorMessage = 'This email is not registered. Please check and try again.';
        _submitting = false;
      });
      return;
    }

    if (!mounted) return;
    try {
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => CreateNewPasswordPage(
            email: email,
            resetToken: null,
          ),
        ),
      );
    } catch (e, stack) {
      debugPrint('ForgotPassword navigation error: $e');
      debugPrint('$stack');
      if (mounted) {
        setState(() {
          _errorMessage = 'Something went wrong. Please try again.';
        });
      }
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.help_outline, color: Colors.black, size: 26),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Contact support for help')),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 8),
                const Text(
                  'Reset Password',
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Enter the email address associated with your account and we'll send an email with confirmation to reset your password.",
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 32),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  autocorrect: false,
                  decoration: InputDecoration(
                    hintText: 'example124@gmail.com',
                    hintStyle: TextStyle(color: Colors.grey[400], fontSize: 16),
                    filled: true,
                    fillColor: Colors.grey[50],
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: Colors.grey.shade300),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _primary, width: 1.5),
                    ),
                    errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: Colors.red),
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 16,
                    ),
                  ),
                  validator: _validateEmail,
                  onChanged: (_) => setState(() => _errorMessage = null),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ],
                const SizedBox(height: 28),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _submitting ? null : _submit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primary,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: _submitting
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text(
                            'Continue',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
