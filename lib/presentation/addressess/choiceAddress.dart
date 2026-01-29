import 'package:flutter/material.dart';
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
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => const CheckoutConfirmationPage(),
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

  /// Called when user taps the check icon. Calls API to set address as default, then refreshes list.
  Future<void> _onUseAddress(DeliveryAddressModel a) async {
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
      await _loadAddresses();
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
                              return Card(
                                margin: const EdgeInsets.only(bottom: 12),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(
                                    color: isDefault ? _redPrimary.withOpacity(0.5) : Colors.grey[200]!,
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
                                          Icon(
                                            _iconForLabel(a.label),
                                            color: _redPrimary,
                                            size: 24,
                                          ),
                                          const SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  a.label,
                                                  style: const TextStyle(
                                                    fontWeight: FontWeight.bold,
                                                    fontSize: 16,
                                                    color: Colors.black87,
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  a.street,
                                                  style: TextStyle(
                                                    fontSize: 14,
                                                    color: Colors.grey[700],
                                                    height: 1.3,
                                                  ),
                                                  maxLines: 3,
                                                  overflow: TextOverflow.ellipsis,
                                                ),
                                                if (a.city.isNotEmpty) ...[
                                                  const SizedBox(height: 4),
                                                  Text(
                                                    a.city,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[600],
                                                    ),
                                                  ),
                                                ],
                                                if (a.phone != null && a.phone!.isNotEmpty) ...[
                                                  const SizedBox(height: 6),
                                                  Text(
                                                    a.phone!,
                                                    style: TextStyle(
                                                      fontSize: 13,
                                                      color: Colors.grey[700],
                                                    ),
                                                  ),
                                                ],
                                                const SizedBox(height: 6),
                                                GestureDetector(
                                                  onTap: () {
                                                    // TODO: open map with lat/lng
                                                  },
                                                  child: const Text(
                                                    'View on map',
                                                    style: TextStyle(
                                                      color: Colors.blue,
                                                      fontSize: 13,
                                                      fontWeight: FontWeight.w500,
                                                    ),
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          // Check icon: clickable, red when is_default true, normal when false
                                          GestureDetector(
                                            onTap: () => _onUseAddress(a),
                                            child: Container(
                                              width: 28,
                                              height: 28,
                                              alignment: Alignment.center,
                                              decoration: BoxDecoration(
                                                color: isDefault ? _redPrimary : Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                                border: Border.all(
                                                  color: isDefault ? _redPrimary : Colors.grey[400]!,
                                                  width: 2,
                                                ),
                                              ),
                                              child: Icon(
                                                Icons.check,
                                                size: 18,
                                                color: isDefault ? Colors.white : Colors.grey[500],
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 8),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.end,
                                        children: [
                                          PopupMenuButton<String>(
                                            padding: EdgeInsets.zero,
                                            icon: Icon(Icons.more_horiz, color: Colors.grey[600], size: 22),
                                            onSelected: (value) {
                                              if (value == 'edit') {
                                                // TODO: edit address
                                              } else if (value == 'delete') {
                                                // TODO: delete address
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
                              );
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
  final _receiverController = TextEditingController();
  final _addressController = TextEditingController();
  final _landmarkController = TextEditingController();
  final _cityController = TextEditingController();
  String _addressType = 'Home';
  bool _saving = false;

  @override
  void dispose() {
    _receiverController.dispose();
    _addressController.dispose();
    _landmarkController.dispose();
    _cityController.dispose();
    super.dispose();
  }

  String? _validateRequired(String? value, String fieldName) {
    if (value == null || value.trim().isEmpty) return '$fieldName is required';
    return null;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _saving = true);
    try {
      final auth = AuthService();
      await auth.createAddress(
        street: _addressController.text.trim(),
        buildingNumber: '',
        apartmentNumber: '',
        city: _cityController.text.trim().isEmpty ? 'City' : _cityController.text.trim(),
        latitude: 0.0,
        longitude: 0.0,
        isDefault: false,
        receiverName: _receiverController.text.trim(),
        addressType: _addressType,
        nearbyLandmark: _landmarkController.text.trim().isEmpty ? null : _landmarkController.text.trim(),
      );
      if (!mounted) return;
      final added = DeliveryAddressModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        label: _addressType,
        street: _addressController.text.trim(),
        city: _cityController.text.trim(),
        postalCode: '',
        country: '',
        latitude: 0,
        longitude: 0,
        phone: null,
        isDefault: false,
      );
      Navigator.of(context).pop(added);
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
                        controller: _receiverController,
                        decoration: InputDecoration(
                          labelText: "Receiver's name *",
                          hintText: "Receiver's name *",
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
                        ),
                        validator: (v) => _validateRequired(v, "Receiver's name"),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _addressController,
                        decoration: InputDecoration(
                          labelText: 'Complete address *',
                          hintText: 'Complete address *',
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
                        ),
                        maxLines: 2,
                        validator: (v) => _validateRequired(v, 'Complete address'),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _cityController,
                        decoration: InputDecoration(
                          labelText: 'City',
                          hintText: 'City',
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
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: _landmarkController,
                        decoration: InputDecoration(
                          labelText: 'Nearby Landmark (optional)',
                          hintText: 'Nearby Landmark (optional)',
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
