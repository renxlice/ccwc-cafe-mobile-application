import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';
import '../screens/models/product_model.dart';
import 'firestore_service.dart';

class ProductService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  
  // Get all products (both active and inactive) for customers
  Stream<List<Product>> get products {
    final productsRef = _firestore.collection('products');
    
    return _transformProductsStream(
      productsRef.snapshots()
    );
  }
  
  // Get ALL products for admin
  Stream<List<Product>> get allProductsForAdmin {
    final productsRef = _firestore.collection('products');
    
    return _transformProductsStream(
      productsRef.snapshots()
    );
  }

  // Get products by category (both active and inactive)
  Stream<List<Product>> getProductsByCategory(String category) {
    final productsRef = _firestore.collection('products')
        .where('category', isEqualTo: category);
    
    return _transformProductsStream(
      productsRef.snapshots()
    );
  }

  // Get featured products (only active products)
  Stream<List<Product>> get featuredProducts {
    final productsRef = _firestore.collection('products')
        .where('isActive', isEqualTo: true)
        .limit(5);
    
    return _transformProductsStream(
      productsRef.snapshots()
    );
  }

  // Get single product
  Stream<Product?> getProductStream(String productId) {
    final docRef = _firestore.collection('products').doc(productId);
    
    return docRef.snapshots().map((doc) {
      if (doc.exists) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      } else {
        return null;
      }
    });
  }
  
  // Get a single product as Future
  Future<Product?> getProduct(String productId) async {
    try {
      final doc = await _firestore.collection('products').doc(productId).get();
      
      if (doc.exists) {
        return Product.fromMap(doc.data() as Map<String, dynamic>, doc.id);
      }
      return null;
    } catch (e) {
      print('Error getting product: $e');
      return null;
    }
  }

  // Helper method to transform QuerySnapshot to List<Product>
  Stream<List<Product>> _transformProductsStream(Stream<QuerySnapshot> stream) {
    return stream.map((snapshot) {
      try {
        final products = snapshot.docs
            .map((doc) => Product.fromMap(doc.data() as Map<String, dynamic>, doc.id))
            .whereType<Product>()
            .toList();
        return products;
      } catch (e) {
        print('Error transforming products: $e');
        throw e;
      }
    });
  }

  // Add a new product (admin function)
  Future<void> addProduct(Product product) async {
    try {
      final productId = product.id.isEmpty ? Uuid().v4() : product.id;
      final docRef = _firestore.collection('products').doc(productId);
      
      await docRef.set(product.toMap());
    } catch (e) {
      print('Error adding product: $e');
      throw Exception('Failed to add product');
    }
  }

  // Update a product (admin function)
  Future<void> updateProduct(Product product) async {
    try {
      final docRef = _firestore.collection('products').doc(product.id);
      await docRef.update(product.toMap());
    } catch (e) {
      print('Error updating product: $e');
      throw Exception('Failed to update product');
    }
  }

  // Delete a product (admin function)
  Future<void> deleteProduct(String productId) async {
    try {
      final docRef = _firestore.collection('products').doc(productId);
      await docRef.delete();
    } catch (e) {
      print('Error deleting product: $e');
      throw Exception('Failed to delete product');
    }
  }

  // Method to toggle product active status
  Future<void> toggleProductStatus(String productId) async {
    try {
      final docRef = _firestore.collection('products').doc(productId);
      final doc = await docRef.get();
      
      if (doc.exists) {
        final data = doc.data() as Map<String, dynamic>;
        final currentStatus = data['isActive'] ?? true;
        
        await docRef.update({'isActive': !currentStatus});
        print('Product status toggled from $currentStatus to ${!currentStatus}');
      }
    } catch (e) {
      print('Error toggling product status: $e');
      throw Exception('Failed to toggle product status');
    }
  }
}