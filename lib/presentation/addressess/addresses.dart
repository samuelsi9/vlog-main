import 'package:flutter/material.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/presentation/home.dart';

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
  final latitudeController = TextEditingController();
  final longitudeController = TextEditingController();
  bool isDefault = false;
  bool _isLoading = false;

  @override
  void dispose() {
    streetController.dispose();
    buildingNumberController.dispose();
    apartmentNumberController.dispose();
    cityController.dispose();
    latitudeController.dispose();
    longitudeController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  String? _validateLatitude(String? value) {
    if (value == null || value.trim().isEmpty) return 'latitude is required';
    final v = double.tryParse(value.trim());
    if (v == null) return 'Enter a valid number';
    if (v < -90 || v > 90) return 'Must be between -90 and 90';
    return null;
  }

  String? _validateLongitude(String? value) {
    if (value == null || value.trim().isEmpty) return 'longitude is required';
    final v = double.tryParse(value.trim());
    if (v == null) return 'Enter a valid number';
    if (v < -180 || v > 180) return 'Must be between -180 and 180';
    return null;
  }

  Future<void> _saveAddress() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    try {
      final lat = double.parse(latitudeController.text.trim());
      final lng = double.parse(longitudeController.text.trim());
      final auth = AuthService();
      await auth.createAddress(
        street: streetController.text.trim(),
        buildingNumber: buildingNumberController.text.trim(),
        apartmentNumber: apartmentNumberController.text.trim(),
        city: cityController.text.trim(),
        latitude: lat,
        longitude: lng,
        isDefault: isDefault,
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
              const SizedBox(height: 16),
              _field(
                controller: latitudeController,
                label: 'latitude',
                hint: 'e.g. -898.598761',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateLatitude,
              ),
              const SizedBox(height: 16),
              _field(
                controller: longitudeController,
                label: 'longitude',
                hint: 'e.g. -968.598761',
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                validator: _validateLongitude,
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
