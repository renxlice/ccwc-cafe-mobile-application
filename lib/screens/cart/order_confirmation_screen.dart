import 'package:flutter/material.dart';
import '../models/order_model.dart';
import '../models/cart_item.dart';
import '../../services/order_service.dart';
import '../home/home.dart';
import 'receipt_screen.dart';

class OrderConfirmationScreen extends StatefulWidget {
  final String? orderId; 
  final bool isPending; 
  final bool isCashOrQRIS; 
  final List<CartItem> cartItems;
  
  OrderConfirmationScreen({
    this.orderId, 
    this.isPending = false,
    this.isCashOrQRIS = false,
    required this.cartItems, 
  });
  
  @override
  _OrderConfirmationScreenState createState() => _OrderConfirmationScreenState();
}

class _OrderConfirmationScreenState extends State<OrderConfirmationScreen> {
  bool _isLoading = true;
  Order? _order;
  String? _errorMessage;

  // Updated calculation methods to properly include customization costs
  double get subtotal => widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * 0.10;
  double get totalAmount => subtotal + tax;

  @override
  void initState() {
    super.initState();
    if (widget.orderId != null) {
      _fetchOrderDetails();
    } else {
      setState(() {
        _isLoading = false;
      });
    }
  }

  Future<void> _fetchOrderDetails() async {
    try {
      final orderService = OrderService();
      // Assuming getOrderDetails returns a Stream<Order?>
      Stream<Order?> orderStream = orderService.getOrderDetails(widget.orderId!);
      
      // Listen to the stream
      orderStream.listen((order) {
        if (mounted) {
          setState(() {
            _order = order; // Update the order with the latest value from the stream
            _isLoading = false; // Stop loading
          });
        }
      }, onError: (error) {
        if (mounted) {
          setState(() {
            _isLoading = false;
            _errorMessage = "Error loading order: ${error.toString()}";
          });
        }
      });
    } catch (error) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = "Error loading order: ${error.toString()}";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        Navigator.of(context).popUntil((route) => route.isFirst);
        return false;
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text('Order Confirmation', style: TextStyle(fontWeight: FontWeight.bold)),
          backgroundColor: Colors.brown,
          automaticallyImplyLeading: false,
        ),
        body: widget.orderId == null
            ? _buildNoOrderView()
            : (_isLoading
                ? Center(child: CircularProgressIndicator())
                : _order == null
                    ? _buildErrorView()
                    : _buildSuccessView()),
      ),
    );
  }

  Widget _buildNoOrderView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.shopping_cart, size: 80, color: Colors.grey),
          SizedBox(height: 20),
          Text('No active order', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          SizedBox(height: 10),
          Text('Complete a purchase to see your order confirmation here', textAlign: TextAlign.center, style: TextStyle(color: Colors.grey)),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text('BROWSE MENU', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 80, color: Colors.red),
          SizedBox(height: 20),
          Text('Failed to load order details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
          SizedBox(height: 10),
          if (_errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Text(_errorMessage!, textAlign: TextAlign.center, style: TextStyle(color: Colors.red[700])),
            ),
          SizedBox(height: 20),
          ElevatedButton(
            onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            child: Text('BACK TO HOME',  style: TextStyle(color: Colors.indigo),),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessView() {
    // Different icon and title based on payment status
    IconData statusIcon = widget.isPending
        ? Icons.access_time_filled
        : Icons.check;
    Color statusColor = widget.isPending
        ? Colors.orange
        : Colors.green;
    String statusTitle = widget.isPending
        ? 'Order Received!'
        : 'Order Active';
    
    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2), 
                shape: BoxShape.circle
              ),
              child: Icon(statusIcon, size: 60, color: statusColor),
            ),
            SizedBox(height: 20),
            Text(statusTitle, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.grey)),
            SizedBox(height: 10),
            Text(
              widget.isPending
                  ? 'Your order has been placed and is awaiting payment confirmation.'
                  : 'Your order has been placed and is being prepared.',
              textAlign: TextAlign.center, 
              style: TextStyle(fontSize: 16, color: Colors.grey[700])
            ),
            SizedBox(height: 30),
            Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Order Details',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                    ),
                    SizedBox(height: 16),

                    // Order information
                    _buildInfoRow('Order ID:', widget.orderId ?? '-'),
                    _buildInfoRow('Username:', _order?.userName ?? 'Unknown'),
                    _buildInfoRow('Status:', widget.isPending ? 'Pending' : 'Paid'),
                    SizedBox(height: 16),

                    // Items List Title
                    Text('Items:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey)),
                    SizedBox(height: 8),

                    // Display items from the order if available, otherwise use cartItems
                    if (_order != null && _order!.items.isNotEmpty)
                      ..._order!.items.map((item) => _buildOrderItemRow(item)).toList()
                    else
                      ...widget.cartItems.map((item) => _buildCartItemRow(item)).toList(),

                    // Divider
                    Divider(height: 32),

                    // Subtotal, Tax, Total Amount
                    _buildInfoRow('Subtotal:', 'Rp ${formatRupiah(subtotal)}'),
                    _buildInfoRow('Tax:', 'Rp ${formatRupiah(tax)}'),
                    Divider(height: 16),
                    _buildInfoRow(
                      'Total Amount:',
                      'Rp ${formatRupiah(totalAmount)}',
                      isTotal: true, 
                    ),
                  ],
                ),
              ),
            ),
            // Cash or QRIS specific instructions
            if (widget.isCashOrQRIS)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Card(
                  color: Colors.blue[50],
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: Colors.blue),
                            SizedBox(width: 8),
                            Text(
                              'Cash or QRIS Payment',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue[700]),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Please follow these steps to complete your payment:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        SizedBox(height: 8),
                        _buildInstructionStep(1, 'Present your Order ID to our cashier.'),
                        _buildInstructionStep(2, 'Make the payment using cash or scan the QRIS code at the store.'),
                        _buildInstructionStep(3, 'Once payment is confirmed, your order will be processed immediately.'),
                        SizedBox(height: 10),
                        Container(
                          padding: EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.receipt_long, color: Colors.blue[700]),
                              SizedBox(width: 8),
                              Text(
                                'Order ID: ${widget.orderId}',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.brown),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            // For pending payments that are not Cash or QRIS (e.g. bank transfers)
            if (widget.isPending && !widget.isCashOrQRIS)
              Padding(
                padding: EdgeInsets.only(top: 20),
                child: Card(
                  color: Colors.amber[50],
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.payments_outlined, color: Colors.amber[800]),
                            SizedBox(width: 8),
                            Text(
                              'Payment Pending',
                              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.amber[800]),
                            ),
                          ],
                        ),
                        SizedBox(height: 12),
                        Text(
                          'Please complete your payment using the instructions provided.',
                          style: TextStyle(fontSize: 16, color: Colors.brown),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Your order will be processed once payment is confirmed.',
                          style: TextStyle(fontSize: 16, color: Colors.brown),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            SizedBox(height: 20),
            Text('Thank you for your order!', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
            SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
                child: Text('RETURN TO HOME', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated method to build a row for a cart item with detailed customizations
  Widget _buildCartItemRow(CartItem item) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '${item.quantity} x ${item.productName}',
                  style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey),
                ),
              ),
              Text(
                'Rp ${formatRupiah(item.totalPrice)}', 
                style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)
              ),
            ],
          ),
        ),
        // Base price information
        Padding(
        padding: const EdgeInsets.only(left: 16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Base Price: Rp ${formatRupiah(item.price)}',
              style: TextStyle(fontSize: 14, color: Colors.grey[600]),
            ),
            if (item.customizationPrice > 0)
              Text(
                '+ Customization: Rp ${formatRupiah(item.customizationPrice)}',
                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
              ),
          ],
        ),
      ),
        
        // Display customizations if they exist
        if (item.customizations != null && item.customizations!.isNotEmpty)
          Container(
            margin: EdgeInsets.only(left: 16.0, top: 4.0, bottom: 8.0),
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customizations:',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                SizedBox(height: 4),
                ...item.customizations!.map((option) => Padding(
                  padding: const EdgeInsets.only(left: 8.0, top: 2.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${option.name}: ${option.value}',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                      Text(
                        'Rp ${formatRupiah(option.price)}',
                        style: TextStyle(fontSize: 13, color: Colors.grey),
                      ),
                    ],
                  ),
                )).toList(),
              ],
            ),
          ),
        
        // If we have notes for the item, display them
        if (item.notes != null && item.notes!.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(left: 16.0, bottom: 8.0),
            child: Text(
              'Notes: ${item.notes}',
              style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic, color: Colors.grey[700]),
            ),
          ),
        
        // Add a small space between items
        SizedBox(height: 6),
      ],
    );
  }

  // Method to build a row for an order item (this is for items from a fetched order)
  Widget _buildOrderItemRow(dynamic item) {
    // Check if the item has customizations and display them
    if (item is CartItem) {
      return _buildCartItemRow(item);
    } else {
      // Fallback for non-CartItem objects
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${item.quantity} x ${item.productName}', style: TextStyle(color: Colors.brown),),
            Text('Rp ${formatRupiah(item.price)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown)),
          ],
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label, 
            style: TextStyle(
              fontSize: isTotal ? 18 : 16, 
              color: isTotal ? Colors.grey : Colors.grey[700],
              fontWeight: isTotal ? FontWeight.bold : FontWeight.normal,
            )
          ),
          Text(
            value, 
            style: TextStyle(
              fontSize: isTotal ? 18 : 16, 
              fontWeight: FontWeight.bold,
              color: isTotal ? Colors.grey : Colors.grey,
            )
          ),
        ],
      ),
    );
  }
  
  Widget _buildInstructionStep(int step, String instruction) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: EdgeInsets.only(top: 2),
            width: 20,
            height: 20,
            decoration: BoxDecoration(
              color: Colors.blue,
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                step.toString(),
                style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
              ),
            ),
          ),
          SizedBox(width: 12),
          Expanded(
            child: Text(instruction, style: TextStyle(fontSize: 15)),
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
}