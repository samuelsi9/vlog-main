import 'package:vlog/Models/model.dart';

class SubCategoryModel {
  final int id;
  final String name;
  final int categoryId; // parent category
  final String image;
  final List<itemModel> items; // products in this subcategory

  SubCategoryModel({
    required this.id,
    required this.name,
    required this.categoryId,
    required this.image,
    required this.items,
  });
}

// 🧩 Example subcategories
List<SubCategoryModel> subCategories = [
  SubCategoryModel(
    id: 1,
    name: "Shoes",
    categoryId: 1, // e.g. Women
    image: "assets/shoesa.webp",
    items: itemC.where((item) => item.categoryId == 1).toList(),
  ),
  SubCategoryModel(
    id: 2,
    name: "Bags",
    categoryId: 1, // Women
    image: "assets/bag.jpg",
    items: [],
  ),

  SubCategoryModel(
    id: 3,
    name: "Jackets",
    categoryId: 2, // Men
    image: "assets/men.jpg",
    items: itemC.where((item) => item.categoryId == 2).toList(),
  ),
  SubCategoryModel(
    id: 4,
    name: "Kids Wear",
    categoryId: 3, // Kids
    image: "assets/kids.jpg",
    items: itemC.where((item) => item.categoryId == 3).toList(),
  ),
];
