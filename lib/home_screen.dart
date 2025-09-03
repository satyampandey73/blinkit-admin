import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/banner_provider.dart';
import 'providers/category_provider.dart';
import 'providers/product_provider.dart';
import 'providers/order_provider.dart';
import 'screens/users_screen.dart';
import 'screens/banners_screen.dart';
import 'screens/categories_screen.dart';
import 'screens/products_screen.dart';
import 'screens/order_screen.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  Widget _infoCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required AsyncSnapshot<int> snapshot,
    required Color color,
  }) {
    final bool loading = snapshot.connectionState == ConnectionState.waiting;
    final String text;
    if (snapshot.hasError) {
      text = 'Error';
    } else if (loading) {
      text = '';
    } else {
      text = '${snapshot.data ?? 0}';
    }

    return Card(
      elevation: 2,
      child: InkWell(
        onTap: () {
          // Navigate to the corresponding detail/list screen for this card
          switch (label) {
            case 'Users':
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const UsersScreen()));
              break;
            case 'Orders':
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const OrderDashboardScreen()),
              );
              break;
            case 'Banners':
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const BannersScreen()));
              break;
            case 'Categories':
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => const CategoriesScreen()),
              );
              break;
            case 'Products':
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const ProductsScreen()));
              break;
            default:
              break;
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: color.withAlpha((0.12 * 255).round()),
                child: Icon(icon, color: color),
              ),
              const SizedBox(height: 12),
              Text(label, style: const TextStyle(fontSize: 16)),
              const SizedBox(height: 8),
              if (loading)
                const SizedBox(
                  height: 24,
                  width: 24,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              if (!loading)
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              if (snapshot.hasError) ...[
                const SizedBox(height: 8),
                Text(
                  snapshot.error.toString(),
                  style: const TextStyle(color: Colors.red, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    // Streams for counts
    final usersStream = FirebaseFirestore.instance
        .collection('users')
        .snapshots()
        .map((s) => s.docs.length);
    final bannersStream = Provider.of<BannerProvider>(
      context,
      listen: false,
    ).bannersStream().map((l) => l.length);
    final categoriesStream = Provider.of<CategoryProvider>(
      context,
      listen: false,
    ).supCategoriesStream().map((l) => l.length);
    final productsStream = Provider.of<ProductProvider>(
      context,
      listen: false,
    ).productsStream().map((l) => l.length);
    final ordersStream = Provider.of<OrderProvider>(
      context,
      listen: false,
    ).streamOrders().map((l) => l.length);

    return Scaffold(
      appBar: AppBar(title: const Text('Dashboard'), centerTitle: true),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: GridView.count(
          crossAxisCount: 2,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          children: [
            StreamBuilder<int>(
              stream: usersStream,
              builder: (ctx, snap) => _infoCard(
                ctx,
                icon: Icons.person,
                label: 'Users',
                snapshot: snap,
                color: Colors.blue,
              ),
            ),
            StreamBuilder<int>(
              stream: bannersStream,
              builder: (ctx, snap) => _infoCard(
                ctx,
                icon: Icons.photo,
                label: 'Banners',
                snapshot: snap,
                color: Colors.purple,
              ),
            ),
            StreamBuilder<int>(
              stream: categoriesStream,
              builder: (ctx, snap) => _infoCard(
                ctx,
                icon: Icons.category,
                label: 'Categories',
                snapshot: snap,
                color: Colors.orange,
              ),
            ),
            StreamBuilder<int>(
              stream: productsStream,
              builder: (ctx, snap) => _infoCard(
                ctx,
                icon: Icons.shopping_bag,
                label: 'Products',
                snapshot: snap,
                color: Colors.green,
              ),
            ),
            StreamBuilder<int>(
              stream: ordersStream,
              builder: (ctx, snap) => _infoCard(
                ctx,
                icon: Icons.receipt_long,
                label: 'Orders',
                snapshot: snap,
                color: Colors.teal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
