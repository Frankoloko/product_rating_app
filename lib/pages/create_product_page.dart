import 'package:flutter/material.dart';
import '../data_models/product.dart';
import '../other/storage.dart';
import 'scan_barcode_page.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer';

class CreateProductPage extends StatefulWidget {
  final Product? selectedProduct;
  final List<Product>? allProducts;

  const CreateProductPage({super.key, this.selectedProduct, this.allProducts});

  @override
  State<CreateProductPage> createState() => _CreateProductPageState();
}

class _CreateProductPageState extends State<CreateProductPage> {
  final _formKey = GlobalKey<FormState>();
  bool _inUpdateMode = false;

  final _productIdController = TextEditingController(text: '5449000000996');  // Coca-cola
  final _productNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _ratingController = TextEditingController();
  final _tagController = TextEditingController();
  final _imageURLController = TextEditingController();

  late List<String> _allTags;

  @override
  void initState() {
    super.initState();

    _inUpdateMode = widget.selectedProduct != null;

    if (_inUpdateMode) {
      _productIdController.text = widget.selectedProduct!.barcode;
      _ratingController.text = widget.selectedProduct!.rating.toString();
      _descriptionController.text = widget.selectedProduct!.description;
      _tagController.text = widget.selectedProduct!.tag;
      _productNameController.text = widget.selectedProduct!.name;
      _imageURLController.text = widget.selectedProduct!.imageURL;
    } else {
      // If we are in create new mode, go straight to the barcode scan page
      // Delay navigation until after first frame
      WidgetsBinding.instance.addPostFrameCallback((_) async {
        _scanBarcode();
      });
    }

    // Get the list of tags the user can use
    _allTags = (widget.allProducts ?? [])
      .map((p) => p.tag.trim())
      .where((tag) => tag.isNotEmpty)
      .toSet() // remove duplicates
      .toList();
  }

  void _scanBarcode() async {
    final barcode = await Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => const ScanBarcodePage()),
    );

    if (barcode == null) {
      // The user didn't scan anything, so go back to home page.
      Navigator.pop(context);
      return;
    }

    final uri = Uri.parse('https://world.openfoodfacts.org/api/v0/product/$barcode.json');
    final response = await http.get(uri);
    if (response.statusCode != 200) {
      _showErrorPopup();
      return;
    }

    final data = jsonDecode(response.body);
    if (data['status'] != 1) {
      if (data["status_verbose"] == "product not found") {
        _showErrorPopup(message: "Product not found");
      } else {
        // Generic error
        _showErrorPopup();
      }

      _showErrorPopup();
      log(data);
      return;
    }

    String name = data['product']['product_name_en'] ?? 'Unknown';
    String imageURL = data['product']['image_small_url'] ?? 'Unknown';

    setState(() {
      _productIdController.text = barcode;
      _productNameController.text = name;
      _imageURLController.text = imageURL;
    });
  }

  @override
  void dispose() {
    _productIdController.dispose();
    _ratingController.dispose();
    _descriptionController.dispose();
    _tagController.dispose();
    super.dispose();
  }

  void _showErrorPopup({String message = "Something went wrong. Please try again."}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
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
    final name = _productNameController.text;
    final image = _imageURLController.text;

    final p = Product(
      barcode: id,
      name: name,
      rating: rating,
      tag: tag,
      description: description,
      imageURL: image,
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
      appBar: AppBar(title: Text(_inUpdateMode ? 'Update product' : 'Create New Product')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [

              // // Keep around for debugging purposes
              // TextFormField(
              //   controller: _productIdController,
              //   decoration: const InputDecoration(
              //     labelText: 'Product ID',
              //   ),
              //   enabled: !_inUpdateMode,
              //   validator: (value) =>
              //       value == null || value.isEmpty ? 'Enter a product ID' : null,
              // ),

              if (_imageURLController.text.isNotEmpty)
                Image.network(
                  _imageURLController.text,
                  height: 200,
                  fit: BoxFit.cover,
                ),

              if (_productNameController.text.isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  _productNameController.text,
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
              ],

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
                  labelText: 'Your notes (optional)',
                ),
                minLines: 1, // Starts as a single line
                maxLines: null, // Grows as the user types (wraps downward)
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
                child: Text(_inUpdateMode ? 'Update' : 'Create'),
              ),

              const SizedBox(height: 24),
              if (_inUpdateMode)
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
