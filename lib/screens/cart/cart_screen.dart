import 'package:crudify/screens/models/product_model.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/cart_service.dart';
import 'checkout_screen.dart';
import '../product/product_detail_screen.dart';
import '../models/customization_option.dart'; 

class CartScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartService>(context);
    final theme = Theme.of(context);
    
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Your Cart',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.brown,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: Icon(Icons.delete_sweep),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => AlertDialog(
                    title: Text('Empty Cart?',  style: TextStyle(color: Colors.grey)),
                    content: Text('Are you sure you want to remove all items?',  style: TextStyle(color: Colors.brown)),
                    actions: [
                      TextButton(
                        onPressed: () => Navigator.of(ctx).pop(),
                        child: Text('CANCEL'),
                      ),
                      TextButton(
                        onPressed: () {
                          cart.clear();
                          Navigator.of(ctx).pop();
                        },
                        child: Text('YES'),
                        style: TextButton.styleFrom(
                          foregroundColor: theme.colorScheme.error,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
        ],
      ),
      body: cart.items.isEmpty
          ? _buildEmptyCart(context)
          : _buildCart(context, cart, theme),
    );
  }

  Widget _buildEmptyCart(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.shopping_cart_outlined,
              size: 80,
              color: Colors.grey.shade400,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Your cart is empty',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
          ),
          SizedBox(height: 12),
          Text(
            'Looks like you haven\'t added\nanything to your cart yet',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 16,
            ),
          ),
          SizedBox(height: 32),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(context).pop(),
            icon: Icon(Icons.restaurant_menu),
            label: Text('BROWSE MENU', style: TextStyle(color: Colors.brown),),
            style: ElevatedButton.styleFrom( 
              padding: EdgeInsets.symmetric(
                horizontal: 30,
                vertical: 12,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
              elevation: 2,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCart(BuildContext context, CartService cart, ThemeData theme) {
    // Perkiraan pajak 10%
    final double tax = cart.totalAmount * 0.1;
    final double grandTotal = cart.totalAmount + tax;
    
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            padding: EdgeInsets.only(top: 12),
            itemCount: cart.items.length,
            itemBuilder: (ctx, i) {
              final cartItem = cart.items.values.toList()[i];
              return Dismissible(
                key: ValueKey(cartItem.productId),
                background: Container(
                  color: theme.colorScheme.error,
                  alignment: Alignment.centerRight,
                  padding: EdgeInsets.only(right: 20),
                  margin: EdgeInsets.symmetric(horizontal: 15, vertical: 4),
                  child: Icon(
                    Icons.delete,
                    color: Colors.white,
                    size: 30,
                  ),
                ),
                direction: DismissDirection.endToStart,
                confirmDismiss: (direction) {
                  return showDialog(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: Text('Remove Item',  style: TextStyle(color: Colors.brown)),
                      content: Text('Remove ${cartItem.productName} from cart?'),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(false),
                          child: Text('CANCEL'),
                        ),
                        TextButton(
                          onPressed: () => Navigator.of(ctx).pop(true),
                          child: Text('REMOVE'),
                          style: TextButton.styleFrom(
                            foregroundColor: theme.colorScheme.error,
                          ),
                        ),
                      ],
                    ),
                  );
                },
                onDismissed: (direction) {
                  cart.removeItem(cartItem.productId);
                },
                child: InkWell(
                  onTap: () {
                    // Get the product from the cartItem
                    final Product product = Product(
    id: cartItem.productId.split('_')[0], // Extract the original product ID
    name: cartItem.productName,
    description: '', // Default value
    price: cartItem.price,
    imageUrl: cartItem.imageUrl,
    category: '', // Default value
    customizationOptions: {}, // Default empty map
  );
  
  // Navigate to product detail screen with the product and selected customizations
  Navigator.of(context).push(
  MaterialPageRoute(
    builder: (_) => ProductDetailScreen(
      product: product,
      initialCustomizations: cartItem.customizations,
      fromCart: true,
    ),
  ),
);
                  },
                  child: Card(
                    elevation: 2,
                    margin: EdgeInsets.symmetric(horizontal: 15, vertical: 6),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Padding(
                      padding: EdgeInsets.all(8),
                      child: Row(
                        children: [
                          // Product image
                          Container(
                            width: 80,
                            height: 80,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black12,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: Stack(
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(10),
                                  child: Image.network(
                                    cartItem.imageUrl,
                                    fit: BoxFit.cover,
                                    width: double.infinity,
                                    height: double.infinity,
                                    errorBuilder: (ctx, error, _) => Container(
                                      color: Colors.grey.shade300,
                                      child: Icon(Icons.image_not_supported),
                                    ),
                                  ),
                                ),
                                Positioned(
                                  right: 0,
                                  bottom: 0,
                                  child: Container(
                                    padding: EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: theme.primaryColor,
                                      borderRadius: BorderRadius.only(
                                        topLeft: Radius.circular(10),
                                        bottomRight: Radius.circular(10),
                                      ),
                                    ),
                                    child: Icon(
                                      Icons.info_outline,
                                      color: Colors.white,
                                      size: 16,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(width: 16),
                          // Product details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cartItem.productName,
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    color: Colors.brown
                                  ),
                                ),
                                SizedBox(height: 4),
                                Text(
                                  'Rp ${formatRupiah(cartItem.price)}',
                                  style: TextStyle(
                                    color: Colors.brown,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                if (cartItem.customizations != null && 
                                    cartItem.customizations!.isNotEmpty) ...[
                                  SizedBox(height: 4),
                                  Container(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 8, 
                                      vertical: 4
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.grey.shade100,
                                      borderRadius: BorderRadius.circular(6),
                                    ),
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        ...cartItem.customizations!.map((option) => 
                                          Text(
                                            '${option.name}: ${option.value}',
                                            style: TextStyle(fontSize: 12, color: Colors.brown),
                                          )
                                        ).toList(),
                                        if (cartItem.customizationPrice > 0)
                                          Text(
                                            '+Rp ${formatRupiah(cartItem.customizationPrice)}',
                                            style: TextStyle(
                                              fontSize: 12,
                                              color: Colors.brown,
                                            ),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          ),
                          // Quantity controls
                          Column(
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.grey.shade300),
                                  borderRadius: BorderRadius.circular(30),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    InkWell(
                                      onTap: () {
                                        // Perbaikan: Jika quantity = 1, hapus item
                                        if (cartItem.quantity > 1) {
                                          cart.updateQuantity(
                                            cartItem.productId, 
                                            cartItem.quantity - 1
                                          );
                                        } else {
                                          // Hapus item jika quantity = 1
                                          cart.removeItem(cartItem.productId);
                                        }
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.remove,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: EdgeInsets.symmetric(horizontal: 8),
                                      child: Text(
                                        '${cartItem.quantity}',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                          color: Colors.brown
                                        ),
                                      ),
                                    ),
                                    InkWell(
                                      onTap: () {
                                        // Menggunakan updateQuantity untuk tambah quantity
                                        cart.updateQuantity(
                                          cartItem.productId,
                                          cartItem.quantity + 1
                                        );
                                      },
                                      child: Container(
                                        padding: EdgeInsets.all(4),
                                        child: Icon(
                                          Icons.add,
                                          size: 18,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Rp ${formatRupiah(cartItem.totalPrice)}',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        // Order summary card
        Card(
          margin: EdgeInsets.all(0),
          elevation: 8,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.only(
              topLeft: Radius.circular(24),
              topRight: Radius.circular(24),
            ),
          ),
          child: Padding(
            padding: EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Order Summary',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Items (${cart.itemCount})', style: TextStyle(color: Colors.brown)),
                    Text('Rp ${formatRupiah(cart.totalAmount)}', style: TextStyle(color: Colors.brown)),
                  ],
                ),
                // Tambahkan tax
                SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Tax (10%)', style: TextStyle(color: Colors.brown)),
                    Text('Rp ${formatRupiah(tax)}', style: TextStyle(color: Colors.brown)),
                  ],
                ),
                Divider(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown
                      ),
                    ),
                    Text(
                      'Rp ${formatRupiah(grandTotal)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                    ),
                  ],
                ),
                SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => CheckoutScreen(
                            cartItems: cart.cartItems,
                            totalAmount: grandTotal,  
                          ),
                        ),
                      );
                    },
                    child: Text(
                      'PROCEED TO CHECKOUT',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800]
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.symmetric(
                        vertical: 15,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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