import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/cart_item.dart';
import '../models/order_model.dart';
import '../../services/order_service.dart';
import '../../services/cart_service.dart';
import '../../services/midtrans_payment_service.dart'; 
import 'payment_screen.dart';
import '../models/customization_option.dart';

class CheckoutScreen extends StatefulWidget {
  final List<CartItem> cartItems;
  final double totalAmount;

  CheckoutScreen({
    required this.cartItems,
    required this.totalAmount,
  });

  @override
  _CheckoutScreenState createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  PaymentMethod _selectedPaymentMethod = PaymentMethod.cash;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _addressController = TextEditingController();
  bool _isLoading = false;
  final OrderService _orderService = OrderService();

  double get subtotal => widget.cartItems.fold(0, (sum, item) => sum + (item.price * item.quantity));
  double get tax => subtotal * 0.10;
  double get totalAmount => subtotal + tax;

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context, listen: false);

    return Scaffold(
      appBar: AppBar(
        title: Text('Checkout', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.brown,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: _isLoading
          ? Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildOrderSummaryCard(),
                    SizedBox(height: 20),
                    _buildPaymentMethodCard(),
                    SizedBox(height: 20),
                    _buildAdditionalNotesCard(),
                    SizedBox(height: 30),
                    _buildProceedToPaymentButton(cartService),
                  ],
                ),
              ),
            ),
    );
  }

// Updated _buildOrderSummaryCard() method in checkout_screen.dart
Widget _buildOrderSummaryCard() {
  return Card(
    elevation: 2,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    child: Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Order Summary', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
          SizedBox(height: 16),
          ...widget.cartItems.map((item) {
            return Padding(
              padding: EdgeInsets.symmetric(vertical: 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text('${item.productName} x ${item.quantity}', style: TextStyle(fontSize: 16, color: Colors.grey)),
                      ),
                      Text('Rp ${formatRupiah(item.price * item.quantity)}', style: TextStyle(fontSize: 16, color: Colors.brown)),
                    ],
                  ),
                  // Display each customization with its specific price
                  if (item.customizations != null && item.customizations!.isNotEmpty) ...[
                    Padding(
                      padding: const EdgeInsets.only(left: 16.0, top: 4.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: item.customizations!.map((option) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  '${option.name}: ${option.value}', 
                                  style: TextStyle(fontSize: 14, color: Colors.grey)
                                ),
                              ),
                              if (option.price > 0)
                                Text(
                                  'Rp ${formatRupiah(option.price * item.quantity)}', 
                                  style: TextStyle(fontSize: 14, color: Colors.grey)
                                ),
                            ],
                          );
                        }).toList(),
                      ),
                    ),
                  ],
                ],
              ),
            );
          }).toList(),
          Divider(height: 24),
          // Subtotal row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Subtotal', style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text('Rp ${formatRupiah(widget.cartItems.fold(0.0, (sum, item) => sum + item.totalPrice))}', style: TextStyle(fontSize: 16, color: Colors.brown)),
            ],
          ),
          SizedBox(height: 8),
          // Tax row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Tax', style: TextStyle(fontSize: 16, color: Colors.grey)),
              Text('Rp ${formatRupiah(widget.cartItems.fold(0.0, (sum, item) => sum + item.totalPrice) * 0.10)}', style: TextStyle(fontSize: 16, color: Colors.brown)),
            ],
          ),
          SizedBox(height: 8),
          // Total row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Total', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
              Text('Rp ${formatRupiah(widget.cartItems.fold(0.0, (sum, item) => sum + item.totalPrice) * 1.10)}', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.brown)),
            ],
          ),
        ],
      ),
    ),
  );
}

  Widget _buildPaymentMethodCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.payment, color: Colors.brown),
                SizedBox(width: 8),
                Text(
                  'Payment Method',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            _buildPaymentOption(
              title: 'Cash/QRIS (At Cashier)',
              value: PaymentMethod.cash,
              icon: Icons.money,
            ),
            _buildPaymentOption(
              title: 'Bank Transfer',
              value: PaymentMethod.bank,
              icon: Icons.account_balance,
            ),
            _buildPaymentOption(
              title: 'E-Wallet',
              value: PaymentMethod.eWallet,
              icon: Icons.account_balance_wallet,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentOption({
    required String title,
    required PaymentMethod value,
    required IconData icon,
  }) {
    return RadioListTile<PaymentMethod>(
      title: Row(
        children: [
          Icon(icon, size: 20, color: _selectedPaymentMethod == value 
              ? Colors.brown 
              : Colors.grey[600]),
          SizedBox(width: 10),
          Text(title),
        ],
      ),
      value: value,
      groupValue: _selectedPaymentMethod,
      activeColor: Colors.brown,
      onChanged: (newValue) {
        setState(() {
          _selectedPaymentMethod = newValue!;
        });
      },
    );
  }

  Widget _buildAdditionalNotesCard() {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.note, color: Colors.brown),
                SizedBox(width: 8),
                Text(
                  'Additional Notes',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.brown,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            TextField(
              controller: _notesController,
              decoration: InputDecoration(
                hintText: 'Add special instructions...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                  borderSide: BorderSide(color: Theme.of(context).primaryColor, width: 2),
                ),
              ),
              maxLines: 3,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProceedToPaymentButton(CartService cartService) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        style: ElevatedButton.styleFrom(
          padding: EdgeInsets.symmetric(vertical: 15),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          backgroundColor: Colors.brown,
        ),
        onPressed: () => _createOrderAndNavigateToPayment(cartService),
        child: Text(
          'PROCEED TO PAYMENT',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Future<void> _createOrderAndNavigateToPayment(CartService cartService) async {
    if (widget.cartItems.isEmpty) {
      _showErrorDialog('Your cart is empty. Please add items before placing an order.');
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      // Create a new order
      final orderId = await _orderService.createOrder(
        cartItems: cartService.cartItems,
        totalAmount: totalAmount,
        paymentMethod: _selectedPaymentMethod,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      if (orderId == null || orderId.isEmpty) {
        throw Exception('Invalid order ID received');
      }

      // Initialize MidtransPaymentService
      final midtransPaymentService = MidtransPaymentService(merchantId: 'G059408741');

      // Navigate to PaymentScreen with MidtransPaymentService
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => PaymentScreen(
            orderId: orderId,
            totalAmount: totalAmount,
            paymentMethod: _selectedPaymentMethod,
            cartService: cartService,
            cartItems: cartService.cartItems,
            midtransPaymentService: midtransPaymentService, 
          ),
        ),
      );
    } catch (error) {
      _showErrorDialog('Failed to create your order: ${_getReadableErrorMessage(error)}');
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  // Helper method to format rupiah with thousand separators
  String formatRupiah(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }

  void processPayment(double totalAmount) async {
  if (widget.cartItems.isEmpty) {
    _showErrorDialog('Your cart is empty. Please add items before placing an order.');
    return;
  }

  setState(() {
    _isLoading = true;
  });

  try {
    // Create a unique order ID
    final String orderId = 'ORDER-${DateTime.now().millisecondsSinceEpoch}';
    
    // Create payment service instance
    final paymentService = MidtransPaymentService(merchantId: 'G059408741');
    
    // Create transaction using the proper variables from the widget
    final paymentParams = await paymentService.createTransaction(
      orderId: orderId,
      amount: totalAmount,
      email: 'customer@example.com', 
      items: widget.cartItems,
    );
    
    // Start payment with custom screen
    final result = await paymentService.startPaymentWithCustomScreen(
      context,
      paymentParams,
    );
    
    // Handle result
    if (result['transaction_status'] == 'success' || 
        result['transaction_status'] == 'settlement' ||
        result['transaction_status'] == 'capture') {
      // Payment successful
      await _orderService.updateOrderStatus(orderId, OrderStatus.completed);
      
      Navigator.of(context).pushNamedAndRemoveUntil(
        '/productList', // Make sure this route is defined in your app
        (route) => false
      );
    } else {
      // Payment failed or cancelled
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['status_message'] as String))
      );
    }
  } catch (error) {
    _showErrorDialog('Payment processing failed: ${_getReadableErrorMessage(error)}');
  } finally {
    setState(() {
      _isLoading = false;
    });
  }
}

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('An Error Occurred!'),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text('OK'),
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  String _getReadableErrorMessage(dynamic error) {
    final errorMsg = error.toString();
    
    if (errorMsg.contains('timeout') || errorMsg.contains('connection')) {
      return 'Network connection issue. Please check your internet connection.';
    } else if (errorMsg.contains('authentication') || errorMsg.contains('unauthorized')) {
      return 'Authentication failed. Please login again.';
    } else if (errorMsg.contains('server')) {
      return 'Server error. Please try again later.';
    } else if (errorMsg.contains('Provider<OrderService>')) {
      return 'Order service initialization error. Please restart the app.';
    } else {
      return 'Please try again or contact support.';
    }
  }
}