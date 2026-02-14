import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/presentation/home.dart';
import 'package:vlog/presentation/addressess/userLocation.dart';
const Color _purplePrimary = Color(0xFF7C4DFF);

class Addresses extends StatefulWidget {
  const Addresses({super.key});

  @override
  State<Addresses> createState() => _AddressesState();
}

class _AddressesState extends State<Addresses> {
  final _formKey = GlobalKey<FormState>();
  final streetController = TextEditingController();
  final buildingNumberController = TextEditingController();
  final apartmentNumberController = TextEditingController();
  final cityController = TextEditingController();
  bool isDefault = false;
  bool _isLoading = false;
  bool _isGettingLocation = false;
  double? _currentLat;
  double? _currentLng;

  @override
  void dispose() {
    streetController.dispose();
    buildingNumberController.dispose();
    apartmentNumberController.dispose();
    cityController.dispose();
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
        const SnackBar(
          content: Text('Please use "Use current location" to set your position for delivery.'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final auth = AuthService();
      await auth.createAddress(
        street: streetController.text.trim(),
        buildingNumber: buildingNumberController.text.trim(),
        apartmentNumber: apartmentNumberController.text.trim(),
        city: cityController.text.trim(),
        latitude: _currentLat!,
        longitude: _currentLng!,
        isDefault: isDefault,
        addressType: 'Home',
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address saved successfully'),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => MainScreen(token: null),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      String message = 'Failed to save address';
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        message = 'Please login again';
      } else if (e.toString().contains('network') ||
          e.toString().contains('Network') ||
          e.toString().contains('SocketException')) {
        message = 'Network error. Please check your connection.';
      } else {
        message = e.toString().replaceAll('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
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
          content: const Text('Current position set. You can now save your address.'),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _isGettingLocation = false);
      String message = 'Could not get location.';
      if (e.toString().contains('permission denied')) {
        message = 'Location permission denied. Please allow access in Settings to use your current position.';
      } else if (e.toString().contains('disabled')) {
        message = 'Location services are off. Please turn on GPS to use your current position.';
      } else {
        message = e.toString().replaceAll('Exception: ', '');
      }
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
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
          icon: const Icon(Icons.arrow_back_ios_new, color: Colors.black87, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Address details',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _field(
                controller: streetController,
                label: 'street',
                hint: 'e.g. qqaa ila',
                validator: (v) => _validateRequired(v, 'street'),
              ),
              const SizedBox(height: 16),
              _field(
                controller: buildingNumberController,
                label: 'building_number',
                hint: 'e.g. Well wwwarir',
                validator: (v) => _validateRequired(v, 'building_number'),
              ),
              const SizedBox(height: 16),
              _field(
                controller: apartmentNumberController,
                label: 'apartment_number',
                hint: 'e.g. wall 678',
                validator: (v) => _validateRequired(v, 'apartment_number'),
              ),
              const SizedBox(height: 16),
              _field(
                controller: cityController,
                label: 'city',
                hint: 'e.g. Girne',
                validator: (v) => _validateRequired(v, 'city'),
              ),
              const SizedBox(height: 24),
              // Use current location – like real delivery apps
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: (_currentLat != null && _currentLng != null)
                      ? Colors.green.withOpacity(0.08)
                      : Colors.grey.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: (_currentLat != null && _currentLng != null)
                        ? Colors.green
                        : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(
                          _currentLat != null && _currentLng != null
                              ? Icons.location_on
                              : Icons.my_location,
                          color: _currentLat != null && _currentLng != null
                              ? Colors.green
                              : _purplePrimary,
                          size: 24,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            _currentLat != null && _currentLng != null
                                ? 'Location set for delivery'
                                : 'We need your position to deliver to this address.',
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[800],
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_currentLat != null && _currentLng != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(
                          '${_currentLat!.toStringAsFixed(5)}, ${_currentLng!.toStringAsFixed(5)}',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                            fontFamily: 'monospace',
                          ),
                        ),
                      ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton.icon(
                        onPressed: _isGettingLocation ? null : _useCurrentLocation,
                        icon: _isGettingLocation
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(
                                _currentLat != null && _currentLng != null
                                    ? Icons.refresh
                                    : Icons.my_location,
                                size: 20,
                                color: _purplePrimary,
                              ),
                        label: Text(
                          _isGettingLocation
                              ? 'Getting your position...'
                              : (_currentLat != null && _currentLng != null
                                  ? 'Update current location'
                                  : 'Use current location'),
                          style: const TextStyle(
                            fontWeight: FontWeight.w600,
                            color: _purplePrimary,
                          ),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _purplePrimary,
                          side: const BorderSide(color: _purplePrimary),
                          padding: const EdgeInsets.symmetric(vertical: 12),
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
              SwitchListTile(
                title: const Text('is_default'),
                subtitle: const Text('Use as default delivery address'),
                value: isDefault,
                onChanged: (value) => setState(() => isDefault = value),
                activeThumbColor: _purplePrimary,
              ),
              const SizedBox(height: 28),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveAddress,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _purplePrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Save address'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _field({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _purplePrimary, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.red),
        ),
      ),
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}
