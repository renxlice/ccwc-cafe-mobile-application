import 'customization_option.dart';

class CartItem {
  final String id;
  final String productId;
  final String productName;
  final double price;
  final int quantity;
  final String imageUrl;
  final String? notes;
  final List<CustomizationOption>? customizations;
  
  CartItem({
    required this.id,
    required this.productId,
    required this.productName,
    required this.price,
    required this.quantity,
    required this.imageUrl,
    this.notes,
    this.customizations,
  });

  double get customizationPrice {
    if (customizations == null || customizations!.isEmpty) {
      return 0.0;
    }
    return customizations!.fold(0.0, (sum, option) => sum + option.price);
  }
  
  // Calculate total price including customizations
  double get totalPrice {
    return (price + customizationPrice) * quantity;
  }
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'price': price,
      'quantity': quantity,
      'imageUrl': imageUrl,
      'notes': notes,
      'customizations': customizations?.map((x) => x.toMap()).toList(),
    };
  }

  factory CartItem.fromMap(Map<String, dynamic> map) {
    return CartItem(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'],
      price: map['price']?.toDouble(),
      quantity: map['quantity'],
      imageUrl: map['imageUrl'],
      notes: map['notes'],
      customizations: map['customizations'] != null 
          ? List<CustomizationOption>.from(
              map['customizations']?.map((x) => CustomizationOption.fromMap(x)))
          : null,
    );
  }
  
  CartItem copyWith({
    String? id,
    String? productId,
    String? productName,
    double? price,
    int? quantity,
    String? imageUrl,
    String? notes,
    List<CustomizationOption>? customizations,
  }) {
    return CartItem(
      id: id ?? this.id,
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
      imageUrl: imageUrl ?? this.imageUrl,
      notes: notes ?? this.notes,
      customizations: customizations ?? this.customizations,
    );
  }
}