import 'package:flutter/material.dart';
import '../Models/delivery_address_model.dart';

class DeliveryAddressService extends ChangeNotifier {
  static final DeliveryAddressService _instance = DeliveryAddressService._internal();
  factory DeliveryAddressService() => _instance;
  DeliveryAddressService._internal();

  final List<DeliveryAddressModel> _addresses = [];
  DeliveryAddressModel? _selectedAddress;

  List<DeliveryAddressModel> get addresses => List.unmodifiable(_addresses);
  DeliveryAddressModel? get selectedAddress => _selectedAddress;

  void addAddress(DeliveryAddressModel address) {
    if (address.isDefault) {
      // Désactiver les autres adresses par défaut
      for (var addr in _addresses) {
        if (addr.isDefault) {
          _addresses[_addresses.indexOf(addr)] = DeliveryAddressModel(
            id: addr.id,
            userId: addr.userId,
            label: addr.label,
            street: addr.street,
            city: addr.city,
            postalCode: addr.postalCode,
            country: addr.country,
            latitude: addr.latitude,
            longitude: addr.longitude,
            instructions: addr.instructions,
            isDefault: false,
          );
        }
      }
    }
    _addresses.add(address);
    if (address.isDefault || _addresses.length == 1) {
      _selectedAddress = address;
    }
    notifyListeners();
  }

  void updateAddress(DeliveryAddressModel address) {
    final index = _addresses.indexWhere((a) => a.id == address.id);
    if (index != -1) {
      if (address.isDefault) {
        // Désactiver les autres adresses par défaut
        for (var addr in _addresses) {
          if (addr.isDefault && addr.id != address.id) {
            final idx = _addresses.indexOf(addr);
            _addresses[idx] = DeliveryAddressModel(
              id: addr.id,
              userId: addr.userId,
              label: addr.label,
              street: addr.street,
              city: addr.city,
              postalCode: addr.postalCode,
              country: addr.country,
              latitude: addr.latitude,
              longitude: addr.longitude,
              instructions: addr.instructions,
              isDefault: false,
            );
          }
        }
      }
      _addresses[index] = address;
      if (address.isDefault || _selectedAddress?.id == address.id) {
        _selectedAddress = address;
      }
      notifyListeners();
    }
  }

  void deleteAddress(String addressId) {
    _addresses.removeWhere((a) => a.id == addressId);
    if (_selectedAddress?.id == addressId) {
      _selectedAddress = _addresses.isNotEmpty ? _addresses.first : null;
    }
    notifyListeners();
  }

  void selectAddress(DeliveryAddressModel address) {
    _selectedAddress = address;
    notifyListeners();
  }

  void setDefaultAddress(String addressId) {
    final address = _addresses.firstWhere((a) => a.id == addressId);
    updateAddress(DeliveryAddressModel(
      id: address.id,
      userId: address.userId,
      label: address.label,
      street: address.street,
      city: address.city,
      postalCode: address.postalCode,
      country: address.country,
      latitude: address.latitude,
      longitude: address.longitude,
      instructions: address.instructions,
      isDefault: true,
    ));
  }
}




