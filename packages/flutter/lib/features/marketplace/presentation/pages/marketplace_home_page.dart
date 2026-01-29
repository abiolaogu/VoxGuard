import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../core/theme/colors.dart';
import '../../../../core/theme/typography.dart';
import '../../../../core/utils/currency_formatter.dart';
import '../widgets/listing_card.dart';
import '../widgets/category_chip.dart';

/// Marketplace home page
class MarketplaceHomePage extends StatefulWidget {
  const MarketplaceHomePage({super.key});

  @override
  State<MarketplaceHomePage> createState() => _MarketplaceHomePageState();
}

class _MarketplaceHomePageState extends State<MarketplaceHomePage> {
  String _selectedCategory = 'All';
  final _searchController = TextEditingController();

  final List<String> _categories = [
    'All',
    'Electronics',
    'Fashion',
    'Home & Garden',
    'Vehicles',
    'Services',
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Marketplace'),
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.add_circle_outline),
            onPressed: () {
              // Navigate to create listing
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search bar
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search products...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: IconButton(
                  icon: const Icon(Icons.tune),
                  onPressed: () {
                    // Show filters
                  },
                ),
              ),
            ),
          ).animate().fadeIn().slideY(begin: -0.1),

          // Categories
          SizedBox(
            height: 48,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              itemCount: _categories.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final category = _categories[index];
                return CategoryChip(
                  label: category,
                  isSelected: _selectedCategory == category,
                  onTap: () {
                    setState(() => _selectedCategory = category);
                  },
                );
              },
            ),
          ).animate().fadeIn(delay: 100.ms).slideX(begin: -0.1),
          const SizedBox(height: 16),

          // Listings grid
          Expanded(
            child: GridView.builder(
              padding: const EdgeInsets.all(16),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 16,
                crossAxisSpacing: 16,
                childAspectRatio: 0.7,
              ),
              itemCount: 10,
              itemBuilder: (context, index) {
                return ListingCard(
                  title: 'Product ${index + 1}',
                  price: (index + 1) * 15000.0,
                  imageUrl: 'https://picsum.photos/200/200?random=$index',
                  location: 'Lagos, Nigeria',
                  isFavorite: index % 3 == 0,
                  onTap: () {
                    // Navigate to listing detail
                  },
                  onFavorite: () {
                    // Toggle favorite
                  },
                ).animate().fadeIn(delay: Duration(milliseconds: 100 * index)).scale(begin: const Offset(0.9, 0.9));
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          // Create new listing
        },
        icon: const Icon(Icons.add),
        label: const Text('Sell'),
      ),
    );
  }
}
