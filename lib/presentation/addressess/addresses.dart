
import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/presentation/home.dart';
import 'package:vlog/presentation/addressess/userLocation.dart';
import 'package:vlog/Utils/api_exception.dart';

const Color _red        = Color(0xFFE53E3E);
const Color _redDark    = Color(0xFFC62828);
const Color _redSoft    = Color(0xFFFFF0F0);
const Color _black      = Color(0xFF1A1A1A);
const Color _slate      = Color(0xFF6B7280);
const Color _surface    = Color(0xFFF9F9F9);

class Addresses extends StatefulWidget {
  final bool showWelcomeOverlay;
  const Addresses({super.key, this.showWelcomeOverlay = false});

  @override
  State<Addresses> createState() => _AddressesState();
}

class _AddressesState extends State<Addresses> {
  final _formKey = GlobalKey<FormState>();
  final buildingNumberController = TextEditingController();
  bool isDefault = false;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  double? _currentLat;
  double? _currentLng;

  @override
  void dispose() {
    buildingNumberController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;
    if (_currentLat == null || _currentLng == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_off, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Expanded(child: Text('Please set your location first.')),
            ],
          ),
          backgroundColor: Colors.orange[700],
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = AuthService();
      await auth.createAddress(
        street: 'for now not yet',
        buildingNumber: buildingNumberController.text.trim(),
        apartmentNumber: 'for now not yet',
        city: 'for now not yet',
        latitude: _currentLat!,
        longitude: _currentLng!,
        isDefault: isDefault,
        label: 'Home',
        addressType: 'Home',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Address saved successfully'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(
            token: null,
            showWelcomeOverlay: widget.showWelcomeOverlay,
          ),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(UserErrorMapper.toUserMessage(e)),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String message = 'Failed to save address';
      if (e.toString().contains('network') ||
          e.toString().contains('Network') ||
          e.toString().contains('SocketException')) {
        message = 'Network error. Please check your connection.';
      } else {
        message = e.toString().replaceAll('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _useCurrentLocation() async {
    setState(() => _isGettingLocation = true);
    try {
      final position = await getUserLocation();
      if (!mounted) return;
      setState(() {
        _currentLat = position.latitude;
        _currentLng = position.longitude;
        _isGettingLocation = false;
      });
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.location_on, color: Colors.white, size: 18),
              SizedBox(width: 10),
              Text('Location set successfully!'),
            ],
          ),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGettingLocation = false);
      String message = 'Could not get location.';
      if (e.toString().contains('permission denied')) {
        message = 'Location permission denied. Please allow access in Settings.';
      } else if (e.toString().contains('disabled')) {
        message = 'Location services are off. Please turn on GPS.';
      } else {
        message = e.toString().replaceAll('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          duration: const Duration(seconds: 4),
        ),
      );
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
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: _surface,
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: const Icon(Icons.arrow_back_ios_new, color: _black, size: 16),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Add Address',
          style: TextStyle(
            color: _black,
            fontWeight: FontWeight.w800,
            fontSize: 20,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [

              // ── Header banner ──────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_red, _redDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: _red.withOpacity(0.35),
                      blurRadius: 16,
                      offset: const Offset(0, 6),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: const Icon(
                        Icons.location_on,
                        color: Colors.white,
                        size: 28,
                      ),
                    ),
                    const SizedBox(width: 16),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Delivery Address',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.3,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Set where you want your order delivered',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ── Building name label ────────────────────────────
              const Text(
                'Building Name',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _black,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),

              // ── Building name field ────────────────────────────
              TextFormField(
                controller: buildingNumberController,
                decoration: InputDecoration(
                  hintText: 'e.g. Sunrise Tower, Block B',
                  hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
                  prefixIcon: Icon(Icons.apartment_outlined, color: _slate, size: 20),
                  filled: true,
                  fillColor: _surface,
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
                    borderSide: const BorderSide(color: _red, width: 2),
                  ),
                  errorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _red),
                  ),
                  focusedErrorBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                    borderSide: const BorderSide(color: _red, width: 2),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 16),
                ),
                validator: (v) => _validateRequired(v, 'Building name'),
              ),

              const SizedBox(height: 24),

              // ── Location section label ─────────────────────────
              const Text(
                'Your Location',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _black,
                  letterSpacing: -0.2,
                ),
              ),
              const SizedBox(height: 8),

              // ── Location card ──────────────────────────────────
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_currentLat != null && _currentLng != null)
                      ? Colors.green.withOpacity(0.06)
                      : _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: (_currentLat != null && _currentLng != null)
                        ? Colors.green.shade300
                        : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: (_currentLat != null && _currentLng != null)
                                ? Colors.green.withOpacity(0.12)
                                : _redSoft,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            _currentLat != null && _currentLng != null
                                ? Icons.location_on
                                : Icons.my_location,
                            color: _currentLat != null && _currentLng != null
                                ? Colors.green
                                : _red,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _currentLat != null && _currentLng != null
                                    ? 'Location confirmed'
                                    : 'No location set',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: _currentLat != null && _currentLng != null
                                      ? Colors.green[700]
                                      : _black,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _currentLat != null && _currentLng != null
                                    ? '${_currentLat!.toStringAsFixed(5)}, ${_currentLng!.toStringAsFixed(5)}'
                                    : 'Tap below to use your GPS position',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: _slate,
                                  fontFamily: _currentLat != null ? 'monospace' : null,
                                ),
                              ),
                            ],
                          ),
                        ),
                        if (_currentLat != null && _currentLng != null)
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                              color: Colors.green.withOpacity(0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.check,
                              color: Colors.green,
                              size: 16,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // ── Location button ────────────────────────
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton.icon(
                        onPressed: _isGettingLocation ? null : _useCurrentLocation,
                        icon: _isGettingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Icon(
                                _currentLat != null && _currentLng != null
                                    ? Icons.refresh
                                    : Icons.my_location,
                                size: 18,
                              ),
                        label: Text(
                          _isGettingLocation
                              ? 'Getting your position...'
                              : (_currentLat != null && _currentLng != null
                                  ? 'Update location'
                                  : 'Use current location'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _red,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _red.withOpacity(0.5),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              // ── Default address toggle ─────────────────────────
              Container(
                decoration: BoxDecoration(
                  color: isDefault ? _redSoft : _surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDefault ? _red.withOpacity(0.3) : Colors.grey.shade200,
                    width: 1.5,
                  ),
                ),
                child: SwitchListTile.adaptive(
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 16, vertical: 4),
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDefault ? _redSoft : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.home_outlined,
                      color: isDefault ? _red : _slate,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    'Set as default',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: isDefault ? _red : _black,
                    ),
                  ),
                  subtitle: Text(
                    'Use as your main delivery address',
                    style: TextStyle(
                      fontSize: 12,
                      color: _slate,
                    ),
                  ),
                  value: isDefault,
                  onChanged: (value) => setState(() => isDefault = value),
                  activeColor: _red,
                ),
              ),

              const SizedBox(height: 32),

              // ── Save button ────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 56,
                child: Container(
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_red, _redDark],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: _red.withOpacity(0.4),
                        blurRadius: 12,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: _isLoading ? null : _saveAddress,
                      borderRadius: BorderRadius.circular(16),
                      child: Center(
                        child: _isLoading
                            ? const SizedBox(
                                height: 24,
                                width: 24,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.save_alt_rounded,
                                      color: Colors.white, size: 20),
                                  SizedBox(width: 10),
                                  Text(
                                    'Save Address',
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontSize: 17,
                                      fontWeight: FontWeight.w700,
                                      letterSpacing: -0.3,
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
        ),
      ),
    );
  }
}
// import 'package:flutter/material.dart';
// import 'package:vlog/Data/apiservices.dart';
// import 'package:vlog/presentation/home.dart';
// import 'package:vlog/presentation/addressess/userLocation.dart';
// import 'package:vlog/Utils/api_exception.dart';
// const Color _purplePrimary = Color(0xFF7C4DFF);

// class Addresses extends StatefulWidget {
//   final bool showWelcomeOverlay;

//   const Addresses({super.key, this.showWelcomeOverlay = false});

//   @override
//   State<Addresses> createState() => _AddressesState();
// }

// class _AddressesState extends State<Addresses> {
//   final _formKey = GlobalKey<FormState>();
//   final buildingNumberController = TextEditingController();
//   bool isDefault = false;
//   bool _isLoading = false;
//   bool _isGettingLocation = false;
//   double? _currentLat;
//   double? _currentLng;

//   @override
//   void dispose() {
//     buildingNumberController.dispose();
//     super.dispose();
//   }

//   String? _validateRequired(String? value, String fieldName) {
//     if (value == null || value.trim().isEmpty) return '$fieldName is required';
//     return null;
//   }

//   Future<void> _saveAddress() async {
//     if (!_formKey.currentState!.validate()) return;
//     if (_currentLat == null || _currentLng == null) {
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Please use "Use current location" to set your position for delivery.'),
//           backgroundColor: Colors.orange,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//       return;
//     }

//     setState(() => _isLoading = true);
//     try {
//       final auth = AuthService();
//       await auth.createAddress(
//         street: 'for now not yet',
//         buildingNumber: buildingNumberController.text.trim(),
//         apartmentNumber: 'for now not yet',
//         city: 'for now not yet',
//         latitude: _currentLat!,
//         longitude: _currentLng!,
//         isDefault: isDefault,
//         label: 'Home',
//         addressType: 'Home',
//       );
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         const SnackBar(
//           content: Text('Address saved successfully'),
//           backgroundColor: Colors.green,
//         ),
//       );
//       Navigator.pushReplacement(
//         context,
//         MaterialPageRoute(
//           builder: (_) => MainScreen(
//             token: null,
//             showWelcomeOverlay: widget.showWelcomeOverlay,
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
//       String message = 'Failed to save address';
//       if (e.toString().contains('network') ||
//           e.toString().contains('Network') ||
//           e.toString().contains('SocketException')) {
//         message = 'Network error. Please check your connection.';
//       } else {
//         message = e.toString().replaceAll('Exception: ', '');
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red,
//           duration: const Duration(seconds: 4),
//         ),
//       );
//     } finally {
//       if (mounted) setState(() => _isLoading = false);
//     }
//   }
//   Future<void> _useCurrentLocation() async {
//     setState(() => _isGettingLocation = true);
//     try {
//       final position = await getUserLocation();
//       if (!mounted) return;
//       setState(() {
//         _currentLat = position.latitude;
//         _currentLng = position.longitude;
//         _isGettingLocation = false;
//       });
//       if (!mounted) return;
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: const Text('Current position set. You can now save your address.'),
//           backgroundColor: Colors.green,
//           behavior: SnackBarBehavior.floating,
//         ),
//       );
//     } catch (e) {
//       if (!mounted) return;
//       setState(() => _isGettingLocation = false);
//       String message = 'Could not get location.';
//       if (e.toString().contains('permission denied')) {
//         message = 'Location permission denied. Please allow access in Settings to use your current position.';
//       } else if (e.toString().contains('disabled')) {
//         message = 'Location services are off. Please turn on GPS to use your current position.';
//       } else {
//         message = e.toString().replaceAll('Exception: ', '');
//       }
//       ScaffoldMessenger.of(context).showSnackBar(
//         SnackBar(
//           content: Text(message),
//           backgroundColor: Colors.red,
//           behavior: SnackBarBehavior.floating,
//           duration: const Duration(seconds: 4),
//         ),
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
   
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: const Text(
//           'Address details',
//           style: TextStyle(
//             color: Colors.black87,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         centerTitle: true,
//       ),
//       body: Form(
//         key: _formKey,
//         child: SingleChildScrollView(
//           padding: const EdgeInsets.all(24),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               _field(
//                 controller: buildingNumberController,
//                 label: 'building_name',
//                 hint: 'e.g. Well wwwarir',
//                 validator: (v) => _validateRequired(v, 'building_number'),
//               ),
//               const SizedBox(height: 24),
//               // Use current location – like real delivery apps
//               Container(
//                 padding: const EdgeInsets.all(16),
//                 decoration: BoxDecoration(
//                   color: (_currentLat != null && _currentLng != null)
//                       ? Colors.green.withOpacity(0.08)
//                       : Colors.grey.withOpacity(0.08),
//                   borderRadius: BorderRadius.circular(12),
//                   border: Border.all(
//                     color: (_currentLat != null && _currentLng != null)
//                         ? Colors.green
//                         : Colors.grey.shade300,
//                     width: 1,
//                   ),
//                 ),
//                 child: Column(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Row(
//                       children: [
//                         Icon(
//                           _currentLat != null && _currentLng != null
//                               ? Icons.location_on
//                               : Icons.my_location,
//                           color: _currentLat != null && _currentLng != null
//                               ? Colors.green
//                               : _purplePrimary,
//                           size: 24,
//                         ),
//                         const SizedBox(width: 12),
//                         Expanded(
//                           child: Text(
//                             _currentLat != null && _currentLng != null
//                                 ? 'Location set for delivery'
//                                 : 'We need your position to deliver to this address.',
//                             style: TextStyle(
//                               fontSize: 14,
//                               color: Colors.grey[800],
//                               fontWeight: FontWeight.w500,
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                     if (_currentLat != null && _currentLng != null)
//                       Padding(
//                         padding: const EdgeInsets.only(top: 8),
//                         child: Text(
//                           '${_currentLat!.toStringAsFixed(5)}, ${_currentLng!.toStringAsFixed(5)}',
//                           style: TextStyle(
//                             fontSize: 12,
//                             color: Colors.grey[600],
//                             fontFamily: 'monospace',
//                           ),
//                         ),
//                       ),
//                     const SizedBox(height: 12),
//                     SizedBox(
//                       width: double.infinity,
//                       child: OutlinedButton.icon(
//                         onPressed: _isGettingLocation ? null : _useCurrentLocation,
//                         icon: _isGettingLocation
//                             ? const SizedBox(
//                                 width: 18,
//                                 height: 18,
//                                 child: CircularProgressIndicator(strokeWidth: 2),
//                               )
//                             : Icon(
//                                 _currentLat != null && _currentLng != null
//                                     ? Icons.refresh
//                                     : Icons.my_location,
//                                 size: 20,
//                                 color: _purplePrimary,
//                               ),
//                         label: Text(
//                           _isGettingLocation
//                               ? 'Getting your position...'
//                               : (_currentLat != null && _currentLng != null
//                                   ? 'Update current location'
//                                   : 'Use current location'),
//                           style: const TextStyle(
//                             fontWeight: FontWeight.w600,
//                             color: _purplePrimary,
//                           ),
//                         ),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: _purplePrimary,
//                           side: const BorderSide(color: _purplePrimary),
//                           padding: const EdgeInsets.symmetric(vertical: 12),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ),
//               const SizedBox(height: 20),
//               SwitchListTile(
//                 title: const Text('is_default'),
//                 subtitle: const Text('Use as default delivery address'),
//                 value: isDefault,
//                 onChanged: (value) => setState(() => isDefault = value),
//                 activeThumbColor: _purplePrimary,
//               ),
//               const SizedBox(height: 28),
//               SizedBox(
//                 width: double.infinity,
//                 height: 52,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _saveAddress,
//                   style: ElevatedButton.styleFrom(
//                     backgroundColor: _purplePrimary,
//                     foregroundColor: Colors.white,
//                     shape: RoundedRectangleBorder(
//                       borderRadius: BorderRadius.circular(12),
//                     ),
//                     elevation: 0,
//                   ),
//                   child: _isLoading
//                       ? const SizedBox(
//                           height: 24,
//                           width: 24,
//                           child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                         )
//                       : const Text('Save address'),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _field({
//     required TextEditingController controller,
//     required String label,
//     required String hint,
//     String? Function(String?)? validator,
//     TextInputType? keyboardType,
//   }) {
//     return TextFormField(
//       controller: controller,
//       decoration: InputDecoration(
//         labelText: label,
//         hintText: hint,
//         border: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         enabledBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: BorderSide(color: Colors.grey[300]!),
//         ),
//         focusedBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: _purplePrimary, width: 2),
//         ),
//         errorBorder: OutlineInputBorder(
//           borderRadius: BorderRadius.circular(12),
//           borderSide: const BorderSide(color: Colors.red),
//         ),
//       ),
//       keyboardType: keyboardType,
//       validator: validator,
//     );
//   }
// }
