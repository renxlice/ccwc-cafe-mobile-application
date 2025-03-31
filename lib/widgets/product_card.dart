import 'package:crudify/services/cart_service.dart';
import 'package:flutter/material.dart';
import '../screens/models/product_model.dart';
import '../providers/cart_provider.dart';
import 'package:provider/provider.dart';

class ProductCard extends StatelessWidget {
  final Product product;
  final Function()? onTap;
  final Color primaryBrown = Color(0xFF795548);

  ProductCard({required this.product, this.onTap});

  @override
  Widget build(BuildContext context) {
    final cartService = Provider.of<CartService>(context);
    
    return GestureDetector(
      onTap: product.isActive ? onTap : null, // Only allow tap if product is active
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        child: Stack(
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Product Image Section
                Container(
                  height: 120,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    // Apply grayscale filter for inactive products
                    image: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(product.imageUrl!),
                            fit: BoxFit.cover,
                            colorFilter: product.isActive 
                                ? null 
                                : ColorFilter.mode(Colors.grey, BlendMode.saturation),
                          )
                        : null,
                  ),
                  child: product.imageUrl == null || product.imageUrl!.isEmpty
                      ? Icon(Icons.image, size: 48, color: Colors.grey)
                      : null,
                ),
                Padding(
                  padding: EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: product.isActive ? Colors.black : Colors.grey,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Rp ${_formatCurrency(product.price)}',
                        style: TextStyle(
                          color: product.isActive ? primaryBrown : Colors.grey,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            product.category,
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 12,
                            ),
                          ),
                          // Only show add to cart button for active products
                          if (product.isActive)
                            IconButton(
                              icon: Icon(
                                cartService.isInCart(product.id)
                                    ? Icons.shopping_cart
                                    : Icons.add_shopping_cart_outlined,
                                color: primaryBrown,
                              ),
                              onPressed: () {
                                cartService.addToCart(product, 1, []);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('${product.name} added to cart'),
                                    backgroundColor: primaryBrown,
                                    duration: Duration(seconds: 1),
                                  ),
                                );
                              },
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
            // "Out of Stock" overlay for inactive products
            if (!product.isActive)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: Colors.black.withOpacity(0.1),
                  ),
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        'OUT OF STOCK',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  String _formatCurrency(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }
}