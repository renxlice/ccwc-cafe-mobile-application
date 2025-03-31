import 'package:flutter/foundation.dart';
import '../screens/models/cart_item.dart';
import '../screens/models/product_model.dart';
import '../screens/models/customization_option.dart';

class CartService with ChangeNotifier {
  final Map<String, CartItem> _items = {};

  Map<String, CartItem> get items => {..._items};

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) {
      return sum + item.totalPrice;
    });
  }

  List<CartItem> get cartItems => _items.values.toList();

  // Check if a product is in the cart
  bool isInCart(String productId) {
    return _items.containsKey(productId);
  }

  // Add method to check if a product can be added
  bool canAddToCart(Product product) {
    return product.isActive;
  }

  // Membuat ID unik untuk item cart berdasarkan customizations
  String _createCartItemId(String productId, List<CustomizationOption>? customizations) {
    final String customizationString = customizations != null && customizations.isNotEmpty 
        ? customizations.map((c) => '${c.name}:${c.value}').join('_')
        : '';
    return customizations != null && customizations.isNotEmpty 
        ? '${productId}_$customizationString'
        : productId;
  }

  // Add to cart with customizations
  void addToCart(Product product, int quantity, List<CustomizationOption> customizations) {
    // Don't add items that are inactive
    if (!product.isActive) {
      print('Cannot add inactive product to cart: ${product.name}');
      return;
    }
    
    // Don't add items with quantity <= 0
    if (quantity <= 0) return;

    // Create a unique ID that includes customization info
    final String cartItemId = _createCartItemId(product.id, customizations);

    if (_items.containsKey(cartItemId)) {
      // Jika sudah ada di cart, tambahkan quantity
      _items.update(
        cartItemId,
        (existingItem) => existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      // Jika belum ada di cart, tambahkan item baru
      _items[cartItemId] = CartItem(
        id: DateTime.now().toString(),
        productId: cartItemId, // Menggunakan cartItemId sebagai productId agar unik
        productName: product.name,
        price: product.price,
        quantity: quantity,
        imageUrl: product.imageUrl,
        customizations: customizations.isNotEmpty ? customizations : null,
      );
    }
    
    notifyListeners();
  }

  // Add item (simplified version for incrementing from cart)
  void addItem(Product product, int quantity, [List<CustomizationOption>? customizations]) {
    // Don't add items that are inactive or have quantity <= 0
    if (quantity <= 0) return;
    if (!product.isActive) {
      print('Cannot add inactive product to cart: ${product.name}');
      return;
    }

    // Create a unique ID that includes customization info
    final String cartItemId = _createCartItemId(product.id, customizations);

    if (_items.containsKey(cartItemId)) {
      // Update existing item
      _items.update(
        cartItemId,
        (existingItem) => existingItem.copyWith(
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      // Add new item
      _items[cartItemId] = CartItem(
        id: DateTime.now().toString(),
        productId: cartItemId, // Menggunakan cartItemId sebagai productId agar unik
        productName: product.name,
        price: product.price,
        quantity: quantity,
        imageUrl: product.imageUrl,
        customizations: customizations,
      );
    }
    
    notifyListeners();
  }

  void updateCartItem(String cartItemId, int newQuantity, List<CustomizationOption> customizations) {
  if (!_items.containsKey(cartItemId)) return;
  
  if (newQuantity > 0) {
    // Update both quantity and customizations
    _items.update(
      cartItemId,
      (existingItem) => existingItem.copyWith(
        quantity: newQuantity,
        customizations: customizations,
      ),
    );
  } else {
    // If quantity is 0, remove the item
    _items.remove(cartItemId);
  }
  notifyListeners();
}

  void updateQuantity(String productId, int newQuantity) {
    if (!_items.containsKey(productId)) return;

    if (newQuantity > 0) {
      // Update quantity without changing customization
      _items.update(
        productId,
        (existingItem) => existingItem.copyWith(quantity: newQuantity),
      );
    } else {
      // If quantity is 0, remove the item
      _items.remove(productId);
    }
    notifyListeners();
  }

  void removeItem(String itemId) {
    if (_items.containsKey(itemId)) {
      _items.remove(itemId);
      notifyListeners();
    }
  }

  void removeSingleItem(String itemId) {
    if (_items.containsKey(itemId)) {
      if (_items[itemId]!.quantity > 1) {
        _items.update(
          itemId,
          (existingItem) => existingItem.copyWith(quantity: existingItem.quantity - 1),
        );
      } else {
        _items.remove(itemId);
      }
      notifyListeners();
    }
  }

  Future<void> clear() async {
    if (_items.isNotEmpty) {
      _items.clear();
      notifyListeners();
    }
    return Future.value();
  }
}