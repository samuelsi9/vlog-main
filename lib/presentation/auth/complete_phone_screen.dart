// import 'package:flutter/material.dart';
// import 'package:intl_phone_field/intl_phone_field.dart';
// import 'package:vlog/Data/apiservices.dart';
// import 'package:vlog/Utils/api_exception.dart';
// import 'package:vlog/Utils/storage_service.dart';
// import 'package:vlog/presentation/home.dart';

// const Color _primaryRed = Color(0xFFE53E3E);
// const Color _primaryRedDark = Color(0xFFC62828);
// const Color _lightGrey = Color(0xFF9E9E9E);

// class CompletePhoneScreen extends StatefulWidget {
//   const CompletePhoneScreen({super.key});

//   @override
//   State<CompletePhoneScreen> createState() => _CompletePhoneScreenState();
// }

// class _CompletePhoneScreenState extends State<CompletePhoneScreen> {
//   final _formKey = GlobalKey<FormState>();
//   final _phoneController = TextEditingController();
//   String _completePhoneNumber = '';
//   bool _isLoading = false;

//   @override
//   void dispose() {
//     _phoneController.dispose();
//     super.dispose();
//   }

//   Future<void> _submitPhone({bool isSkipping = false}) async {
//     _formKey.currentState?.save();

//     // If user didn't enter a number and isn't skipping
//     if (_completePhoneNumber.isEmpty && !isSkipping) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please enter your phone number or skip'),
//           backgroundColor: Colors.orange,
//         ),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);
//     try {
//       Map<String, dynamic>? result;

//       if (!isSkipping && _completePhoneNumber.isNotEmpty) {
//         final auth = AuthService();
//         result = await auth.updatePhone(_completePhoneNumber);
//         if (result['user'] != null && result['user'] is Map<String, dynamic>) {
//           await StorageService.saveUser(result['user'] as Map<String, dynamic>);
//         }

//         if (!mounted) return;
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text('Phone number updated successfully'),
//             backgroundColor: Colors.green,
//           ),
//         );
//       }

//       // Navigate to main screen whether skipped or updated
//       if (!mounted) return;
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => MainScreen(
//             token: result?['user']?['id']?.toString(),
//             showWelcomeOverlay: true,
//           ),
//         ),
//       );
//     } on ApiException catch (e) {
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(UserErrorMapper.toUserMessage(e)),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 4),
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       final msg = e.toString().contains('network') ||
//               e.toString().contains('Network') ||
//               e.toString().contains('SocketException')
//           ? 'Network error. Please check your connection.'
//           : 'Failed to update phone number';
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(msg),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 4),
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }

//   InputDecoration _inputDecoration(String hint) => InputDecoration(
//         hintText: hint,
//         hintStyle: TextStyle(color: _lightGrey, fontSize: 15),
//         filled: true,
//         fillColor: Colors.grey.shade50,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide(color: Colors.grey.shade200),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: BorderSide(color: Colors.grey.shade200),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(14),
//           borderSide: const BorderSide(color: _primaryRed, width: 2),
//         ),
//         contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
//       );

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       body: SafeArea(
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.stretch,
//               children: [
//                 // Header
//                 Container(
//                   padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
//                   decoration: BoxDecoration(
//                     gradient: const LinearGradient(
//                       colors: [_primaryRed, _primaryRedDark],
//                       begin: Alignment.topLeft,
//                       end: Alignment.bottomRight,
//                     ),
//                     borderRadius: BorderRadius.circular(24),
//                     boxShadow: [
//                       BoxShadow(
//                         color: _primaryRed.withOpacity(0.4),
//                         blurRadius: 16,
//                         offset: const Offset(0, 6),
//                       ),
//                     ],
//                   ),
//                   child: const Column(
//                     children: [
//                       Icon(Icons.phone_android, color: Colors.white, size: 48),
//                       SizedBox(height: 12),
//                       Text(
//                         'Complete Your Profile',
//                         style: TextStyle(
//                           color: Colors.white,
//                           fontSize: 22,
//                           fontWeight: FontWeight.bold,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                       SizedBox(height: 6),
//                       Text(
//                         'Please add your phone number to continue',
//                         style: TextStyle(
//                           color: Colors.white70,
//                           fontSize: 14,
//                         ),
//                         textAlign: TextAlign.center,
//                       ),
//                     ],
//                   ),
//                 ),
//                 const SizedBox(height: 32),
//                 IntlPhoneField(
//                   controller: _phoneController,
//                   decoration: _inputDecoration('Phone Number (optional)'),
//                   initialCountryCode: 'US',
//                   onChanged: (phone) {
//                     _completePhoneNumber = phone.completeNumber;
//                   },
//                   onSaved: (phone) {
//                     if (phone != null) _completePhoneNumber = phone.completeNumber;
//                   },
//                 ),
//                 const SizedBox(height: 32),
//                 SizedBox(
//                   height: 54,
//                   child: ElevatedButton(
//                     onPressed: _isLoading ? null : () => _submitPhone(),
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _primaryRed,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: _primaryRed.withOpacity(0.6),
//                       elevation: 0,
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(14),
//                       ),
//                     ),
//                     child: _isLoading
//                         ? const SizedBox(
//                             height: 24,
//                             width: 24,
//                             child: CircularProgressIndicator(
//                               strokeWidth: 2,
//                               valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
//                             ),
//                           )
//                         : const Text('Submit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
//                   ),
//                 ),
//                 const SizedBox(height: 12),
//                 TextButton(
//                   onPressed: _isLoading ? null : () => _submitPhone(isSkipping: true),
//                   child: const Text(
//                     'Skip',
//                     style: TextStyle(
//                       color: _primaryRedDark,
//                       fontWeight: FontWeight.w600,
//                       fontSize: 16,
//                     ),
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'package:flutter/material.dart';
import 'package:intl_phone_field/intl_phone_field.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Utils/api_exception.dart';
import 'package:vlog/Utils/storage_service.dart';
import 'package:vlog/presentation/home.dart';
import 'package:vlog/presentation/addressess/choiceAddress.dart';

const Color _primaryRed = Color(0xFFE53E3E);
const Color _primaryRedDark = Color(0xFFC62828);
const Color _lightGrey = Color(0xFF9E9E9E);

class CompletePhoneScreen extends StatefulWidget {
  const CompletePhoneScreen({super.key});

  @override
  State<CompletePhoneScreen> createState() => _CompletePhoneScreenState();
}

class _CompletePhoneScreenState extends State<CompletePhoneScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  String _completePhoneNumber = '';
  bool _isLoading = false;

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  Future<void> _submitPhone() async {
    _formKey.currentState?.save();
    if (_completePhoneNumber.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter your phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    if (_completePhoneNumber.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a valid phone number'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = AuthService();
      final result = await auth.updatePhone(_completePhoneNumber);

      if (result['user'] != null && result['user'] is Map<String, dynamic>) {
        await StorageService.saveUser(result['user'] as Map<String, dynamic>);
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Phone number updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => ChoiceAddress(fromCheckout: true)//MainScreen(
           // token: result['user']?['id']?.toString(),
           // showWelcomeOverlay: true,
         // ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(UserErrorMapper.toUserMessage(e)),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      final msg = e.toString().contains('network') ||
              e.toString().contains('Network') ||
              e.toString().contains('SocketException')
          ? 'Network error. Please check your connection.'
          : 'Failed to update phone number';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: _primaryRed, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text('Complete Your Profile', style: TextStyle(color: Colors.black, fontSize: 20, fontWeight: FontWeight.bold),),
        centerTitle: true,
      ),
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 48),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header
                Container(
                  padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 16),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_primaryRed, _primaryRedDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: _primaryRed.withOpacity(0.4),
                        blurRadius: 16,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: const Column(
                    children: [
                      Icon(Icons.phone_android, color: Colors.white, size: 48),
                      SizedBox(height: 12),
                      Text(
                        'Complete Your Profile',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      SizedBox(height: 6),
                      Text(
                        'Please add your phone number to continue',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                IntlPhoneField(
                  controller: _phoneController,
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
                const SizedBox(height: 32),
                SizedBox(
                  height: 54,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _submitPhone,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _primaryRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: _primaryRed.withOpacity(0.6),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            height: 24,
                            width: 24,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : const Text('Submit', style: TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
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
