class Product {
  final String id;
  final String name;
  final String description;
  final double price;
  final String imageUrl;
  final String category;
  final bool isActive;
  final Map<String, dynamic>? customizationOptions;


  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.category,
    this.isActive = true,
    this.customizationOptions,
  });

  // Convert a Product object into a Map object
  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'category': category,
      'isActive': isActive, 
      'customizationOptions': customizationOptions,
    };
  }

  // Factory method to create a Product from a Map
  factory Product.fromMap(Map<String, dynamic> data, String id) {
    return Product(
      id: id,
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      price: data['price']?.toDouble() ?? 0.0,
      imageUrl: data['imageUrl'] ?? '',
      category: data['category'] ?? 'All',
      isActive: data['isActive'] ?? data['available'] ?? true,
      customizationOptions: data['customizationOptions'],
    );
  }
}