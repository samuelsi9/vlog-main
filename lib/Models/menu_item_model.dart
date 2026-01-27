class MenuItem {
  final String id;
  final String restaurantId;
  final String name;
  final String description;
  final double price;
  final String image;
  final String category;
  final bool isAvailable;
  final bool isVegetarian;
  final bool isVegan;
  final bool isSpicy;
  final List<String> allergens;
  final double rating;
  final int reviewCount;
  final List<Variation> variations; // Taille, options, etc.

  MenuItem({
    required this.id,
    required this.restaurantId,
    required this.name,
    required this.description,
    required this.price,
    required this.image,
    required this.category,
    this.isAvailable = true,
    this.isVegetarian = false,
    this.isVegan = false,
    this.isSpicy = false,
    this.allergens = const [],
    this.rating = 0.0,
    this.reviewCount = 0,
    this.variations = const [],
  });
}

class Variation {
  final String id;
  final String name;
  final List<VariationOption> options;
  final bool required;

  Variation({
    required this.id,
    required this.name,
    required this.options,
    this.required = false,
  });
}

class VariationOption {
  final String id;
  final String name;
  final double price; // Prix supplémentaire

  VariationOption({required this.id, required this.name, this.price = 0.0});
}

// Données de démonstration
Map<String, List<MenuItem>> demoMenus = {
  '1': [
    // Le Bon Burger
    MenuItem(
      id: 'm1',
      restaurantId: '1',
      name: 'Burger Classic',
      description: 'Steak haché, salade, tomate, oignon, sauce maison',
      price: 8.50,
      image: 'assets/cafe.png',
      category: 'Burgers',
      isAvailable: true,
      isVegetarian: false,
      rating: 4.6,
      reviewCount: 234,
      variations: [
        Variation(
          id: 'v1',
          name: 'Taille',
          required: true,
          options: [
            VariationOption(id: 'o1', name: 'Standard', price: 0),
            VariationOption(id: 'o2', name: 'Grand', price: 2.0),
          ],
        ),
        Variation(
          id: 'v2',
          name: 'Suppléments',
          required: false,
          options: [
            VariationOption(id: 'o3', name: 'Fromage', price: 1.0),
            VariationOption(id: 'o4', name: 'Bacon', price: 1.5),
            VariationOption(id: 'o5', name: 'Oeuf', price: 1.0),
          ],
        ),
      ],
    ),
    MenuItem(
      id: 'm2',
      restaurantId: '1',
      name: 'Burger Végétarien',
      description: 'Steak de légumes, salade, tomate, sauce spéciale',
      price: 7.50,
      image: 'assets/tomate.png',
      category: 'Burgers',
      isAvailable: true,
      isVegetarian: true,
      rating: 4.5,
      reviewCount: 156,
    ),
    MenuItem(
      id: 'm3',
      restaurantId: '1',
      name: 'Frites',
      description: 'Frites maison croustillantes',
      price: 3.50,
      image: 'assets/lays.png',
      category: 'Accompagnements',
      isAvailable: true,
      isVegetarian: true,
    ),
    MenuItem(
      id: 'm4',
      restaurantId: '1',
      name: 'Coca-Cola',
      description: 'Coca-Cola 33cl',
      price: 2.50,
      image: 'assets/cocacola.png',
      category: 'Boissons',
      isAvailable: true,
      isVegetarian: true,
    ),
  ],
  '2': [
    // Sushi Tokyo
    MenuItem(
      id: 'm5',
      restaurantId: '2',
      name: 'Plateau Sushi Mix',
      description: '12 pièces de sushi variés',
      price: 18.00,
      image: 'assets/fresh.png',
      category: 'Sushis',
      isAvailable: true,
      rating: 4.8,
      reviewCount: 445,
    ),
    MenuItem(
      id: 'm6',
      restaurantId: '2',
      name: 'Sashimi Saumon',
      description: '6 tranches de saumon frais',
      price: 12.00,
      image: 'assets/frozenchicken.png',
      category: 'Sashimis',
      isAvailable: true,
    ),
  ],
  '3': [
    // Pizza Napoli
    MenuItem(
      id: 'm7',
      restaurantId: '3',
      name: 'Pizza Margherita',
      description: 'Tomate, mozzarella, basilic',
      price: 10.00,
      image: 'assets/tomate.png',
      category: 'Pizzas',
      isAvailable: true,
      isVegetarian: true,
      rating: 4.7,
      reviewCount: 892,
    ),
    MenuItem(
      id: 'm8',
      restaurantId: '3',
      name: 'Pizza Quattro Stagioni',
      description:
          'Tomate, mozzarella, jambon, champignons, artichauts, olives',
      price: 13.50,
      image: 'assets/olive.png',
      category: 'Pizzas',
      isAvailable: true,
    ),
  ],
};
