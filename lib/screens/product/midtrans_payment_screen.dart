import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'dart:math'; 

class MidtransPaymentScreen extends StatefulWidget {
  final Map<String, dynamic> paymentParams;
  final String clientKey;
  final String serverKey;
  final String token;
  final bool isProduction;
  final String redirectRoute;
  
  // Add paymentUrl property
  final String paymentUrl;

  MidtransPaymentScreen({
    required this.paymentParams,
    required this.clientKey,
    required this.serverKey,
    required this.token,
    this.isProduction = false,
    this.redirectRoute = '/productlistscreen',
    String? paymentUrl, // Optional parameter with default value in initState
  }) : this.paymentUrl = paymentUrl ?? (isProduction 
        ? 'https://app.midtrans.com/snap/v2/vtweb/$token'
        : 'https://app.sandbox.midtrans.com/snap/v2/vtweb/$token');

  @override
  _MidtransPaymentScreenState createState() => _MidtransPaymentScreenState();
}

class _MidtransPaymentScreenState extends State<MidtransPaymentScreen> {
  late WebViewController _controller;
  bool isLoading = true;
  Timer? _checkStatusTimer;
  bool _hasCompleted = false;
  
  @override
  void initState() {
    super.initState();
    
    // Get order ID from payment params for status checking
    final transactionDetails = widget.paymentParams['transaction_details'] as Map<String, Object>;
    final orderId = transactionDetails['order_id'] as String;
    
    // Initialize WebViewController with proper settings
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0x00000000))
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            print('WebView loading progress: $progress%');
          },
          onPageStarted: (String url) {
            print('Page started loading: $url');
            if (mounted) {
              setState(() {
                isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            print('Page finished loading: $url');
            if (mounted) {
              setState(() {
                isLoading = false;
              });
              
              // Check if the URL contains payment status information
              _checkPaymentStatus(url, orderId);
            }
          },
          onNavigationRequest: (NavigationRequest request) {
            print('Navigation request to: ${request.url}');
            
            // Parse the URL to check for any callback patterns
            final url = request.url.toLowerCase();
            
            // Check for success indicators in URL
            if (_isSuccessUrl(url)) {
              _handlePaymentSuccess(orderId);
              return NavigationDecision.prevent;
            }
            
            // Check for failure indicators in URL
            if (_isFailureUrl(url)) {
              _handlePaymentFailure();
              return NavigationDecision.prevent;
            }
            
            // Allow normal navigation
            return NavigationDecision.navigate;
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.paymentUrl));
    
    // Set up periodic status checking
    _setupStatusCheck(orderId);
  }
  
  // Add the missing _setupStatusCheck method
  void _setupStatusCheck(String orderId) {
    _checkStatusTimer?.cancel();
    _checkStatusTimer = Timer.periodic(Duration(seconds: 5), (timer) {
      _checkPaymentStatusFromApi(orderId);
    });
  }
  
  @override
  void dispose() {
    _checkStatusTimer?.cancel();
    super.dispose();
  }
  
  bool _isSuccessUrl(String url) {
    return url.contains('transaction_status=capture') ||
           url.contains('transaction_status=settlement') ||
           url.contains('status_code=200') ||
           url.contains('status_code=201') ||
           url.contains('payment_type=credit_card') && url.contains('transaction_status=success');
  }
  
  bool _isFailureUrl(String url) {
    return url.contains('transaction_status=deny') ||
           url.contains('transaction_status=cancel') ||
           url.contains('transaction_status=expire') ||
           url.contains('transaction_status=failure') ||
           url.contains('status_code=400') ||
           url.contains('status_code=401') ||
           url.contains('status_code=402') ||
           url.contains('status_code=500');
  }
  
  void _checkPaymentStatus(String url, String orderId) {
    // Check if URL contains payment status
    if (url.contains('status_code=') || url.contains('transaction_status=')) {
      print('Detected payment status in URL: $url');
      
      // Parse query parameters from URL
      Uri uri = Uri.parse(url);
      Map<String, String> params = uri.queryParameters;
      
      if (params.containsKey('transaction_status')) {
        String status = params['transaction_status'] ?? '';
        print('Transaction status: $status');
        
        if (status == 'capture' || status == 'settlement' || status == 'success') {
          _handlePaymentSuccess(orderId);
        } else if (status == 'pending') {
          // Keep waiting or check API
          _checkPaymentStatusFromApi(orderId);
        } else {
          _handlePaymentFailure();
        }
      }
    }
  }
  
  void _checkPaymentStatusFromApi(String orderId) async {
  if (_hasCompleted) return;
  
  try {
    final String baseUrl = widget.isProduction
        ? 'https://api.midtrans.com/v2/$orderId/status'
        : 'https://api.sandbox.midtrans.com/v2/$orderId/status';

    final response = await http.get(
      Uri.parse(baseUrl),
      headers: {
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Authorization': 'Basic ' + base64Encode(utf8.encode('${widget.serverKey}:')),
      },
    ).timeout(Duration(seconds: 10));

    print('Status check response: ${response.body}');

    if (response.statusCode == 200) {
      final dynamic statusData = json.decode(response.body);
      
      // Check if statusData is a Map first
      if (statusData is Map) {
        final transactionStatus = statusData['transaction_status'] as String?;
        
        if (transactionStatus == 'capture' || 
            transactionStatus == 'settlement' || 
            transactionStatus == 'success') {
          // Convert Map<String, dynamic> to Map<String, Object>
          final Map<String, Object> convertedData = 
              Map<String, Object>.from(statusData as Map<String, dynamic>);
          _handlePaymentSuccess(orderId, convertedData);
        } else if (transactionStatus == 'deny' || 
                  transactionStatus == 'cancel' || 
                  transactionStatus == 'expire') {
          // Convert Map<String, dynamic> to Map<String, Object>
          final Map<String, Object> convertedData = 
              Map<String, Object>.from(statusData as Map<String, dynamic>);
          _handlePaymentFailure(convertedData);
        }
      }
    }
  } catch (e) {
    print('Error checking payment status: $e');
  }
}
  
  void _handlePaymentSuccess(String orderId, [Map<String, Object>? statusData]) {
  if (_hasCompleted) return;
  _hasCompleted = true;
  _checkStatusTimer?.cancel();
  
  // Prepare result data
  final Map<String, Object> result = statusData ?? {
    'status_code': '200',
    'transaction_status': 'success',
    'status_message': 'Payment successful',
    'order_id': orderId,
    'redirect_route': widget.redirectRoute,
  };
  
  // Show enhanced success message with animation
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      title: Row(
        children: [
          Icon(Icons.check_circle, color: Colors.green, size: 28),
          SizedBox(width: 10),
          Text(
            'Payment Successful',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green[700],
              fontSize: 20,
            ),
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Your payment has been processed successfully.',
            style: TextStyle(fontSize: 16),
          ),
          SizedBox(height: 12),
          Text(
            'Order ID: $orderId',
            style: TextStyle(fontSize: 14, color: Colors.grey[700]),
          ),
          SizedBox(height: 20),
          _buildConfetti(),
        ],
      ),
      actions: [
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Return to previous screen with payment result
            Navigator.of(context).pop(result);
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.green,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: Text('CONTINUE', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

// Simple confetti animation widget
Widget _buildConfetti() {
  return Container(
    height: 100,
    width: double.infinity,
    child: Stack(
      children: List.generate(20, (index) {
        return Positioned(
          left: Random().nextDouble() * 250,
          top: Random().nextDouble() * 100,
          child: Icon(
            Icons.star,
            color: Color.fromRGBO(
              Random().nextInt(255),
              Random().nextInt(255),
              Random().nextInt(255),
              0.7,
            ),
            size: 12 + Random().nextInt(8).toDouble(),
          ),
        );
      }),
    ),
  );
}

void _handlePaymentFailure([Map<String, Object>? statusData]) {
  if (_hasCompleted) return;
  _hasCompleted = true;
  _checkStatusTimer?.cancel();
  
  // Prepare result data
  final Map<String, Object> result = statusData ?? {
    'status_code': '400',
    'transaction_status': 'failed',
    'status_message': 'Payment failed or was cancelled',
    'redirect_route': widget.redirectRoute,
  };
  
  // Show enhanced failure message
  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (context) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      title: Row(
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 28),
          SizedBox(width: 10),
          Text(
            'Payment Failed',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.red[700],
            ),
          ),
        ],
      ),
      content: Container(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Your payment could not be processed or was cancelled.',
              style: TextStyle(fontSize: 16),
            ),
            SizedBox(height: 16),
            Text(
              'You can try again or choose a different payment method.',
              style: TextStyle(fontSize: 14, color: Colors.grey[700]),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            Navigator.of(context).pop();
            // Return to previous screen with payment result
            Navigator.of(context).pop(result);
          },
          style: TextButton.styleFrom(
            foregroundColor: Colors.grey[700],
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          child: Text('BACK'),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop();
            _initializePayment(); // Add this method to retry payment
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
            elevation: 2,
          ),
          child: Text('TRY AGAIN', style: TextStyle(fontWeight: FontWeight.bold)),
        ),
      ],
    ),
  );
}

@override
Widget build(BuildContext context) {
  final screenSize = MediaQuery.of(context).size;
  final isSmallScreen = screenSize.width < 360;
  
  return WillPopScope(
    onWillPop: () async {
      // Show confirmation dialog before going back
      final shouldPop = await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          title: Row(
            children: [
              Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
              SizedBox(width: 10),
              Text(
                'Cancel Payment?',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            'If you go back now, your payment will be cancelled.',
            style: TextStyle(fontSize: 16),
          ),
          actions: [
            // Responsive buttons based on screen size
            Wrap(
              alignment: WrapAlignment.end,
              spacing: 8,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(false),
                  style: TextButton.styleFrom(
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: 12,
                    ),
                  ),
                  child: Text('STAY'),
                ),
                ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).pop(true);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    foregroundColor: Colors.white,
                    padding: EdgeInsets.symmetric(
                      horizontal: isSmallScreen ? 12 : 16,
                      vertical: 12,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text('CANCEL PAYMENT', 
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: isSmallScreen ? 12 : 14,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      );
      
      if (shouldPop == true) {
        // Return payment cancelled result
        Navigator.of(context).pop({
          'status_code': '400',
          'transaction_status': 'cancel',
          'status_message': 'Payment cancelled by user',
          'redirect_route': widget.redirectRoute,
        });
      }
      
      return false;
    },
    child: Scaffold(
      appBar: AppBar(
        title: Text('Payment'),
        backgroundColor: Colors.brown,
        leading: IconButton(
          icon: Icon(Icons.close),
          onPressed: () {
            // Show confirmation dialog before closing
            showDialog(
              context: context,
              builder: (context) => AlertDialog(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                title: Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, color: Colors.amber, size: 28),
                    SizedBox(width: 10),
                    Text(
                      'Cancel Payment?',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                content: Text(
                  'If you go back now, your payment will be cancelled.',
                  style: TextStyle(fontSize: 16),
                ),
                actions: [
                  // Responsive buttons based on screen size
                  Wrap(
                    alignment: WrapAlignment.end,
                    spacing: 8,
                    children: [
                      TextButton(
                        onPressed: () => Navigator.of(context).pop(),
                        style: TextButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16, 
                            vertical: 12,
                          ),
                        ),
                        child: Text('STAY'),
                      ),
                      ElevatedButton(
                        onPressed: () {
                          Navigator.of(context).pop();
                          Navigator.of(context).pop({
                            'status_code': '400',
                            'transaction_status': 'cancel',
                            'status_message': 'Payment cancelled by user',
                            'redirect_route': widget.redirectRoute
                          });
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red,
                          foregroundColor: Colors.white,
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 12 : 16,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text('CANCEL PAYMENT', 
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: isSmallScreen ? 12 : 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            );
          },
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (isLoading)
            Container(
              color: Colors.white.withOpacity(0.8),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 60,
                      height: 60,
                      child: CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                        strokeWidth: 3,
                      ),
                    ),
                    SizedBox(height: 24),
                    Text(
                      'Loading payment gateway...',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: Colors.blue[800],
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Please wait while we connect to the secure payment service',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    ),
  );
}

// Fixed method to retry payment
void _initializePayment() {
  setState(() {
    isLoading = true;
    _hasCompleted = false;
  });
  
  // Reset webview and load payment URL again
  _controller.loadRequest(Uri.parse(widget.paymentUrl));
  
  // Get order ID from payment params for status checking
  final transactionDetails = widget.paymentParams['transaction_details'] as Map<String, Object>;
  final orderId = transactionDetails['order_id'] as String;
  
  // Setup status check timer again
  _setupStatusCheck(orderId);
}
}