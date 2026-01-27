import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../Models/restaurant_model.dart';
import '../../Models/menu_item_model.dart';
import '../../Utils/restaurant_cart_service.dart';

class MenuItemDetailPage extends StatefulWidget {
  final MenuItem menuItem;
  final Restaurant restaurant;

  const MenuItemDetailPage({
    super.key,
    required this.menuItem,
    required this.restaurant,
  });

  @override
  State<MenuItemDetailPage> createState() => _MenuItemDetailPageState();
}

class _MenuItemDetailPageState extends State<MenuItemDetailPage> {
  final Map<String, String> _selectedVariations = {};
  final Map<String, double> _variationPrices = {};

  @override
  void initState() {
    super.initState();
    // Sélectionner les options par défaut pour les variations requises
    for (var variation in widget.menuItem.variations) {
      if (variation.required && variation.options.isNotEmpty) {
        final defaultOption = variation.options.first;
        _selectedVariations[variation.id] = defaultOption.id;
        if (defaultOption.price > 0) {
          _variationPrices[variation.id] = defaultOption.price;
        }
      }
    }
  }

  double get _totalPrice {
    final basePrice = widget.menuItem.price;
    final variationsPrice = _variationPrices.values.fold(0.0, (sum, price) => sum + price);
    return basePrice + variationsPrice;
  }

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<RestaurantCartService>(context);
    
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: Stack(
                fit: StackFit.expand,
                children: [
                  widget.menuItem.image.isNotEmpty
                      ? Image.asset(
                          widget.menuItem.image,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) {
                            return Container(color: Colors.grey[300]);
                          },
                        )
                      : Container(color: Colors.grey[300]),
                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withOpacity(0.7),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.black, size: 20),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ),
          SliverToBoxAdapter(
            child: Container(
              color: Colors.white,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.menuItem.name,
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        if (widget.menuItem.description.isNotEmpty)
                          Text(
                            widget.menuItem.description,
                            style: TextStyle(
                              color: Colors.grey[700],
                              fontSize: 16,
                              height: 1.5,
                            ),
                          ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Text(
                              "${_totalPrice.toStringAsFixed(2)}€",
                              style: const TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                            ),
                            if (widget.menuItem.rating > 0) ...[
                              const Spacer(),
                              Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 20),
                                  const SizedBox(width: 4),
                                  Text(
                                    widget.menuItem.rating.toStringAsFixed(1),
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    " (${widget.menuItem.reviewCount})",
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],
                        ),
                        if (widget.menuItem.isVegetarian || widget.menuItem.isVegan || widget.menuItem.isSpicy) ...[
                          const SizedBox(height: 16),
                          Wrap(
                            spacing: 8,
                            children: [
                              if (widget.menuItem.isVegetarian)
                                _buildTag("Végétarien", Colors.green),
                              if (widget.menuItem.isVegan)
                                _buildTag("Végan", Colors.green),
                              if (widget.menuItem.isSpicy)
                                _buildTag("Épicé", Colors.red),
                            ],
                          ),
                        ],
                        if (widget.menuItem.allergens.isNotEmpty) ...[
                          const SizedBox(height: 16),
                          Text(
                            "Allergènes: ${widget.menuItem.allergens.join(', ')}",
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  
                  // Variations
                  if (widget.menuItem.variations.isNotEmpty)
                    ...widget.menuItem.variations.map((variation) {
                      return _buildVariationSection(variation);
                    }),
                  
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: widget.menuItem.isAvailable
                ? () {
                    cartService.addItem(
                      menuItem: widget.menuItem,
                      selectedVariations: _selectedVariations,
                      variationPrices: _variationPrices,
                    );
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text("${widget.menuItem.name} ajouté au panier"),
                        backgroundColor: Colors.black,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    );
                    Navigator.pop(context);
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.black,
              disabledBackgroundColor: Colors.grey[300],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              widget.menuItem.isAvailable
                  ? "Ajouter au panier - ${_totalPrice.toStringAsFixed(2)}€"
                  : "Indisponible",
              style: TextStyle(
                color: widget.menuItem.isAvailable ? Colors.white : Colors.grey[600],
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildVariationSection(Variation variation) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                variation.name,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              if (variation.required)
                Text(
                  " *",
                  style: TextStyle(color: Colors.red[400], fontSize: 16),
                ),
            ],
          ),
          const SizedBox(height: 12),
          ...variation.options.map((option) {
            final isSelected = _selectedVariations[variation.id] == option.id;
            return InkWell(
              onTap: () {
                setState(() {
                  if (isSelected && !variation.required) {
                    _selectedVariations.remove(variation.id);
                    _variationPrices.remove(variation.id);
                  } else {
                    _selectedVariations[variation.id] = option.id;
                    if (option.price > 0) {
                      _variationPrices[variation.id] = option.price;
                    } else {
                      _variationPrices.remove(variation.id);
                    }
                  }
                });
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isSelected ? Colors.black : Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: isSelected ? Colors.black : Colors.grey[300]!,
                    width: 2,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.grey[400]!,
                          width: 2,
                        ),
                        color: isSelected ? Colors.white : Colors.transparent,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              size: 12,
                              color: Colors.black,
                            )
                          : null,
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        option.name,
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                    ),
                    if (option.price > 0)
                      Text(
                        "+${option.price.toStringAsFixed(2)}€",
                        style: TextStyle(
                          color: isSelected ? Colors.white : Colors.black,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildTag(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: color,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}







