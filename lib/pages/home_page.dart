import 'package:flutter/material.dart';
import 'create_product_page.dart';
import '../other/storage.dart';
import '../data_models/product.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Product> _products = [];

  @override
  void initState() {
    super.initState();

    _loadProducts();
    // ProductStorage.deleteAllProducts();
  }

  void _loadProducts() async {
    final loaded = await ProductStorage.loadProducts();
    setState(() => _products = loaded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Product Ratings"),
      ),
      body: ListView(
        children: _products
            .map(
              (p) => ListTile(
                title: Text('${p.name} (${p.barcode}) (${p.rating}/5)'),
                subtitle: Text('${p.tag} — ${p.description}'),
              ),
            )
            .toList(),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to the create product screen
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => const CreateProductPage()),
          );
          // After returning, you could refresh data later
          _loadProducts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
