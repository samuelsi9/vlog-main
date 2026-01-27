import 'package:flutter/material.dart';
import 'package:vlog/Models/model.dart';

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
  });

  factory ProductDetailModel.fromMap(Map<String, dynamic> map) {
    return ProductDetailModel(
      id: map['id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      image: map['image'] as String? ?? '',
      categoryId: map['category_id'] as int? ?? 0,
      subcategoryId: map['subcategory_id'] as int? ?? 0,
      createdAt: map['created_at'] as String? ?? '',
      updatedAt: map['updated_at'] as String? ?? '',
      rating: (map['rating'] as num?)?.toDouble() ?? 4.0, // Default to 4.0 if not provided
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
