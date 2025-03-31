import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../models/customization_option.dart';
import '../../services/cart_service.dart';
import '../auth/authenticate.dart';
import '../cart/cart_screen.dart';
import 'edit_product_screen.dart';
import 'package:flutter/services.dart';

class ProductDetailScreen extends StatefulWidget {
  final Product product;
  final List<CustomizationOption>? initialCustomizations;
  final bool fromCart;

  const ProductDetailScreen({
    Key? key,
    required this.product,
    this.initialCustomizations,
    this.fromCart = false,
  }) : super(key: key);

  @override
  _ProductDetailScreenState createState() => _ProductDetailScreenState();
}

class _ProductDetailScreenState extends State<ProductDetailScreen>
    with SingleTickerProviderStateMixin {
  int _quantity = 1;
  String? _selectedSugarLevel;
  String? _selectedShot;
  String? _selectedTopping;
  String? _selectedSize;
  double _additionalPrice = 0.0;
  bool _isDescriptionExpanded = false;
  ScrollController _scrollController = ScrollController();
  late AnimationController _colorAnimation;
  bool _showAppBarTitle = false;

  @override
  void initState() {
    super.initState();

    _colorAnimation = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 300),
    );

    _scrollController.addListener(() {
      if (_scrollController.offset > 150 && !_showAppBarTitle) {
        setState(() {
          _showAppBarTitle = true;
        });
        _colorAnimation.forward();
      } else if (_scrollController.offset <= 150 && _showAppBarTitle) {
        setState(() {
          _showAppBarTitle = false;
        });
        _colorAnimation.reverse();
      }
    });

    if (widget.initialCustomizations != null &&
        widget.initialCustomizations!.isNotEmpty) {
      // Apply initial customizations if coming from cart
      for (var option in widget.initialCustomizations!) {
        switch (option.name.toLowerCase()) {
          case 'sugar level':
            _selectedSugarLevel = option.value;
            break;
          case 'coffee shot':
            _selectedShot = option.value;
            break;
          case 'topping':
            _selectedTopping = option.value;
            break;
          case 'size':
            _selectedSize = option.value;
            break;
        }
      }
    } else {
      final customOptions = widget.product.customizationOptions;
      if (customOptions != null) {
        // Process each customization group
        customOptions.forEach((groupName, options) {
          if (options is Map) {
            // Handle each group type
            switch (groupName.toLowerCase()) {
              case 'sugar':
                if (options.isNotEmpty) {
                  _selectedSugarLevel = options.keys.first.toString();
                }
                break;
              case 'shot':
                if (options.isNotEmpty) {
                  _selectedShot = options.keys.first.toString();
                }
                break;
              case 'topping':
                if (options.isNotEmpty) {
                  // Try to set "No Topping" as default if available
                  if (options.containsKey('No Topping')) {
                    _selectedTopping = 'No Topping';
                  } else {
                    _selectedTopping = options.keys.first.toString();
                  }
                }
                break;
              case 'size':
                if (options.isNotEmpty) {
                  // Default to small if available
                  if (options.containsKey('Small')) {
                    _selectedSize = 'Small';
                  } else {
                    _selectedSize = options.keys.first.toString();
                  }
                }
                break;
              default:
                print('Found customization group: $groupName with options: $options');
                break;
            }
          }
        });
      }
    }
    
    // Calculate initial additional price
    _calculateAdditionalPrice();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    _colorAnimation.dispose();
    super.dispose();
  }

  void _calculateAdditionalPrice() {
    double additionalPrice = 0.0;
    final customOptions = widget.product.customizationOptions;

    if (customOptions != null) {
      // Add sugar level price
      if (_selectedSugarLevel != null &&
          customOptions.containsKey('sugar') &&
          (customOptions['sugar'] as Map).containsKey(_selectedSugarLevel)) {
        additionalPrice += (customOptions['sugar'] as Map)[_selectedSugarLevel] ?? 0.0;
      }

      // Add shot option price
      if (_selectedShot != null &&
          customOptions.containsKey('shot') &&
          (customOptions['shot'] as Map).containsKey(_selectedShot)) {
        additionalPrice += (customOptions['shot'] as Map)[_selectedShot] ?? 0.0;
      }

      // Add topping price
      if (_selectedTopping != null &&
          customOptions.containsKey('topping') &&
          (customOptions['topping'] as Map).containsKey(_selectedTopping)) {
        additionalPrice += (customOptions['topping'] as Map)[_selectedTopping] ?? 0.0;
      }

      // Add size price
      if (_selectedSize != null &&
          customOptions.containsKey('size') &&
          (customOptions['size'] as Map).containsKey(_selectedSize)) {
        additionalPrice += (customOptions['size'] as Map)[_selectedSize] ?? 0.0;
      }
    }

    setState(() {
      _additionalPrice = additionalPrice;
    });
  }

  List<CustomizationOption> _getSelectedCustomizations() {
    final customizationsList = <CustomizationOption>[];
    final customOptions = widget.product.customizationOptions;

    if (_selectedSugarLevel != null) {
      double price = 0.0;
      if (customOptions != null &&
          customOptions.containsKey('sugar') &&
          (customOptions['sugar'] as Map).containsKey(_selectedSugarLevel)) {
        price = (customOptions['sugar'] as Map)[_selectedSugarLevel] ?? 0.0;
      }
      customizationsList.add(CustomizationOption(
        name: 'Sugar Level',
        value: _selectedSugarLevel!,
        price: price,
      ));
    }

    if (_selectedShot != null) {
      double price = 0.0;
      if (customOptions != null &&
          customOptions.containsKey('shot') &&
          (customOptions['shot'] as Map).containsKey(_selectedShot)) {
        price = (customOptions['shot'] as Map)[_selectedShot] ?? 0.0;
      }
      customizationsList.add(CustomizationOption(
        name: 'Coffee Shot',
        value: _selectedShot!,
        price: price,
      ));
    }

    if (_selectedTopping != null) {
      double price = 0.0;
      if (customOptions != null &&
          customOptions.containsKey('topping') &&
          (customOptions['topping'] as Map).containsKey(_selectedTopping)) {
        price = (customOptions['topping'] as Map)[_selectedTopping] ?? 0.0;
      }
      customizationsList.add(CustomizationOption(
        name: 'Topping',
        value: _selectedTopping!,
        price: price,
      ));
    }

    if (_selectedSize != null) {
      double price = 0.0;
      if (customOptions != null &&
          customOptions.containsKey('size') &&
          (customOptions['size'] as Map).containsKey(_selectedSize)) {
        price = (customOptions['size'] as Map)[_selectedSize] ?? 0.0;
      }
      customizationsList.add(CustomizationOption(
        name: 'Size',
        value: _selectedSize!,
        price: price,
      ));
    }

    return customizationsList;
  }

  Widget _buildOptionSelector(String title, Map<String, dynamic> options, String? selectedValue, Function(String?) onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.brown[800],
          ),
        ),
        SizedBox(height: 12),
        Wrap(
          spacing: 10,
          runSpacing: 12,
          children: options.keys.map((option) {
            final priceAdjustment = options[option] ?? 0.0;
            final displayText = priceAdjustment > 0
                ? '$option (+Rp ${formatRupiah(priceAdjustment)})'
                : option;

            return GestureDetector(
              onTap: () {
                onChanged(option);
                _calculateAdditionalPrice();
              },
              child: AnimatedContainer(
                duration: Duration(milliseconds: 200),
                padding: EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: selectedValue == option
                      ? Colors.brown[600]
                      : Colors.brown[50],
                  borderRadius: BorderRadius.circular(30),
                  boxShadow: selectedValue == option
                      ? [
                          BoxShadow(
                            color: Colors.brown.withOpacity(0.3),
                            blurRadius: 4,
                            offset: Offset(0, 2),
                          )
                        ]
                      : [],
                ),
                child: Text(
                  displayText,
                  style: TextStyle(
                    color: selectedValue == option ? Colors.white : Colors.brown[800],
                    fontWeight: selectedValue == option ? FontWeight.bold : FontWeight.normal,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        SizedBox(height: 20),
      ],
    );
  }

  Widget _buildDescriptionSection() {
  return Container(
    decoration: BoxDecoration(
      color: Colors.brown[50],
      borderRadius: BorderRadius.circular(16),
    ),
    padding: EdgeInsets.all(20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'About this product',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.brown[800],
              ),
            ),
            // Removed the arrow icon completely
          ],
        ),
        SizedBox(height: 12),
        AnimatedContainer(
          duration: Duration(milliseconds: 300),
          height: _isDescriptionExpanded
              ? null
              : (widget.product.description.length > 100 ? 60 : null),
          child: Text(
            widget.product.description,
            style: TextStyle(
              fontSize: 16,
              color: Colors.brown[700],
              height: 1.5,
            ),
            overflow: _isDescriptionExpanded ? TextOverflow.visible : TextOverflow.fade,
          ),
        ),
        if (!_isDescriptionExpanded && widget.product.description.length > 100)
          Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _isDescriptionExpanded = true;
                });
              },
              child: Text(
                'Read more',
                style: TextStyle(
                  color: Colors.brown[600],
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    ),
  );
}

  Widget _buildQuantitySelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Quantity',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.brown[800],
            ),
          ),
          Row(
            children: [
              _buildCircularButton(
                icon: Icons.remove,
                onPressed: _quantity > 1
                    ? () => setState(() => _quantity--)
                    : null,
              ),
              Container(
                margin: EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  _quantity.toString(),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              _buildCircularButton(
                icon: Icons.add,
                onPressed: () => setState(() => _quantity++),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularButton({
    required IconData icon,
    required VoidCallback? onPressed,
  }) {
    return Material(
      color: onPressed == null ? Colors.grey[300] : Colors.brown[600],
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
          ),
          child: Icon(
            icon,
            size: 18,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  Widget _buildPriceBreakdown() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.brown[50],
        borderRadius: BorderRadius.circular(16),
      ),
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Price Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.brown[800],
            ),
          ),
          SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Base Price:',
                style: TextStyle(color: Colors.brown[700]),
              ),
              Text(
                'Rp ${formatRupiah(widget.product.price)} × $_quantity',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          if (_additionalPrice > 0) ...[
            SizedBox(height: 10),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Customization:',
                  style: TextStyle(color: Colors.brown[700]),
                ),
                Text(
                  'Rp ${formatRupiah(_additionalPrice)} × $_quantity',
                  style: TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ],
          SizedBox(height: 10),
          Divider(color: Colors.brown[200]),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Subtotal:',
                style: TextStyle(color: Colors.brown[700]),
              ),
              Text(
                'Rp ${formatRupiah((widget.product.price + _additionalPrice) * _quantity)}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Tax (10%):',
                style: TextStyle(color: Colors.brown[700]),
              ),
              Text(
                'Rp ${formatRupiah(((widget.product.price + _additionalPrice) * _quantity) * 0.1)}',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            ],
          ),
          SizedBox(height: 10),
          Divider(color: Colors.brown[200]),
          SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Total Price:',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
              Text(
                'Rp ${formatRupiah(((widget.product.price + _additionalPrice) * _quantity) * 1.1)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.brown[800],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    final cart = Provider.of<CartService>(context);
    final customOptions = widget.product.customizationOptions;
    final hasCustomOptions = customOptions != null && customOptions.isNotEmpty;
    
    bool isAdmin = user != null && (FirebaseAuth.instance.currentUser?.email == 'admin@cafe.com');
    
    final statusBarHeight = MediaQuery.of(context).padding.top;

    return Scaffold(
      backgroundColor: Colors.white,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        elevation: _showAppBarTitle ? 2 : 0,
        backgroundColor: _showAppBarTitle ? Colors.white : Colors.transparent,
        foregroundColor: _showAppBarTitle ? Colors.brown[800] : Colors.white,
        title: AnimatedOpacity(
          opacity: _showAppBarTitle ? 1.0 : 0.0,
          duration: Duration(milliseconds: 250),
          child: Text(
            widget.product.name,
            style: TextStyle(
              color: Colors.brown[800],
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios,
            color: _showAppBarTitle ? Colors.brown[800] : Colors.white,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          if (isAdmin)
            IconButton(
              icon: Icon(
                Icons.edit,
                color: _showAppBarTitle ? Colors.brown[800] : Colors.white,
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => EditProductScreen(product: widget.product),
                  ),
                );
              },
            ),
        ],
        systemOverlayStyle: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: _showAppBarTitle ? Brightness.dark : Brightness.light,
        ),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              spreadRadius: 1,
              blurRadius: 10,
              offset: Offset(0, -4),
            ),
          ],
        ),
        padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: user != null
                ? () {
                    final cartService = Provider.of<CartService>(context, listen: false);
                    
                    if (widget.fromCart) {
                      cartService.updateCartItem(
                        widget.product.id,
                        _quantity,
                        _getSelectedCustomizations(),
                      );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${widget.product.name} updated in cart'),
                          backgroundColor: Colors.brown[600],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: EdgeInsets.all(10),
                        ),
                      );
                      
                      Navigator.of(context).pop();
                    } else {
                      cartService.addToCart(
                        widget.product,
                        _quantity,
                        _getSelectedCustomizations(),
                      );
                      
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${widget.product.name} added to cart'),
                          backgroundColor: Colors.brown[600],
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          margin: EdgeInsets.all(10),
                          action: SnackBarAction(
                            label: 'VIEW CART',
                            textColor: Colors.white,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (context) => CartScreen()),
                              );
                            },
                          ),
                        ),
                      );
                      
                      // Add haptic feedback
                      HapticFeedback.mediumImpact();
                    }
                  }
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => Authenticate()),
                    );
                  },
            style: ElevatedButton.styleFrom(
              padding: EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              backgroundColor: Colors.brown[700],
              elevation: 0,
            ),
            child: Text(
              user != null
                  ? (widget.fromCart ? 'UPDATE CART' : 'ADD TO CART')
                  : 'LOGIN TO CONTINUE',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
      body: CustomScrollView(
        controller: _scrollController,
        physics: BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Stack(
              children: [
                // Product Image with Gradient Overlay
                Container(
                  height: 350,
                  decoration: BoxDecoration(
                    image: DecorationImage(
                      image: NetworkImage(widget.product.imageUrl),
                      fit: BoxFit.cover,
                    ),
                  ),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withOpacity(0.3),
                          Colors.black.withOpacity(0.5),
                        ],
                      ),
                    ),
                  ),
                ),
                // Positioned Product Info
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    padding: EdgeInsets.only(top: 30, left: 20, right: 20, bottom: 20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    widget.product.name,
                                    style: TextStyle(
                                      fontSize: 26,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.brown[900],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.brown[50],
                                borderRadius: BorderRadius.circular(16),
                                border: Border.all(
                                  color: Colors.brown[100]!,
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                'Rp ${formatRupiah(widget.product.price)}',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[700],
                                ),
                              ),
                            ),
                          ],
                        ),
                        SizedBox(height: 20),
                        _buildDescriptionSection(),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(height: 16),
                  
                  if (hasCustomOptions) ...[
                    Text(
                      'Customize Your Order',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown[800],
                      ),
                    ),
                    SizedBox(height: 20),
                    
                    // Sugar level options
                    if (customOptions!.containsKey('sugar') && (customOptions['sugar'] as Map).isNotEmpty)
                      _buildOptionSelector(
                        'Sugar Level',
                        customOptions['sugar'] as Map<String, dynamic>,
                        _selectedSugarLevel,
                        (value) => setState(() => _selectedSugarLevel = value),
                      ),
                    
                    // Shot options for coffee
                    if (customOptions.containsKey('shot') && (customOptions['shot'] as Map).isNotEmpty)
                      _buildOptionSelector(
                        'Coffee Shot',
                        customOptions['shot'] as Map<String, dynamic>,
                        _selectedShot,
                        (value) => setState(() => _selectedShot = value),
                      ),
                    
                    // Topping options
                    if (customOptions.containsKey('topping') && (customOptions['topping'] as Map).isNotEmpty)
                      _buildOptionSelector(
                        'Topping',
                        customOptions['topping'] as Map<String, dynamic>,
                        _selectedTopping,
                        (value) => setState(() => _selectedTopping = value),
                      ),
                    
                    // Size options
                    if (customOptions.containsKey('size') && (customOptions['size'] as Map).isNotEmpty)
                      _buildOptionSelector(
                        'Size',
                        customOptions['size'] as Map<String, dynamic>,
                        _selectedSize,
                        (value) => setState(() => _selectedSize = value),
                      ),
                    
                    SizedBox(height: 16),
                  ],
                  
                  SizedBox(height: 16),
                  
                  // Quantity selector
                  _buildQuantitySelector(),
                  
                  SizedBox(height: 24),
                  
                  // Price breakdown
                  _buildPriceBreakdown(),
                  
                  SizedBox(height: 100), // Add extra space at the bottom for the fixed button
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String formatRupiah(double amount) {
    return amount.toStringAsFixed(0).replaceAllMapped(
      RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
      (Match m) => '${m[1]}.',
    );
  }
}