import 'package:flutter/material.dart';

class itemModel {
  final String name;
  final String description;
  final int price;
  final int categoryId;
  final String image;
  final double rating;
  final String review;
  final List<Color> fcolor;
  final List<String> size;

  itemModel({
    required this.description,
    required this.price,
    required this.categoryId,
    required this.name,
    required this.image,
    required this.rating,
    required this.review,
    required this.fcolor,
    required this.size,
  });
}

List<itemModel> itemC = [
  itemModel(
    name: "Nescafe Classic",
    description: "new model ",
    price: 145,
    categoryId: 1,
    image: 'assets/cafe.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Tat Tomate",
    description:
        "new model nkjcjhvjdvv h jkvjkv jjfkn jkfjkd fjkdjf kjkjf dk,kjdfjfnj jkdkn",
    price: 30,
    categoryId: 2,
    image: 'assets/tomate.png',
    rating: 2.3,
    review: "too good",
    fcolor: [Colors.black, Colors.orange, Colors.grey],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),

  itemModel(
    name: "Fanta",
    description:
        "new model nkjcjhvjdvv h jkvjkv jjfkn jkfjkd fjkdjf kjkjf dk,kjdfjfnj jkdkn",
    price: 30,
    categoryId: 2,
    image: 'assets/fanta.png',
    rating: 2.3,
    review: "too good",
    fcolor: [Colors.black, Colors.orange, Colors.grey],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Eggs",
    description: "new model ",
    price: 245,
    categoryId: 2,
    image: 'assets/egg.png',
    rating: 2.3,
    review: "too good",
    fcolor: [Colors.purple, Colors.yellow, Colors.pink],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Eker",
    description: "new model ",
    price: 45,
    categoryId: 2,
    image: 'assets/eker.png',
    rating: 2.3,
    review: "too good",
    fcolor: [Colors.green, Colors.blueAccent, Colors.brown],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Sugar",
    description: "new model ",
    price: 45,
    categoryId: 2,
    image: 'assets/sugar.png',
    rating: 2.3,
    review: "too good",
    fcolor: [Colors.green, Colors.blueAccent, Colors.brown],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Lays",
    description: "new model ",
    price: 345,
    categoryId: 2,
    image: 'assets/lays.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Lipton",
    description: "new model ",
    price: 345,
    categoryId: 2,
    image: 'assets/Lipton.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: " Milka ",
    description: "new model ",
    price: 345,
    categoryId: 2,
    image: 'assets/tukas.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: " frozen chiken ",
    description: "new model ",
    price: 345,
    categoryId: 2,
    image: 'assets/frozenchicken.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: " çökokrem ",
    description: "new model ",
    price: 345,
    categoryId: 2,
    image: 'assets/choco.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Super Fresh",
    description: "new model ",
    price: 345,
    categoryId: 2,
    image: 'assets/fresh.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Tat Tomato",
    description: "new model ",
    price: 345,
    categoryId: 2,
    image: 'assets/tat-tomatoes.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "oil  1lt ",
    description: "new model ",
    price: 305,
    categoryId: 2,
    image: 'assets/olive.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Makaronni ",
    description: "new model ",
    price: 345,
    categoryId: 2,
    image: 'assets/maroconni.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Başhan ",
    description: "new model ",
    price: 345,
    categoryId: 2,
    image: 'assets/rice.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Sprite",
    description: "new model ",
    price: 35,
    categoryId: 2,
    image: 'assets/Sprite.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Labne",
    description: "new model ",
    price: 345,
    categoryId: 2,
    image: 'assets/labne.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Nutella",
    description: "new model ",
    price: 305,
    categoryId: 1,
    image: 'assets/shoesa.webp',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: " Corn Flakes ",
    description: "new model ",
    price: 450,
    categoryId: 1,
    image: 'assets/cornflake.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "papper ",
    description: "new model ",
    price: 450,
    categoryId: 1,
    image: 'assets/fam.jpeg',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Coco pops ",
    description: "new model ",
    price: 50,
    categoryId: 1,
    image: 'assets/Cocopops.png',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Nido ",
    description: "new model ",
    price: 50,
    categoryId: 1,
    image: 'assets/nido.jpeg',
    rating: 2.3,
    review: "pounder milk",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Peak ",
    description: "new model ",
    price: 50,
    categoryId: 1,
    image: 'assets/Peak.jpeg',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Makayabu ",
    description: "new model ",
    price: 50,
    categoryId: 1,
    image: 'assets/Makayabu.jpeg',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Çokokrem 400 Gram ",
    description: "new model ",
    price: 500,
    categoryId: 1,
    image: 'assets/chocolate.webp',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "koop 1 lt  ",
    description: "new model ",
    price: 450,
    categoryId: 1,
    image: 'assets/koop.jpg',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Persil 5kg ",
    description: "new model ",
    price: 450,
    categoryId: 1,
    image: 'assets/persil-5-kg-rose.webp',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Tursill 2.14 lt ",
    description: "new model ",
    price: 450,
    categoryId: 1,
    image: 'assets/produt.jpeg',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Laura 4 lt ",
    description: "new model ",
    price: 450,
    categoryId: 1,
    image: 'assets/laura.jpg',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Egg  20pieces",
    description: "new model ",
    price: 450,
    categoryId: 1,
    image: 'assets/egg20.jpg',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Papper 100gr",
    description: "new model ",
    price: 450,
    categoryId: 1,
    image: 'assets/small.jpeg',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Yes",
    description: "new model ",
    price: 450,
    categoryId: 1,
    image: 'assets/yes.jpeg',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
  itemModel(
    name: "Pril",
    description: "new model ",
    price: 450,
    categoryId: 1,
    image: 'assets/Pril.jpeg',
    rating: 2.3,
    review: "too good ",
    fcolor: [Colors.red, Colors.blue, Colors.green],
    size: ["S", "M", "L", "XL"], // ✅ ajouté ici
  ),
];
