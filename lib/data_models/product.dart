import 'dart:convert';

class Product {
  final String barcode;
  final String name;
  final int rating;
  final String tag;
  final String description;
  final String imageURL;

  Product({
    required this.barcode,
    required this.name,
    required this.rating,
    required this.tag,
    required this.description,
    required this.imageURL,
  });

  Map<String, dynamic> toJson() => {
    'barcode': barcode,
    'name': name,
    'rating': rating,
    'tag': tag,
    'description': description,
    'imageURL': imageURL,
  };

  factory Product.fromJson(Map<String, dynamic> json) => Product(
    barcode: json['barcode'],
    name: json['name'],
    rating: json['rating'],
    tag: json['tag'],
    description: json['description'],
    imageURL: json['imageURL'],
  );
}

List<Product> productsFromJson(String str) =>
    List<Product>.from(json.decode(str).map((x) => Product.fromJson(x)));

String productsToJson(List<Product> data) =>
    json.encode(List<dynamic>.from(data.map((x) => x.toJson())));
