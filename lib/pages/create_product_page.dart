import 'package:flutter/material.dart';
import '../data_models/product.dart';
import '../other/storage.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateProductPage extends StatefulWidget {
  const CreateProductPage({super.key});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();

  final _productIdController = TextEditingController(text: '5449000000996');  // Coca-cola
  // final _productIdController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ratingController = TextEditingController();
  final _tagController = TextEditingController();

  @override
  void dispose() {
    _productIdController.dispose();
    _ratingController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _createProduct() async {
    if (_formKey.currentState!.validate()) {
      final id = _productIdController.text;
      final rating = int.parse(_ratingController.text);
      final description = _descriptionController.text;
      final tag = _tagController.text;

      // Just print for now (later you’ll save this)
      debugPrint('Created product: ID=$id, Rating=$rating, Desc=$description, Tag=$tag');
      final uri = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$id.json');
      final response = await http.get(uri);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        String name = data['product']['product_name'] ?? 'Unknown';

        final p = Product(
          barcode: id,
          name: name,
          rating: rating,
          tag: tag,
          description: description,
        );

        final loaded = await ProductStorage.loadProducts();
        loaded.add(p);
        await ProductStorage.saveProducts(loaded);
      }

      // Go back to previous screen
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Product')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              TextFormField(
                controller: _productIdController,
                decoration: const InputDecoration(
                  labelText: 'Product ID',
                ),
                validator: (value) =>
                    value == null || value.isEmpty ? 'Enter a product ID' : null,
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _ratingController,
                decoration: const InputDecoration(
                  labelText: 'Rating (integer)',
                ),
                keyboardType: TextInputType.number,
                validator: (value) {
                  final number = int.tryParse(value ?? '');
                  if (number == null) return 'Enter a valid integer';
                  return null;
                },
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(
                  labelText: 'Description (optional)',
                ),
              ),

              const SizedBox(height: 16),
              TextFormField(
                controller: _tagController,
                decoration: const InputDecoration(
                  labelText: 'Tag (optional)',
                ),
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createProduct,
                child: const Text('Create'),
              ),

            ],
          ),
        ),
      ),
    );
  }
}
