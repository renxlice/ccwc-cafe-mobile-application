import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import '../models/order_model.dart';
import '../models/cart_item.dart';
import '../../services/order_service.dart';
import '../../services/cart_service.dart';
import '../../services/midtrans_payment_service.dart'; 
import 'order_confirmation_screen.dart';

class PaymentScreen extends StatefulWidget {
  final String orderId;
  final double totalAmount;
  final PaymentMethod paymentMethod;
  final CartService cartService; 
  final List<CartItem> cartItems;
  final MidtransPaymentService midtransPaymentService;

  PaymentScreen({
    required this.orderId,
    required this.totalAmount,
    required this.paymentMethod,
    required this.cartService,
    required this.cartItems,
    required this.midtransPaymentService,
  });

  @override
  _PaymentScreenState createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  bool _isLoading = false;
  late Timer _paymentTimer;
  int _timeLeft = 300; // 5 minutes (300 seconds)
  
  // Updated calculation methods to properly include customization costs
  double get subtotal => widget.cartItems.fold(0, (sum, item) => sum + item.totalPrice);
  double get tax => subtotal * 0.10;
  double get totalAmount => subtotal + tax;

  @override
  void initState() {
    super.initState();
    
    // Start payment timer
    _paymentTimer = Timer.periodic(Duration(seconds: 1), (timer) {
      setState(() {
        if (_timeLeft > 0) {
          _timeLeft--;
        } else {
          _paymentTimer.cancel();
          _handlePaymentTimeout();
        }
      });
    });
  }

  @override
  void dispose() {
    _paymentTimer.cancel();
    super.dispose();
  }

  Future<void> _handlePaymentTimeout() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? '';
      
      final orderService = OrderService();
      await orderService.updatePaymentStatus(widget.orderId, PaymentStatus.failed, email: email);
      await orderService.cancelOrder(widget.orderId, reason: 'Payment timeout', email: email);
      
      // Show timeout dialog
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text('Payment Timeout'),
          content: Text('Your payment time has expired. The order has been cancelled.'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
              child: Text('OK'),
            ),
          ],
        ),
      );
    } catch (error) {
      print('Error handling payment timeout: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    String minutes = (_timeLeft ~/ 60).toString().padLeft(2, '0');
    String seconds = (_timeLeft % 60).toString().padLeft(2, '0');

    return Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Colors.brown,
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            showDialog(
              context: context,
              builder: (ctx) => AlertDialog(
                title: Text('Cancel Payment?', style: TextStyle(color: Colors.grey),),
                content: Text('If you go back, your order will be cancelled.', style: TextStyle(color: Colors.brown),),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.of(ctx).pop(),
                    child: Text('STAY'),
                  ),
                  TextButton(
                    onPressed: () async {
                      Navigator.of(ctx).pop();
                      setState(() {
                        _isLoading = true;
                      });

                      try {
                        final user = FirebaseAuth.instance.currentUser;
                        final email = user?.email ?? '';
                        
                        final orderService = OrderService();
                        await orderService.cancelOrder(widget.orderId, reason: 'User cancelled payment', email: email);
                        Navigator.of(context).popUntil((route) => route.isFirst);
                      } catch (error) {
                        print('Error cancelling order: $error');
                      } finally {
                        setState(() {
                          _isLoading = false;
                        });
                      }
                    },
                    child: Text('CANCEL ORDER', style: TextStyle(color: Colors.red)),
                  ),
                ],
              ),
            );
          },
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
                    // Payment timer
                    Container(
                      width: double.infinity,
                      padding: EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.orange.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Payment Time Remaining',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 8),
                          Text(
                            '$minutes:$seconds',
                            style: TextStyle(
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                              color: _timeLeft < 60 ? Colors.red : Colors.black,
                            ),
                          ),
                        ],
                      ),
                    ),

                    SizedBox(height: 20),

                    // Order ID
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Order ID', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            SizedBox(height: 4),
                            Text(widget.orderId, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown)),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 20),

                    // Payment details
                    Card(
                      child: Padding(
                        padding: EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment Details', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                            SizedBox(height: 16),
                            
                            // Payment method info
                            Text('Payment Method', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            SizedBox(height: 4),
                            Text(
                              _getPaymentMethodName(widget.paymentMethod),
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown),
                            ),
                            
                            SizedBox(height: 16),

                            // Itemized order details
                            Text('Order Items', style: TextStyle(fontSize: 16, color: Colors.grey)),
                            SizedBox(height: 8),
                            
                            // List all items with their details
                            ...widget.cartItems.map((item) => Padding(
                              padding: const EdgeInsets.only(bottom: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text('${item.quantity}x ${item.productName}', 
                                          style: TextStyle(fontWeight: FontWeight.w500, color: Colors.grey)),
                                      Text('Rp ${formatRupiah(item.price * item.quantity)}', style: TextStyle(color: Colors.brown),)
                                    ],
                                  ),
                                  if (item.customizations != null && item.customizations!.isNotEmpty)
                                    ...item.customizations!.map((option) => Padding(
                                      padding: const EdgeInsets.only(left: 12.0),
                                      child: Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Text('${option.name}: ${option.value}', 
                                              style: TextStyle(fontSize: 14, color: Colors.brown)),
                                          Text('Rp ${formatRupiah(option.price * item.quantity)}', 
                                              style: TextStyle(fontSize: 14, color: Colors.brown))
                                        ],
                                      ),
                                    )).toList(),
                                ],
                              ),
                            )).toList(),
                            
                            Divider(thickness: 1),

                            // Subtotal
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Subtotal', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                Text(
                                  'Rp ${formatRupiah(subtotal)}',
                                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.brown),
                                ),
                              ],
                            ),

                            SizedBox(height: 8),

                            // Tax
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Tax (10%)', style: TextStyle(fontSize: 16, color: Colors.grey)),
                                Text(
                                  'Rp ${formatRupiah(tax)}',
                                  style: TextStyle(fontSize: 16, color: Colors.brown),
                                ),
                              ],
                            ),

                            SizedBox(height: 12),
                            Divider(thickness: 1),
                            SizedBox(height: 8),

                            // Total Amount
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total Amount', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey)),
                                Text(
                                  'Rp ${formatRupiah(totalAmount)}',
                                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: Colors.brown),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),

                    SizedBox(height: 30),

                    // Confirm payment button
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(vertical: 15),
                          backgroundColor: Colors.green,
                        ),
                        onPressed: _processMidtransPayment,
                        child: Text(
                          'PROCEED TO PAYMENT',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),

                    SizedBox(height: 15),

                    // Cancel payment button
                    SizedBox(
                      width: double.infinity,
                      child: TextButton(
                        style: TextButton.styleFrom(padding: EdgeInsets.symmetric(vertical: 15)),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: Text('Cancel Payment?', style: TextStyle(color: Colors.brown),),
                              content: Text('Your order will be cancelled. Are you sure?', style: TextStyle(color: Colors.brown),),
                              actions: [
                                TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text('NO')),
                                TextButton(
                                  onPressed: () async {
                                    Navigator.of(ctx).pop();
                                    setState(() {
                                      _isLoading = true;
                                    });

                                    try {
                                      final user = FirebaseAuth.instance.currentUser;
                                      final email = user?.email ?? '';
                                      
                                      final orderService = OrderService();
                                      await orderService.cancelOrder(widget.orderId, reason: 'User cancelled payment', email: email);
                                      Navigator.of(context).popUntil((route) => route.isFirst);
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        SnackBar(
                                          content: Text('Order cancelled successfully'),
                                          duration: Duration(seconds: 2),
                                          backgroundColor: Colors.brown,
                                        ),
                                      );
                                    } catch (error) {
                                      print('Error cancelling order: $error');
                                    } finally {
                                      setState(() {
                                        _isLoading = false;
                                      });
                                    }
                                  },
                                  child: Text('YES, CANCEL', style: TextStyle(color: Colors.red)),
                                ),
                              ],
                            ),
                          );
                        },
                        child: Text(
                          'CANCEL PAYMENT',
                          style: TextStyle(fontSize: 16, color: Colors.red),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
    );
  }

  String _getPaymentMethodName(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash Or QRIS';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      case PaymentMethod.eWallet:
        return 'E-Wallet';
      default:
        return 'Unknown';
    }
  }
  
  // Helper method to format rupiah with thousand separators
  String formatRupiah(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
  
  Future<void> _processMidtransPayment() async {
    setState(() {
      _isLoading = true;
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      final email = user?.email ?? 'guest@example.com';

      // Jika metode pembayaran adalah Cash/QRIS
      if (widget.paymentMethod == PaymentMethod.cash) {
        final orderService = OrderService();
        
        // Update status order menjadi pending
        await orderService.updatePaymentStatus(widget.orderId, PaymentStatus.pending, email: email);
        
        // Tampilkan dialog konfirmasi pembayaran
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text('Payment Confirmation', style: TextStyle(color: Colors.brown),),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Order ID: ${widget.orderId}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  SizedBox(height: 8),
                  Text('Total Amount: Rp ${formatRupiah(totalAmount)}', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  SizedBox(height: 16),
                  Text('Please make the payment to our cashier or scan the QRIS code at the store.', style: TextStyle(color: Colors.grey),),
                  SizedBox(height: 8),
                  Text('Your order will be processed after payment is confirmed.', style: TextStyle(color: Colors.grey),),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () async {
                  Navigator.of(ctx).pop();
                  
                  // Bersihkan keranjang setelah konfirmasi pembayaran
                  await widget.cartService.clear();
                  
                  // Navigasi ke layar konfirmasi order
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => OrderConfirmationScreen(
                        orderId: widget.orderId, 
                        isPending: true,
                        isCashOrQRIS: true,
                        cartItems: widget.cartItems,
                      ),
                    ),
                  );
                },
                child: Text('CONFIRM PAYMENT', style: TextStyle(color: Colors.brown),),
              ),
            ],
          ),
        );
        
        setState(() {
          _isLoading = false;
        });
        
        return;
      }

      // Create transaction details for Midtrans with proper item details
      final paymentParams = await widget.midtransPaymentService.createTransaction(
        orderId: widget.orderId,
        amount: totalAmount, // Use the properly calculated total amount
        email: email,
        items: widget.cartItems, // Pass the full cart items with customizations
      );

      // Configure payment type based on selected payment method
      switch (widget.paymentMethod) {
        case PaymentMethod.bank:
          paymentParams['enabled_payments'] = ['bank_transfer'];
          paymentParams['bank_transfer'] = {'bank': 'mandiri'};
          break;
        case PaymentMethod.eWallet:
          paymentParams['enabled_payments'] = ['gopay', 'shopeepay'];
          break;
        default:
          paymentParams['enabled_payments'] = ['credit_card', 'gopay', 'shopeepay', 'bank_transfer'];
      }

      // Start Midtrans payment flow with custom screen
      final result = await widget.midtransPaymentService.startPaymentWithCustomScreen(
        context,
        paymentParams,
      );

      // Handle payment result
      if (result['status_code'] == '200' || result['transaction_status'] == 'settlement' || result['transaction_status'] == 'capture') {
        // Payment successful
        final orderService = OrderService();
        await orderService.updatePaymentStatus(widget.orderId, PaymentStatus.completed, email: email);

        // Clear the cart after successful payment
        await widget.cartService.clear();

        // Navigate to order confirmation
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (_) => OrderConfirmationScreen(orderId: widget.orderId, cartItems: widget.cartItems),
          ),
        );
      } else if (result['transaction_status'] == 'pending') {
        // Payment pending - show instructions to complete
        final orderService = OrderService();
        await orderService.updatePaymentStatus(widget.orderId, PaymentStatus.pending, email: email);

        // Create payment instructions based on the selected payment method
        List<String> paymentInstructions = [];

        switch (widget.paymentMethod) {
          case PaymentMethod.bank:
            paymentInstructions = [
              'Go to your mobile banking app or ATM',
              'Select transfer > Virtual Account',
              'Enter the virtual account number provided',
              'Confirm the payment details',
              'Complete the payment within the time limit'
            ];
            break;
          case PaymentMethod.eWallet:
            paymentInstructions = [
              'Open your e-wallet app (GoPay or ShopeePay)',
              'Go to the payment or scan section',
              'Follow the instructions in your e-wallet app',
              'Confirm the payment details',
              'Complete the payment within the time limit'
            ];
            break;
          default:
            paymentInstructions = [
              'Follow the payment instructions provided by your payment provider',
              'Complete the transaction within the time limit',
              'Your order will be processed once payment is confirmed'
            ];
        }

        // Show pending payment instructions
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            title: Text('Payment Pending'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Your payment is being processed. Please follow these instructions:'),
                  SizedBox(height: 12),
                  ...List.generate(
                    paymentInstructions.length,
                    (index) => Padding(
                      padding: EdgeInsets.only(bottom: 8),
                      child: Text('${index + 1}. ${paymentInstructions[index]}'),
                    )
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(ctx).pop();
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(
                      builder: (_) => OrderConfirmationScreen(orderId: widget.orderId, isPending: true, cartItems: widget.cartItems),
                    ),
                  );
                },
                child: Text('OK'),
              ),
            ],
          ),
        );
      } else {
        // Payment failed
        throw Exception('Payment failed with status: ${result['status_message'] ?? 'Unknown error'}');
      }
    } catch (error) {
      print('Error processing payment: $error');

      // Show error dialog
      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text('Payment Failed'),
          content: Text('There was an error processing your payment. Please try again later.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text('OK'),
            ),
          ],
        ),
      );
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }
}