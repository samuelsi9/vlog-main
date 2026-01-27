import 'package:flutter/material.dart';

class Restaurant {
  final String id;
  final String name;
  final String description;
  final String image;
  final double rating;
  final int reviewCount;
  final String cuisineType;
  final double deliveryTime; // en minutes
  final double deliveryFee;
  final double minOrder;
  final double distance; // en km
  final bool isOpen;
  final bool isPromoted;
  final Color primaryColor;
  final List<String> images;
  final String address;
  final double latitude;
  final double longitude;
  final List<String> tags; // ["vegetarian", "fast-food", etc.]

  Restaurant({
    required this.id,
    required this.name,
    required this.description,
    required this.image,
    required this.rating,
    required this.reviewCount,
    required this.cuisineType,
    required this.deliveryTime,
    required this.deliveryFee,
    required this.minOrder,
    required this.distance,
    required this.isOpen,
    this.isPromoted = false,
    this.primaryColor = Colors.orange,
    this.images = const [],
    required this.address,
    required this.latitude,
    required this.longitude,
    this.tags = const [],
  });

  factory Restaurant.fromMap(Map<String, dynamic> map) {
    return Restaurant(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      image: map['image']?.toString() ?? '',
      rating: (map['rating'] ?? 0.0).toDouble(),
      reviewCount: map['reviewCount'] ?? 0,
      cuisineType: map['cuisineType']?.toString() ?? '',
      deliveryTime: (map['deliveryTime'] ?? 30.0).toDouble(),
      deliveryFee: (map['deliveryFee'] ?? 2.0).toDouble(),
      minOrder: (map['minOrder'] ?? 10.0).toDouble(),
      distance: (map['distance'] ?? 0.0).toDouble(),
      isOpen: map['isOpen'] ?? true,
      isPromoted: map['isPromoted'] ?? false,
      address: map['address']?.toString() ?? '',
      latitude: (map['latitude'] ?? 0.0).toDouble(),
      longitude: (map['longitude'] ?? 0.0).toDouble(),
      tags: List<String>.from(map['tags'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'image': image,
      'rating': rating,
      'reviewCount': reviewCount,
      'cuisineType': cuisineType,
      'deliveryTime': deliveryTime,
      'deliveryFee': deliveryFee,
      'minOrder': minOrder,
      'distance': distance,
      'isOpen': isOpen,
      'isPromoted': isPromoted,
      'address': address,
      'latitude': latitude,
      'longitude': longitude,
      'tags': tags,
    };
  }
}

// Données de démonstration
List<Restaurant> demoRestaurants = [
  Restaurant(
    id: '1',
    name: 'Le Bon Burger',
    description: 'Burgers artisanaux préparés avec des ingrédients frais',
    image: 'assets/cafe.png',
    rating: 4.7,
    reviewCount: 1245,
    cuisineType: 'Fast-Food',
    deliveryTime: 25,
    deliveryFee: 2.99,
    minOrder: 15.0,
    distance: 1.2,
    isOpen: true,
    isPromoted: true,
    address: '123 Rue de la Paix, Paris',
    latitude: 48.8566,
    longitude: 2.3522,
    tags: ['burger', 'fast-food', 'halal'],
  ),
  Restaurant(
    id: '2',
    name: 'Sushi Tokyo',
    description: 'Sushis et sashimis préparés par nos maîtres sushi',
    image: 'assets/fresh.png',
    rating: 4.9,
    reviewCount: 856,
    cuisineType: 'Japonais',
    deliveryTime: 35,
    deliveryFee: 3.50,
    minOrder: 20.0,
    distance: 2.5,
    isOpen: true,
    isPromoted: true,
    address: '45 Avenue des Champs, Paris',
    latitude: 48.8698,
    longitude: 2.3314,
    tags: ['sushi', 'japonais', 'poisson'],
  ),
  Restaurant(
    id: '3',
    name: 'Pizza Napoli',
    description: 'Pizzas authentiques au feu de bois',
    image: 'assets/tomate.png',
    rating: 4.6,
    reviewCount: 1890,
    cuisineType: 'Italien',
    deliveryTime: 30,
    deliveryFee: 2.50,
    minOrder: 12.0,
    distance: 0.8,
    isOpen: true,
    address: '78 Boulevard Saint-Germain, Paris',
    latitude: 48.8534,
    longitude: 2.3488,
    tags: ['pizza', 'italien', 'végétarien'],
  ),
  Restaurant(
    id: '4',
    name: 'Curry House',
    description: 'Spécialités indiennes épicées',
    image: 'assets/choco.png',
    rating: 4.5,
    reviewCount: 567,
    cuisineType: 'Indien',
    deliveryTime: 40,
    deliveryFee: 3.00,
    minOrder: 18.0,
    distance: 3.2,
    isOpen: true,
    address: '12 Rue de la République, Paris',
    latitude: 48.8606,
    longitude: 2.3376,
    tags: ['indien', 'épicé', 'végétarien'],
  ),
  Restaurant(
    id: '5',
    name: 'Tacos Express',
    description: 'Tacos, burritos et quesadillas',
    image: 'assets/lays.png',
    rating: 4.4,
    reviewCount: 723,
    cuisineType: 'Mexicain',
    deliveryTime: 20,
    deliveryFee: 2.00,
    minOrder: 10.0,
    distance: 1.5,
    isOpen: true,
    address: '56 Rue de Rivoli, Paris',
    latitude: 48.8556,
    longitude: 2.3515,
    tags: ['mexicain', 'fast-food', 'halal'],
  ),
  Restaurant(
    id: '6',
    name: 'Thai Garden',
    description: 'Cuisine thaïlandaise traditionnelle',
    image: 'assets/olive.png',
    rating: 4.8,
    reviewCount: 432,
    cuisineType: 'Thaïlandais',
    deliveryTime: 35,
    deliveryFee: 3.50,
    minOrder: 22.0,
    distance: 4.1,
    isOpen: true,
    address: '89 Rue du Faubourg, Paris',
    latitude: 48.8638,
    longitude: 2.3274,
    tags: ['thaïlandais', 'épicé', 'végétarien'],
  ),
];


