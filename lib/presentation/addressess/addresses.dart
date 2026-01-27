import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';
import 'package:vlog/presentation/home.dart';

class Addresses extends StatefulWidget {
  final String? userId;
  const Addresses({super.key, this.userId});

  @override
  State<Addresses> createState() => _AddressesState();
}

class _AddressesState extends State<Addresses> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Map variables
  GoogleMapController? _mapController;
  LatLng _selectedLocation = const LatLng(48.8566, 2.3522); // Default: Paris
  Marker? _marker;
  bool _isLoadingLocation = false;
  String? _selectedAddressText;
  double? _latitude;
  double? _longitude;

  // Form controllers
  final TextEditingController _labelController = TextEditingController();
  final TextEditingController _streetController = TextEditingController();
  final TextEditingController _buildingNumberController = TextEditingController();
  final TextEditingController _cityController = TextEditingController();
  final TextEditingController _postalCodeController = TextEditingController();
  final TextEditingController _countryController = TextEditingController();
  final TextEditingController _instructionsController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isDefault = false;

  @override
  void initState() {
    super.initState();
    // Initialize with default location and marker
    _latitude = _selectedLocation.latitude;
    _longitude = _selectedLocation.longitude;
    _updateMarker(_selectedLocation);
    // Try to get current location, but don't block if it fails
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _getCurrentLocation();
    });
  }

  @override
  void dispose() {
    _pageController.dispose();
    _mapController?.dispose();
    _labelController.dispose();
    _streetController.dispose();
    _buildingNumberController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _countryController.dispose();
    _instructionsController.dispose();
    super.dispose();
  }

  Future<void> _getCurrentLocation() async {
    setState(() => _isLoadingLocation = true);
    
    try {
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location services are disabled')),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Location permissions are denied')),
            );
          }
          setState(() => _isLoadingLocation = false);
          return;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Location permissions are permanently denied')),
          );
        }
        setState(() => _isLoadingLocation = false);
        return;
      }

      Position position = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final newLocation = LatLng(position.latitude, position.longitude);
      setState(() {
        _selectedLocation = newLocation;
        _latitude = newLocation.latitude;
        _longitude = newLocation.longitude;
        _isLoadingLocation = false;
      });

      _updateMarker(newLocation);
      _mapController?.animateCamera(
        CameraUpdate.newLatLngZoom(newLocation, 15),
      );
      await _reverseGeocode(newLocation);
    } catch (e) {
      setState(() => _isLoadingLocation = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error getting location: $e')),
        );
      }
    }
  }

  void _updateMarker(LatLng location) {
    setState(() {
      _marker = Marker(
        markerId: const MarkerId('selected_location'),
        position: location,
        draggable: true,
        icon: BitmapDescriptor.defaultMarkerWithHue(BitmapDescriptor.hueRed),
        onDragEnd: (newPosition) {
          setState(() {
            _selectedLocation = newPosition;
            _latitude = newPosition.latitude;
            _longitude = newPosition.longitude;
          });
          _reverseGeocode(newPosition);
        },
      );
    });
  }

  Future<void> _reverseGeocode(LatLng location) async {
    try {
      List<Placemark> placemarks = await placemarkFromCoordinates(
        location.latitude,
        location.longitude,
      );

      if (placemarks.isNotEmpty) {
        final place = placemarks.first;
        setState(() {
          _selectedAddressText = '${place.street ?? ''}, ${place.locality ?? ''}, ${place.postalCode ?? ''}';
          _streetController.text = place.street ?? '';
          _cityController.text = place.locality ?? '';
          _postalCodeController.text = place.postalCode ?? '';
          _countryController.text = place.country ?? '';
        });
      }
    } catch (e) {
      debugPrint('Reverse geocoding error: $e');
    }
  }

  void _onMapTap(LatLng location) {
    setState(() {
      _selectedLocation = location;
      _latitude = location.latitude;
      _longitude = location.longitude;
    });
    _updateMarker(location);
    _reverseGeocode(location);
  }

  void _onMapCreated(GoogleMapController controller) {
    _mapController = controller;
  }

  void _nextPage() {
    if (_currentPage == 0) {
      // Always allow navigation to next page, even if location isn't perfect
      // User can still manually enter address
      setState(() {
        _currentPage = 1;
      });
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  void _saveAddress() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    // Validate required fields
    if (_streetController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter street address'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    if (_cityController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter city'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // Here you would save the address to your backend
    final addressData = {
      "user_id": widget.userId,
      "label": _labelController.text.trim().isEmpty ? "Home" : _labelController.text.trim(),
      "street": _streetController.text.trim(),
      "building_number": _buildingNumberController.text.trim(),
      "city": _cityController.text.trim(),
      "postal_code": _postalCodeController.text.trim(),
      "country": _countryController.text.trim().isEmpty ? "Unknown" : _countryController.text.trim(),
      "instructions": _instructionsController.text.trim().isEmpty ? null : _instructionsController.text.trim(),
      "latitude": _latitude ?? _selectedLocation.latitude,
      "longitude": _longitude ?? _selectedLocation.longitude,
      "is_default": _isDefault,
    };

    debugPrint("ADDRESS DATA => $addressData");

    if (mounted) {
      // Show loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(
          child: CircularProgressIndicator(),
        ),
      );

      // Simulate API call (replace with actual API call)
      await Future.delayed(const Duration(milliseconds: 500));

      if (mounted) {
        Navigator.pop(context); // Close loading dialog
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Address saved successfully!'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 2),
          ),
        );
        
        // Navigate to MainScreen after saving address
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(
            builder: (context) => MainScreen(token: widget.userId),
          ),
          (route) => false, // Remove all previous routes
        );
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
        leading: widget.userId != null
            ? null // Hide back button if coming from registration
            : IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.black),
                onPressed: () => Navigator.pop(context),
              ),
        title: Text(
          _currentPage == 0 ? 'Select Location' : 'Address Details',
          style: const TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (_currentPage == 1)
            TextButton(
              onPressed: _saveAddress,
              child: const Text(
                'Save',
                style: TextStyle(
                  color: Colors.black,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // Page indicator dots at the top
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _buildPageIndicator(0),
                Container(
                  width: 30,
                  height: 2,
                  margin: const EdgeInsets.symmetric(horizontal: 4),
                  color: Colors.grey[300],
                ),
                _buildPageIndicator(1),
              ],
            ),
          ),
          // PageView
          Expanded(
            child: PageView(
              controller: _pageController,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
              },
              physics: const NeverScrollableScrollPhysics(),
              children: [
                _buildMapPage(),
                _buildAddressFormPage(),
              ],
            ),
          ),
          // Navigation buttons
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.grey.withOpacity(0.1),
                  spreadRadius: 1,
                  blurRadius: 5,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: Row(
              children: [
                if (_currentPage > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _previousPage,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: const BorderSide(color: Colors.black),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text(
                        'Back',
                        style: TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                if (_currentPage > 0) const SizedBox(width: 12),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _currentPage == 0 ? _nextPage : _saveAddress,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.black,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _currentPage == 0 ? 'Continue' : 'Save Address',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPageIndicator(int index) {
    final isActive = _currentPage == index;
    return Container(
      width: isActive ? 24 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: isActive ? Colors.black : Colors.grey[300],
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }

  Widget _buildMapPage() {
    return Stack(
      children: [
        // Google Maps integration with interactive map
        // Wrap in try-catch widget to handle map loading errors gracefully
        Builder(
          builder: (context) {
            try {
              return GoogleMap(
                onMapCreated: _onMapCreated,
                initialCameraPosition: CameraPosition(
                  target: _selectedLocation,
                  zoom: 15,
                ),
                markers: _marker != null ? {_marker!} : {},
                onTap: _onMapTap,
                myLocationButtonEnabled: false,
                zoomControlsEnabled: false,
                mapToolbarEnabled: false,
                myLocationEnabled: true,
                onCameraMove: (CameraPosition position) {
                  // Update location as user pans the map
                  setState(() {
                    _selectedLocation = position.target;
                    _latitude = position.target.latitude;
                    _longitude = position.target.longitude;
                  });
                },
                onCameraIdle: () {
                  // When map stops moving, update marker and geocode
                  _updateMarker(_selectedLocation);
                  _reverseGeocode(_selectedLocation);
                },
              );
            } catch (e) {
              debugPrint('Map error: $e');
              // Fallback UI if map fails to load
              return Container(
                color: Colors.grey[200],
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.map, size: 64, color: Colors.grey),
                      const SizedBox(height: 16),
                      const Text(
                        'Map unavailable',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'You can still enter your address manually',
                        style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                      ),
                      const SizedBox(height: 24),
                      ElevatedButton(
                        onPressed: _nextPage,
                        child: const Text('Continue to Address Form'),
                      ),
                    ],
                  ),
                ),
              );
            }
          },
        ),
        // Current location button
        Positioned(
          bottom: 100,
          right: 16,
          child: FloatingActionButton(
            onPressed: _getCurrentLocation,
            backgroundColor: Colors.white,
            child: _isLoadingLocation
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location, color: Colors.black),
          ),
        ),
        // Location info card showing selected address and coordinates
        Positioned(
          top: 16,
          left: 16,
          right: 16,
          child: Card(
            elevation: 4,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.location_on, color: Colors.red, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Selected Location',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedAddressText ?? 'Tap on map to select location',
                    style: TextStyle(
                      color: Colors.grey[700],
                      fontSize: 14,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Lat: ${_selectedLocation.latitude.toStringAsFixed(6)}, '
                    'Lng: ${_selectedLocation.longitude.toStringAsFixed(6)}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        // Instructions overlay
        Positioned(
          bottom: 16,
          left: 16,
          right: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Card(
                color: Colors.black87,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      const Icon(Icons.info_outline, color: Colors.white, size: 20),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Tap on the map or drag the marker to select your location',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 8),
              // Skip map button
              TextButton(
                onPressed: _nextPage,
                style: TextButton.styleFrom(
                  backgroundColor: Colors.white.withOpacity(0.9),
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
                child: const Text(
                  'Skip Map - Enter Address Manually',
                  style: TextStyle(
                    color: Colors.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildAddressFormPage() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Location summary card showing selected coordinates
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Container(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green, size: 20),
                        SizedBox(width: 8),
                        Text(
                          'Location Selected',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _selectedAddressText ?? 'Location coordinates selected',
                      style: TextStyle(
                        color: Colors.grey[700],
                        fontSize: 13,
                      ),
                    ),
                    if (_latitude != null && _longitude != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          'Coordinates: ${_latitude!.toStringAsFixed(6)}, ${_longitude!.toStringAsFixed(6)}',
                          style: TextStyle(
                            color: Colors.grey[600],
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            // Address label field (Home, Office, etc.) - Optional
            TextFormField(
              controller: _labelController,
              decoration: InputDecoration(
                labelText: "Address Label (Optional)",
                hintText: "e.g., Home, Office, etc.",
                prefixIcon: const Icon(Icons.label_outline),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            // Street and building number fields (side by side)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _streetController,
                    decoration: InputDecoration(
                      labelText: "Street",
                      hintText: "Street name",
                      prefixIcon: const Icon(Icons.streetview),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _buildingNumberController,
                    decoration: InputDecoration(
                      labelText: "Building #",
                      hintText: "123",
                      prefixIcon: const Icon(Icons.home),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // City and postal code fields (side by side)
            Row(
              children: [
                Expanded(
                  flex: 2,
                  child: TextFormField(
                    controller: _postalCodeController,
                    decoration: InputDecoration(
                      labelText: "Postal Code",
                      hintText: "75001",
                      prefixIcon: const Icon(Icons.markunread_mailbox),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: TextFormField(
                    controller: _cityController,
                    decoration: InputDecoration(
                      labelText: "City",
                      hintText: "City name",
                      prefixIcon: const Icon(Icons.location_city),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.grey[50],
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Required';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            // Country field - Optional
            TextFormField(
              controller: _countryController,
              decoration: InputDecoration(
                labelText: "Country (Optional)",
                hintText: "Country name",
                prefixIcon: const Icon(Icons.public),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
            ),
            const SizedBox(height: 16),
            // Delivery instructions (optional, multi-line)
            TextFormField(
              controller: _instructionsController,
              decoration: InputDecoration(
                labelText: "Delivery Instructions (Optional)",
                hintText: "e.g., Ring doorbell twice, Apartment 3B",
                prefixIcon: const Icon(Icons.note_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Colors.grey[50],
              ),
              maxLines: 3,
            ),
            const SizedBox(height: 24),
            // Set as default address checkbox
            InkWell(
              onTap: () {
                setState(() {
                  _isDefault = !_isDefault;
                });
              },
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Row(
                  children: [
                    Checkbox(
                      value: _isDefault,
                      onChanged: (value) {
                        setState(() {
                          _isDefault = value ?? false;
                        });
                      },
                      activeColor: Colors.black,
                    ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Set as default address",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            "This address will be used by default for your orders",
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }
}
