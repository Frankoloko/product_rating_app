import 'package:flutter/material.dart';
import '../data_models/product.dart';
import '../other/storage.dart';
import 'scan_barcode_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class CreateProductPage extends StatefulWidget {
  final Product? selectedProduct;
  final List<Product>? allProducts;

  const CreateProductPage({super.key, this.selectedProduct, this.allProducts});

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

  late List<String> _allTags;

  @override
  void initState() {
    super.initState();

    if (widget.selectedProduct != null) {
      _productIdController.text = widget.selectedProduct!.barcode;
      _ratingController.text = widget.selectedProduct!.rating.toString();
      _descriptionController.text = widget.selectedProduct!.description;
      _tagController.text = widget.selectedProduct!.tag;
      // _productName = widget.selectedProduct!.name;
    }

    _allTags = (widget.allProducts ?? [])
      .map((p) => p.tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet() // remove duplicates
      .toList();
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _ratingController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _showErrorPopup() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Something went wrong. Please try again.'),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _createProduct() async {
    if (!_formKey.currentState!.validate()) return;

    final id = _productIdController.text;
    final rating = int.parse(_ratingController.text);
    final description = _descriptionController.text;
    final tag = _tagController.text;

    final uri = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$id.json');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      _showErrorPopup();
      return;
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 1) {
      _showErrorPopup();
      return;
    }

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

    // Go back to previous screen
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Product')),
      body: SingleChildScrollView(
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

              ElevatedButton(
                onPressed: () async {
                  final barcode = await Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const ScanBarcodePage()),
                  );

                  if (barcode != null) {
                    setState(() {
                      _productIdController.text = barcode;
                    });
                  }
                },
                child: const Text('Scan Barcode'),
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

              Autocomplete<String>(
                optionsBuilder: (TextEditingValue textEditingValue) {
                  // If the user hasn’t typed anything, show nothing
                  if (textEditingValue.text.isEmpty) {
                    return const Iterable<String>.empty();
                  }

                  // Filter tags based on what the user typed
                  return _allTags.where((tag) =>
                      tag.toLowerCase().contains(textEditingValue.text.toLowerCase()));
                },
                onSelected: (String selection) {
                  _tagController.text = selection; // Update the controller
                },
                fieldViewBuilder:
                    (context, textEditingController, focusNode, onFieldSubmitted) {
                  // Use your existing controller
                  textEditingController.text = _tagController.text;

                  return TextFormField(
                    controller: textEditingController,
                    focusNode: focusNode,
                    decoration: const InputDecoration(
                      labelText: 'Tag (optional)',
                    ),
                    onChanged: (value) {
                      _tagController.text = value;
                    },
                  );
                },
              ),

              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _createProduct,
                child: const Text('Create'),
              ),

              if (widget.selectedProduct != null)
                ElevatedButton.icon(
                  icon: const Icon(Icons.delete),
                  label: const Text('Delete Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: () async {
                    await ProductStorage.deleteProduct(widget.selectedProduct!);
                    Navigator.pop(context); // go back to list after deleting
                  },
                ),

            ],
          ),
        ),
      ),
    );
  }
}
