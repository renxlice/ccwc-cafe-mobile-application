import 'package:cloud_firestore/cloud_firestore.dart';
import 'cart_item.dart';

enum OrderStatus {
  active,
  ready,
  completed,
  cancelled,
  processing,
  pending, 
  paid,
}

enum PreparingStatus {
  pending,
  preparing,
  ready,
  completed
}

enum PaymentMethod {
  bank,
  eWallet,
  qris,
  cash
}

enum PaymentStatus {
  paid,
  pending,
  completed,
  failed
}

class Order {
  final String id;
  final String userId;
  final String userName;
  final List<CartItem> items;
  final double totalAmount;
  final double subtotal;
  final double tax;
  final DateTime orderDate;
  final OrderStatus status;
  final DateTime createdAt;
  final PreparingStatus preparingStatus;
  final PaymentMethod paymentMethod;
  final PaymentStatus paymentStatus;
  final DateTime? lastUpdated;
  final String? notes;
  final DateTime? preparingTime;
  final DateTime? completionTime;
  final String? cancellationReason; 
  final DateTime? cancelledAt;
  final DateTime? paymentTime;
  final DateTime? readyTime;
  
  Order({
    required this.id,
    required this.userId,
    required this.userName,
    required this.items,
    required this.totalAmount,
    required this.orderDate,
    required this.createdAt,
    this.lastUpdated,
    this.status = OrderStatus.active,
    this.preparingStatus = PreparingStatus.pending,
    required this.paymentMethod,
    this.paymentStatus = PaymentStatus.pending,
    this.notes,
    this.subtotal = 0,
    this.tax = 0,
    this.preparingTime,
    this.completionTime,
    this.cancellationReason,  
    this.cancelledAt,
    this.paymentTime,
    this.readyTime,
  });
  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'userName': userName,
      'items': items.map((item) => item.toMap()).toList(),
      'totalAmount': totalAmount,
      'subtotal': subtotal,
      'tax': tax,
      'orderDate': Timestamp.fromDate(orderDate),
      'createdAt': Timestamp.fromDate(createdAt),
      'status': status.toString().split('.').last,
      'lastUpdated': lastUpdated ?? FieldValue.serverTimestamp(),
      'preparingStatus': preparingStatus.toString().split('.').last,
      'paymentMethod': paymentMethod.toString().split('.').last,
      'paymentStatus': paymentStatus.toString().split('.').last,
      'notes': notes,
      'preparingTime': preparingTime != null ? Timestamp.fromDate(preparingTime!) : null,
      'completionTime': completionTime != null ? Timestamp.fromDate(completionTime!) : null,
      'cancellationReason': cancellationReason,
      'cancelledAt': cancelledAt != null ? Timestamp.fromDate(cancelledAt!) : null,
      'paymentTime': paymentTime != null ? Timestamp.fromDate(paymentTime!) : null,
      'readyTime': readyTime != null ? Timestamp.fromDate(readyTime!) : null,
    };
  }
  
  factory Order.fromMap(Map<String, dynamic> map, String documentId) {
    return Order(
      id: documentId,
      userId: map['userId'] ?? '',
      userName: map['userName'] ?? '',
      items: (map['items'] as List?)?.map((item) => CartItem.fromMap(item)).toList() ?? [],
      totalAmount: (map['totalAmount'] ?? 0).toDouble(),
      subtotal: (map['subtotal'] ?? 0).toDouble(),
      tax: (map['tax'] ?? 0).toDouble(),
      orderDate: map['orderDate'] != null 
          ? (map['orderDate'] as Timestamp).toDate() 
          : DateTime.now(),
      status: OrderStatus.values.firstWhere(
      (e) => e.toString().split('.').last == map['status'],
      orElse: () => OrderStatus.pending,
      ),
      createdAt: map['createdAt'] != null 
          ? (map['createdAt'] as Timestamp).toDate() 
          : DateTime.now(),
      preparingStatus: PreparingStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['preparingStatus'],
        orElse: () => PreparingStatus.pending,
      ),
      paymentMethod: PaymentMethod.values.firstWhere(
        (e) => e.toString().split('.').last == map['paymentMethod'],
        orElse: () => PaymentMethod.cash,
      ),
      paymentStatus: PaymentStatus.values.firstWhere(
        (e) => e.toString().split('.').last == map['paymentStatus'],
        orElse: () => PaymentStatus.pending,
      ),
      notes: map['notes'],
      preparingTime: map['preparingTime'] != null 
          ? (map['preparingTime'] as Timestamp).toDate() 
          : null,
      completionTime: map['completionTime'] != null 
          ? (map['completionTime'] as Timestamp).toDate() 
          : null,
      cancellationReason: map['cancellationReason'],
      cancelledAt: map['cancelledAt'] != null 
          ? (map['cancelledAt'] as Timestamp).toDate() 
          : null,
      lastUpdated: (map['lastUpdated'] as Timestamp?)?.toDate(),
      paymentTime: map['paymentTime'] != null              
          ? (map['paymentTime'] as Timestamp).toDate() 
          : null,
      readyTime: map['readyTime'] != null                  
          ? (map['readyTime'] as Timestamp).toDate() 
          : null,
    );
  }
  
  Order copyWith({
    String? id,
    String? userId,
    String? userName,
    List<CartItem>? items,
    double? totalAmount,
    double? subtotal,
    double? tax,
    DateTime? orderDate,
    OrderStatus? status,
    PreparingStatus? preparingStatus,
    PaymentMethod? paymentMethod,
    PaymentStatus? paymentStatus,
    String? notes,
    DateTime? preparingTime,
    DateTime? completionTime,
    DateTime? createdAt,  
    String? cancellationReason,  
    DateTime? cancelledAt,
    DateTime? paymentTime,  
    DateTime? readyTime,
  }) {
    return Order(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      items: items ?? this.items,
      totalAmount: totalAmount ?? this.totalAmount,
      subtotal: subtotal ?? this.subtotal,
      tax: tax ?? this.tax,
      orderDate: orderDate ?? this.orderDate,
      status: status ?? this.status,
      preparingStatus: preparingStatus ?? this.preparingStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      notes: notes ?? this.notes,
      preparingTime: preparingTime ?? this.preparingTime,
      completionTime: completionTime ?? this.completionTime,
      createdAt: createdAt ?? this.createdAt,
      cancellationReason: cancellationReason ?? this.cancellationReason,
      cancelledAt: cancelledAt ?? this.cancelledAt,
      paymentTime: paymentTime ?? this.paymentTime,  
      readyTime: readyTime ?? this.readyTime,
    );
  }
}