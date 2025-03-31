import 'package:crudify/screens/cart/order_process_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../models/user_model.dart';
import '../../services/product_service.dart';
import '../../services/auth_service.dart';
import '../../services/cart_service.dart';
import 'product_detail_screen.dart';
import '../cart/cart_screen.dart';
import '../auth/authenticate.dart';
import '../home/home.dart';
import 'loyalty_screen.dart'; 

class MainScreen extends StatefulWidget {
  final int initialIndex;

  const MainScreen({Key? key, this.initialIndex = 0}) : super(key: key);

  @override
  _MainScreenState createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  late int _selectedIndex;
  late List<Widget> _pages;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pages = [
      ProductListScreen(useBottomButton: false),
      OrderProcessScreen(), 
      LoyaltyScreen(),
      Home(),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();

    // Check if user is logged in when trying to access protected pages
    if (user == null && (_selectedIndex == 1 || _selectedIndex == 2)) {
      // Using a microtask to ensure the frame is completed before showing the dialog
      Future.microtask(() {
        if (mounted) {
          _showAuthRequiredDialog();
          setState(() {
            _selectedIndex = 0; // Reset to Menu tab
          });
        }
      });
    }

    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: buildBottomNavigation(context),
    );
  }

 Widget buildBottomNavigation(BuildContext context) {
  final user = context.watch<UserModel?>();
  CartService? cart;
  try {
    cart = Provider.of<CartService>(context);
  } catch (e) {
    cart = null;
  }
  final cartCount = cart?.itemCount ?? 0;

  return Container(
    padding: EdgeInsets.symmetric(vertical: 8, horizontal: 8), 
    decoration: BoxDecoration(
      color: Colors.white,
      boxShadow: [
        BoxShadow(
          color: Colors.black12,
          blurRadius: 8, 
          spreadRadius: 1, 
        ),
      ],
    ),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        buildNavButton(
          icon: Icons.restaurant_menu,
          label: 'Menu',
          isSelected: _selectedIndex == 0,
          onTap: () {
            setState(() {
              _selectedIndex = 0;
            });
          },
        ),
        
        buildNavButton(
          icon: Icons.receipt_long,
          label: 'Orders',
          isSelected: _selectedIndex == 1,
          badge: cartCount,
          onTap: () {
            if (user == null) {
              _showAuthRequiredDialog();
            } else {
              setState(() {
                _selectedIndex = 1;
              });
            }
          },
        ),
        
        buildNavButton(
          icon: Icons.loyalty,
          label: 'Loyalty',
          isSelected: _selectedIndex == 2,
          onTap: () {
            if (user == null) {
              _showAuthRequiredDialog();
            } else {
              setState(() {
                _selectedIndex = 2;
              });
            }
          },
        ),
        
        buildNavButton(
          icon: user == null ? Icons.login : Icons.person,
          label: user == null ? 'Login' : 'Profile',
          isSelected: _selectedIndex == 3,
          onTap: () {
            if (user == null) {
              _showAuthRequiredDialog();
            } else {
              setState(() {
                _selectedIndex = 3;
              });
            }
          },
        ),
      ],
    ),
  );
}

  Widget buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    final Color selectedColor = Colors.brown;
    final Color unselectedColor = Colors.grey;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? selectedColor : unselectedColor,
                  size: 24,
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 4),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAuthRequiredDialog() {
  if (!mounted) return;
 }
}

class ProductListScreen extends StatefulWidget {
  final bool useBottomButton;
  final String? category;

  const ProductListScreen({
    Key? key, 
    this.useBottomButton = true,
    this.category,
  }) : super(key: key);

  @override
  _ProductListScreenState createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  final ProductService _productService = ProductService();
  String _selectedCategory = 'All';
  final List<String> _categories = ['All', 'Beverages', 'Pastries', 'Meals', 'Desserts'];
  final Color primaryBrown = Color(0xFF795548);

  final List<Color> _categoryColors = [
    Colors.blueAccent,      // All
    Colors.brown,           // Beverages
    Colors.pink,            // Pastries
    Colors.orange,          // Meals
    Colors.purple,          // Desserts
  ];

  bool _isSearching = false;
  bool _shouldShowLoyaltyDialog = false;
  bool _dialogHasBeenShown = false;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  final FocusNode _searchFocusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    if (widget.category != null) {
      _selectedCategory = widget.category!;
    }
  }

  @override
  void dispose() {
    _searchFocusNode.dispose();
    _searchController.dispose();
    super.dispose();
  }

  
  UserModel? _previousUser;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final user = Provider.of<UserModel?>(context);
    
    if (user != null && !_dialogHasBeenShown) {
      _shouldShowLoyaltyDialog = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<UserModel?>();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_shouldShowLoyaltyDialog && !_dialogHasBeenShown && mounted) {
        _dialogHasBeenShown = true;
        _shouldShowLoyaltyDialog = false;
        _showLoyaltyInfoDialog();
      }
    });

    CartService? cart;
    try {
      cart = Provider.of<CartService>(context);
    } catch (e) {
      cart = null;
    }
    final cartCount = cart?.itemCount ?? 0;

    return Scaffold(
  appBar: AppBar(
    toolbarHeight: 50,
    title: _isSearching
        ? Container(
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Center(
              child: TextField(
                controller: _searchController,
                focusNode: _searchFocusNode,
                decoration: InputDecoration(
                  prefixIcon: Icon(Icons.search, color: Colors.grey),
                  hintText: 'Search products...',
                  border: InputBorder.none,
                  hintStyle: TextStyle(color: Colors.grey),
                  contentPadding: EdgeInsets.symmetric(vertical: 10),
                ),
                style: TextStyle(color: Colors.black),
                onChanged: _filterProducts,
              ),
            ),
          )
        : Text('CCWC Cafe', style: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: Colors.black,
          )),
    automaticallyImplyLeading: false,
    actions: [
      AnimatedSwitcher(
        duration: Duration(milliseconds: 300),
        child: _isSearching
            ? IconButton(
                icon: Icon(Icons.clear, color: Colors.black),
                onPressed: () {
                  setState(() {
                    _searchController.clear();
                    _filteredProducts.clear();
                    _isSearching = false;
                  });
                },
              )
            : Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.search, color: Colors.black),
                    onPressed: () {
                      setState(() {
                        _isSearching = true;
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          if (_searchFocusNode.canRequestFocus) {
                            _searchFocusNode.requestFocus();
                          }
                        });
                      });
                    },
                  ),
                  IconButton(
                    icon: Stack(
                      alignment: Alignment.center,
                      children: [
                        Icon(Icons.shopping_cart, color: Colors.black),
                        if (cartCount > 0)
                          Positioned(
                            right: 0,
                            top: 0,
                            child: Container(
                              padding: EdgeInsets.all(1),
                              decoration: BoxDecoration(
                                color: Colors.red,
                                borderRadius: BorderRadius.circular(10),
                              ),
                              constraints: BoxConstraints(
                                minWidth: 16,
                                minHeight: 16,
                              ),
                              child: Text(
                                '$cartCount',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 10,
                                ),
                                textAlign: TextAlign.center,
                              ),
                            ),
                          ),
                      ],
                    ),
                    onPressed: () {
                      if (user == null) {
                        showDialog(
                          context: context,
                          builder: (ctx) => AlertDialog(
                            title: Text('Authentication Required', style: TextStyle(color: Colors.brown),),
                            content: Text('You need to login first to view your cart.', style: TextStyle(color: Colors.grey),),
                            actions: [
                              TextButton(
                                onPressed: () => Navigator.of(ctx).pop(),
                                child: Text('CANCEL', style: TextStyle(color: Colors.grey),),
                              ),
                              ElevatedButton(
                                onPressed: () {
                                  Navigator.of(ctx).pop();
                                  Navigator.of(context).push(
                                    MaterialPageRoute(builder: (_) => Authenticate())
                                  );
                                },
                                child: Text('LOGIN', style: TextStyle(color: Colors.brown),),
                              ),
                            ],
                          ),
                        );
                      } else {
                        Navigator.of(context).push(
                          MaterialPageRoute(builder: (_) => CartScreen())
                        );
                      }
                    },
                  ),
                ],
              ),
      ),
    ],
    backgroundColor: primaryBrown,
    elevation: 0,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        bottom: Radius.circular(15),
      ),
    ),
  ),
  body: Column(
    children: [
      // Category selector
      Container(
        height: 48,
        margin: EdgeInsets.symmetric(vertical: 4),
        child: ListView.builder(
          scrollDirection: Axis.horizontal,
          itemCount: _categories.length,
          itemBuilder: (ctx, i) => Padding(
            padding: EdgeInsets.symmetric(horizontal: 4),
            child: ChoiceChip(
              label: Text(
                _categories[i],
                style: TextStyle(
                  fontSize: 12,
                  color: _selectedCategory == _categories[i] 
                      ? Colors.white 
                      : Colors.black,
                  fontWeight: FontWeight.w500,
                ),
              ),
              selected: _selectedCategory == _categories[i],
              selectedColor: _categoryColors[i], 
              backgroundColor: Colors.grey[200], 
              onSelected: (selected) {
                setState(() {
                  _selectedCategory = _categories[i];
                  if (_isSearching) {
                    _filterProducts(_searchController.text);
                  }
                });
              },
            ),
          ),
        ),
      ),

      // Search results indicator
      if (_isSearching && _searchController.text.isNotEmpty)
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Text(
                'Search results for "${_searchController.text}"',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
              Spacer(),
              Text(
                '${_filteredProducts.length} items found',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),

      // Products grid
      Expanded(
        child: _isSearching && _searchController.text.isNotEmpty
            ? _filteredProducts.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 50, color: Colors.grey),
                        SizedBox(height: 16),
                        Text(
                          'No products found',
                          style: TextStyle(
                            fontSize: 18,
                            color: Colors.grey,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Try different keywords',
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  )
                : _buildFilteredProductsGrid()
            : _buildProductsGrid(),
      ),
    ],
  ),
  bottomNavigationBar: widget.useBottomButton ? _buildBottomNavigation() : null,
);
  }

  Widget _buildBottomNavigation() {
    final user = context.watch<UserModel?>();
    CartService? cart;
    try {
      cart = Provider.of<CartService>(context);
    } catch (e) {
      cart = null;
    }
    final cartCount = cart?.itemCount ?? 0;

    return Container(
  padding: EdgeInsets.symmetric(vertical: 8, horizontal: 16), 
  decoration: BoxDecoration(
    color: Colors.white,
    boxShadow: [
      BoxShadow(
        color: Colors.black12,
        blurRadius: 8, 
        spreadRadius: 1, 
      ),
    ],
  ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavButton(
            icon: Icons.restaurant_menu,
            label: 'Menu',
            isSelected: true,
            onTap: () {
            },
          ),
          
          // Order Button
          _buildNavButton(
            icon: Icons.receipt_long,
            label: 'Orders',
            isSelected: false,
            badge: cartCount,
            onTap: () {
              if (user == null) {
                _showAuthRequiredDialog();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MainScreen(initialIndex: 1))
                );
              }
            },
          ),

          _buildNavButton(
          icon: Icons.loyalty,
          label: 'Loyalty',
          isSelected: false,
          onTap: () {
            if (user == null) {
              _showAuthRequiredDialog();
            } else {
              Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MainScreen(initialIndex: 2))
                );
            }
          },
        ),
          
          // Profile/Login Button
          _buildNavButton(
            icon: user == null ? Icons.login : Icons.person,
            label: user == null ? 'Login' : 'Profile',
            isSelected: false,
            onTap: () {
              if (user == null) {
                _showAuthRequiredDialog();
              } else {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => MainScreen(initialIndex: 3))
                );
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildNavButton({
    required IconData icon,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
    int badge = 0,
  }) {
    final Color selectedColor = Colors.brown;
    final Color unselectedColor = Colors.grey;
    
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: isSelected ? selectedColor.withOpacity(0.1) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(
                  icon,
                  color: isSelected ? selectedColor : unselectedColor,
                  size: 22,
                ),
                if (badge > 0)
                  Positioned(
                    right: -8,
                    top: -8,
                    child: Container(
                      padding: EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: BoxConstraints(
                        minWidth: 16,
                        minHeight: 16,
                      ),
                      child: Text(
                        '$badge',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
              ],
            ),
            SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                color: isSelected ? selectedColor : unselectedColor,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                fontSize: 10,
              ),
            ),
          ],
        ),
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

  void _showAuthRequiredDialog() {
  if (!mounted) return;
  
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Authentication Required', style: TextStyle(color: Colors.brown),),
      content: Text('You need to login first to view your orders, loyalty, and profile.', style: TextStyle(color: Colors.grey),),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text('CANCEL', style: TextStyle(color: Colors.grey),),
        ),
        ElevatedButton(
          onPressed: () {
            Navigator.of(ctx).pop();
            if (mounted) {
              Navigator.of(context).pushAndRemoveUntil(
                MaterialPageRoute(builder: (context) => Authenticate()),
                (route) => false
              );
            }
          },
          child: Text('LOGIN', style: TextStyle(color: Colors.brown),),
        ),
      ],
    ),
  );
}

void _showLoyaltyInfoDialog() {
  if (!mounted) return;
  
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      backgroundColor: Colors.white,
      title: Column(
        children: [
          Icon(Icons.loyalty, size: 40, color: Colors.amber[700]),
          SizedBox(height: 10),
          Text(
            'Earn Loyalty Points!',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.brown,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Every order you make will earn you loyalty points that can be redeemed for rewards!',
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[800],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 15),
          Container(
            padding: EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.amber[50],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                Icon(Icons.info_outline, color: Colors.amber[700]),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '1 point for every Rp10,000 spent',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.amber[900],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(
            'GOT IT!',
            style: TextStyle(
              color: Colors.brown,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ),
      ],
    ),
  );
}

  void _filterProducts(String query) {
    if (query.isEmpty) {
      setState(() {
        _filteredProducts.clear();
      });
      return;
    }

     _productService.products.listen((products) {
    if (mounted) {
      setState(() {
        _filteredProducts = products.where((product) {
          final nameMatch = product.name.toLowerCase().contains(query.toLowerCase());
          final categoryMatch = _selectedCategory == 'All' || product.category == _selectedCategory;
          return nameMatch && categoryMatch;
        }).toList();
      });
    }
  });
}

  Widget _buildFilteredProductsGrid() {
    if (_filteredProducts.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off, size: 64, color: Colors.grey.shade300),
            SizedBox(height: 16),
            Text(
              'No products found.',
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
          ],
        ),
      );
    }

    return GridView.builder(
      padding: EdgeInsets.all(16),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
      ),
      itemCount: _filteredProducts.length,
      itemBuilder: (ctx, i) => _buildProductItem(_filteredProducts[i]),
    );
  }

  Widget _buildProductsGrid() {
    return StreamBuilder<List<Product>>(
      stream: _selectedCategory == 'All'
          ? _productService.products
          : _productService.getProductsByCategory(_selectedCategory),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryBrown));
        }

        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: Colors.grey.shade300),
                SizedBox(height: 16),
                Text(
                  'No products available.',
                  style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
                ),
              ],
            ),
          );
        }

        final products = snapshot.data!;

        return RefreshIndicator(
          onRefresh: () async {
            setState(() {});
          },
          color: primaryBrown,
          child: GridView.builder(
            padding: EdgeInsets.all(16),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: products.length,
            itemBuilder: (ctx, i) => _buildProductItem(products[i]),
          ),
        );
      },
    );
  }

  Widget _buildProductItem(Product product) {
    CartService? cart;
    try {
      cart = Provider.of<CartService>(context, listen: false);
    } catch (e) {
      cart = null;
    }

    // Determine opacity based on product status
    final double opacity = product.isActive ? 1.0 : 0.6;

    return GestureDetector(
      onTap: () {
        if (product.isActive) {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (ctx) => ProductDetailScreen(product: product),
            ),
          );
        } else {
          // Show a message for inactive products
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('This product is currently unavailable'),
              duration: Duration(seconds: 2), backgroundColor: primaryBrown,
            ),
          );
        }
      },
      child: Opacity(
        opacity: opacity,
        child: Card(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Product image
              Expanded(
                child: Stack(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                      child: product.imageUrl.isNotEmpty
                          ? Image.network(
                              product.imageUrl,
                              width: double.infinity,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey[300],
                                  child: Icon(
                                    Icons.broken_image,
                                    size: 50,
                                    color: Colors.grey[600],
                                  ),
                                );
                              },
                            )
                          : Container(
                              color: Colors.grey[300],
                              child: Icon(
                                Icons.image,
                                size: 50,
                                color: Colors.grey[600],
                              ),
                            ),
                    ),
                    if (!product.isActive)
                      Positioned.fill(
                        child: Container(
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.3),
                            borderRadius: BorderRadius.vertical(top: Radius.circular(15)),
                          ),
                          child: Container(
                            padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              'Out Of Stock',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Product details
              Padding(
                padding: EdgeInsets.all(10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: Colors.brown,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 2),
                    Text(
                      product.description,
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey[600],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          ('Rp ${formatRupiah(product.price)}'),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: Colors.brown,
                          ),
                        ),
                        SizedBox(
                          width: MediaQuery.of(context).size.width * 0.15,
                          child: IconButton(
                            icon: Icon(
                              Icons.add_shopping_cart,
                              color: product.isActive ? Colors.brown : Colors.grey,
                            ),
                            onPressed: product.isActive ? () {
                              final user = Provider.of<UserModel?>(context, listen: false);
                              if (user == null) {
                                showDialog(
                                  context: context,
                                  builder: (ctx) => AlertDialog(
                                    title: Text('Authentication Required', style: TextStyle(color: Colors.brown),),
                                    content: Text('You need to login first to add items to cart.', style: TextStyle(color: Colors.grey),),
                                    actions: [
                                      TextButton(
                                        onPressed: () => Navigator.of(ctx).pop(),
                                        child: Text('CANCEL', style: TextStyle(color: Colors.grey),),
                                      ),
                                      ElevatedButton(
                                        onPressed: () {
                                          Navigator.of(ctx).pop();
                                          Navigator.of(context).push(
                                            MaterialPageRoute(builder: (_) => Authenticate())
                                          );
                                        },
                                        child: Text('LOGIN', style: TextStyle(color: Colors.brown),),
                                      ),
                                    ],
                                  ),
                                );
                              } else if (cart == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Cart service is not available'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    margin: EdgeInsets.only(
                                      bottom: MediaQuery.of(context).size.height - 320,
                                      left: 20,
                                      right: 20,
                                    ),
                                    backgroundColor: Colors.brown,
                                  ),
                                );
                              } else {
                                cart.addItem(product, 1);
                                ScaffoldMessenger.of(context).hideCurrentSnackBar();
                                ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('${product.name} added to cart'),
                                  duration: Duration(seconds: 1),  
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
                              }
                            } : null,
                          ),
                        ),
                      ],
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
}