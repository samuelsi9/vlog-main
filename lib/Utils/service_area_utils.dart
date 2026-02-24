import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';

/// Supported delivery area: Nicosia only. No services outside Nicosia.
const List<String> supportedCities = [
  'Nicosia', 'Lefkoşa', 'Lefkosa', 'NICOSIA',
];

/// Display name for the service area (used in "coming soon" message).
const String serviceCityDisplayName = 'Nicosia';

/// Checks if [city] is within the service area.
bool isCityInServiceArea(String city) {
  if (city.isEmpty) return false;
  final normalized = city.trim().toLowerCase();
  return supportedCities.any((c) => c.toLowerCase() == normalized);
}

/// Reverse-geocodes [latitude] and [longitude] to get the locality (city) name.
/// Returns null if geocoding fails.
Future<String?> getCityFromCoordinates(double latitude, double longitude) async {
  try {
    final placemarks = await placemarkFromCoordinates(latitude, longitude);
    if (placemarks.isEmpty) return null;
    final locality = placemarks.first.locality?.trim();
    final administrativeArea = placemarks.first.administrativeArea?.trim();
    return (locality?.isNotEmpty == true) ? locality : administrativeArea;
  } catch (_) {
    return null;
  }
}

/// Checks if the user's location ([latitude], [longitude]) is within the service area.
/// Returns a record: (isInArea: bool, detectedCity: String?).
Future<({bool isInArea, String? detectedCity})> checkServiceArea(
  double latitude,
  double longitude,
) async {
  final city = await getCityFromCoordinates(latitude, longitude);
  if (city == null || city.isEmpty) {
    return (isInArea: true, detectedCity: null); // Allow if we can't determine city
  }
  return (isInArea: isCityInServiceArea(city), detectedCity: city);
}

/// Shows the "coming soon" dialog when user is outside the service area.
/// Includes option to browse the app anyway (see how it works).
void showComingSoonDialog(BuildContext context, {String? detectedCity}) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      title: Row(
        children: [
          Icon(Icons.location_off, color: Colors.orange[700], size: 28),
          const SizedBox(width: 12),
          const Expanded(
            child: Text(
              'Out of service area',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
      content: Text(
        detectedCity != null
            ? "You're not in $serviceCityDisplayName (detected: $detectedCity). Delivery for other cities — coming soon!"
            : "You're not in our delivery area ($serviceCityDisplayName). For other cities — coming soon!",
        style: const TextStyle(fontSize: 15, height: 1.4),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('OK'),
        ),
        FilledButton(
          onPressed: () => Navigator.pop(context),
          style: FilledButton.styleFrom(
            backgroundColor: Colors.orange[700],
          ),
          child: const Text('See how the app works'),
        ),
      ],
    ),
  );
}
