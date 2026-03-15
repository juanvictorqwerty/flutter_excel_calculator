// Exercise 3: Product List with Details
// Flutter app with two screens, ViewModel (ChangeNotifier), and Navigator.

import 'package:flutter/material.dart';

void main() => runApp(const MyApp());

// ── Data model ────────────────────────────────────────────────────────────────
class Product {
  final int id;
  final String name;
  final double price;

  const Product({
    required this.id,
    required this.name,
    required this.price,
  });
}

// ── ViewModel (ChangeNotifier = observable state) ─────────────────────────────
class ProductViewModel extends ChangeNotifier {
  final List<Product> products = const [
    Product(id: 1, name: 'Laptop',  price: 999.99),
    Product(id: 2, name: 'Phone',   price: 599.99),
    Product(id: 3, name: 'Headset', price: 149.99),
    Product(id: 4, name: 'Tablet',  price: 449.99),
  ];

  Product? _selected;

  // Getter — read-only from outside
  Product? get selected => _selected;

  // Setter — notifies listeners so dependent widgets rebuild
  void selectProduct(Product p) {
    _selected = p;
    notifyListeners();
  }
}

// ── App entry ─────────────────────────────────────────────────────────────────
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    // ViewModel created once at the top and passed down
    final vm = ProductViewModel();

    return MaterialApp(
      title: 'Product App',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.indigo),
        useMaterial3: true,
      ),
      home: ProductListScreen(vm: vm),
    );
  }
}

// ── Screen 1: Product list ────────────────────────────────────────────────────
class ProductListScreen extends StatelessWidget {
  final ProductViewModel vm;

  const ProductListScreen({required this.vm, super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Products'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: ListView.separated(
        itemCount: vm.products.length,
        separatorBuilder: (_, __) => const Divider(height: 1),
        itemBuilder: (ctx, i) {
          final product = vm.products[i];
          return ListTile(
            title: Text(product.name),
            subtitle: Text('\$${product.price.toStringAsFixed(2)}'),
            trailing: const Icon(Icons.chevron_right),
            onTap: () {
              vm.selectProduct(product); // store selection in ViewModel
              Navigator.of(ctx).push(
                MaterialPageRoute(
                  builder: (_) => ProductDetailScreen(vm: vm),
                ),
              );
            },
          );
        },
      ),
    );
  }
}

// ── Screen 2: Product detail ──────────────────────────────────────────────────
class ProductDetailScreen extends StatelessWidget {
  final ProductViewModel vm;

  const ProductDetailScreen({required this.vm, super.key});

  @override
  Widget build(BuildContext context) {
    // Read the selected product from the ViewModel
    final product = vm.selected!;

    return Scaffold(
      appBar: AppBar(
        title: Text(product.name),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              product.name,
              style: Theme.of(context).textTheme.headlineMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '\$${product.price.toStringAsFixed(2)}',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  // Add-to-cart logic goes here
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('${product.name} added to cart!'),
                    ),
                  );
                },
                icon: const Icon(Icons.shopping_cart),
                label: const Text('Add to cart'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
