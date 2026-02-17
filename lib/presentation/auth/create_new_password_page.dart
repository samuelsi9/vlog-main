import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/presentation/auth/login_page.dart';

const Color _primary = Color(0xFFD32F2F);

class CreateNewPasswordPage extends StatefulWidget {
  final String? email;
  final String? resetToken;

  const CreateNewPasswordPage({
    super.key,
    this.email,
    this.resetToken,
  });

  @override
  State<CreateNewPasswordPage> createState() => _CreateNewPasswordPageState();
}

class _CreateNewPasswordPageState extends State<CreateNewPasswordPage> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _submitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'New password is required';
    }
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    return null;
  }

  String? _validateConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _submit() async {
    if (!mounted) return;
    final formState = _formKey.currentState;
    if (formState == null || !formState.validate()) return;

    final email = widget.email?.trim();
    if (email == null || email.isEmpty) {
      setState(() => _errorMessage = 'Email is required to reset password.');
      return;
    }

    setState(() => _errorMessage = null);
    if (!mounted) return;
    setState(() => _submitting = true);

    try {
      final auth = AuthService();
      final res = await auth.resetPassword(
        email: email,
        password: _passwordController.text,
        passwordConfirmation: _confirmController.text,
      );
      if (!mounted) return;
      final message = res['message']?.toString() ?? '';
      if (message == 'Password updated successfully') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Password updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (route) => false,
        );
        return;
      }
      setState(() {
        _errorMessage = message.isNotEmpty ? message : 'Reset failed. Please try again.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Reset failed. Please check your details and try again.';
      });
    } finally {
      if (mounted) {
        setState(() => _submitting = false);
      }
    }
  }

  void _goToLogin() {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LoginPage()),
      (route) => false,
    );
  }

  InputDecoration _inputDecoration(String hint, bool obscure, VoidCallback onToggle) {
    return InputDecoration(
      hintText: hint,
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
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      suffixIcon: IconButton(
        icon: Icon(
          obscure ? Icons.visibility_off : Icons.visibility,
          color: Colors.grey[600],
          size: 22,
        ),
        onPressed: onToggle,
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
          icon: const Icon(Icons.arrow_back_ios, color: Colors.black, size: 22),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Create New Password',
          style: TextStyle(
            color: Colors.black,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        centerTitle: false,
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
                Text(
                  'This password should be different from the previous password.',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey[700],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 28),
                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  decoration: _inputDecoration(
                    'New password',
                    _obscurePassword,
                    () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                  validator: _validatePassword,
                  onChanged: (_) => setState(() => _errorMessage = null),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _confirmController,
                  obscureText: _obscureConfirm,
                  decoration: _inputDecoration(
                    'Confirm password',
                    _obscureConfirm,
                    () => setState(() => _obscureConfirm = !_obscureConfirm),
                  ),
                  validator: _validateConfirm,
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
                            'Reset Password',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 40),
                Center(
                  child: Wrap(
                    alignment: WrapAlignment.center,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        'Did you succeed to reset your password? So, ',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[700],
                        ),
                      ),
                      GestureDetector(
                        onTap: _goToLogin,
                        child: const Text(
                          'Log In',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _primary,
                          ),
                        ),
                      ),
                    ],
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
