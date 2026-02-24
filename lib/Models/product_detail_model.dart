import 'package:flutter/material.dart';
import 'package:vlog/Models/model.dart';
import 'package:vlog/Utils/parse_utils.dart';

class ProductDetailModel {
  final int id;
  final String name;
  final String description;
  final double price;
  final String image;
  final int categoryId;
  final int subcategoryId;
  final String createdAt;
  final String updatedAt;
  final double rating; // Default rating value
  final String unitType; // e.g. "piece", "kg", "liter"

  ProductDetailModel({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.categoryId,
    required this.subcategoryId,
    required this.createdAt,
    required this.updatedAt,
    this.rating = 4.0, // Default rating value
    this.unitType = 'piece',
  });

  factory ProductDetailModel.fromMap(Map<String, dynamic> map) {
    final r = parseDouble(map['rating']);
    return ProductDetailModel(
      id: parseInt(map['id']),
      name: map['name']?.toString() ?? '',
      description: map['description']?.toString() ?? '',
      price: parseDouble(map['price']),
      image: map['image']?.toString() ?? '',
      categoryId: parseInt(map['category_id']),
      subcategoryId: parseInt(map['subcategory_id']),
      createdAt: map['created_at']?.toString() ?? '',
      updatedAt: map['updated_at']?.toString() ?? '',
      rating: r > 0 ? r : 4.0,
      unitType: map['unit_type']?.toString().trim().toLowerCase() ?? 'piece',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'image': image,
      'category_id': categoryId,
      'subcategory_id': subcategoryId,
      'created_at': createdAt,
      'updated_at': updatedAt,
      'rating': rating,
      'unit_type': unitType,
    };
  }

  // Convert to itemModel for compatibility with existing code
  itemModel toItemModel() {
    return itemModel(
      name: name,
      description: description,
      price: price.toInt(),
      categoryId: categoryId,
      image: image,
      rating: rating,
      review: '',
      fcolor: [Colors.red, Colors.blue, Colors.green],
      size: ['S', 'M', 'L', 'XL'],
    );
  }
}
