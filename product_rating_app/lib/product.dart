class Product {
  final int id;           // primary key (auto-increment)
  final String name;
  final int rating;       // 1–5
  final String tag;       // user-defined label
  final String description; // optional
  final String barcode;   // the barcode number string

  Product({required this.id, required this.name, required this.rating,
           required this.tag, required this.description, required this.barcode});

  // Convert Product to a map for database insertion:
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'rating': rating,
      'tag': tag,
      'description': description,
      'barcode': barcode,
    };
  }
}
