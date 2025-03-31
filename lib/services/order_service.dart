import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'loyalty_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:uuid/uuid.dart';
import '../screens/models/order_model.dart' as app_models;
import '../screens/models/cart_item.dart';
import 'cart_service.dart';

class OrderService {
  // Singleton implementation
  static final OrderService _instance = OrderService._internal();
  final FirebaseFirestore firestore = FirebaseFirestore.instance;
  
  factory OrderService() {
    return _instance;
  }
  
  OrderService._internal();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  
  // Collection reference
  final CollectionReference ordersCollection = 
      FirebaseFirestore.instance.collection('orders');
  
  // Create a new order
Future<String> createOrder({
  required List<CartItem> cartItems,
  required double totalAmount,
  required app_models.PaymentMethod paymentMethod,
  String? notes,
}) async {
  try {
    final user = _auth.currentUser ;
    if (user == null) {
      throw Exception('User  not authenticated');
    }
    
    // Get user data
    final userDoc = await _firestore.collection('users').doc(user.uid).get();
    final userData = userDoc.data() as Map<String, dynamic>? ?? {};
    
    final orderId = _firestore.collection('orders').doc().id;
    final now = DateTime.now();
    
    // Calculate subtotal from cart items
    double subtotal = cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
    
    // Calculate tax (10% of subtotal)
    double tax = subtotal * 0.10; // 10% tax
    
    // Calculate total amount
    double calculatedTotal = subtotal + tax;
    
    final order = app_models.Order(
      id: orderId,
      userId: user.uid,
      userName: userData['name'] ?? 'User ',
      items: cartItems,
      subtotal: subtotal,
      tax: tax,
      totalAmount: calculatedTotal, // Use the calculated total
      orderDate: now,
      paymentMethod: paymentMethod,
      paymentStatus: app_models.PaymentStatus.pending,
      status: app_models.OrderStatus.pending,
      preparingStatus: app_models.PreparingStatus.pending,
      notes: notes,
      createdAt: now,
    );
    
    await ordersCollection.doc(orderId).set(order.toMap());
    
    // Send notification to cashier about new order
    await _firestore.collection('notifications').add({
      'type': 'new_order',
      'orderId': orderId,
      'timestamp': Timestamp.now(),
      'isRead': false,
      'userName': userData['name'] ?? 'User ',
      'totalAmount': calculatedTotal,
      'userId': user.uid,
    });
    
    return orderId;
  } catch (e) {
    print('Error creating order: $e');
    throw e;
  }
}
  
  // Update payment status
  Future<void> updatePaymentStatus(String orderId, app_models.PaymentStatus status, {required String email}) async {
  try {
    // First update the payment status
    await ordersCollection.doc(orderId).update({
      'paymentStatus': status.toString().split('.').last,
    });

    final orderDoc = await ordersCollection.doc(orderId).get();
    final orderData = orderDoc.data() as Map<String, dynamic>? ?? {};

    if (status == app_models.PaymentStatus.completed) {
      // If payment is completed, update order status to paid and preparing status to preparing
      await ordersCollection.doc(orderId).update({
        'status': app_models.OrderStatus.paid.toString().split('.').last,
        'preparingStatus': app_models.PreparingStatus.preparing.toString().split('.').last,
        'paymentTime': FieldValue.serverTimestamp(),
      });

      await _firestore.collection('notifications').add({
        'type': 'payment_success',
        'orderId': orderId,
        'userId': orderData['userId'] ?? '',
        'message': 'Your payment was successful. Your order is being prepared.',
        'timestamp': Timestamp.now(),
        'isRead': false,
      });
    } else if (status == app_models.PaymentStatus.failed) {
      await _firestore.collection('notifications').add({
        'type': 'payment_failed',
        'orderId': orderId,
        'userId': orderData['userId'] ?? '',
        'message': 'Your payment failed. Please try again or contact support.',
        'timestamp': Timestamp.now(),
        'isRead': false,
      });
    }
  } catch (e) {
    print('Error updating payment status: $e');
    throw e;
  }
}

Future<void> confirmPayment(String orderId) async {
  try {
    await ordersCollection.doc(orderId).update({
      'paymentStatus': app_models.PaymentStatus.completed.toString().split('.').last,
      'status': app_models.OrderStatus.paid.toString().split('.').last,
      'preparingStatus': app_models.PreparingStatus.preparing.toString().split('.').last,
      'paymentTime': FieldValue.serverTimestamp(),
      'lastUpdated': FieldValue.serverTimestamp()
    });

    final order = await ordersCollection.doc(orderId).get();
    final orderData = order.data() as Map<String, dynamic>? ?? {};

    await _firestore.collection('notifications').add({
      'type': 'payment_confirmed',
      'orderId': orderId,
      'userId': orderData['userId'] ?? '',
      'message': 'Your payment has been confirmed. Your order is being prepared.',
      'timestamp': Timestamp.now(),
      'isRead': false,
    });
  } catch (e) {
    print('Error confirming payment: $e');
    throw e;
  }
}

  
Future<void> cancelOrder(String orderId, {required String? reason, required String? email}) async {
  try {
    // Handle null values for reason and email
    final String safeReason = reason ?? '';
    final String safeEmail = email ?? '';
    
    // Determine if the email belongs to an admin
    bool isAdmin = safeEmail == 'admin@cafe.com';

    // Update the order status and cancellation reason
    await ordersCollection.doc(orderId).update({
      'status': app_models.OrderStatus.cancelled.toString().split('.').last,
      'cancellationReason': safeReason.isNotEmpty ? safeReason : (isAdmin ? 'Cancelled by admin' : 'Cancelled by user'),
      'cancelledAt': FieldValue.serverTimestamp(),
    });

    // Send notification about cancelled order
    final order = await ordersCollection.doc(orderId).get();
    final orderData = order.data() as Map<String, dynamic>? ?? {};

    await _firestore.collection('notifications').add({
      'type': 'order_cancelled',
      'orderId': orderId,
      'userId': orderData['userId'] ?? '',
      'message': 'Your order has been cancelled. Reason: ${safeReason.isNotEmpty ? safeReason : (isAdmin ? 'Cancelled by admin' : 'Cancelled by user')}',
      'timestamp': Timestamp.now(),
      'isRead': false,
    });
  } catch (e) {
    print('Error cancelling order: $e');
    throw e;
  }
}

Future<void> clearOrdersByStatus(app_models.OrderStatus status) async {
  try {
    // Get all orders with the specified status
    final ordersSnapshot = await _firestore
        .collection('orders')
        .where('status', isEqualTo: status.toString().split('.').last)
        .get();
    
    // Delete each order document
    final batch = _firestore.batch();
    for (var doc in ordersSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  } catch (e) {
    print('Error clearing orders by status: $e');
    rethrow;
  }
}

// Delete a single order
Future<void> deleteOrder(String orderId) async {
  try {
    await _firestore.collection('orders').doc(orderId).delete();
  } catch (e) {
    print('Error deleting order: $e');
    rethrow;
  }
}

// Delete multiple orders at once
Future<void> deleteMultipleOrders(List<String> orderIds) async {
  try {
    // Use a batch to delete multiple documents
    final batch = _firestore.batch();
    
    for (String orderId in orderIds) {
      final docRef = _firestore.collection('orders').doc(orderId);
      batch.delete(docRef);
    }
    
    await batch.commit();
  } catch (e) {
    print('Error deleting multiple orders: $e');
    rethrow;
  }
}

Future<List<app_models.Order>> getAllOrdersOnce() async {
  try {
    final querySnapshot = await _firestore
        .collection('orders')
        .orderBy('orderDate', descending: true)  
        .get();
        
    return querySnapshot.docs
        .map((doc) => app_models.Order.fromMap(
            doc.data() as Map<String, dynamic>, 
            doc.id
        ))
        .toList();
  } catch (e) {
    print('Error getting orders: $e');
    return [];
  }
}

Future<void> clearAllOrders() async {
  try {
    // Get all orders
    final ordersSnapshot = await _firestore.collection('orders').get();
    
    // Delete each order document
    final batch = _firestore.batch();
    for (var doc in ordersSnapshot.docs) {
      batch.delete(doc.reference);
    }
    
    await batch.commit();
  } catch (e) {
    print('Error clearing all orders: $e');
    rethrow;
  }
}
  
  // Get user orders
  Stream<List<app_models.Order>> getUserOrders() {
  final user = _auth.currentUser;
  if (user == null) {
    print('User is not authenticated. Returning empty stream.');
    return Stream.value([]); // Hindari query tanpa autentikasi
  }

  return ordersCollection
      .where('userId', isEqualTo: user.uid)
      .orderBy('orderDate', descending: true)
      .snapshots()
      .handleError((error) {
        print('Error fetching user orders: $error');
      })
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return app_models.Order.fromMap(data, doc.id);
          }).toList());
}

  
  // Get user orders by status
  Stream<List<app_models.Order>> getUserOrdersByStatus(String userId, app_models.OrderStatus status) {
    return ordersCollection
        .where('userId', isEqualTo: userId)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('orderDate', descending: true)
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data() as Map<String, dynamic>? ?? {};
              return app_models.Order.fromMap(data, doc.id);
            }).toList());
  }

  Stream<List<app_models.Order>> getActiveOrders(String userId) {
  return ordersCollection
      .where('userId', isEqualTo: userId)
      .where('status', whereIn: [
        app_models.OrderStatus.active.toString().split('.').last,
        app_models.OrderStatus.pending.toString().split('.').last,
        app_models.OrderStatus.paid.toString().split('.').last,
        app_models.OrderStatus.processing.toString().split('.').last,
        app_models.OrderStatus.ready.toString().split('.').last,
      ])
      .orderBy('orderDate', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return app_models.Order.fromMap(data, doc.id);
          }).toList());
}

// Add this method to OrderService class
Stream<List<app_models.Order>> getAllActiveOrders(String userId) {
  return firestore
      .collection('orders')
      .where('userId', isEqualTo: userId)
      .where('status', whereIn: [
        app_models.OrderStatus.active.toString().split('.').last,
        app_models.OrderStatus.paid.toString().split('.').last,
        app_models.OrderStatus.processing.toString().split('.').last,
        app_models.OrderStatus.ready.toString().split('.').last
      ])
      .orderBy('orderDate', descending: true)
      .snapshots()
      .map((snapshot) {
        return snapshot.docs.map((doc) {
          return app_models.Order.fromMap(doc.data() as Map<String, dynamic>, doc.id);
        }).toList();
      });
}

  // Get order details
  Stream<app_models.Order?> getOrderDetails(String orderId) {
    return ordersCollection
        .doc(orderId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) return null;
          final data = snapshot.data() as Map<String, dynamic>? ?? {};
          return app_models.Order.fromMap(data, snapshot.id);
        });
  }

  // Get order stream for tracking
Stream<app_models.Order?> getOrderStream(String orderId) {
  return ordersCollection
      .doc(orderId)
      .snapshots()
      .map((snapshot) {
        if (!snapshot.exists) return null;
        final data = snapshot.data() as Map<String, dynamic>? ?? {};
        return app_models.Order.fromMap(data, snapshot.id);
      }).handleError((error) {
        print('Error in order stream: $error');
      });
}
  
  // Get all orders (for cashier/admin)
 Stream<List<app_models.Order>> getAllOrders() {
  // Periksa autentikasi terlebih dahulu
  final user = _auth.currentUser;
  if (user == null) {
    // Jika pengguna belum login, kembalikan stream kosong
    return Stream.value([]);
  }
  
  // Periksa jika pengguna adalah admin
  if (user.email != 'admin@cafe.com') {
    // Jika bukan admin, kembalikan stream kosong atau hanya pesanan milik pengguna
    return getUserOrders();
  }
  
  // Jika pengguna admin, lanjutkan dengan query asli
  return ordersCollection
      .orderBy('orderDate', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return app_models.Order.fromMap(data, doc.id);
          }).toList());
}
  
  // Get orders by status (for cashier/admin)
  // Modifikasi getOrdersByStatus()
Stream<List<app_models.Order>> getOrdersByStatus(app_models.OrderStatus status) {
  final user = _auth.currentUser;
  if (user == null) {
    return Stream.value([]);
  }
  
  // Periksa jika pengguna adalah admin
  if (user.email != 'admin@cafe.com') {
    // Kembalikan pesanan pengguna dengan status tertentu saja
    return getUserOrdersByStatus(user.uid, status);
  }
  
  // Untuk admin
  return ordersCollection
      .where('status', isEqualTo: status.toString().split('.').last)
      .orderBy('orderDate', descending: true)
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return app_models.Order.fromMap(data, doc.id);
          }).toList());
}
  
  // Get today's orders (for reports)
  // Tambahkan error handling di getTodaysOrders()
Stream<List<app_models.Order>> getTodaysOrders() {
  final user = _auth.currentUser;
  if (user == null) {
    return Stream.value([]);
  }
  
  // Untuk admin saja
  if (user.email != 'admin@cafe.com') {
    return Stream.value([]);
  }
  
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final tomorrow = DateTime(now.year, now.month, now.day + 1);
  
  return ordersCollection
      .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(today))
      .where('orderDate', isLessThan: Timestamp.fromDate(tomorrow))
      .snapshots()
      .map((snapshot) => snapshot.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>? ?? {};
            return app_models.Order.fromMap(data, doc.id);
          }).toList())
      .handleError((error) {
        print('Error in getTodaysOrders: $error');
        return [];
      });
}
  
  // Update order status (for cashier/admin)
  Future<void> updateOrderStatus(String orderId, app_models.OrderStatus status) async {
  try {
    final now = DateTime.now();
    Map<String, dynamic> updateData = {
      'status': status.toString().split('.').last,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    
    // Synchronize preparingStatus with orderStatus
    switch (status) {
      case app_models.OrderStatus.paid:
        updateData['paymentStatus'] = app_models.PaymentStatus.completed.toString().split('.').last;
        updateData['preparingStatus'] = app_models.PreparingStatus.pending.toString().split('.').last;
        break;
      case app_models.OrderStatus.processing:
        updateData['preparingStatus'] = app_models.PreparingStatus.preparing.toString().split('.').last;
        break;
      case app_models.OrderStatus.ready:
        updateData['preparingStatus'] = app_models.PreparingStatus.ready.toString().split('.').last;
        break;
      case app_models.OrderStatus.completed:
        updateData['preparingStatus'] = app_models.PreparingStatus.completed.toString().split('.').last;
        updateData['completionTime'] = FieldValue.serverTimestamp();
        await _addLoyaltyPointsForOrder(orderId); 
        break;
      default:
        // Keep existing preparingStatus
        break;
    }
    
    await ordersCollection.doc(orderId).update(updateData);
    
    // Send notification about order status update
    final order = await ordersCollection.doc(orderId).get();
    final orderData = order.data() as Map<String, dynamic>? ?? {};
    
    String message;
    switch (status) {
      case app_models.OrderStatus.paid:
        message = 'Payment confirmed. Your order is being prepared.';
        break;
      case app_models.OrderStatus.processing:
        message = 'Your order is being prepared.';
        break;
      case app_models.OrderStatus.ready:
        message = 'Your order is ready for pickup!';
        break;
      case app_models.OrderStatus.completed:
        message = 'Your order has been completed. Enjoy your meal!';
        break;
      case app_models.OrderStatus.cancelled:
        message = 'Your order has been cancelled.';
        break;
      default:
        message = 'Your order status has been updated.';
    }
    
    await _firestore.collection('notifications').add({
      'type': 'order_status_update',
      'orderId': orderId,
      'userId': orderData['userId'] ?? '',
      'message': message,
      'timestamp': Timestamp.now(),
      'isRead': false,
    });
  } catch (e) {
    print('Error updating order status: $e');
    throw e;
  }
}

  // Update preparing status
  Future<void> updatePreparingStatus(String orderId, app_models.PreparingStatus preparingStatus) async {
  try {
    final now = DateTime.now();
    Map<String, dynamic> updateData = {
      'preparingStatus': preparingStatus.toString().split('.').last,
      'lastUpdated': FieldValue.serverTimestamp(),
    };
    
    // Update corresponding order status based on preparing status
    if (preparingStatus == app_models.PreparingStatus.preparing) {
      updateData['preparingTime'] = Timestamp.fromDate(now);
      updateData['status'] = app_models.OrderStatus.processing.toString().split('.').last;
    } else if (preparingStatus == app_models.PreparingStatus.ready) {
      updateData['status'] = app_models.OrderStatus.ready.toString().split('.').last;
    }
    
    await ordersCollection.doc(orderId).update(updateData);
    
    // Send notification about preparation status update
    final order = await ordersCollection.doc(orderId).get();
    final orderData = order.data() as Map<String, dynamic>? ?? {};
    
    String message;
    switch (preparingStatus) {
      case app_models.PreparingStatus.preparing:
        message = 'Your order is being prepared in the kitchen.';
        break;
      case app_models.PreparingStatus.ready:
        message = 'Your order is ready for pickup!';
        break;
      default:
        message = 'Your order preparation status has been updated.';
    }
    
    await _firestore.collection('notifications').add({
      'type': 'preparing_status_update',
      'orderId': orderId,
      'userId': orderData['userId'] ?? '',
      'message': message,
      'timestamp': Timestamp.now(),
      'isRead': false,
    });
  } catch (e) {
    print('Error updating preparing status: $e');
    throw e;
  }
}

Future<void> _addLoyaltyPointsForOrder(String orderId) async {
  try {
    final orderDoc = await ordersCollection.doc(orderId).get();
    if (orderDoc.exists) {
      final orderData = orderDoc.data() as Map<String, dynamic>;
      final userId = orderData['userId'];
      final totalAmount = orderData['totalAmount'] ?? 0.0;
      
      // Hitung poin (contoh: 1 poin per Rp10.000, minimal 5 poin)
      int pointsEarned = max(5, (totalAmount / 10000).floor());
      
      final loyaltyService = LoyaltyService();
      await loyaltyService.addPoints(userId, pointsEarned);
      
      // Tambahkan notifikasi ke user
      await _firestore.collection('notifications').add({
        'type': 'loyalty_points_added',
        'userId': userId,
        'message': 'You earned $pointsEarned loyalty points for your order!',
        'timestamp': Timestamp.now(),
        'isRead': false,
      });
    }
  } catch (e) {
    print('Error adding loyalty points: $e');
    // Tidak perlu throw error karena ini opsional
  }
}

  // Get daily sales report
  Future<Map<String, dynamic>> getDailySalesReport(DateTime date) async {
    try {
      final startOfDay = DateTime(date.year, date.month, date.day);
      final endOfDay = DateTime(date.year, date.month, date.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startOfDay))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('paymentStatus', isEqualTo: app_models.PaymentStatus.completed.toString().split('.').last)
          .get();
      
      final orders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return app_models.Order.fromMap(data, doc.id);
      }).toList();
      
      double totalSales = 0;
      int totalOrders = orders.length;
      Map<String, int> productCounts = {};
      
      for (var order in orders) {
        totalSales += order.totalAmount;
        
        for (var item in order.items) {
          if (productCounts.containsKey(item.productName)) {
            productCounts[item.productName] = productCounts[item.productName]! + item.quantity;
          } else {
            productCounts[item.productName] = item.quantity;
          }
        }
      }
      List<MapEntry<String, int>> topProducts = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return {
        'date': startOfDay,
        'totalSales': totalSales,
        'totalOrders': totalOrders,
        'averageOrderValue': totalOrders > 0 ? totalSales / totalOrders : 0,
        'topProducts': topProducts.take(5).map((e) => {
          'name': e.key,
          'count': e.value,
        }).toList(),
      };
    } catch (e) {
      print('Error generating daily sales report: $e');
      rethrow;
    }
  }

  // Get weekly sales report
  Future<Map<String, dynamic>> getWeeklySalesReport(DateTime startDate) async {
    try {
      // Calculate the end date (start date + 6 days = 1 week)
      final endDate = startDate.add(Duration(days: 6));
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('paymentStatus', isEqualTo: app_models.PaymentStatus.completed.toString().split('.').last)
          .get();
      
      final orders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return app_models.Order.fromMap(data, doc.id);
      }).toList();
      
      double totalSales = 0;
      int totalOrders = orders.length;
      Map<String, int> productCounts = {};
      Map<String, double> dailySales = {};
      
      // Initialize daily sales for each day in the week
      for (int i = 0; i <= 6; i++) {
        final day = startDate.add(Duration(days: i));
        final dayStr = '${day.year}-${day.month}-${day.day}';
        dailySales[dayStr] = 0;
      }
      
      for (var order in orders) {
        totalSales += order.totalAmount;
        
        // Safely access orderDate
        final orderDate = order.orderDate;
        final dayStr = '${orderDate.year}-${orderDate.month}-${orderDate.day}';
        dailySales[dayStr] = (dailySales[dayStr] ?? 0) + order.totalAmount;
        
        for (var item in order.items) {
          if (productCounts.containsKey(item.productName)) {
            productCounts[item.productName] = productCounts[item.productName]! + item.quantity;
          } else {
            productCounts[item.productName] = item.quantity;
          }
        }
      }
      
      // Find top selling products
      List<MapEntry<String, int>> topProducts = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return {
        'startDate': startDate,
        'endDate': endDate,
        'totalSales': totalSales,
        'totalOrders': totalOrders,
        'averageOrderValue': totalOrders > 0 ? totalSales / totalOrders : 0,
        'dailySales': dailySales,
        'topProducts': topProducts.take(5).map((e) => {
          'name': e.key,
          'count': e.value,
        }).toList(),
      };
    } catch (e) {
      print('Error generating weekly sales report: $e');
      rethrow;
    }
  }
  
  // Get monthly sales report
  Future<Map<String, dynamic>> getMonthlySalesReport(int year, int month) async {
    try {
      final startDate = DateTime(year, month, 1);
      final endDate = (month < 12) 
          ? DateTime(year, month + 1, 1).subtract(Duration(days: 1))
          : DateTime(year + 1, 1, 1).subtract(Duration(days: 1));
      final endOfDay = DateTime(endDate.year, endDate.month, endDate.day, 23, 59, 59);
      
      final snapshot = await _firestore
          .collection('orders')
          .where('orderDate', isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('orderDate', isLessThanOrEqualTo: Timestamp.fromDate(endOfDay))
          .where('paymentStatus', isEqualTo: app_models.PaymentStatus.completed.toString().split('.').last)
          .get();
      
      final orders = snapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>? ?? {};
        return app_models.Order.fromMap(data, doc.id);
      }).toList();
      
      double totalSales = 0;
      int totalOrders = orders.length;
      Map<String, int> productCounts = {};
      Map<String, double> weeklySales = {
        'Week 1': 0,
        'Week 2': 0,
        'Week 3': 0,
        'Week 4': 0,
        'Week 5': 0,
      };
      
      for (var order in orders) {
        totalSales += order.totalAmount;
        
        // Safely access orderDate
        final orderDate = order.orderDate;
        final day = orderDate.day;
        
        if (day <= 7) {
          weeklySales['Week 1'] = weeklySales['Week 1']! + order.totalAmount;
        } else if (day <= 14) {
          weeklySales['Week 2'] = weeklySales['Week 2']! + order.totalAmount;
        } else if (day <= 21) {
          weeklySales['Week 3'] = weeklySales['Week 3']! + order.totalAmount;
        } else if (day <= 28) {
          weeklySales['Week 4'] = weeklySales['Week 4']! + order.totalAmount;
        } else {
          weeklySales['Week 5'] = weeklySales['Week 5']! + order.totalAmount;
        }
        
        for (var item in order.items) {
          if (productCounts.containsKey(item.productName)) {
            productCounts[item.productName] = productCounts[item.productName]! + item.quantity;
          } else {
            productCounts[item.productName] = item.quantity;
          }
        }
      }
      
      // Find top selling products
      List<MapEntry<String, int>> topProducts = productCounts.entries.toList()
        ..sort((a, b) => b.value.compareTo(a.value));
      
      return {
        'year': year,
        'month': month,
        'totalSales': totalSales,
        'totalOrders': totalOrders,
        'averageOrderValue': totalOrders > 0 ? totalSales / totalOrders : 0,
        'weeklySales': weeklySales,
        'topProducts': topProducts.take(5).map((e) => {
          'name': e.key,
          'count': e.value,
        }).toList(),
      };
    } catch (e) {
      print('Error generating monthly sales report: $e');
      rethrow;
    }
  }

  
}
