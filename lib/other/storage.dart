import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../data_models/product.dart';

class ProductStorage {
  static Future<String> _getFilePath() async {
    final dir = await getApplicationDocumentsDirectory();
    return '${dir.path}/products.json';
  }

  static Future<void> deleteAllProducts() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
        print('Products file deleted.');
      }
    } catch (e) {
      print('Error deleting products file: $e');
    }
  }

  static Future<List<Product>> loadProducts() async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      if (await file.exists()) {
        final contents = await file.readAsString();
        return productsFromJson(contents);
      } else {
        return [];
      }
    } catch (e) {
      print('Error loading products: $e');
      return [];
    }
  }

  static Future<void> saveProducts(List<Product> products) async {
    try {
      final path = await _getFilePath();
      final file = File(path);
      await file.writeAsString(productsToJson(products));
    } catch (e) {
      print('Error saving products: $e');
    }
  }

  static Future<void> deleteProduct(Product product) async {
    final products = await loadProducts();
    products.removeWhere((p) => p.barcode == product.barcode);
    await saveProducts(products);
  }

}
