import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/order_model.dart';
import '../models/user_model.dart';
import '../../services/order_service.dart';
import 'receipt_screen.dart'; 

class OrderDetailScreen extends StatefulWidget {
  final Order order;

  const OrderDetailScreen({Key? key, required this.order}) : super(key: key);

  @override
  _OrderDetailScreenState createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  final OrderService _orderService = OrderService();
  late Stream<Order?> _orderStream; 

  @override
  void initState() {
    super.initState();
    _orderStream = _orderService.getOrderStream(widget.order.id);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Order Details'),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: Icon(Icons.receipt_long),
            tooltip: 'View Receipt',
            onPressed: () => _navigateToReceiptScreen(context, widget.order),
          ),
        ],
      ),
      body: StreamBuilder<Order?>(
        stream: _orderStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final order = snapshot.data ?? widget.order; // Handle null case

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID and Status
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order.id.substring(0, 8)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown),
                            ),
                            _buildStatusChip(order),
                          ],
                        ),
                        SizedBox(height: 8),
                        Divider(),
                        SizedBox(height: 8),
                        _buildTrackingTimeline(order),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Order Processing Info
                Text(
                  'Processing Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                SizedBox(height: 10),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Colors.brown),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Estimated Completion: ${_getEstimatedCompletionTime(order)}',
                                style: TextStyle(fontSize: 16, color: Colors.brown),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),
                // Order Items
                Text(
                  'Order Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                SizedBox(height: 10),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      
                      // Calculate item price including customizations
                      double itemBasePrice = item.price;
                      double customizationPrice = 0.0;
                      
                      if (item.customizations != null && item.customizations!.isNotEmpty) {
                        customizationPrice = item.customizations!
                            .fold(0.0, (sum, option) => sum + option.price);
                      }
                      
                      double totalItemPrice = (itemBasePrice + customizationPrice) * item.quantity;
                      
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          ListTile(
                            title: Text(item.productName, style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                            subtitle: Text('Quantity: ${item.quantity}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                            trailing: Text(
                              'Rp ${formatRupiah(totalItemPrice)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                            ),
                          ),
                          if (item.customizations != null && item.customizations!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Customizations:', 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 14,
                                        color: Colors.brown,
                                      )),
                                  SizedBox(height: 4),
                                  ...item.customizations!.map((option) => 
                                    Padding(
                                      padding: EdgeInsets.only(left: 8, bottom: 2),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${option.name}: ${option.value}',
                                              style: TextStyle(fontSize: 14, color: Colors.brown)),
                                          if (option.price > 0)
                                            Text('+Rp ${formatRupiah(option.price)}',
                                                style: TextStyle(fontSize: 14, color: Colors.brown)),
                                        ],
                                      ),
                                    )
                                  ).toList(),
                                ],
                              ),
                            ),
                          if (item.notes != null && item.notes!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(left: 16, right: 16, bottom: 8),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Notes:', 
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold, 
                                        fontSize: 14,
                                        color: Colors.brown,
                                      )),
                                  SizedBox(height: 4),
                                  Text(item.notes!,
                                      style: TextStyle(
                                        fontStyle: FontStyle.italic,
                                        fontSize: 14,
                                        color: Colors.brown,
                                      )),
                                ],
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Order Summary
                Text(
              'Order Summary',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
            ),
            SizedBox(height: 10),
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  children: [
                    // Display each item with customizations
                    ...order.items.map((item) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${item.productName} x ${item.quantity}',
                                  style: TextStyle(fontWeight: FontWeight.w500, color: Colors.brown),
                                ),
                              ),
                              Text('Rp ${formatRupiah(item.price * item.quantity)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                            ],
                          ),
                          // Display customizations if any
                          if (item.customizations != null && item.customizations!.isNotEmpty)
                            ...item.customizations!.map((option) => Padding(
                              padding: EdgeInsets.only(left: 16, top: 4),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${option.name}: ${option.value}',
                                    style: TextStyle(fontSize: 12, color: Colors.brown),
                                  ),
                                  Text(
                                    'Rp ${formatRupiah(option.price * item.quantity)}',
                                    style: TextStyle(fontSize: 12, color: Colors.brown),
                                  ),
                                ],
                              ),
                            )),
                          // Add a separator to improve readability if there are customizations
                          if (item.customizations != null && item.customizations!.isNotEmpty)
                            Padding(
                              padding: EdgeInsets.only(top: 2),
                              child: Divider(height: 1, color: Colors.grey[300]),
                            ),
                        ],
                      ),
                    )),
                    Divider(),
                    // Calculate the true subtotal based on totalPrice from all items
                    Builder(
                      builder: (context) {
                        final calculatedSubtotal = order.items.fold(
                          0.0, 
                          (sum, item) => sum + item.totalPrice
                        );
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                            Text('Rp ${formatRupiah(calculatedSubtotal)}',style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                          ],
                        );
                      }
                    ),
                    SizedBox(height: 8),
                    // Recalculate tax based on the correct subtotal if needed
                    Builder(
                      builder: (context) {
                        final calculatedSubtotal = order.items.fold(
                          0.0, 
                          (sum, item) => sum + item.totalPrice
                        );
                        // Assuming tax is 10% - adjust as needed
                        final calculatedTax = calculatedSubtotal * 0.1;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tax', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                            Text('Rp ${formatRupiah(calculatedTax)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
                          ],
                        );
                      }
                    ),
                    Divider(),
                    // Calculate total from subtotal and tax
                    Builder(
                      builder: (context) {
                        final calculatedSubtotal = order.items.fold(
                          0.0, 
                          (sum, item) => sum + item.totalPrice
                        );
                        // Assuming tax is 10% - adjust as needed
                        final calculatedTax = calculatedSubtotal * 0.1;
                        final calculatedTotal = calculatedSubtotal + calculatedTax;
                        return Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                            ),
                            Text(
                              'Rp ${formatRupiah(calculatedTotal)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                            ),
                          ],
                        );
                      }
                    ),
                    if (order.notes != null && order.notes!.isNotEmpty) ...[
                      SizedBox(height: 16),
                      Divider(),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Additional Notes:',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Expanded(
                            child: Text(
                              order.notes!,
                              style: TextStyle(fontStyle: FontStyle.italic, color: Colors.brown),
                              textAlign: TextAlign.end,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ],
                ),
              ),
            ),
                SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.receipt),
                        label: Text('View Receipt'),
                        onPressed: () => _navigateToReceiptScreen(context, order),
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                    SizedBox(width: 10),
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.help_outline),
                        label: Text('Need Help?'),
                        onPressed: () {
                          _showSupportDialog(context, order);
                        },
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 12),
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                        ),
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  // Helper method to format rupiah with thousand separators
  String formatRupiah(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  // Navigation to ReceiptScreen
  void _navigateToReceiptScreen(BuildContext context, Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiptScreen(order: order),
      ),
    );
  }

  Widget _buildStatusChip(Order order) {
  Color statusColor;
  String statusText;
  IconData statusIcon;

  if (order.paymentStatus == PaymentStatus.pending) {
  statusColor = Colors.orange;
  statusText = 'Pending Pay';
  statusIcon = Icons.access_time;
} else if (order.status == OrderStatus.paid) {
  statusColor = Colors.green;
  statusText = 'Paid';
  statusIcon = Icons.payments;
} else if (order.status == OrderStatus.processing) {
  statusColor = Colors.amber;
  statusText = 'Preparing';
  statusIcon = Icons.hourglass_bottom;
} else if (order.status == OrderStatus.ready) {
  statusColor = Colors.cyan;
  statusText = 'Ready';
  statusIcon = Icons.inventory;
} else if (order.status == OrderStatus.active) {
  statusColor = Colors.green;
  statusText = 'Active';
  statusIcon = Icons.check;
} else if (order.status == OrderStatus.completed) {
  statusColor = Colors.blue;
  statusText = 'Completed';
  statusIcon = Icons.check_circle;
} else {
  statusColor = Colors.red;
  statusText = 'Cancelled';
  statusIcon = Icons.cancel;
}

  return Chip(
    avatar: Icon(statusIcon, color: Colors.white, size: 18),
    label: Text(statusText, style: TextStyle(color: Colors.white)),
    backgroundColor: statusColor,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
  );
}


  Widget _buildTrackingTimeline(Order order) {
    // Define the steps in the order process
    List<Map<String, dynamic>> steps = [
      {
        'title': 'Order Placed',
        'icon': Icons.receipt,
        'isCompleted': true, // Always completed as we're viewing an existing order
        'time': _formatDateTime(order.orderDate),
      },
      {
        'title': 'Preparing',
        'icon': Icons.restaurant,
        'isCompleted': order.preparingStatus == PreparingStatus.preparing || 
                       order.preparingStatus == PreparingStatus.ready || 
                       order.status == OrderStatus.completed,
        'time': order.preparingTime != null ? _formatDateTime(order.preparingTime!) : 'N/A',
      },
      {
        'title': 'Ready',
        'icon': Icons.done_all,
        'isCompleted': order.preparingStatus == PreparingStatus.ready || order.status == OrderStatus.completed,
        'time': (order.preparingStatus == PreparingStatus.ready && order.completionTime != null) 
                ? _formatDateTime(order.completionTime!) 
                : 'N/A', 
      },
      {
        'title': 'Completed',
        'icon': Icons.check_circle,
        'isCompleted': order.status == OrderStatus.completed,
        'time': order.completionTime != null ? _formatDateTime(order.completionTime!) : 'N/A',
      },
    ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: step['isCompleted'] ? Colors.brown : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step['icon'],
                    color: step['isCompleted'] ? Colors.white : Colors.grey[600],
                    size: 18,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: step['isCompleted'] && steps[index + 1]['isCompleted'] 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[300],
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: step['isCompleted'] ? Colors.brown : Colors.grey[600],
                    ),
                  ),
                  if (step['time'] != null && step['time'] != 'N/A')
                    Text(
                      step['time'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  SizedBox(height: isLast ? 0 : 20),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _getEstimatedCompletionTime(Order order) {
    if (order.status == OrderStatus.completed) {
      return 'Completed';
    }

    if (order.status == OrderStatus.cancelled) {
      return 'Order Cancelled';
    }

    // If no estimated time, calculate a rough estimate
    final now = DateTime.now();

    if (order.preparingStatus == PreparingStatus.preparing) {
      // If still preparing, estimate 30 minutes from current time
      return _formatDateTime(now.add(Duration(minutes: 30)));
    } else if (order.preparingStatus == PreparingStatus.ready) {
      // If ready, estimate 5 minutes from current time
      return _formatDateTime(now.add(Duration(minutes: 5)));
    }

    // Default fallback
    return _formatDateTime(now.add(Duration(minutes: 35)));
  }

  void _showSupportDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contact Support'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.call),
              title: Text('Call Support'),
              onTap: () {
                // Implementation for calling support
                Navigator.of(ctx).pop();
                // Add call functionality here
              },
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Message Support'),
              onTap: () {
                // Implementation for messaging support
                Navigator.of(ctx).pop();
                // Add messaging functionality here
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close'),
          ),
        ],
      ),
    );
  }
}

class OrderProcessScreen extends StatefulWidget {
  @override
  _OrderProcessScreenState createState() => _OrderProcessScreenState();
}

class _OrderProcessScreenState extends State<OrderProcessScreen> with SingleTickerProviderStateMixin, AutomaticKeepAliveClientMixin {
  late TabController _tabController;
  final OrderService _orderService = OrderService();
  bool isLoading = false;
  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);

    if (user == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.lock, size: 64, color: Colors.grey),
            SizedBox(height: 16),
            Text(
              'Please login to view your orders',
              style: TextStyle(fontSize: 18),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('My Orders', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Active'),
            Tab(text: 'Completed'),
            Tab(text: 'Cancelled'),
          ],
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white,
          indicatorColor: Theme.of(context).primaryColor,
        ),
      ),
      body: Stack(
        children: [
          TabBarView(
            controller: _tabController,
            children: [
              _buildOrdersList(OrderStatus.active, user.uid),
              _buildOrdersList(OrderStatus.completed, user.uid),
              _buildOrdersList(OrderStatus.cancelled, user.uid),
            ],
          ),
          if (isLoading)
            Container(
              color: Colors.black.withOpacity(0.3),
              child: Center(
                child: CircularProgressIndicator(),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildOrdersList(OrderStatus status, String userId) {
    return StreamBuilder<List<Order>>(
      stream: (status == OrderStatus.active || status == OrderStatus.processing || status == OrderStatus.ready)
          ? _orderService.getActiveOrders(userId) 
          : _orderService.getUserOrdersByStatus(userId, status),

      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final orders = snapshot.data;

        if (orders == null || orders.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  status == OrderStatus.active ? Icons.access_time : 
                  status == OrderStatus.completed ? Icons.check_circle : Icons.cancel,
                  size: 64,
                  color: Colors.grey,
                ),
                SizedBox(height: 16),
                Text(
                  'No ${status.toString().split('.').last} orders',
                  style: TextStyle(fontSize: 18, color: Colors.grey[600]),
                ),
              ],
            ),
          );
        }

        // Urutkan order berdasarkan tanggal terbaru
        orders.sort((a, b) => b.orderDate.compareTo(a.orderDate));

        return ListView.builder(
          padding: EdgeInsets.all(8),
          itemCount: orders.length,
          itemBuilder: (ctx, index) {
            final order = orders[index];
            return _buildOrderCard(context, order, status);
          },
        );
      },
    );
  }

  Widget _buildOrderCard(BuildContext context, Order order, OrderStatus status) {
    Color statusColor;
    IconData statusIcon;

    switch (order.status) {
      case OrderStatus.active:
        statusColor = Colors.green;
        statusIcon = Icons.check;
        break;
      case OrderStatus.paid:
        statusColor = Colors.lightGreen;
        statusIcon = Icons.payments;
        break; 
      case OrderStatus.processing:
        if (order.preparingStatus == PreparingStatus.preparing) {
          statusColor = Colors.orange;
          statusIcon = Icons.restaurant;
        } else {
          statusColor = Colors.amber;
          statusIcon = Icons.access_time;
        }
        break;
      case OrderStatus.ready:
        statusColor = Colors.blue;
        statusIcon = Icons.done_all;
        break;
      case OrderStatus.completed:
        statusColor = Colors.green;
        statusIcon = Icons.check_circle;
        break;
      case OrderStatus.cancelled:
        statusColor = Colors.red;
        statusIcon = Icons.cancel;
        break;
      default:
        statusColor = Colors.orange;
        statusIcon = Icons.access_time;
    }

    final orderDate = DateTime.fromMillisecondsSinceEpoch(order.orderDate.millisecondsSinceEpoch);
    final formattedDate = "${orderDate.day}/${orderDate.month}/${orderDate.year}";
    final formattedTime = "${orderDate.hour}:${orderDate.minute.toString().padLeft(2, '0')}";

    // Calculate total price including customizations
    double orderTotal = order.totalAmount;

    return Card(
  elevation: 2,
  margin: EdgeInsets.symmetric(vertical: 8, horizontal: 4),
  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
  child: InkWell(
    onTap: () {
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => OrderDetailScreen(order: order),
        ),
      );
    },
    borderRadius: BorderRadius.circular(12),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Order #${order.id.substring(0, 8)}',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown),
              ),
              Row(
                children: [
                  Icon(statusIcon, color: statusColor, size: 18),
                  SizedBox(width: 4),
                  Text(
                    capitalize(order.status.toString().split('.').last),
                    style: TextStyle(color: statusColor, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ],
          ),
          Divider(),
          Row(
            children: [
              Icon(Icons.access_time, size: 16, color: Colors.grey),
              SizedBox(width: 4),
              Expanded(
                child: Text(
                  '$formattedDate at $formattedTime',
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.brown),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${order.items.length} ${order.items.length == 1 ? 'item' : 'items'}',
                style: TextStyle(color: Colors.grey[600]),
              ),
              // Calculate total including customization prices and tax
              Builder(
                builder: (context) {
                  // Calculate subtotal (items + customizations)
                  double subtotal = 0.0;
                  for (var item in order.items) {
                    double itemBasePrice = item.price * item.quantity;
                    double customizationPrice = 0.0;
                    
                    if (item.customizations != null && item.customizations!.isNotEmpty) {
                      customizationPrice = item.customizations!.fold(0.0, 
                        (sum, option) => sum + (option.price * item.quantity));
                    }
                    
                    subtotal += (itemBasePrice + customizationPrice);
                  }
                  
                  final double taxRate = 0.10;
                  final double taxAmount = subtotal * taxRate;
                  final double totalWithTax = subtotal + taxAmount;
                  
                  return Text(
                    'Rp ${formatRupiah(totalWithTax)}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold, 
                      fontSize: 16, 
                      color: Colors.brown
                    ),
                  );
                }
              ),
            ],
          ),
          if (order.status == OrderStatus.cancelled && order.cancellationReason != null)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Cancellation Reason:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  SizedBox(height: 4),
                  Text(order.cancellationReason!, style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
                ],
              ),
            ),
          
          if (order.status == OrderStatus.active || order.status == OrderStatus.processing || order.status == OrderStatus.ready)
            Padding(
              padding: const EdgeInsets.only(top: 12.0),
              child: Row(
                children: [
                  if (order.status == OrderStatus.active || order.status == OrderStatus.processing)
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.cancel_outlined, size: 16),
                        label: Text('Cancel', style: TextStyle(fontSize: 12)),
                        onPressed: () => cancelOrder(order.id),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          foregroundColor: Colors.white,
                          backgroundColor: Colors.red,
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    
                    SizedBox(width: 8), 
                    
                    Expanded(
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.visibility, size: 16),
                        label: Text('Track', style: TextStyle(fontSize: 12)),
                        onPressed: () => _navigateToTrackingScreen(context, order),
                        style: ElevatedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          backgroundColor: Colors.brown,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    
                    
                    if (order.status == OrderStatus.ready)
                      Expanded(
                        child: OutlinedButton.icon(
                          icon: Icon(Icons.help_outline, size: 16),
                          label: Text('Support', style: TextStyle(fontSize: 12)),
                          onPressed: () => _showSupportDialog(context, order),
                          style: OutlinedButton.styleFrom(
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                            foregroundColor: Theme.of(context).primaryColor,
                            padding: EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              
            if (order.status == OrderStatus.completed)
              Padding(
                padding: const EdgeInsets.only(top: 12.0),
                child: Row(
                  children: [
                    // Receipt button
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.receipt, color: Colors.amber[500]),
                        label: Text('View Receipt', style: TextStyle(color: Colors.amber[800]),),
                        onPressed: () => _navigateToReceiptScreen(context, order),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(vertical: 10),
                        ),
                      ),
                    ),
                    SizedBox(width: 8),
                    // Support button for completed orders
                    Expanded(
                      child: OutlinedButton.icon(
                        icon: Icon(Icons.help_outline, color: Colors.amber[500]),
                        label: Text('Support', style: TextStyle(color: Colors.amber[800]),),
                        onPressed: () => _showSupportDialog(context, order),
                        style: OutlinedButton.styleFrom(
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          padding: EdgeInsets.symmetric(vertical: 10),
                          
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    ),
  );
}


  // Helper function to capitalize the first letter of a string
  String capitalize(String text) {
    if (text.isEmpty) return text;
    return "${text[0].toUpperCase()}${text.substring(1)}";
  }

  void _showSupportDialog(BuildContext context, Order order) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Contact Support'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            leading: Icon(Icons.call, color: Theme.of(context).primaryColor),
            title: Text('Call Support'),
            subtitle: Text('Speak with our team directly'),
            onTap: () {
              // Implementation for calling support
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Calling support...'), duration: Duration(seconds: 2), backgroundColor: Colors.brown,),
              );
              // Add call functionality here
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.message, color: Theme.of(context).primaryColor),
            title: Text('Message Support'),
            subtitle: Text('Send us a message about your order'),
            onTap: () {
              // Implementation for messaging support
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Opening messaging...'), duration: Duration(seconds: 2), backgroundColor: Colors.brown,),
              );
              // Add messaging functionality here
            },
          ),
          Divider(),
          ListTile(
            leading: Icon(Icons.report_problem, color: Theme.of(context).primaryColor),
            title: Text('Report Issue'),
            subtitle: Text('Report a problem with your order'),
            onTap: () {
              // Implementation for reporting an issue
              Navigator.of(ctx).pop();
              _showReportIssueDialog(context, order);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('Close'),
        ),
      ],
    ),
  );
}

void _showReportIssueDialog(BuildContext context, Order order) {
  final TextEditingController _issueController = TextEditingController();
  
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Report an Issue'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Please describe the issue with your order:'),
          SizedBox(height: 12),
          TextField(
            controller: _issueController,
            decoration: InputDecoration(
              hintText: 'Describe your issue here...',
              border: OutlineInputBorder(),
              filled: true,
              fillColor: Colors.grey[100],
            ),
            maxLines: 5,
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            // Submit the issue report
            if (_issueController.text.trim().isNotEmpty) {
              // Implementation for submitting issue report
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Issue reported successfully. Our team will contact you soon.'),
                  backgroundColor: Colors.brown,
                ),
              );
              // Add issue reporting functionality here
            } else {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Please describe your issue'),
                  backgroundColor: Colors.red,
                ),
              );
            }
          },
          child: Text('Submit'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Theme.of(context).primaryColor,
            foregroundColor: Colors.white,
          ),
        ),
      ],
    ),
  );
}

  // Helper method to format rupiah with thousand separators
  String formatRupiah(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _navigateToTrackingScreen(BuildContext context, Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => OrderTrackingScreen(order: order),
      ),
    );
  }
  
  // Add navigation to receipt screen
  void _navigateToReceiptScreen(BuildContext context, Order order) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ReceiptScreen(order: order),
      ),
    );
  }

  // Cancel Order implementation
Future<void> cancelOrder(String orderId) async {
  try {
    // Get the current user's email safely
    final user = FirebaseAuth.instance.currentUser;
    final email = user?.email ?? ''; // Safe handling of null email

    // Show a dialog to confirm and get reason
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => CancelOrderDialog(
        orderId: orderId,
      ),
    );

    // The dialog might return null (if user dismisses it)
    // We should handle this case properly
    if (reason != null) {
      // Show loading indicator
      setState(() {
        isLoading = true;
      });

      // Call the service with null-safe parameters
      await _orderService.cancelOrder(
        orderId, 
        reason: reason,  // This could be empty string but not null now
        email: email,    // This could be empty string but not null now
      ); 

      // Check if widget is still mounted before updating UI
      if (mounted) {
        setState(() {
          isLoading = false;
        });

        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Order cancelled successfully'),
            backgroundColor: Colors.brown,
          ),
        );
      }
    }
  } catch (e) {
    // Check if widget is still mounted before showing error
    if (mounted) {
      setState(() {
        isLoading = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error cancelling order: ${e.toString()}'),
          backgroundColor: Colors.brown,
        ),
      );
    }
  }
}
}

class CancelOrderDialog extends StatefulWidget {
  final String orderId;

  const CancelOrderDialog({Key? key, required this.orderId}) : super(key: key);

  @override
  State<CancelOrderDialog> createState() => _CancelOrderDialogState();
}

class _CancelOrderDialogState extends State<CancelOrderDialog> with TickerProviderStateMixin {
  bool _isLoading = false;
  String? selectedReason;

  final List<String> cancelReasons = [
    'Changed my mind',
    'Ordered by mistake',
    'Took too long to prepare',
    'Found a better option',
  ];
  
  Future<void> _processCancellation() async {
    setState(() {
      _isLoading = true;
    });
    try {
      final orderService = OrderService();
      String reason = selectedReason ?? '';

      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? '';

      await orderService.cancelOrder(widget.orderId, reason: reason, email: email);

      if (mounted) {
        Navigator.of(context).pop(reason); // Return the reason to the parent
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Failed to cancel order: ${e.toString()}')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Text('Cancel Order', style: TextStyle(color: Colors.brown),),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Please select a reason for cancellation:', style: TextStyle(color: Colors.grey),),
            SizedBox(height: 16),
            ...cancelReasons.map((reason) => RadioListTile<String>(
              title: Text(reason),
              value: reason,
              groupValue: selectedReason,
              onChanged: (value) {
                setState(() {
                  selectedReason = value;
                });
              },
              contentPadding: EdgeInsets.zero,
              dense: true,
            )).toList(),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.of(context).pop(),
          child: Text('Back', style: TextStyle(color: Colors.brown),),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
            foregroundColor: Colors.white,
          ),
          onPressed: _isLoading ? null : () {
            if (selectedReason != null) {
              _processCancellation();
            } else {
              // Show error if no reason selected
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Please select a reason')),
              );
            }
          },
          child: _isLoading 
              ? CircularProgressIndicator(color: Colors.white)
              : Text('Cancel Order'),
        ),
      ],
    );
  }
}

class OrderTrackingScreen extends StatefulWidget {
  final Order order;

  const OrderTrackingScreen({Key? key, required this.order}) : super(key: key);

  @override
  _OrderTrackingScreenState createState() => _OrderTrackingScreenState();
}

class _OrderTrackingScreenState extends State<OrderTrackingScreen> {
  final OrderService _orderService = OrderService();
  late Stream<Order> _orderStream;

  @override
  void initState() {
    super.initState();
    _orderStream = _orderService.getOrderStream(widget.order.id).cast<Order>(); // Ensure the stream is cast to Stream<Order>
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Track Order'),
        backgroundColor: Colors.brown,
      ),
      body: StreamBuilder<Order>(
        stream: _orderStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final order = snapshot.data ?? widget.order; // Use the order from the stream or fallback to the passed order

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Order ID and Status
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Order #${order.id.substring(0, 8)}',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: Colors.brown),
                            ),
                            _buildStatusChip(order),
                          ],
                        ),
                        SizedBox(height: 8),
                        Divider(),
                        SizedBox(height: 8),
                        _buildTrackingTimeline(order),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Order Processing Info
                Text(
                  'Processing Information',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                SizedBox(height: 10),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.access_time, color: Theme.of(context).primaryColor),
                            SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Estimated Completion: ${_getEstimatedCompletionTime(order)}',
                                style: TextStyle(fontSize: 16, color: Colors.brown),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Order Items
                Text(
                  'Order Items',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                SizedBox(height: 10),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: ListView.separated(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: order.items.length,
                    separatorBuilder: (context, index) => Divider(),
                    itemBuilder: (context, index) {
                      final item = order.items[index];
                      return ListTile(
                        title: Text(item.productName, style: TextStyle(color: Colors.brown),),
                        subtitle: Text('Quantity: ${item.quantity}', style: TextStyle(color: Colors.brown),),
                        trailing: Text(
                          'Rp ${formatRupiah(item.price * item.quantity)}',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                        ),
                      );
                    },
                  ),
                ),

                SizedBox(height: 20),

                // Order Summary
                Text(
                  'Order Summary',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown),
                ),
                SizedBox(height: 10),
                Card(
                  elevation: 2,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Subtotal', style: TextStyle(color: Colors.brown),),
                            Text('Rp ${formatRupiah(order.subtotal)}', style: TextStyle(color: Colors.brown),),
                          ],
                        ),
                        SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Tax', style: TextStyle(color: Colors.brown),),
                            Text('Rp ${formatRupiah(order.tax)}', style: TextStyle(color: Colors.brown),),
                          ],
                        ),
                        Divider(),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Total',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                            ),
                            Text(
                              'Rp ${formatRupiah(order.totalAmount)}',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),

                SizedBox(height: 20),

                // Support Button
                if (order.status == OrderStatus.active)
                  Center(
                    child: ElevatedButton.icon(
                      icon: Icon(Icons.help_outline),
                      label: Text('Need Help?'),
                      onPressed: () {
                        _showSupportDialog(context, order);
                      },
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        backgroundColor: Colors.brown,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ),

                SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusChip(Order order) {
  Color statusColor;
  String statusText;
  IconData statusIcon;

  if (order.paymentStatus == PaymentStatus.pending) {
    statusColor = Colors.orange;
    statusText = 'Pending Pay';
    statusIcon = Icons.access_time;
  } else if (order.status == OrderStatus.paid) {
    statusColor = Colors.lightGreen;
    statusText = 'Paid';
    statusIcon = Icons.payments;  
  } else if (order.status == OrderStatus.processing) {
    statusColor = Colors.orangeAccent;
    statusText = 'Processing';
    statusIcon = Icons.restaurant;  
  } else if (order.status == OrderStatus.ready) {
    statusColor = Colors.blue;
    statusText = 'Ready';
    statusIcon = Icons.done_all;
  } else if (order.status == OrderStatus.completed) {
    statusColor = Colors.blue;
    statusText = 'Completed';
    statusIcon = Icons.check_circle;
  } else if (order.status == OrderStatus.cancelled) {
    statusColor = Colors.red;
    statusText = 'Cancelled';
    statusIcon = Icons.cancel;
  } else {
    statusColor = Colors.grey;
    statusText = 'Unknown';
    statusIcon = Icons.help_outline;
  }

  return Chip(
    avatar: Icon(statusIcon, color: Colors.white, size: 18),
    label: Text(
      statusText,
      style: TextStyle(color: Colors.white),
    ),
    backgroundColor: statusColor,
    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 0),
  );
}


  Widget _buildTrackingTimeline(Order order) {
  // Define the steps in the order process
  List<Map<String, dynamic>> steps = [
    {
      'title': 'Order Placed',
      'icon': Icons.receipt,
      'isCompleted': true, // Always completed as we're viewing an existing order
      'time': _formatDateTime(order.orderDate),
    },
    {
      'title': 'Paid',
      'icon': Icons.payments,
      'isCompleted': order.status == OrderStatus.paid || 
                     order.status == OrderStatus.processing || 
                     order.preparingStatus == PreparingStatus.preparing || 
                     order.preparingStatus == PreparingStatus.ready || 
                     order.status == OrderStatus.completed,
      'time': order.paymentTime != null ? _formatDateTime(order.paymentTime!) : 'N/A',
    },
    {
      'title': 'Preparing',
      'icon': Icons.restaurant,
      'isCompleted': order.status == OrderStatus.processing || 
                     order.preparingStatus == PreparingStatus.preparing || 
                     order.preparingStatus == PreparingStatus.ready || 
                     order.status == OrderStatus.completed,
      'time': order.preparingTime != null ? _formatDateTime(order.preparingTime!) : 'N/A',
    },
    {
      'title': 'Ready',
      'icon': Icons.done_all,
      'isCompleted': order.status == OrderStatus.ready || 
                     order.preparingStatus == PreparingStatus.ready || 
                     order.status == OrderStatus.completed,
      'time': (order.preparingStatus == PreparingStatus.ready && order.readyTime != null) 
              ? _formatDateTime(order.readyTime!) 
              : 'N/A', 
    },
    {
      'title': 'Completed',
      'icon': Icons.check_circle,
      'isCompleted': order.status == OrderStatus.completed,
      'time': order.completionTime != null ? _formatDateTime(order.completionTime!) : 'N/A',
    },
  ];

    return Column(
      children: List.generate(steps.length, (index) {
        final step = steps[index];
        final isLast = index == steps.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: step['isCompleted'] ? Colors.brown : Colors.grey[300],
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    step['icon'],
                    color: step['isCompleted'] ? Colors.white : Colors.grey[600],
                    size: 18,
                  ),
                ),
                if (!isLast)
                  Container(
                    width: 2,
                    height: 30,
                    color: step['isCompleted'] && steps[index + 1]['isCompleted'] 
                        ? Theme.of(context).primaryColor 
                        : Colors.grey[300],
                  ),
              ],
            ),
            SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    step['title'],
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: step['isCompleted'] ? Colors.brown : Colors.grey[600],
                    ),
                  ),
                  if (step['time'] != null && step['time'] != 'N/A')
                    Text(
                      step['time'],
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 12,
                      ),
                    ),
                  SizedBox(height: isLast ? 0 : 20),
                ],
              ),
            ),
          ],
        );
      }),
    );
  }

  String _formatDateTime(DateTime dateTime) {
    final day = dateTime.day.toString().padLeft(2, '0');
    final month = dateTime.month.toString().padLeft(2, '0');
    final year = dateTime.year;
    final hour = dateTime.hour.toString().padLeft(2, '0');
    final minute = dateTime.minute.toString().padLeft(2, '0');

    return '$day/$month/$year $hour:$minute';
  }

  String _getEstimatedCompletionTime(Order order) {
    if (order.status == OrderStatus.completed) {
      return 'Completed';
    }

    if (order.status == OrderStatus.cancelled) {
      return 'Order Cancelled';
    }

    // If no estimated time, calculate a rough estimate
    final now = DateTime.now();

    if (order.preparingStatus == PreparingStatus.preparing) {
      // If still preparing, estimate 30 minutes from current time
      return _formatDateTime(now.add(Duration(minutes: 30)));
    } else if (order.preparingStatus == PreparingStatus.ready) {
      // If ready, estimate 5 minutes from current time
      return _formatDateTime(now.add(Duration(minutes: 5)));
    }

    // Default fallback
    return _formatDateTime(now.add(Duration(minutes: 35)));
  }

  // Helper method to format rupiah with thousand separators
  String formatRupiah(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void _showSupportDialog(BuildContext context, Order order) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Contact Support', style: TextStyle(color: Colors.brown),),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.call),
              title: Text('Call Support'),
              onTap: () {
                // Implementation for calling support
                Navigator.of(ctx).pop();
                // Add call functionality here
              },
            ),
            ListTile(
              leading: Icon(Icons.message),
              title: Text('Message Support'),
              onTap: () {
                // Implementation for messaging support
                Navigator.of(ctx).pop();
                // Add messaging functionality here
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('Close', style: TextStyle(color: Colors.brown),),
          ),
        ],
      ),
    );
  }
}