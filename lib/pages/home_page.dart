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
  List<Product> _allProducts = [];
  String? _selectedTag; // null means no filter

  @override
  void initState() {
    super.initState();

    _loadProducts();
    // ProductStorage.deleteAllProducts();
  }

  List<String> get _availableTags {
    final tags = _allProducts.map((p) => p.tag).toSet().toList();
    tags.sort();
    return tags;
  }

  List<Product> get _filteredProducts {
    if (_selectedTag == null) return _allProducts;
    return _allProducts.where((p) => p.tag == _selectedTag).toList();
  }

  void _loadProducts() async {
    final loaded = await ProductStorage.loadProducts();
    setState(() => _allProducts = loaded);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        title: Text("Product Ratings"),
      ),
      body: Column(
        children: [

          // Tags filter
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: DropdownButton<String>(
              hint: const Text('Filter by tag'),
              value: _selectedTag,
              isExpanded: true,
              items: [
                const DropdownMenuItem<String>(
                  value: null,
                  child: Text('All'),
                ),
                ..._availableTags.map(
                  (tag) => DropdownMenuItem<String>(
                    value: tag,
                    child: Text(tag),
                  ),
                ),
              ],
              onChanged: (value) {
                setState(() => _selectedTag = value);
              },
            ),
          ),

          // Products list
          Expanded(
            child: ListView(
              children: _filteredProducts.map(
                (p) => ListTile(
                  title: Text('${p.name} (${p.rating}/5)'),
                  subtitle: Text('${p.tag} — ${p.description}'),
                  onTap: () async {
                    // Go to CreateProductPage with this product as an argument
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CreateProductPage(selectedProduct: p, allProducts: _allProducts),
                      ),
                    );

                    // Reload after coming back
                    _loadProducts();
                  },
                ),
              ).toList(),
            ),
          ),

        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          // Navigate to the create product screen
          await Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => CreateProductPage(allProducts: _allProducts)),
          );
          // After returning, you could refresh data later
          _loadProducts();
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
