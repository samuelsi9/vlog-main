import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Models/delivery_address_model.dart';
import 'package:vlog/presentation/screen/checkout_confirmation_page.dart';

// Color palette: red, yellow, white, black
const Color _redPrimary = Color(0xFFE53E3E);
const Color _yellowLight = Color(0xFFFFF8E1);
const Color _yellowAccent = Color(0xFFFFC107);
const Color _black = Color(0xFF000000);

class ChoiceAddress extends StatefulWidget {
  /// When true, show "Continue to checkout" and navigate to checkout after selecting address.
  final bool fromCheckout;

  const ChoiceAddress({super.key, this.fromCheckout = false});

  @override
  State<ChoiceAddress> createState() => _ChoiceAddressState();
}

class _ChoiceAddressState extends State<ChoiceAddress> {
  List<DeliveryAddressModel> _addresses = [];
  String? _selectedId; // id of address selected for delivery
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final auth = AuthService();
      final list = await auth.allMyAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        for (final a in list) {
          if (a.isDefault) {
            _selectedId = a.id;
            break;
          }
        }
        _selectedId ??= list.isNotEmpty ? list.first.id : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString().replaceAll('Exception: ', '');
        _loading = false;
      });
    }
  }

  void _openAddAddress() async {
    final added = await showModalBottomSheet<DeliveryAddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const _AddressDetailsSheet(),
    );
    if (added != null && mounted) {
      setState(() {
        _addresses = [..._addresses, added];
        _selectedId = added.id;
      });
    }
  }

  void _continueToCheckout() {
    if (_selectedId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select an address for delivery'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    final selectedAddress = _addresses.firstWhere((a) => a.id == _selectedId);
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => CheckoutConfirmationPage(selectedAddress: selectedAddress),
      ),
    );
  }

  IconData _iconForLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('home')) return Icons.home;
    if (lower.contains('office')) return Icons.work;
    if (lower.contains('friend')) return Icons.person;
    return Icons.location_on;
  }

  /// Map thumbnail - circular placeholder with location pin
  Widget _mapThumbnail(double lat, double lng) {
    return Container(
      width: 56,
      height: 56,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Colors.grey[200],
        border: Border.all(color: Colors.grey[300]!, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipOval(
        child: Stack(
          fit: StackFit.expand,
          children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [Colors.grey[300]!, Colors.grey[200]!],
                ),
              ),
            ),
            Center(
              child: Icon(Icons.location_on, color: _redPrimary, size: 28),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(DeliveryAddressModel a, bool isDefault) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        GestureDetector(
          onTap: () => _onUseAddress(a),
          behavior: HitTestBehavior.opaque,
          child: Card(
            margin: const EdgeInsets.only(bottom: 16, top: 8),
            shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
            side: BorderSide(
              color: isDefault ? _redPrimary : Colors.grey[200]!,
              width: isDefault ? 2 : 1,
            ),
          ),
          elevation: 2,
          shadowColor: Colors.black.withOpacity(0.06),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFE0B2),
                          shape: BoxShape.circle,
                        ),
                            child: Icon(_iconForLabel(a.label), color: _redPrimary, size: 22),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  a.label,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 17,
                                    color: Colors.black87,
                                  ),
                                ),
                                if (a.buildingNumber.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    a.buildingNumber,
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey[800],
                                      height: 1.3,
                                    ),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                                if (a.phone != null && a.phone!.isNotEmpty) ...[
                                  const SizedBox(height: 4),
                                  Text(
                                    a.phone!,
                                    style: TextStyle(
                                      fontSize: 13,
                                      color: Colors.grey[700],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 12),
                    _mapThumbnail(a.latitude, a.longitude),
                    PopupMenuButton<String>(
                      padding: EdgeInsets.zero,
                      icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
                      onSelected: (value) {
                        if (value == 'edit') {
                          // TODO: edit address
                        } else if (value == 'delete') {
                          _onDeleteAddress(a);
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(value: 'edit', child: Text('Edit')),
                        const PopupMenuItem(value: 'delete', child: Text('Delete')),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        ),
        if (isDefault)
          Positioned(
            top: 10,
            right: 10,
            child: Transform.rotate(
              angle: 0.785398,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
                decoration: BoxDecoration(
                  color: _redPrimary,
                  borderRadius: BorderRadius.circular(2),
                  boxShadow: [
                    BoxShadow(
                      color: _redPrimary.withOpacity(0.4),
                      blurRadius: 4,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: const Text(
                  'SELECTED',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ),
      ],
    );
  }

  /// Optimistic update: tap anywhere on card to set as default. No refetch, no reorder.
  Future<void> _onUseAddress(DeliveryAddressModel a) async {
    if (a.isDefault) return;
    final previousDefaultId = _selectedId;
    setState(() {
      _addresses = _addresses
          .map((addr) => addr.copyWith(isDefault: addr.id == a.id))
          .toList();
      _selectedId = a.id;
    });
    try {
      final auth = AuthService();
      await auth.useAddress(a.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Address set for delivery'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addresses = _addresses
            .map((addr) => addr.copyWith(isDefault: addr.id == previousDefaultId))
            .toList();
        _selectedId = previousDefaultId;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Future<void> _onDeleteAddress(DeliveryAddressModel a) async {
    try {
      final auth = AuthService();
      final response = await auth.deleteAddress(a.id);
      if (!mounted) return;
      final message = response['message']?.toString() ?? '';
      // Always refresh the list after delete
      await _loadAddresses();
      if (!mounted) return;
      if (message == 'Address deleted successfully') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address deleted successfully'),
            backgroundColor: Colors.green,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message.isNotEmpty ? message : 'Address could not be deleted'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new, color: _black, size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: const Text(
          'Addresses',
          style: TextStyle(
            color: _black,
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        centerTitle: true,
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: _black),
            onSelected: (value) {
              if (value == 'refresh') _loadAddresses();
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'refresh', child: Text('Refresh list')),
            ],
          ),
        ],
      ),
      body: Column(
        children: [
          // Add New Address button
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
            child: Material(
              color: _yellowLight,
              borderRadius: BorderRadius.circular(12),
              child: InkWell(
                onTap: _openAddAddress,
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: _redPrimary.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.add, color: _redPrimary, size: 22),
                      ),
                      const SizedBox(width: 14),
                      const Text(
                        'Add New Address',
                        style: TextStyle(
                          color: _redPrimary,
                          fontWeight: FontWeight.w600,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          // List
          Expanded(
            child: _loading
                ? const Center(child: CircularProgressIndicator(color: _redPrimary))
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.error_outline, size: 48, color: Colors.grey[600]),
                              const SizedBox(height: 12),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[700]),
                              ),
                              const SizedBox(height: 16),
                              TextButton(
                                onPressed: _loadAddresses,
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : _addresses.isEmpty
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.location_off_outlined, size: 64, color: Colors.grey[400]),
                                const SizedBox(height: 16),
                                Text(
                                  'No addresses yet',
                                  style: TextStyle(
                                    fontSize: 18,
                                    color: Colors.grey[700],
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap "Add New Address" to add one',
                                  style: TextStyle(color: Colors.grey[600], fontSize: 14),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            itemCount: _addresses.length,
                            itemBuilder: (context, index) {
                              final a = _addresses[index];
                              final isDefault = a.isDefault;
                              return _buildAddressCard(a, isDefault);
                            },
                          ),
          ),
          // Continue to checkout (only when fromCheckout)
          if (widget.fromCheckout && _addresses.isNotEmpty)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.06),
                    blurRadius: 10,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _selectedId != null ? _continueToCheckout : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _redPrimary,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor: Colors.grey[300],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    child: const Text('Continue to checkout'),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Address details form as bottom sheet (receiver name, complete address, landmark, address type).
class _AddressDetailsSheet extends StatefulWidget {
  const _AddressDetailsSheet();

  @override
  State<_AddressDetailsSheet> createState() => _AddressDetailsSheetState();
}

class _AddressDetailsSheetState extends State<_AddressDetailsSheet> {
  final _formKey = GlobalKey<FormState>();
  final _buildingController = TextEditingController();
  final _latitudeController = TextEditingController();
  final _longitudeController = TextEditingController();
  String _addressType = 'Home';
  bool _saving = false;
  bool _gettingLocation = false;
  bool _hasCurrentLocation = false;

  @override
  void dispose() {
    _buildingController.dispose();
    _latitudeController.dispose();
    _longitudeController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _gettingLocation = true);
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location services are disabled. Please enable them.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission permanently denied. You can set it in device settings.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      if (permission == LocationPermission.denied && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Location permission is required to use your current location.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      final position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      if (!mounted) return;
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
        _hasCurrentLocation = true;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Location set from your current position'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not get location: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  double _parseLatLng(TextEditingController c, double fallback) {
    final t = c.text.trim();
    if (t.isEmpty) return fallback;
    return double.tryParse(t) ?? fallback;
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  InputDecoration _addressFieldDecoration(String labelText, String hintText) {
    return InputDecoration(
      labelText: labelText,
      hintText: hintText,
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
        borderSide: const BorderSide(color: _redPrimary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Colors.red),
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please fill in Building number'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }
    if (!_hasCurrentLocation) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please tap "Use my current location" to set your delivery position'),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    setState(() => _saving = true);
    try {
      final auth = AuthService();
      final lat = _parseLatLng(_latitudeController, 0.0);
      final lng = _parseLatLng(_longitudeController, 0.0);
      await auth.createAddress(
        street: 'for now not yet',
        buildingNumber: _buildingController.text.trim(),
        apartmentNumber: 'for now not yet',
        city: 'for now not yet',
        latitude: lat,
        longitude: lng,
        isDefault: false,
        receiverName: null,
        label: _addressType,
        addressType: _addressType,
      );
      if (!mounted) return;
      // Fetch all addresses from API - the new one will have the real ID
      final list = await auth.allMyAddresses();
      if (!mounted) return;
      if (list.isNotEmpty) {
        Navigator.of(context).pop(list.last);
      } else {
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', '')),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      initialChildSize: 0.85,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // Handle bar
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                // Header
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Address details',
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Complete address would assist us in serving you better',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.grey[200],
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                    children: [
                      const Text(
                        'Select address type',
                        style: TextStyle(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _typeChip('Home', Icons.home),
                            const SizedBox(width: 10),
                            _typeChip('Office', Icons.work),
                            const SizedBox(width: 10),
                            _typeChip("Friend's house", Icons.person),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                      TextFormField(
                        controller: _buildingController,
                        decoration: _addressFieldDecoration('Building number *', 'Building number'),
                        validator: (v) => _validateRequired(v, 'Building number'),
                      ),
                      const SizedBox(height: 20),
                      OutlinedButton.icon(
                        onPressed: _gettingLocation ? null : _getCurrentLocation,
                        icon: _gettingLocation
                            ? const SizedBox(
                                width: 20,
                                height: 20,
                                child: CircularProgressIndicator(strokeWidth: 2),
                              )
                            : Icon(Icons.my_location, size: 20, color: _hasCurrentLocation ? Colors.green : _redPrimary),
                        label: Text(
                          _gettingLocation ? 'Getting location...' : 'Use my current location',
                          style: TextStyle(color: _hasCurrentLocation ? Colors.green : _redPrimary, fontWeight: _hasCurrentLocation ? FontWeight.w600 : null),
                        ),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: _hasCurrentLocation ? Colors.green : _redPrimary,
                          side: BorderSide(color: _hasCurrentLocation ? Colors.green : _redPrimary),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _saving ? null : _save,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _redPrimary,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _saving
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
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _typeChip(String label, IconData icon) {
    final isSelected = _addressType == label;
    return GestureDetector(
      onTap: () => setState(() => _addressType = label),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? _yellowLight : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? _yellowAccent : Colors.grey[300]!,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20, color: _redPrimary),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? _redPrimary : Colors.grey[700],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
