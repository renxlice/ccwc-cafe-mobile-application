import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'package:share_plus/share_plus.dart';
import 'package:photo_manager/photo_manager.dart';
import 'dart:io';
import 'package:path_provider/path_provider.dart';
import '../models/order_model.dart';
import '../models/cart_item.dart';


class ReceiptScreen extends StatefulWidget {
  final Order order;
  
  const ReceiptScreen({super.key, required this.order});
  
  @override
  State<ReceiptScreen> createState() => _ReceiptScreenState();
}

class _ReceiptScreenState extends State<ReceiptScreen> {
  final GlobalKey _receiptKey = GlobalKey();
  
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Receipt'),
        backgroundColor: Colors.brown,
        actions: [
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () => _shareReceipt(context),
          ),
          IconButton(
            icon: const Icon(Icons.download),
            onPressed: () => _downloadReceipt(context),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              RepaintBoundary(
                key: _receiptKey,
                child: Card(
                  elevation: 4,
                  color: Colors.white,
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        const Text(
                          'CCWC CAFE APP',
                          style: TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown
                          ),
                        ),
                        
                        const SizedBox(height: 4),
                        
                        Text(
                          'Digital Receipt',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                          ),
                        ),
                        
                        const Divider(height: 30),
                        
                        _buildInfoRow('Order ID:', widget.order.id),
                        _buildInfoRow('Date:', _formatDate(widget.order.orderDate)),
                        _buildInfoRow('Payment Method:', _getPaymentMethodText(widget.order.paymentMethod)),
                        _buildInfoRow('Additional Notes:', widget.order.notes ?? 'No additional notes'),
                        
                        const SizedBox(height: 20),
                        
                        const Divider(),
                        
                        ...widget.order.items.map((item) => _buildItemRow(item)),
                        
                        const Divider(),
                        
                        const SizedBox(height: 10),
                        _buildInfoRow('Subtotal:', 'Rp ${_formatRupiah(calculateSubtotal())}'),
                        _buildInfoRow('Tax:', 'Rp ${_formatRupiah(calculateTax())}'),
                        
                        const SizedBox(height: 10),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'Total',
                              style: TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.grey,
                              ),
                            ),
                            Text(
                              'Rp ${_formatRupiah(calculateTotal())}',
                              style: const TextStyle(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.brown,
                              ),
                            ),
                          ],
                        ),
                        
                        const SizedBox(height: 30),
                        
                        const Text(
                          'Thank you for your order!',
                          style: TextStyle(
                            fontSize: 16,
                            fontStyle: FontStyle.italic,
                            color: Colors.brown,
                          ),
                        ),
                        
                        const SizedBox(height: 10),
                        
                        const Text(
                          'Visit us again soon.',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.brown,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              
              const SizedBox(height: 30),
              
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: widget.order.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Order ID copied to clipboard'),
                      duration: Duration(seconds: 2),
                    ),
                  );
                },
                icon: const Icon(Icons.copy, color: Colors.brown),
                label: const Text('COPY ORDER ID', style: TextStyle(color: Colors.brown),),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _shareReceipt(BuildContext context) async {
    try {
      final box = context.findRenderObject() as RenderBox?;
      final receiptContent = _generateReceiptText();
      
      await Share.share(
        receiptContent,
        subject: 'Order Receipt from CCWC Cafe',
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
      
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to share receipt: ${e.toString()}'),
          duration: const Duration(seconds: 2),
          backgroundColor: Colors.brown,
        ),
      );
    }
  }

  Future<void> _downloadReceipt(BuildContext context) async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Saving receipt to gallery...'),
          backgroundColor: Colors.brown,
          duration: Duration(seconds: 1),
        ),
      );
      
      // Capture the receipt card as an image
      final imageBytes = await _captureReceiptAsImage();
      
      if (imageBytes == null) {
        throw Exception('Failed to capture receipt image');
      }
      
      // Request permission if needed
      final PermissionState permission = await PhotoManager.requestPermissionExtend();
      if (!permission.isAuth) {
        throw Exception('Permission denied to access gallery');
      }
      
      // Save to gallery
      final String fileName = 'CCWC_Receipt_${widget.order.id}.png';
      final result = await PhotoManager.editor.saveImage(
        imageBytes, // Uint8List of the image
        title: fileName, filename: 'CCWC_Receipt_${widget.order.id}.png', 
      );
      
      if (!context.mounted) return;
      
      if (result != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receipt saved to gallery successfully'),
            duration: Duration(seconds: 3),
            backgroundColor: Colors.brown,
          ),
        );
      } else {
        throw Exception('Failed to save to gallery');
      }
    } catch (e) {
      if (!context.mounted) return;
      _showErrorSnackbar(context, 'Failed to save receipt: ${e.toString()}');
    }
  }

  Future<Uint8List?> _captureReceiptAsImage() async {
    try {
      // Find the RenderRepaintBoundary
      RenderRepaintBoundary boundary = _receiptKey.currentContext!
          .findRenderObject() as RenderRepaintBoundary;
      
      // Capture the image with pixel ratio for better quality
      final ui.Image image = await boundary.toImage(pixelRatio: 3.0);
      
      // Convert image to byte data
      final ByteData? byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      
      if (byteData == null) {
        return null;
      }
      
      return byteData.buffer.asUint8List();
    } catch (e) {
      debugPrint('Error capturing receipt image: $e');
      return null;
    }
  }

  void _showErrorSnackbar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  String _generateReceiptText() {
    final buffer = StringBuffer();
    
    buffer.writeln('CCWC CAFE APP');
    buffer.writeln('Digital Receipt\n');
    buffer.writeln('Order ID: ${widget.order.id}');
    buffer.writeln('Date: ${_formatDate(widget.order.orderDate)}');
    buffer.writeln('Payment Method: ${_getPaymentMethodText(widget.order.paymentMethod)}');
    buffer.writeln('Additional Notes: ${widget.order.notes ?? 'No additional notes'}\n');
    
    buffer.writeln('--- Order Items ---');
    for (var item in widget.order.items) {
      buffer.writeln('${item.productName} - ${item.quantity} x Rp ${_formatRupiah(item.price)}');
      buffer.writeln('Total: Rp ${_formatRupiah(item.totalPrice)}');
      
      if (item.customizations != null && item.customizations!.isNotEmpty) {
        buffer.writeln('Customizations:');
        for (var option in item.customizations!) {
          buffer.writeln('  ${option.name}: ${option.value} (Rp ${_formatRupiah(option.price)})');
        }
      }
      buffer.writeln();
    }
    
    buffer.writeln('--- Summary ---');
    buffer.writeln('Subtotal: Rp ${_formatRupiah(calculateSubtotal())}');
    buffer.writeln('Tax (10%): Rp ${_formatRupiah(calculateTax())}');
    buffer.writeln('Total: Rp ${_formatRupiah(calculateTotal())}\n');
    
    buffer.writeln('Thank you for your order!');
    buffer.writeln('Visit us again soon.');
    
    return buffer.toString();
  }
  
  double calculateSubtotal() {
    return widget.order.items.fold(0, (sum, item) => sum + item.totalPrice);
  }
  
  double calculateTax() {
    return calculateSubtotal() * 0.10;  // 10% tax rate
  }
  
  double calculateTotal() {
    return calculateSubtotal() + calculateTax();
  }
  
  Widget _buildInfoRow(String label, String? value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[700],
            ),
          ),
          Text(
            value ?? 'N/A',
            style: const TextStyle(
              fontSize: 14,
              color: Colors.brown
            ),
          ),
        ],
      ),
    );
  }
  
  Widget _buildItemRow(CartItem item) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  item.productName,
                  style: const TextStyle(
                    fontSize: 16,
                    color: Colors.grey,
                  ),
                ),
              ),
              Text(
                'Rp ${_formatRupiah(item.totalPrice)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown,
                ),
              ),
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${item.quantity} x Rp ${_formatRupiah(item.price)}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[700],
                ),
              ),
              if (item.customizationPrice > 0)
                Text(
                  '+ Customization: Rp ${_formatRupiah(item.customizationPrice * item.quantity)}',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.brown,
                  ),
                ),
            ],
          ),
          
          if (item.customizations != null && item.customizations!.isNotEmpty)
            ...item.customizations!.map((option) => Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 2.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${option.name}: ${option.value}',
                    style: TextStyle(fontSize: 13, color: Colors.brown,),
                  ),
                  Text(
                    'Rp ${_formatRupiah(option.price)}',
                    style: TextStyle(fontSize: 13, color: Colors.brown,),
                  ),
                ],
              ),
            )),
        ],
      ),
    );
  }

  String _formatRupiah(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),  
      (Match m) => '${m[1]}.',
    );
  }
  
  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
  }
  
  String _getPaymentMethodText(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return 'Cash/QRIS';
      case PaymentMethod.bank:
        return 'Bank Transfer';
      case PaymentMethod.eWallet:
        return 'E-Wallet';
      case PaymentMethod.qris:
        return 'QRIS';
    }
  }
}