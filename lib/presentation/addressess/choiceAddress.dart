


import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:vlog/Data/apiservices.dart';
import 'package:vlog/Models/delivery_address_model.dart';
import 'package:vlog/presentation/screen/delivery_schedule_page.dart';
import 'package:vlog/presentation/screen/payment_method_selection_page.dart';

const Color _red      = Color(0xFFE53E3E);
const Color _redDark  = Color(0xFFC62828);
const Color _redSoft  = Color(0xFFFFF0F0);
const Color _black    = Color(0xFF1A1A1A);
const Color _slate    = Color(0xFF6B7280);
const Color _surface  = Color(0xFFF9F9F9);

// ─────────────────────────────────────────────
//  Snackbar helper
// ─────────────────────────────────────────────
enum _SnackType { success, warning, error, info }

void _showSnack(
  BuildContext context,
  String message, {
  _SnackType type = _SnackType.info,
  Duration duration = const Duration(seconds: 3),
}) {
  final config = {
    _SnackType.success: (icon: Icons.check_circle_rounded, bg: const Color(0xFF1B5E20), accent: const Color(0xFF4CAF50)),
    _SnackType.warning: (icon: Icons.info_rounded,         bg: const Color(0xFF4A3000), accent: const Color(0xFFFFC107)),
    _SnackType.error:   (icon: Icons.error_rounded,        bg: const Color(0xFF5C0A0A), accent: const Color(0xFFEF5350)),
    _SnackType.info:    (icon: Icons.info_outline_rounded, bg: const Color(0xFF0D2340), accent: const Color(0xFF42A5F5)),
  }[type]!;

  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        duration: duration,
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.transparent,
        elevation: 0,
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
        content: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: config.bg,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: config.accent.withOpacity(0.4)),
            boxShadow: [
              BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 36, height: 36,
                decoration: BoxDecoration(color: config.accent.withOpacity(0.15), shape: BoxShape.circle),
                child: Icon(config.icon, color: config.accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(message, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500, height: 1.4)),
              ),
            ],
          ),
        ),
      ),
    );
}

// ─────────────────────────────────────────────
//  Main page
// ─────────────────────────────────────────────
class ChoiceAddress extends StatefulWidget {
  final bool fromCheckout;
  const ChoiceAddress({super.key, this.fromCheckout = false});

  @override
  State<ChoiceAddress> createState() => _ChoiceAddressState();
}

class _ChoiceAddressState extends State<ChoiceAddress> {
  List<DeliveryAddressModel> _addresses = [];
  String? _selectedId;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadAddresses();
  }

  Future<void> _loadAddresses() async {
    setState(() { _loading = true; _error = null; });
    try {
      final list = await AuthService().allMyAddresses();
      if (!mounted) return;
      setState(() {
        _addresses = list;
        for (final a in list) {
          if (a.isDefault) { _selectedId = a.id; break; }
        }
        _selectedId ??= list.isNotEmpty ? list.first.id : null;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = "Couldn't load your addresses.\nPlease check your connection and try again.";
        _loading = false;
      });
    }
  }

  void _openAddAddress() async {
    final added = await showModalBottomSheet<DeliveryAddressModel>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _AddressDetailsSheet(),
    );
    if (added != null && mounted) {
      setState(() {
        _addresses = [..._addresses, added];
        _selectedId = added.id;
      });
    }
  }

  Future<void> _continueToCheckout() async {
    if (_selectedId == null) {
      _showSnack(context, 'Please choose a delivery address first.', type: _SnackType.warning);
      return;
    }
    final selectedAddress = _addresses.firstWhere((a) => a.id == _selectedId);
    final result = await Navigator.push(context, MaterialPageRoute(builder: (_) => const DeliverySchedulePage()));
    if (result == null || !mounted) return;
    final date = result['date'] as DateTime?;
    final timeSlot = result['timeSlot'] as String?;
    if (date == null || timeSlot == null) return;
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => PaymentMethodSelectionPage(
          selectedAddress: selectedAddress,
          initialDate: date,
          initialTimeSlot: timeSlot,
        ),
      ),
    );
  }

  Future<void> _onUseAddress(DeliveryAddressModel a) async {
    if (a.id == _selectedId) return;
    final previousId = _selectedId;
    setState(() {
      _addresses = _addresses.map((addr) => addr.copyWith(isDefault: addr.id == a.id)).toList();
      _selectedId = a.id;
    });
    try {
      await AuthService().useAddress(a.id);
      if (!mounted) return;
      _showSnack(context, '${a.label} set as delivery address.', type: _SnackType.success, duration: const Duration(seconds: 2));
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _addresses = _addresses.map((addr) => addr.copyWith(isDefault: addr.id == previousId)).toList();
        _selectedId = previousId;
      });
      _showSnack(context, "Couldn't update delivery address. Please try again.", type: _SnackType.error);
    }
  }

  Future<void> _onDeleteAddress(DeliveryAddressModel a) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56, height: 56,
                decoration: BoxDecoration(color: _redSoft, shape: BoxShape.circle),
                child: const Icon(Icons.delete_outline_rounded, color: _red, size: 28),
              ),
              const SizedBox(height: 16),
              const Text('Remove address?', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _black)),
              const SizedBox(height: 10),
              Text(
                'Are you sure you want to remove "${a.label}"? This cannot be undone.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 14, color: _slate, height: 1.5),
              ),
              const SizedBox(height: 24),
              Row(children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: _slate,
                      side: BorderSide(color: Colors.grey.shade300),
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _red,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    child: const Text('Remove', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ]),
            ],
          ),
        ),
      ),
    );
    if (confirmed != true) return;
    try {
      final response = await AuthService().deleteAddress(a.id);
      if (!mounted) return;
      await _loadAddresses();
      if (!mounted) return;
      final msg = response['message']?.toString() ?? '';
      if (msg == 'Address deleted successfully') {
        _showSnack(context, '"${a.label}" removed successfully.', type: _SnackType.success);
      } else {
        _showSnack(context, "Couldn't remove this address. Try again later.", type: _SnackType.warning);
      }
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, "Something went wrong. Please try again.", type: _SnackType.error);
    }
  }

  IconData _iconForLabel(String label) {
    final l = label.toLowerCase();
    if (l.contains('home'))   return Icons.home_rounded;
    if (l.contains('office')) return Icons.work_rounded;
    if (l.contains('friend')) return Icons.person_rounded;
    return Icons.location_on_rounded;
  }

  Widget _buildAddressCard(DeliveryAddressModel a, bool isSelected) {
    return GestureDetector(
      onTap: () => _onUseAddress(a),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: isSelected ? _red : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
          boxShadow: [
            BoxShadow(
              color: isSelected
                  ? _red.withOpacity(0.10)
                  : Colors.black.withOpacity(0.05),
              blurRadius: isSelected ? 16 : 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Icon circle ───────────────────────────
              Container(
                width: 48, height: 48,
                decoration: BoxDecoration(
                  color: isSelected ? _redSoft : _surface,
                  shape: BoxShape.circle,
                ),
                child: Icon(_iconForLabel(a.label), color: _red, size: 24),
              ),
              const SizedBox(width: 14),

              // ── Info ──────────────────────────────────
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          a.label,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 16,
                            color: isSelected ? _red : _black,
                            letterSpacing: -0.3,
                          ),
                        ),
                        if (isSelected) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                            decoration: BoxDecoration(
                              color: _red,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: const Text(
                              'Selected',
                              style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (a.buildingNumber.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        a.buildingNumber,
                        style: TextStyle(fontSize: 13, color: _slate, height: 1.4),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    if (a.phone != null && a.phone!.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(Icons.phone_outlined, size: 13, color: _slate),
                          const SizedBox(width: 4),
                          Text(a.phone!, style: TextStyle(fontSize: 12, color: _slate)),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    // ── Coordinates pill ──────────────────
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: _surface,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.grey.shade200),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.location_on_rounded, size: 12, color: _red),
                          const SizedBox(width: 4),
                          Text(
                            '${a.latitude.toStringAsFixed(4)}, ${a.longitude.toStringAsFixed(4)}',
                            style: TextStyle(fontSize: 11, color: _slate, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // ── Menu ──────────────────────────────────
              PopupMenuButton<String>(
                padding: EdgeInsets.zero,
                icon: Icon(Icons.more_vert_rounded, color: Colors.grey.shade400, size: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (value) {
                  if (value == 'delete') _onDeleteAddress(a);
                },
                itemBuilder: (_) => [
                  PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline_rounded, color: _red, size: 18),
                        const SizedBox(width: 8),
                        Text('Remove', style: TextStyle(color: _red, fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _surface,
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
          'My Addresses',
          style: TextStyle(color: _black, fontWeight: FontWeight.w800, fontSize: 20, letterSpacing: -0.5),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: _surface,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Icon(Icons.refresh_rounded, color: _black, size: 18),
            ),
            onPressed: _loadAddresses,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          // ── Add new address button ────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: GestureDetector(
              onTap: _openAddAddress,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_red, _redDark],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _red.withOpacity(0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.add_location_alt_rounded, color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 14),
                    const Text(
                      'Add New Address',
                      style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    const Spacer(),
                    const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white70, size: 16),
                  ],
                ),
              ),
            ),
          ),

          // ── Address count ─────────────────────────────
          if (!_loading && _error == null && _addresses.isNotEmpty)
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                children: [
                  Text(
                    '${_addresses.length} saved address${_addresses.length > 1 ? 'es' : ''}',
                    style: TextStyle(fontSize: 13, color: _slate, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ),

          // ── Content ───────────────────────────────────
          Expanded(
            child: _loading
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        CircularProgressIndicator(color: _red, strokeWidth: 3),
                        const SizedBox(height: 16),
                        Text('Loading addresses...', style: TextStyle(color: _slate, fontSize: 14)),
                      ],
                    ),
                  )
                : _error != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(32),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 80, height: 80,
                                decoration: BoxDecoration(color: _redSoft, shape: BoxShape.circle),
                                child: const Icon(Icons.wifi_off_rounded, size: 40, color: _red),
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                "Couldn't load addresses",
                                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: _black),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                _error!,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: _slate, height: 1.5, fontSize: 14),
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton.icon(
                                onPressed: _loadAddresses,
                                icon: const Icon(Icons.refresh_rounded, size: 18),
                                label: const Text('Try again', style: TextStyle(fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _red,
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
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
                                Container(
                                  width: 100, height: 100,
                                  decoration: BoxDecoration(color: _redSoft, shape: BoxShape.circle),
                                  child: const Icon(Icons.location_off_rounded, size: 50, color: _red),
                                ),
                                const SizedBox(height: 20),
                                const Text(
                                  'No saved addresses',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _black),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Add a delivery address to get started',
                                  style: TextStyle(color: _slate, fontSize: 14),
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton.icon(
                                  onPressed: _openAddAddress,
                                  icon: const Icon(Icons.add_location_alt_rounded, size: 18),
                                  label: const Text('Add Address', style: TextStyle(fontWeight: FontWeight.w700)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: _red,
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 14),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                  ),
                                ),
                              ],
                            ),
                          )
                        : ListView.builder(
                            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                            itemCount: _addresses.length,
                            itemBuilder: (_, index) {
                              final a = _addresses[index];
                              return _buildAddressCard(a, a.id == _selectedId);
                            },
                          ),
          ),

          // ── Checkout button ───────────────────────────
          if (widget.fromCheckout && _addresses.isNotEmpty)
            Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
              decoration: BoxDecoration(
                color: Colors.white,
                boxShadow: [
                  BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 20, offset: const Offset(0, -4)),
                ],
              ),
              child: SafeArea(
                child: SizedBox(
                  width: double.infinity,
                  height: 56,
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: _selectedId != null
                          ? const LinearGradient(colors: [_red, _redDark], begin: Alignment.topLeft, end: Alignment.bottomRight)
                          : null,
                      color: _selectedId == null ? Colors.grey.shade300 : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _selectedId != null
                          ? [BoxShadow(color: _red.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))]
                          : null,
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        onTap: _selectedId != null ? _continueToCheckout : null,
                        borderRadius: BorderRadius.circular(16),
                        child: Center(
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.shopping_bag_rounded, color: _selectedId != null ? Colors.white : Colors.grey, size: 20),
                              const SizedBox(width: 10),
                              Text(
                                'Continue to Checkout',
                                style: TextStyle(
                                  color: _selectedId != null ? Colors.white : Colors.grey,
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
              ),
            ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────
//  Add address bottom sheet
// ─────────────────────────────────────────────
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
        _showSnack(context, 'Please enable location services in your device settings.', type: _SnackType.warning, duration: const Duration(seconds: 4));
        return;
      }
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever && mounted) {
        _showSnack(context, "Location permanently denied. Enable it in Settings → App Permissions.", type: _SnackType.warning, duration: const Duration(seconds: 5));
        return;
      }
      if (permission == LocationPermission.denied && mounted) {
        _showSnack(context, 'Location permission needed. Please allow it and try again.', type: _SnackType.warning, duration: const Duration(seconds: 4));
        return;
      }
      final position = await Geolocator.getCurrentPosition(desiredAccuracy: LocationAccuracy.medium);
      if (!mounted) return;
      setState(() {
        _latitudeController.text = position.latitude.toString();
        _longitudeController.text = position.longitude.toString();
        _hasCurrentLocation = true;
      });
      _showSnack(context, 'Location pinned successfully!', type: _SnackType.success, duration: const Duration(seconds: 2));
    } catch (e) {
      if (mounted) _showSnack(context, "Couldn't detect location. Make sure GPS is on.", type: _SnackType.error);
    } finally {
      if (mounted) setState(() => _gettingLocation = false);
    }
  }

  double _parseLatLng(TextEditingController c, double fallback) {
    final t = c.text.trim();
    if (t.isEmpty) return fallback;
    return double.tryParse(t) ?? fallback;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      _showSnack(context, 'Please enter your building name.', type: _SnackType.warning);
      return;
    }
    if (!_hasCurrentLocation) {
      _showSnack(context, 'Please set your current location first.', type: _SnackType.warning, duration: const Duration(seconds: 4));
      return;
    }
    setState(() => _saving = true);
    try {
      final lat = _parseLatLng(_latitudeController, 0.0);
      final lng = _parseLatLng(_longitudeController, 0.0);
      await AuthService().createAddress(
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
      final list = await AuthService().allMyAddresses();
      if (!mounted) return;
      Navigator.of(context).pop(list.isNotEmpty ? list.last : null);
    } catch (e) {
      if (!mounted) return;
      _showSnack(context, "Couldn't save address. Please check your connection.", type: _SnackType.error);
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
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                // ── Handle ────────────────────────────────
                Container(
                  margin: const EdgeInsets.only(top: 12),
                  width: 40, height: 4,
                  decoration: BoxDecoration(color: Colors.grey.shade300, borderRadius: BorderRadius.circular(2)),
                ),

                // ── Header ────────────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 20, 16, 8),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: _redSoft, borderRadius: BorderRadius.circular(12)),
                        child: const Icon(Icons.add_location_alt_rounded, color: _red, size: 24),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Add Address', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: _black, letterSpacing: -0.5)),
                            Text('Fill in details for your delivery spot', style: TextStyle(fontSize: 13, color: _slate)),
                          ],
                        ),
                      ),
                      IconButton(
                        onPressed: () => Navigator.of(context).pop(),
                        icon: const Icon(Icons.close_rounded),
                        style: IconButton.styleFrom(
                          backgroundColor: _surface,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ],
                  ),
                ),

                const Divider(height: 1),

                Expanded(
                  child: ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 32),
                    children: [
                      // ── Address type ──────────────────────
                      const Text('Address type', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _black)),
                      const SizedBox(height: 12),
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _typeChip('Home', Icons.home_rounded),
                            const SizedBox(width: 10),
                            _typeChip('Office', Icons.work_rounded),
                            const SizedBox(width: 10),
                            _typeChip("Friend's house", Icons.person_rounded),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Building name ─────────────────────
                      const Text('Building name', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _black)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: _buildingController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Sunrise Tower, Block B',
                          hintStyle: TextStyle(color: Colors.grey.shade400, fontSize: 14),
                          prefixIcon: Icon(Icons.apartment_outlined, color: _slate, size: 20),
                          filled: true,
                          fillColor: _surface,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide(color: Colors.grey.shade200)),
                          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _red, width: 2)),
                          errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: const BorderSide(color: _red)),
                          contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Building name is required' : null,
                      ),
                      const SizedBox(height: 24),

                      // ── Location ──────────────────────────
                      const Text('Your location', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: _black)),
                      const SizedBox(height: 8),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _hasCurrentLocation ? Colors.green.withOpacity(0.05) : _surface,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: _hasCurrentLocation ? Colors.green.shade300 : Colors.grey.shade200,
                            width: 1.5,
                          ),
                        ),
                        child: Column(
                          children: [
                            Row(
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: _hasCurrentLocation ? Colors.green.withOpacity(0.12) : _redSoft,
                                    borderRadius: BorderRadius.circular(10),
                                  ),
                                  child: Icon(
                                    _hasCurrentLocation ? Icons.location_on_rounded : Icons.my_location_rounded,
                                    color: _hasCurrentLocation ? Colors.green : _red,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        _hasCurrentLocation ? 'Location confirmed' : 'No location set',
                                        style: TextStyle(
                                          fontWeight: FontWeight.w700,
                                          fontSize: 14,
                                          color: _hasCurrentLocation ? Colors.green.shade700 : _black,
                                        ),
                                      ),
                                      Text(
                                        _hasCurrentLocation
                                            ? '${double.parse(_latitudeController.text).toStringAsFixed(5)}, ${double.parse(_longitudeController.text).toStringAsFixed(5)}'
                                            : 'Tap below to use GPS position',
                                        style: TextStyle(fontSize: 12, color: _slate),
                                      ),
                                    ],
                                  ),
                                ),
                                if (_hasCurrentLocation)
                                  Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(color: Colors.green.withOpacity(0.12), shape: BoxShape.circle),
                                    child: const Icon(Icons.check_rounded, color: Colors.green, size: 16),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            SizedBox(
                              width: double.infinity,
                              height: 48,
                              child: ElevatedButton.icon(
                                onPressed: _gettingLocation ? null : _getCurrentLocation,
                                icon: _gettingLocation
                                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                    : Icon(_hasCurrentLocation ? Icons.refresh_rounded : Icons.my_location_rounded, size: 18),
                                label: Text(
                                  _gettingLocation
                                      ? 'Getting location...'
                                      : _hasCurrentLocation
                                          ? 'Update location'
                                          : 'Use current location',
                                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _red,
                                  foregroundColor: Colors.white,
                                  disabledBackgroundColor: _red.withOpacity(0.5),
                                  elevation: 0,
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Save button ───────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 56,
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(colors: [_red, _redDark], begin: Alignment.topLeft, end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: [BoxShadow(color: _red.withOpacity(0.4), blurRadius: 12, offset: const Offset(0, 4))],
                          ),
                          child: Material(
                            color: Colors.transparent,
                            child: InkWell(
                              onTap: _saving ? null : _save,
                              borderRadius: BorderRadius.circular(16),
                              child: Center(
                                child: _saving
                                    ? const SizedBox(width: 24, height: 24, child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                                    : const Row(
                                        mainAxisAlignment: MainAxisAlignment.center,
                                        children: [
                                          Icon(Icons.save_alt_rounded, color: Colors.white, size: 20),
                                          SizedBox(width: 10),
                                          Text('Save Address', style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w700, letterSpacing: -0.3)),
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
          color: isSelected ? _redSoft : Colors.white,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: isSelected ? _red : Colors.grey.shade300, width: isSelected ? 2 : 1),
          boxShadow: isSelected
              ? [BoxShadow(color: _red.withOpacity(0.15), blurRadius: 8, offset: const Offset(0, 2))]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: _red),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                color: isSelected ? _red : _slate,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
// old codeaaaaaaaa

// import 'package:flutter/material.dart';
// import 'package:geolocator/geolocator.dart';
// import 'package:vlog/Data/apiservices.dart';
// import 'package:vlog/Models/delivery_address_model.dart';
// import 'package:vlog/presentation/screen/delivery_schedule_page.dart';
// import 'package:vlog/presentation/screen/payment_method_selection_page.dart';


// const Color _redPrimary = Color(0xFFE53E3E);
// const Color _yellowLight = Color(0xFFFFF8E1);
// const Color _yellowAccent = Color(0xFFFFC107);
// const Color _black = Color(0xFF000000);

// enum _SnackType { success, warning, error, info }

// void _showSnack(
//   BuildContext context,
//   String message, {
//   _SnackType type = _SnackType.info,
//   Duration duration = const Duration(seconds: 3),
// }) {
//   final config = {
//     _SnackType.success: (
//       icon: Icons.check_circle_rounded,
//       bg: const Color(0xFF1B5E20),
//       accent: const Color(0xFF4CAF50),
//     ),
//     _SnackType.warning: (
//       icon: Icons.info_rounded,
//       bg: const Color(0xFF4A3000),
//       accent: const Color(0xFFFFC107),
//     ),
//     _SnackType.error: (
//       icon: Icons.error_rounded,
//       bg: const Color(0xFF5C0A0A),
//       accent: const Color(0xFFEF5350),
//     ),
//     _SnackType.info: (
//       icon: Icons.info_outline_rounded,
//       bg: const Color(0xFF0D2340),
//       accent: const Color(0xFF42A5F5),
//     ),
//   }[type]!;

//   ScaffoldMessenger.of(context)
//     ..hideCurrentSnackBar()
//     ..showSnackBar(
//       SnackBar(
//         duration: duration,
//         behavior: SnackBarBehavior.floating,
//         backgroundColor: Colors.transparent,
//         elevation: 0,
//         margin: const EdgeInsets.fromLTRB(16, 0, 16, 20),
//         content: Container(
//           padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//           decoration: BoxDecoration(
//             color: config.bg,
//             borderRadius: BorderRadius.circular(14),
//             border: Border.all(color: config.accent.withOpacity(0.4), width: 1),
//             boxShadow: [
//               BoxShadow(
//                 color: Colors.black.withOpacity(0.25),
//                 blurRadius: 16,
//                 offset: const Offset(0, 6),
//               ),
//             ],
//           ),
//           child: Row(
//             children: [
//               Container(
//                 width: 36,
//                 height: 36,
//                 decoration: BoxDecoration(
//                   color: config.accent.withOpacity(0.15),
//                   shape: BoxShape.circle,
//                 ),
//                 child: Icon(config.icon, color: config.accent, size: 20),
//               ),
//               const SizedBox(width: 12),
//               Expanded(
//                 child: Text(
//                   message,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 14,
//                     fontWeight: FontWeight.w500,
//                     height: 1.4,
//                   ),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
// }

// // ─────────────────────────────────────────────

// class ChoiceAddress extends StatefulWidget {
//   /// When true, show "Continue to checkout" and navigate to checkout after selecting address.
//   final bool fromCheckout;

//   const ChoiceAddress({super.key, this.fromCheckout = false});

//   @override
//   State<ChoiceAddress> createState() => _ChoiceAddressState();
// }

// class _ChoiceAddressState extends State<ChoiceAddress> {
//   List<DeliveryAddressModel> _addresses = [];
//   String? _selectedId;
//   bool _loading = true;
//   String? _error;

//   @override
//   void initState() {
//     super.initState();
//     _loadAddresses();
//   }

//   Future<void> _loadAddresses() async {
//     setState(() {
//       _loading = true;
//       _error = null;
//     });
//     try {
//       final auth = AuthService();
//       final list = await auth.allMyAddresses();
//       if (!mounted) return;
//       setState(() {
//         _addresses = list;
//         if (widget.fromCheckout) {
//           // In checkout flow, require the user to explicitly select an address.
//           // Do not auto-select the default/first address.
//           _selectedId = null;
//         } else {
//           for (final a in list) {
//             if (a.isDefault) {
//               _selectedId = a.id;
//               break;
//             }
//           }
//           _selectedId ??= list.isNotEmpty ? list.first.id : null;
//         }
//         _loading = false;
//       });
//     } catch (e) {
//       // dev error: e.toString()
//       if (!mounted) return;
//       setState(() {
//         _error = "We couldn't load your addresses right now.\nPlease check your connection and try again.";
//         _loading = false;
//       });
//     }
//   }

//   void _openAddAddress() async {
//     final added = await showModalBottomSheet<DeliveryAddressModel>(
//       context: context,
//       isScrollControlled: true,
//       backgroundColor: Colors.transparent,
//       builder: (context) => const _AddressDetailsSheet(),
//     );
//     if (added != null && mounted) {
//       setState(() {
//         _addresses = [..._addresses, added];
//         _selectedId = added.id;
//       });
//     }
//   }

//   void _continueToCheckout() {
//     _continueToCheckoutInternal();
//   }

//   Future<void> _continueToCheckoutInternal() async {
//     if (_selectedId == null) {
//       // dev: no address selected – _selectedId is null
//       _showSnack(
//         context,
//         'Please choose a delivery address before continuing.',
//         type: _SnackType.warning,
//       );
//       return;
//     }
//     final selectedAddress = _addresses.firstWhere((a) => a.id == _selectedId);
//     final result = await Navigator.push(
//       context,
//       MaterialPageRoute(
//         builder: (_) => const DeliverySchedulePage(),
//       ),
//     );

//     if (result == null || !mounted) return;
//     final date = result['date'] as DateTime?;
//     final timeSlot = result['timeSlot'] as String?;

//     if (date == null || timeSlot == null) return;

//     Navigator.of(context).pushReplacement(
//       MaterialPageRoute(
//         builder: (_) => PaymentMethodSelectionPage(
//           selectedAddress: selectedAddress,
//           initialDate: date,
//           initialTimeSlot: timeSlot,
//         ),
//       ),
//     );
//   }

//   IconData _iconForLabel(String label) {
//     final lower = label.toLowerCase();
//     if (lower.contains('home')) return Icons.home;
//     if (lower.contains('office')) return Icons.work;
//     if (lower.contains('friend')) return Icons.person;
//     return Icons.location_on;
//   }

//   Widget _mapThumbnail(double lat, double lng) {
//     return Container(
//       width: 56,
//       height: 56,
//       decoration: BoxDecoration(
//         shape: BoxShape.circle,
//         color: Colors.grey[200],
//         border: Border.all(color: Colors.grey[300]!, width: 1),
//         boxShadow: [
//           BoxShadow(
//             color: Colors.black.withOpacity(0.06),
//             blurRadius: 6,
//             offset: const Offset(0, 2),
//           ),
//         ],
//       ),
//       child: ClipOval(
//         child: Stack(
//           fit: StackFit.expand,
//           children: [
//             Container(
//               decoration: BoxDecoration(
//                 gradient: LinearGradient(
//                   begin: Alignment.topLeft,
//                   end: Alignment.bottomRight,
//                   colors: [Colors.grey[300]!, Colors.grey[200]!],
//                 ),
//               ),
//             ),
//             Center(
//               child: Icon(Icons.location_on, color: _redPrimary, size: 28),
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   Widget _buildAddressCard(DeliveryAddressModel a, bool isDefault) {
//     return Stack(
//       clipBehavior: Clip.none,
//       children: [
//         GestureDetector(
//           onTap: () => _onUseAddress(a),
//           behavior: HitTestBehavior.opaque,
//           child: Card(
//             margin: const EdgeInsets.only(bottom: 16, top: 8),
//             shape: RoundedRectangleBorder(
//               borderRadius: BorderRadius.circular(16),
//               side: BorderSide(
//                 color: isDefault ? _redPrimary : Colors.grey[200]!,
//                 width: isDefault ? 2 : 1,
//               ),
//             ),
//             elevation: 2,
//             shadowColor: Colors.black.withOpacity(0.06),
//             child: Padding(
//               padding: const EdgeInsets.all(16),
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Row(
//                     crossAxisAlignment: CrossAxisAlignment.start,
//                     children: [
//                       Expanded(
//                         child: Row(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             Container(
//                               width: 44,
//                               height: 44,
//                               decoration: const BoxDecoration(
//                                 color: Color(0xFFFFE0B2),
//                                 shape: BoxShape.circle,
//                               ),
//                               child: Icon(_iconForLabel(a.label), color: _redPrimary, size: 22),
//                             ),
//                             const SizedBox(width: 14),
//                             Expanded(
//                               child: Column(
//                                 crossAxisAlignment: CrossAxisAlignment.start,
//                                 children: [
//                                   Text(
//                                     a.label,
//                                     style: const TextStyle(
//                                       fontWeight: FontWeight.bold,
//                                       fontSize: 17,
//                                       color: Colors.black87,
//                                     ),
//                                   ),
//                                   if (a.buildingNumber.isNotEmpty) ...[
//                                     const SizedBox(height: 6),
//                                     Text(
//                                       a.buildingNumber,
//                                       style: TextStyle(
//                                         fontSize: 14,
//                                         color: Colors.grey[800],
//                                         height: 1.3,
//                                       ),
//                                       maxLines: 2,
//                                       overflow: TextOverflow.ellipsis,
//                                     ),
//                                   ],
//                                   if (a.phone != null && a.phone!.isNotEmpty) ...[
//                                     const SizedBox(height: 4),
//                                     Text(
//                                       a.phone!,
//                                       style: TextStyle(
//                                         fontSize: 13,
//                                         color: Colors.grey[700],
//                                       ),
//                                     ),
//                                   ],
//                                 ],
//                               ),
//                             ),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(width: 12),
//                       _mapThumbnail(a.latitude, a.longitude),
//                       PopupMenuButton<String>(
//                         padding: EdgeInsets.zero,
//                         icon: Icon(Icons.more_vert, color: Colors.grey[600], size: 20),
//                         onSelected: (value) {
//                           if (value == 'edit') {
//                             // TODO: edit address
//                           } else if (value == 'delete') {
//                             _onDeleteAddress(a);
//                           }
//                         },
//                         itemBuilder: (context) => [
//                           const PopupMenuItem(value: 'edit', child: Text('Edit')),
//                           const PopupMenuItem(value: 'delete', child: Text('Delete')),
//                         ],
//                       ),
//                     ],
//                   ),
//                 ],
//               ),
//             ),
//           ),
//         ),
//         if (isDefault)
//           Positioned(
//             top: 10,
//             right: 10,
//             child: Transform.rotate(
//               angle: 0.785398,
//               child: Container(
//                 padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 5),
//                 decoration: BoxDecoration(
//                   color: _redPrimary,
//                   borderRadius: BorderRadius.circular(2),
//                   boxShadow: [
//                     BoxShadow(
//                       color: _redPrimary.withOpacity(0.4),
//                       blurRadius: 4,
//                       offset: const Offset(0, 2),
//                     ),
//                   ],
//                 ),
//                 child: const Text(
//                   'SELECTED',
//                   style: TextStyle(
//                     color: Colors.white,
//                     fontSize: 11,
//                     fontWeight: FontWeight.bold,
//                     letterSpacing: 0.5,
//                   ),
//                 ),
//               ),
//             ),
//           ),
//       ],
//     );
//   }

//   Future<void> _onUseAddress(DeliveryAddressModel a) async {
//     if (a.isDefault) {
//       // Even if it's already default, user still needs an explicit selection
//       // in checkout flow.
//       setState(() => _selectedId = a.id);
//       return;
//     }
//     final previousDefaultId = _selectedId;
//     setState(() {
//       _addresses = _addresses
//           .map((addr) => addr.copyWith(isDefault: addr.id == a.id))
//           .toList();
//       _selectedId = a.id;
//     });
//     try {
//       final auth = AuthService();
//       await auth.useAddress(a.id);
//       if (!mounted) return;
//       _showSnack(
//         context,
//         '${a.label} is now your delivery address.',
//         type: _SnackType.success,
//         duration: const Duration(seconds: 2),
//       );
//     } catch (e) {
//       // dev error: e.toString()
//       if (!mounted) return;
//       setState(() {
//         _addresses = _addresses
//             .map((addr) => addr.copyWith(isDefault: addr.id == previousDefaultId))
//             .toList();
//         _selectedId = previousDefaultId;
//       });
//       _showSnack(
//         context,
//         "We couldn't update your delivery address. Please try again.",
//         type: _SnackType.error,
//       );
//     }
//   }

//   Future<void> _onDeleteAddress(DeliveryAddressModel a) async {
//     // Confirm before deleting
//     final confirmed = await showDialog<bool>(
//       context: context,
//       builder: (ctx) => AlertDialog(
//         shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
//         title: const Text('Remove address?', style: TextStyle(fontWeight: FontWeight.bold)),
//         content: Text(
//           'Are you sure you want to remove "${a.label}"? This action cannot be undone.',
//           style: TextStyle(color: Colors.grey[700], height: 1.4),
//         ),
//         actions: [
//           TextButton(
//             onPressed: () => Navigator.of(ctx).pop(false),
//             child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
//           ),
//           ElevatedButton(
//             onPressed: () => Navigator.of(ctx).pop(true),
//             style: ElevatedButton.styleFrom(
//               backgroundColor: _redPrimary,
//               foregroundColor: Colors.white,
//               shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
//               elevation: 0,
//             ),
//             child: const Text('Remove'),
//           ),
//         ],
//       ),
//     );
//     if (confirmed != true) return;

//     try {
//       final auth = AuthService();
//       final response = await auth.deleteAddress(a.id);
//       if (!mounted) return;
//       final message = response['message']?.toString() ?? '';
//       await _loadAddresses();
//       if (!mounted) return;
//       if (message == 'Address deleted successfully') {
//         // dev: server returned 'Address deleted successfully'
//         _showSnack(
//           context,
//           '"${a.label}" has been removed from your addresses.',
//           type: _SnackType.success,
//         );
//       } else {
//         // dev: unexpected server message → $message
//         _showSnack(
//           context,
//           "We couldn't remove this address right now. Please try again later.",
//           type: _SnackType.warning,
//         );
//       }
//     } catch (e) {
//       // dev error: e.toString()
//       if (!mounted) return;
//       _showSnack(
//         context,
//         "Something went wrong while removing the address. Please try again.",
//         type: _SnackType.error,
//       );
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.grey[50],
//       appBar: AppBar(
//         backgroundColor: Colors.white,
//         elevation: 0,
//         leading: IconButton(
//           icon: const Icon(Icons.arrow_back_ios_new, color: _black, size: 20),
//           onPressed: () => Navigator.of(context).pop(),
//         ),
//         title: const Text(
//           'Addresses',
//           style: TextStyle(
//             color: _black,
//             fontWeight: FontWeight.bold,
//             fontSize: 20,
//           ),
//         ),
//         centerTitle: true,
//         actions: [
//           PopupMenuButton<String>(
//             icon: const Icon(Icons.more_vert, color: _black),
//             onSelected: (value) {
//               if (value == 'refresh') _loadAddresses();
//             },
//             itemBuilder: (context) => [
//               const PopupMenuItem(value: 'refresh', child: Text('Refresh list')),
//             ],
//           ),
//         ],
//       ),
//       body: Column(
//         children: [
//           Padding(
//             padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
//             child: Material(
//               color: _yellowLight,
//               borderRadius: BorderRadius.circular(12),
//               child: InkWell(
//                 onTap: _openAddAddress,
//                 borderRadius: BorderRadius.circular(12),
//                 child: Container(
//                   padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
//                   child: Row(
//                     children: [
//                       Container(
//                         padding: const EdgeInsets.all(8),
//                         decoration: BoxDecoration(
//                           color: _redPrimary.withOpacity(0.2),
//                           borderRadius: BorderRadius.circular(8),
//                         ),
//                         child: const Icon(Icons.add, color: _redPrimary, size: 22),
//                       ),
//                       const SizedBox(width: 14),
//                       const Text(
//                         'Add New Address',
//                         style: TextStyle(
//                           color: _redPrimary,
//                           fontWeight: FontWeight.w600,
//                           fontSize: 16,
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ),
//             ),
//           ),
//           Expanded(
//             child: _loading
//                 ? const Center(child: CircularProgressIndicator(color: _redPrimary))
//                 : _error != null
//                     ? Center(
//                         child: Padding(
//                           padding: const EdgeInsets.all(24),
//                           child: Column(
//                             mainAxisSize: MainAxisSize.min,
//                             children: [
//                               Container(
//                                 width: 72,
//                                 height: 72,
//                                 decoration: BoxDecoration(
//                                   color: Colors.red.shade50,
//                                   shape: BoxShape.circle,
//                                 ),
//                                 child: Icon(Icons.wifi_off_rounded, size: 36, color: Colors.red.shade300),
//                               ),
//                               const SizedBox(height: 16),
//                               const Text(
//                                 "Couldn't load addresses",
//                                 style: TextStyle(
//                                   fontSize: 17,
//                                   fontWeight: FontWeight.bold,
//                                   color: Colors.black87,
//                                 ),
//                               ),
//                               const SizedBox(height: 8),
//                               Text(
//                                 _error!,
//                                 textAlign: TextAlign.center,
//                                 style: TextStyle(color: Colors.grey[600], height: 1.5),
//                               ),
//                               const SizedBox(height: 20),
//                               ElevatedButton.icon(
//                                 onPressed: _loadAddresses,
//                                 icon: const Icon(Icons.refresh_rounded, size: 18),
//                                 label: const Text('Try again'),
//                                 style: ElevatedButton.styleFrom(
//                                   backgroundColor: _redPrimary,
//                                   foregroundColor: Colors.white,
//                                   shape: RoundedRectangleBorder(
//                                     borderRadius: BorderRadius.circular(10),
//                                   ),
//                                   elevation: 0,
//                                   padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
//                                 ),
//                               ),
//                             ],
//                           ),
//                         ),
//                       )
//                     : _addresses.isEmpty
//                         ? Center(
//                             child: Column(
//                               mainAxisSize: MainAxisSize.min,
//                               children: [
//                                 Container(
//                                   width: 88,
//                                   height: 88,
//                                   decoration: BoxDecoration(
//                                     color: Colors.grey.shade100,
//                                     shape: BoxShape.circle,
//                                   ),
//                                   child: Icon(Icons.location_off_outlined, size: 44, color: Colors.grey[400]),
//                                 ),
//                                 const SizedBox(height: 16),
//                                 const Text(
//                                   'No saved addresses',
//                                   style: TextStyle(
//                                     fontSize: 18,
//                                     color: Colors.black87,
//                                     fontWeight: FontWeight.w600,
//                                   ),
//                                 ),
//                                 const SizedBox(height: 8),
//                                 Text(
//                                   'Add a delivery address to get started',
//                                   style: TextStyle(color: Colors.grey[500], fontSize: 14),
//                                 ),
//                               ],
//                             ),
//                           )
//                         : ListView.builder(
//                             padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
//                             itemCount: _addresses.length,
//                             itemBuilder: (context, index) {
//                               final a = _addresses[index];
//                               return _buildAddressCard(a, a.isDefault);
//                             },
//                           ),
//           ),
//           if (widget.fromCheckout && _addresses.isNotEmpty)
//             Container(
//               padding: const EdgeInsets.all(20),
//               decoration: BoxDecoration(
//                 color: Colors.white,
//                 boxShadow: [
//                   BoxShadow(
//                     color: Colors.black.withOpacity(0.06),
//                     blurRadius: 10,
//                     offset: const Offset(0, -4),
//                   ),
//                 ],
//               ),
//               child: SafeArea(
//                 child: SizedBox(
//                   width: double.infinity,
//                   height: 52,
//                   child: ElevatedButton(
//                     onPressed: _selectedId != null ? _continueToCheckout : null,
//                     style: ElevatedButton.styleFrom(
//                       backgroundColor: _redPrimary,
//                       foregroundColor: Colors.white,
//                       disabledBackgroundColor: Colors.grey[300],
//                       shape: RoundedRectangleBorder(
//                         borderRadius: BorderRadius.circular(12),
//                       ),
//                       elevation: 0,
//                     ),
//                     child: const Text('Continue to checkout'),
//                   ),
//                 ),
//               ),
//             ),
//         ],
//       ),
//     );
//   }
// }

// // ─────────────────────────────────────────────
// //  Add address bottom sheet
// // ─────────────────────────────────────────────
// class _AddressDetailsSheet extends StatefulWidget {
//   const _AddressDetailsSheet();

//   @override
//   State<_AddressDetailsSheet> createState() => _AddressDetailsSheetState();
// }

// class _AddressDetailsSheetState extends State<_AddressDetailsSheet> {
//   final _formKey = GlobalKey<FormState>();
//   final _buildingController = TextEditingController();
//   final _latitudeController = TextEditingController();
//   final _longitudeController = TextEditingController();
//   String _addressType = 'Home';
//   bool _saving = false;
//   bool _gettingLocation = false;
//   bool _hasCurrentLocation = false;

//   @override
//   void dispose() {
//     _buildingController.dispose();
//     _latitudeController.dispose();
//     _longitudeController.dispose();
//     super.dispose();
//   }

//   Future<void> _getCurrentLocation() async {
//     setState(() => _gettingLocation = true);
//     try {
//       bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
//       if (!serviceEnabled && mounted) {
//         // dev: Geolocator.isLocationServiceEnabled() returned false
//         _showSnack(
//           context,
//           'Your location is turned off. Please enable it in your device settings.',
//           type: _SnackType.warning,
//           duration: const Duration(seconds: 4),
//         );
//         return;
//       }

//       LocationPermission permission = await Geolocator.checkPermission();
//       if (permission == LocationPermission.denied) {
//         permission = await Geolocator.requestPermission();
//       }

//       if (permission == LocationPermission.deniedForever && mounted) {
//         // dev: LocationPermission.deniedForever – must open app settings
//         _showSnack(
//           context,
//           "Location access was permanently denied. You can allow it from your phone's Settings → App Permissions.",
//           type: _SnackType.warning,
//           duration: const Duration(seconds: 5),
//         );
//         return;
//       }

//       if (permission == LocationPermission.denied && mounted) {
//         // dev: LocationPermission.denied after request
//         _showSnack(
//           context,
//           'We need location permission to pin your delivery spot. Please allow it and try again.',
//           type: _SnackType.warning,
//           duration: const Duration(seconds: 4),
//         );
//         return;
//       }

//       final position = await Geolocator.getCurrentPosition(
//         desiredAccuracy: LocationAccuracy.medium,
//       );
//       if (!mounted) return;
//       setState(() {
//         _latitudeController.text = position.latitude.toString();
//         _longitudeController.text = position.longitude.toString();
//         _hasCurrentLocation = true;
//       });
//       _showSnack(
//         context,
//         'Location pinned! Your current position has been saved.',
//         type: _SnackType.success,
//         duration: const Duration(seconds: 2),
//       );
//     } catch (e) {
//       // dev error: e.toString()
//       if (mounted) {
//         _showSnack(
//           context,
//           "We couldn't detect your location. Make sure GPS is on and try again.",
//           type: _SnackType.error,
//         );
//       }
//     } finally {
//       if (mounted) setState(() => _gettingLocation = false);
//     }
//   }

//   double _parseLatLng(TextEditingController c, double fallback) {
//     final t = c.text.trim();
//     if (t.isEmpty) return fallback;
//     return double.tryParse(t) ?? fallback;
//   }

//   String? _validateRequired(String? value, String fieldName) {
//     if (value == null || value.trim().isEmpty) return '$fieldName is required';
//     return null;
//   }

//   InputDecoration _addressFieldDecoration(String labelText, String hintText) {
//     return InputDecoration(
//       labelText: labelText,
//       hintText: hintText,
//       border: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: Colors.grey[300]!),
//       ),
//       enabledBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: BorderSide(color: Colors.grey[300]!),
//       ),
//       focusedBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: _redPrimary, width: 2),
//       ),
//       errorBorder: OutlineInputBorder(
//         borderRadius: BorderRadius.circular(12),
//         borderSide: const BorderSide(color: Colors.red),
//       ),
//     );
//   }

//   Future<void> _save() async {
//     if (!_formKey.currentState!.validate()) {
//       // dev: form validation failed – buildingNumber is empty
//       _showSnack(
//         context,
//         'Please enter your building name to continue.',
//         type: _SnackType.warning,
//       );
//       return;
//     }
//     if (!_hasCurrentLocation) {
//       // dev: _hasCurrentLocation is false – lat/lng not set yet
//       _showSnack(
//         context,
//         'Tap "Use my current location" so we know where to deliver.',
//         type: _SnackType.warning,
//         duration: const Duration(seconds: 4),
//       );
//       return;
//     }

//     setState(() => _saving = true);
//     try {
//       final auth = AuthService();
//       final lat = _parseLatLng(_latitudeController, 0.0);
//       final lng = _parseLatLng(_longitudeController, 0.0);
//       await auth.createAddress(
//         street: 'for now not yet',
//         buildingNumber: _buildingController.text.trim(),
//         apartmentNumber: 'for now not yet',
//         city: 'for now not yet',
//         latitude: lat,
//         longitude: lng,
//         isDefault: false,
//         receiverName: null,
//         label: _addressType,
//         addressType: _addressType,
//       );
//       if (!mounted) return;
//       final list = await auth.allMyAddresses();
//       if (!mounted) return;
//       if (list.isNotEmpty) {
//         Navigator.of(context).pop(list.last);
//       } else {
//         Navigator.of(context).pop();
//       }
//     } catch (e) {
//       // dev error: e.toString()
//       if (!mounted) return;
//       _showSnack(
//         context,
//         "We couldn't save your address right now. Please check your connection and try again.",
//         type: _SnackType.error,
//       );
//     } finally {
//       if (mounted) setState(() => _saving = false);
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return DraggableScrollableSheet(
//       initialChildSize: 0.85,
//       minChildSize: 0.5,
//       maxChildSize: 0.95,
//       builder: (context, scrollController) {
//         return Container(
//           decoration: const BoxDecoration(
//             color: Colors.white,
//             borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
//           ),
//           child: Form(
//             key: _formKey,
//             child: Column(
//               children: [
//                 Container(
//                   margin: const EdgeInsets.only(top: 12),
//                   width: 40,
//                   height: 4,
//                   decoration: BoxDecoration(
//                     color: Colors.grey[300],
//                     borderRadius: BorderRadius.circular(2),
//                   ),
//                 ),
//                 Padding(
//                   padding: const EdgeInsets.fromLTRB(24, 20, 24, 8),
//                   child: Row(
//                     children: [
//                       Expanded(
//                         child: Column(
//                           crossAxisAlignment: CrossAxisAlignment.start,
//                           children: [
//                             const Text(
//                               'Address details',
//                               style: TextStyle(
//                                 fontSize: 22,
//                                 fontWeight: FontWeight.bold,
//                                 color: Colors.black87,
//                               ),
//                             ),
//                             const SizedBox(height: 4),
//                             Text(
//                               'Complete address would assist us in serving you better',
//                               style: TextStyle(fontSize: 14, color: Colors.grey[600]),
//                             ),
//                           ],
//                         ),
//                       ),
//                       IconButton(
//                         onPressed: () => Navigator.of(context).pop(),
//                         icon: const Icon(Icons.close),
//                         style: IconButton.styleFrom(
//                           backgroundColor: Colors.grey[200],
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(10),
//                           ),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//                 Expanded(
//                   child: ListView(
//                     controller: scrollController,
//                     padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
//                     children: [
//                       const Text(
//                         'Select address type',
//                         style: TextStyle(
//                           fontWeight: FontWeight.w600,
//                           fontSize: 15,
//                           color: Colors.black87,
//                         ),
//                       ),
//                       const SizedBox(height: 12),
//                       SingleChildScrollView(
//                         scrollDirection: Axis.horizontal,
//                         child: Row(
//                           children: [
//                             _typeChip('Home', Icons.home),
//                             const SizedBox(width: 10),
//                             _typeChip('Office', Icons.work),
//                             const SizedBox(width: 10),
//                             _typeChip("Friend's house", Icons.person),
//                           ],
//                         ),
//                       ),
//                       const SizedBox(height: 24),
//                       TextFormField(
//                         controller: _buildingController,
//                         decoration: _addressFieldDecoration('Building name*', 'Building name'),
//                         validator: (v) => _validateRequired(v, 'Building name'),
//                       ),
//                       const SizedBox(height: 20),
//                       OutlinedButton.icon(
//                         onPressed: _gettingLocation ? null : _getCurrentLocation,
//                         icon: _gettingLocation
//                             ? const SizedBox(
//                                 width: 20,
//                                 height: 20,
//                                 child: CircularProgressIndicator(strokeWidth: 2),
//                               )
//                             : Icon(
//                                 _hasCurrentLocation
//                                     ? Icons.check_circle_rounded
//                                     : Icons.my_location,
//                                 size: 20,
//                                 color: _hasCurrentLocation ? Colors.green : _redPrimary,
//                               ),
//                         label: Text(
//                           _gettingLocation
//                               ? 'Detecting your location...'
//                               : _hasCurrentLocation
//                                   ? 'Location saved'
//                                   : 'Use my current location',
//                           style: TextStyle(
//                             color: _hasCurrentLocation ? Colors.green : _redPrimary,
//                             fontWeight: _hasCurrentLocation ? FontWeight.w600 : null,
//                           ),
//                         ),
//                         style: OutlinedButton.styleFrom(
//                           foregroundColor: _hasCurrentLocation ? Colors.green : _redPrimary,
//                           side: BorderSide(color: _hasCurrentLocation ? Colors.green : _redPrimary),
//                           padding: const EdgeInsets.symmetric(vertical: 14),
//                           shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(12),
//                           ),
//                         ),
//                       ),
//                       const SizedBox(height: 28),
//                       SizedBox(
//                         width: double.infinity,
//                         height: 52,
//                         child: ElevatedButton(
//                           onPressed: _saving ? null : _save,
//                           style: ElevatedButton.styleFrom(
//                             backgroundColor: _redPrimary,
//                             foregroundColor: Colors.white,
//                             shape: RoundedRectangleBorder(
//                               borderRadius: BorderRadius.circular(12),
//                             ),
//                             elevation: 0,
//                           ),
//                           child: _saving
//                               ? const SizedBox(
//                                   height: 24,
//                                   width: 24,
//                                   child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
//                                 )
//                               : const Text('Save address'),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ),
//               ],
//             ),
//           ),
//         );
//       },
//     );
//   }

//   Widget _typeChip(String label, IconData icon) {
//     final isSelected = _addressType == label;
//     return GestureDetector(
//       onTap: () => setState(() => _addressType = label),
//       child: AnimatedContainer(
//         duration: const Duration(milliseconds: 150),
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
//         decoration: BoxDecoration(
//           color: isSelected ? _yellowLight : Colors.white,
//           borderRadius: BorderRadius.circular(24),
//           border: Border.all(
//             color: isSelected ? _yellowAccent : Colors.grey[300]!,
//             width: isSelected ? 2 : 1,
//           ),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Icon(icon, size: 20, color: _redPrimary),
//             const SizedBox(width: 8),
//             Text(
//               label,
//               style: TextStyle(
//                 fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
//                 color: isSelected ? _redPrimary : Colors.grey[700],
//                 fontSize: 14,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
// }