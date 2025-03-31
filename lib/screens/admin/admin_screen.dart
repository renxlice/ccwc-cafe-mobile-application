import 'dart:io';
import 'package:crudify/screens/admin/admin_loyalty_screen.dart';
import 'package:firebase_auth/firebase_auth.dart'; 
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../models/product_model.dart';
import '../../services/product_service.dart';
import '../../services/order_service.dart';
import '../models/order_model.dart'; 
import '../product/add_product_screen.dart';
import '../product/edit_product_screen.dart';
import '../product/product_list_screen.dart';
import '../../services/loyalty_service.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/services.dart';
import '../models/loyalty_reward.dart';
import '../admin/admin_redemption_screen.dart';
import 'package:image_picker/image_picker.dart';

class AdminScreen extends StatefulWidget {
  @override
  _AdminScreenState createState() => _AdminScreenState();
}

class _AdminScreenState extends State<AdminScreen> with SingleTickerProviderStateMixin {
  final ProductService _productService = ProductService();
  final OrderService _orderService = OrderService();
  late TabController _tabController;
  late ScrollController _orderScrollController;
  final TextEditingController _searchController = TextEditingController();
  
  // Brown theme colors
  final Color primaryBrown = Color(0xFF795548);
  final Color lightBrown = Color(0xFFD7CCC8);
  
  final Set<String> _selectedOrderIds = {};
  bool _selectMode = false;
  OrderStatus? _selectedOrderStatus;
  String _searchQuery = '';
  bool _isSearching = false;
  
  final AudioPlayer _audioPlayer = AudioPlayer();
  Stream<List<Order>>? _previousOrdersStream;
  int _previousOrderCount = 0;
  bool _isFirstLoad = true;
  bool _isAudioReady = false;
  String? _audioUrl;
  
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _orderScrollController = ScrollController();
    _tabController.addListener(() {
      setState(() {
        if (_tabController.index != 1) {
          _selectedOrderIds.clear();
          _selectMode = false;
        }
      });
    });
    
    _preloadAudio();
    _initAudioPlayer();
    _initOrderNotifications();
  }

  Future<void> _preloadAudio() async {
    try {
      
      final audioPath = 'assets/sounds/ding-sound-effect_2.mp3';
      final bytes = await rootBundle.load(audioPath);
      
      
      _audioUrl = audioPath;
      _isAudioReady = true;
      
      
      await _audioPlayer.setVolume(1.5);
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      
      if (kIsWeb) {
        await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      }
    } catch (e) {
      debugPrint('Audio preload error: $e');
      _isAudioReady = false;
    }
  }
  
  Future<void> _initAudioPlayer() async {
    try {
      
      await _audioPlayer.setReleaseMode(ReleaseMode.release);
      await _audioPlayer.setVolume(1.0); 
      await _audioPlayer.setPlaybackRate(1.0); 
      
      if (kIsWeb) {
        await _audioPlayer.setPlayerMode(PlayerMode.lowLatency);
      }
    } catch (e) {
      debugPrint('Audio player initialization error: $e');
    }
  }
  
  void _initOrderNotifications() {
    _previousOrdersStream?.drain();
    
    _previousOrdersStream = _orderService.getAllOrders();
    
    _previousOrdersStream?.listen((orders) async {
      if (_isFirstLoad) {
        _previousOrderCount = orders.length;
        _isFirstLoad = false;
        return;
      }
      
      if (orders.length > _previousOrderCount) {
        final newOrdersCount = orders.length - _previousOrderCount;
        _previousOrderCount = orders.length;
        
        if (mounted) {
          
          await _playNewOrderSound();
          
          WidgetsBinding.instance.addPostFrameCallback((_) {
            _showNewOrderNotification(newOrdersCount);
          });
        }
      } else {
        _previousOrderCount = orders.length;
      }
    }, onError: (error) {
      debugPrint('Order stream error: $error');
    });
  }


void _showNewOrderNotification(int newOrdersCount) {
    if (!mounted) return;
    
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'New order${newOrdersCount > 1 ? 's' : ''} received! ($newOrdersCount new)',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        backgroundColor: primaryBrown,
        duration: Duration(seconds: 5),
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.all(10),
        elevation: 6,
        action: SnackBarAction(
          label: 'VIEW',
          textColor: Colors.white,
          onPressed: () {
            if (_tabController.index != 1) {
              _tabController.animateTo(1);
            }
          },
        ),
      ),
    );
  }
  
  Future<void> _playNewOrderSound() async {
    if (!_isAudioReady || _audioUrl == null) {
      debugPrint('Audio not ready, trying fallback');
      await _playFallbackSound();
      return;
    }

    try {
      
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource(_audioUrl!));
      debugPrint('Played notification sound');
    } catch (e) {
      debugPrint('Playback failed: $e');
      await _playFallbackSound();
    }
  }

  Future<void> _playFallbackSound() async {
    try {

      await _audioPlayer.play(AssetSource('sounds/ding-sound-effect_2.mp3'));
    } catch (e) {
      debugPrint('Asset playback failed: $e');
      
      try {
        await SystemSound.play(SystemSoundType.alert);
      } catch (e2) {
        debugPrint('System sound failed: $e2');
      }
    }
  }

  void _navigateToLoyaltyScreen() {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => const AdminLoyaltyScreen(),
    ),
  );
}

  
  @override
void dispose() {
  _audioPlayer.dispose();
  _tabController.dispose();
  _orderScrollController.dispose();
  _searchController.dispose();
  _previousOrdersStream?.drain();
  super.dispose();
}
  
  void _performSearch() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
      _isSearching = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Theme(
      data: ThemeData(
        primaryColor: primaryBrown,
        floatingActionButtonTheme: FloatingActionButtonThemeData(
          backgroundColor: primaryBrown,
        ),
        tabBarTheme: TabBarTheme(
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
        ),
      ),
      child: Scaffold(
        appBar: AppBar(
          title: Text(
            _tabController.index == 0 
              ? 'Product Management' 
              : _tabController.index == 1
                ? (_selectMode ? '${_selectedOrderIds.length} Selected' : 'Order Management')
              : _tabController.index == 2
                ? 'Loyalty Management'
                : 'Verify Redemption',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          elevation: 0,
          backgroundColor: primaryBrown,
          actions: [
            if (_tabController.index == 1 && _selectMode)
              IconButton(
                icon: Icon(Icons.select_all, color: Colors.white),
                tooltip: 'Select All',
                onPressed: () async {
                  final orders = await _orderService.getAllOrdersOnce();
                  setState(() {
                    if (_selectedOrderIds.length == orders.length) {
                      _selectedOrderIds.clear();
                    } else {
                      _selectedOrderIds.clear();
                      _selectedOrderIds.addAll(orders.map((order) => order.id));
                    }
                    if (_orderScrollController.hasClients) {
                      _orderScrollController.animateTo(
                        0.0,
                        duration: Duration(milliseconds: 500),
                        curve: Curves.easeInOut,
                      );
                    }
                  });
                },
              ),
            IconButton(
              icon: Icon(Icons.logout, color: Colors.white),
              onPressed: () async {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Logging out...'),
                    backgroundColor: primaryBrown,
                  ),
                );
                
                try {
                  await FirebaseAuth.instance.signOut();
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (context) => const ProductListScreen()),
                    (route) => false,
                  );
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error logging out: ${e.toString()}')),
                  );
                }
              },
            ),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: Colors.white,
            tabs: [
              Tab(
                icon: Icon(Icons.shopping_bag, color: Colors.white),
                text: 'Products',
              ),
              Tab(
                icon: Icon(Icons.receipt_long, color: Colors.white),
                text: 'Orders',
              ),
              Tab(
                icon: Icon(Icons.loyalty, color: Colors.white),
                text: 'Loyalty',
              ),
              Tab(
                icon: Icon(Icons.verified_user, color: Colors.white),
                text: 'Verify Redeem',
              ),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: [
            _buildProductManagement(),
            _buildOrderManagement(),
            AdminLoyaltyScreen(),
            AdminRedemptionScreen(),
          ],
        ),
        floatingActionButton: _tabController.index == 0
    ? FloatingActionButton(
        onPressed: () {
          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => AddProductScreen()),
          );
        },
        child: Icon(Icons.add, color: Colors.white),
        tooltip: 'Add Product',
        backgroundColor: primaryBrown,
      )
    : _tabController.index == 1
        ? (_selectMode 
            ? null 
            : FloatingActionButton(
                onPressed: _showClearOrderHistoryDialog,
                child: Icon(Icons.delete_sweep, color: Colors.white),
                tooltip: 'Clear Order History',
                backgroundColor: Colors.red,
              ))
            : null,
      ),
    );
  }

  Widget _buildProductManagement() {
    return StreamBuilder<List<Product>>(
      stream: _productService.allProductsForAdmin,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator(color: primaryBrown));
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.shopping_bag_outlined, size: 64, color: lightBrown),
                SizedBox(height: 16),
                Text('No products available.', style: TextStyle(fontSize: 18)),
                SizedBox(height: 24),
                ElevatedButton.icon(
                  icon: Icon(Icons.add),
                  label: Text('Add First Product'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryBrown,
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(builder: (context) => AddProductScreen()),
                    );
                  },
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
            padding: EdgeInsets.all(8),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: MediaQuery.of(context).size.width > 600 ? 3 : 2,
              childAspectRatio: 0.7,
              crossAxisSpacing: 8,
              mainAxisSpacing: 8,
            ),
            itemCount: products.length,
            itemBuilder: (ctx, i) {
              return _buildProductCard(products[i]);
            },
          ),
        );
      },
    );
  }

  Widget _buildProductCard(Product product) {
  return Card(
    elevation: 4,
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    clipBehavior: Clip.antiAlias,
    child: ConstrainedBox(
      constraints: BoxConstraints(
        minHeight: 200,
        maxHeight: 260, // Added max height constraint
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          return Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                mainAxisSize: MainAxisSize.min, // Changed to min
                children: [
                  // Product Image Section
                  Container(
                    height: constraints.maxHeight * 0.45, // Dynamic height based on available space
                    color: Colors.grey.shade200,
                    child: product.imageUrl != null && product.imageUrl!.isNotEmpty
                        ? Image.network(
                            product.imageUrl!,
                            fit: BoxFit.cover,
                            width: double.infinity,
                            height: double.infinity,
                          )
                        : Center(child: Icon(Icons.image, size: 48, color: Colors.grey)),
                  ),
                  Padding(
                    padding: EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min, // Added min
                      children: [
                        Text(
                          product.name,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Rp ${_formatCurrency(product.price)}',
                          style: TextStyle(
                            color: primaryBrown,
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                          ),
                        ),
                        SizedBox(height: 8),
                        _buildProductButtons(product),
                      ],
                    ),
                  ),
                ],
              ),
              if (!product.isActive)
                Positioned(
                  top: 0,
                  right: 0,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.only(
                        bottomLeft: Radius.circular(12),
                      ),
                    ),
                    child: Text(
                      'OUT OF STOCK',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 10,
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    ),
  );
}

  Widget _buildProductButtons(Product product) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: _buildActionButton(
                icon: Icons.edit,
                label: 'Edit',
                color: primaryBrown,
                textColor: Colors.white,
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditProductScreen(product: product),
                    ),
                  );
                },
              ),
            ),
            SizedBox(width: 4),
            Expanded(
              child: _buildActionButton(
                icon: Icons.delete,
                label: 'Delete',
                color: Colors.red,
                isOutlined: true,
                onPressed: () {
                  _showDeleteConfirmation(product);
                },
              ),
            ),
          ],
        ),
        SizedBox(height: 4),
        _buildActionButton(
          icon: product.isActive ? Icons.pause : Icons.play_arrow,
          label: product.isActive ? 'Mark Out' : 'Activate',
          color: product.isActive ? Colors.orange : Colors.green,
          textColor: Colors.white,
          onPressed: () {
            _productService.toggleProductStatus(product.id);
          },
        ),
      ],
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    Color? textColor,
    bool isOutlined = false,
    required VoidCallback onPressed,
  }) {
    final buttonChild = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(icon, size: 16, color: isOutlined ? color : textColor ?? Colors.white),
        SizedBox(width: 4),
        Flexible(
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: isOutlined ? color : textColor ?? Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );

    return SizedBox(
      height: 32,
      child: isOutlined
          ? OutlinedButton(
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: color),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: onPressed,
              child: buttonChild,
            )
          : ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: color,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
                padding: EdgeInsets.symmetric(horizontal: 4),
              ),
              onPressed: onPressed,
              child: buttonChild,
            ),
    );
  }

  void _showDeleteConfirmation(Product product) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Confirm Deletion'),
        content: Text('Are you sure you want to delete ${product.name}?'),
        actions: [
          TextButton(
            child: Text('Cancel', style: TextStyle(color: primaryBrown)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Delete'),
            onPressed: () {
              _productService.deleteProduct(product.id);
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('${product.name} has been deleted')),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildOrderManagement() {
  return StreamBuilder<List<Order>>(
    stream: _orderService.getAllOrders(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) {
        return Center(child: CircularProgressIndicator(color: primaryBrown));
      }
      if (!snapshot.hasData || snapshot.data!.isEmpty) {
        return Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.receipt_long_outlined, size: 64, color: lightBrown),
              SizedBox(height: 16),
              Text('No orders available.', style: TextStyle(fontSize: 18)),
            ],
          ),
        );
      }
      
      final orders = snapshot.data!;
      
      // Filter orders by status if selected
      var filteredOrders = orders;
      if (_selectedOrderStatus != null) {
        filteredOrders = orders.where((order) => order.status == _selectedOrderStatus).toList();
      }
      
      // Filter orders by search query
      if (_searchQuery.isNotEmpty) {
        filteredOrders = filteredOrders.where((order) => 
          order.id.toLowerCase().contains(_searchQuery) ||
          (order.userName?.toLowerCase().contains(_searchQuery) ?? false) ||
          order.items.any((item) => item.productName.toLowerCase().contains(_searchQuery))
        ).toList();
      }
      
      return RefreshIndicator(
        onRefresh: () async {
          setState(() {
            _selectedOrderIds.clear();
            _selectMode = false;
            _searchController.clear();
          });
        },
        color: primaryBrown,
        child: Column(
          children: [
            _buildOrderFilterBar(filteredOrders.length),
            Expanded(
              child: filteredOrders.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: lightBrown),
                        SizedBox(height: 16),
                        Text(
                          'No orders match your search criteria.',
                          style: TextStyle(fontSize: 18),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    controller: _orderScrollController,
                    padding: EdgeInsets.all(16),
                    itemCount: filteredOrders.length,
                    itemBuilder: (ctx, i) {
                      return _buildOrderCard(filteredOrders[i]);
                    },
                  ),
            ),
            if (_selectMode && _selectedOrderIds.isNotEmpty)
              _buildSelectionActionBar(),
          ],
        ),
      );
    },
  );
}

  Widget _buildOrderCard(Order order) {
  // Define status colors
  Color statusColor;
  switch (order.status) {
    case OrderStatus.pending:
      statusColor = Colors.orange;
      break;
    case OrderStatus.processing:
      statusColor = Colors.amber;
      break;
    case OrderStatus.ready:
      statusColor = Colors.blue;
      break;
    case OrderStatus.completed:
      statusColor = Colors.green;
      break;
    case OrderStatus.cancelled:
      statusColor = Colors.red;
      break;
    default:
      statusColor = Colors.indigoAccent;
  }

  // Format order date and time
  final orderDate = DateTime.fromMillisecondsSinceEpoch(order.orderDate.millisecondsSinceEpoch);
  final formattedDate = "${orderDate.day}/${orderDate.month}/${orderDate.year}";
  final formattedTime = "${orderDate.hour}:${orderDate.minute.toString().padLeft(2, '0')}";

  final bool isSelected = _selectedOrderIds.contains(order.id);

  return Card(
    elevation: 3,
    margin: EdgeInsets.only(bottom: 16),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(12),
      side: isSelected
          ? BorderSide(color: primaryBrown, width: 2)
          : BorderSide.none,
    ),
    child: Column(
      children: [
        ExpansionTile(
          leading: _selectMode
              ? Checkbox(
                  value: isSelected,
                  activeColor: primaryBrown,
                  onChanged: (bool? value) {
                    setState(() {
                      if (value == true) {
                        _selectedOrderIds.add(order.id);
                        if (_orderScrollController.hasClients) {
                          _orderScrollController.animateTo(
                            0.0,
                            duration: Duration(milliseconds: 500),
                            curve: Curves.easeInOut,
                          );
                        }
                      } else {
                        _selectedOrderIds.remove(order.id);
                      }
                    });
                  },
                )
              : null,
          title: Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: statusColor),
                ),
                child: Text(
                  _getStatusText(order.status),
                  style: TextStyle(color: statusColor, fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Order #${order.id.substring(0, 8)}',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text(
                      '${order.items.length} items · Rp ${_formatCurrency(order.totalAmount)}',
                      style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Customer: ${order.userName ?? 'N/A'}',
                  style: TextStyle(fontSize: 13),
                ),
                SizedBox(height: 4),
                Text(
                  '$formattedDate at $formattedTime',
                  style: TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
          ),
          children: [
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Divider(),
                  Text(
                    'Order Items:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  SizedBox(height: 8),
                  ...order.items.map((item) => Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                '${item.quantity}x ${item.productName}',
                                style: TextStyle(fontSize: 14),
                              ),
                            ),
                            Text(
                              'Rp ${_formatCurrency(item.price * item.quantity)}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ],
                        ),
                      )),
                  Divider(),
                  if (order.status != OrderStatus.completed &&
                      order.status != OrderStatus.cancelled)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Show "Confirm Payment" button when status is pending
                          if (order.status == OrderStatus.pending)
                            ElevatedButton.icon(
                              icon: Icon(Icons.payment, color: Colors.white),
                              label: Text('Confirm Payment', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.indigo,
                              ),
                              onPressed: () {
                                _orderService.updateOrderStatus(
                                  order.id, OrderStatus.paid,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Payment confirmed for order #${order.id.substring(0, 8)}'),
                                    backgroundColor: primaryBrown,
                                  ),
                                );
                              },
                            ),
                          
                          // Show "Preparing" button when status is paid
                          if (order.status == OrderStatus.paid)
                            ElevatedButton.icon(
                              icon: Icon(Icons.check_circle_outline),
                              label: Text('Preparing'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.amber,
                              ),
                              onPressed: () {
                                _orderService.updateOrderStatus(
                                  order.id, OrderStatus.processing,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Order #${order.id.substring(0, 8)} is now preparing!'),
                                    backgroundColor: primaryBrown,
                                  ),
                                );
                              },
                            ),

                            // Show "Mark as Ready" button when status is preparing
                          if (order.status == OrderStatus.processing)
                            ElevatedButton.icon(
                              icon: Icon(Icons.check_circle_outline, color: Colors.white),
                              label: Text('Mark as Ready', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.blue,
                              ),
                              onPressed: () {
                                _orderService.updateOrderStatus(
                                  order.id, OrderStatus.ready,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Order #${order.id.substring(0, 8)} is now ready!'),
                                    backgroundColor: primaryBrown,
                                  ),
                                );
                              },
                            ),

                            // Show "Complete" button when status is preparing
                          if (order.status == OrderStatus.ready)
                            ElevatedButton.icon(
                              icon: Icon(Icons.check_circle_outline, color: Colors.white),
                              label: Text('Complete', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                _orderService.updateOrderStatus(
                                  order.id, OrderStatus.completed,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Order #${order.id.substring(0, 8)} is now ready!'),
                                    backgroundColor: primaryBrown,
                                  ),
                                );
                              },
                            ),
                          
                          // Show Complete button if status is processing
                          if (order.status == OrderStatus.processing)
                            ElevatedButton.icon(
                              icon: Icon(Icons.done_all, color: Colors.white),
                              label: Text('Complete', style: TextStyle(color: Colors.white)),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: Colors.green,
                              ),
                              onPressed: () {
                                _orderService.updateOrderStatus(
                                  order.id,
                                  OrderStatus.completed,
                                );
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text('Order #${order.id.substring(0, 8)} completed!'),
                                    backgroundColor: primaryBrown,
                                  ),
                                );
                              },
                            ),
                          SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.cancel_outlined, color: Colors.white,),
                                  label: Text('Cancel Order', style: TextStyle(color: Colors.white)),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.red,
                                  ),
                                  onPressed: () {
                                    _showCancelConfirmation(order);
                                  },
                                ),
                              ),
                              SizedBox(width: 8),
                              Expanded(
                                child: ElevatedButton.icon(
                                  icon: Icon(Icons.delete_outline, color: Colors.white),
                                  label: Text('Delete Order', style: TextStyle(color: Colors.white),),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Colors.deepOrange,
                                  ),
                                  onPressed: () {
                                    _showDeleteSingleOrderConfirmation(order);
                                  },
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  // For completed or cancelled orders, show only delete button
                  if (order.status == OrderStatus.completed ||
                      order.status == OrderStatus.cancelled)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: ElevatedButton.icon(
                        icon: Icon(Icons.delete_outline, color: Colors.white),
                        label: Text('Delete Order', style: TextStyle(color: Colors.white)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.deepOrange,
                        ),
                        onPressed: () {
                          _showDeleteSingleOrderConfirmation(order);
                        },
                      ),
                    ),
                  // Show reason if order is cancelled
                  if (order.status == OrderStatus.cancelled)
                    Padding(
                      padding: const EdgeInsets.only(top: 8.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cancellation Reason:',
                            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                          ),
                          SizedBox(height: 4),
                          Text(
                            order.cancellationReason ?? 'No reason provided',
                            style: TextStyle(fontStyle: FontStyle.italic),
                          ),
                        ],
                      ),
                    ),
                  // Additional Notes section
                  if (order.notes != null && order.notes!.isNotEmpty) ...[
                    Divider(),
                    Text(
                      'Additional Notes:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    SizedBox(height: 4),
                    Text(order.notes!, style: TextStyle(fontStyle: FontStyle.italic)),
                  ],
                ],
              ),
            ),
          ],
          onExpansionChanged: (expanded) {
            // If we're in select mode and the user taps the order, toggle selection
            if (_selectMode && !expanded) {
              setState(() {
                if (_selectedOrderIds.contains(order.id)) {
                  _selectedOrderIds.remove(order.id);
                } else {
                  _selectedOrderIds.add(order.id);
                }
                // Scroll to top when order is selected
                if (_orderScrollController.hasClients) {
                  _orderScrollController.animateTo(
                    0.0,
                    duration: Duration(milliseconds: 500),
                    curve: Curves.easeInOut,
                  );
                }
              });
            }
          },
        ),
      ],
    ),
  );
}


Widget _buildSearchBar() {
  return Padding(
    padding: EdgeInsets.symmetric(horizontal: 16),
    child: Row(
      children: [
        Expanded(
          child: TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: 'Search order ID, customer, product...',
              prefixIcon: Icon(Icons.search, color: primaryBrown),
              suffixIcon: _searchController.text.isNotEmpty
                ? IconButton(
                    icon: Icon(Icons.clear),
                    onPressed: () {
                      _searchController.clear();
                      _performSearch(); // Clear search results when cleared
                    },
                  )
                : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: lightBrown),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: primaryBrown, width: 2),
              ),
              contentPadding: EdgeInsets.symmetric(vertical: 0),
              filled: true,
              fillColor: Colors.white,
            ),
            onSubmitted: (value) {
              _performSearch();
            },
            textInputAction: TextInputAction.search,
          ),
        ),
        SizedBox(width: 8),
        ElevatedButton(
          onPressed: _performSearch,
          style: ElevatedButton.styleFrom(
            backgroundColor: primaryBrown,
            padding: EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(8),
            ),
          ),
          child: Text('Search', style: TextStyle(color: Colors.white),),
        ),
      ],
    ),
  );
}

 Widget _buildOrderFilterBar(int totalOrders) {
  return Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Container(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        color: lightBrown.withOpacity(0.3),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'Orders',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                SizedBox(width: 8),
                Text(
                  '($totalOrders)',
                  style: TextStyle(
                    color: Colors.grey.shade700,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                // Toggle select mode button
                IconButton(
                  icon: Icon(
                    _selectMode ? Icons.cancel : Icons.check_box_outline_blank,
                    color: _selectMode ? Colors.red : primaryBrown,
                  ),
                  tooltip: _selectMode ? 'Cancel Selection' : 'Select Orders',
                  onPressed: () {
                    setState(() {
                      _selectMode = !_selectMode;
                      if (!_selectMode) {
                        _selectedOrderIds.clear();
                      }
                    });
                  },
                ),
                SizedBox(width: 8),
                IconButton(
                  icon: Icon(Icons.delete_sweep, color: Colors.red),
                  tooltip: 'Delete Orders',
                  onPressed: () {
                    _showClearOrderHistoryDialog();
                  },
                ),
              ],
            ),
          ],
        ),
      ),
      // Search bar
      SizedBox(height: 16),
       _buildSearchBar(),
      SizedBox(height: 16),
      // Status filter chips
      Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              _buildStatusFilterChip(null, 'All'),
              SizedBox(width: 8),
              _buildStatusFilterChip(OrderStatus.pending, 'Pending'),
              SizedBox(width: 8),
              _buildStatusFilterChip(OrderStatus.paid, 'Paid'),  
              SizedBox(width: 8),
              _buildStatusFilterChip(OrderStatus.processing, 'Preparing'),
              SizedBox(width: 8),
              _buildStatusFilterChip(OrderStatus.ready, 'Ready'),
              SizedBox(width: 8),
              _buildStatusFilterChip(OrderStatus.completed, 'Completed'),
              SizedBox(width: 8),
              _buildStatusFilterChip(OrderStatus.cancelled, 'Cancelled'),
            ],
          ),
        ),
      ),
      SizedBox(height: 8),
    ],
  );
}

Widget _buildStatusFilterChip(OrderStatus? status, String label) {
  bool isSelected = _selectedOrderStatus == status;
  
  Color chipColor;
  if (status == null) {
    chipColor = Colors.grey;
  } else {
    switch (status) {
      case OrderStatus.pending:
        chipColor = Colors.orange;
        break;
      case OrderStatus.paid:
        chipColor = Colors.indigoAccent;
        break;
      case OrderStatus.processing:
        chipColor = Colors.amber;
        break;
      case OrderStatus.ready:
        chipColor = Colors.blue;
        break;
      case OrderStatus.completed:
        chipColor = Colors.green;
        break;
      case OrderStatus.cancelled:
        chipColor = Colors.red;
        break;
      default:
        chipColor = Colors.grey;
    }
  }

  return FilterChip(
    label: Text(
      label,
      style: TextStyle(
        color: isSelected ? Colors.white : chipColor,
        fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
      ),
    ),
    selected: isSelected,
    checkmarkColor: Colors.white,
    selectedColor: chipColor,
    backgroundColor: chipColor.withOpacity(0.1),
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(16),
      side: BorderSide(color: chipColor),
    ),
    onSelected: (bool selected) {
      setState(() {
        if (selected) {
          _selectedOrderStatus = status;
        } else {
          _selectedOrderStatus = null;
        }
      });
    },
  );
}

Widget _buildSelectionActionBar() {
  return Container(
    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    color: primaryBrown.withOpacity(0.9),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          '${_selectedOrderIds.length} orders selected',
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        Row(
          children: [
            TextButton.icon(
              icon: Icon(Icons.delete, color: Colors.white),
              label: Text('Delete Selected', style: TextStyle(color: Colors.white)),
              onPressed: () {
                _showDeleteSelectedConfirmation();
              },
            ),
          ],
        ),
      ],
    ),
  );
}

void _showDeleteSingleOrderConfirmation(Order order) {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Confirm Deletion'),
      content: Text('Are you sure you want to delete Order #${order.id.substring(0, 8)}? This action cannot be undone.'),
      actions: [
        TextButton(
          child: Text('Cancel', style: TextStyle(color: primaryBrown)),
          onPressed: () {
            Navigator.of(ctx).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text('Delete'),
          onPressed: () async {
            // Delete the single order
            await _orderService.deleteOrder(order.id);
            
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Order #${order.id.substring(0, 8)} has been deleted'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ],
    ),
  );
}

void _showDeleteSelectedConfirmation() {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Confirm Deletion'),
      content: Text('Are you sure you want to delete ${_selectedOrderIds.length} selected orders? This action cannot be undone.'),
      actions: [
        TextButton(
          child: Text('Cancel', style: TextStyle(color: primaryBrown)),
          onPressed: () {
            Navigator.of(ctx).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text('Delete'),
          onPressed: () async {
            // Delete selected orders
            await _orderService.deleteMultipleOrders(_selectedOrderIds.toList());
            
            // Clear selection and close dialog
            setState(() {
              _selectedOrderIds.clear();
              _selectMode = false;
            });
            
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Selected orders have been deleted'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ],
    ),
  );
}

  void _showCancelConfirmation(Order order) {
  // Predefined cancellation reasons
  final List<String> cancellationOptions = [
    'Out of stock',
    'Kitchen closed',
    'Order processing error',
    'Excessive wait time',
    'Customer requested',
    'Payment issue'
  ];
  String selectedReason = cancellationOptions.first;

  showDialog(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => StatefulBuilder(
      builder: (context, setState) => AlertDialog(
        title: Text('Cancel Order'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Are you sure you want to cancel this order?'),
              SizedBox(height: 16),
              Text('Select reason for cancellation:'),
              SizedBox(height: 8),
              ...cancellationOptions.map((reason) => 
                RadioListTile<String>(
                  title: Text(reason),
                  value: reason,
                  groupValue: selectedReason,
                  dense: true,
                  activeColor: primaryBrown,
                  onChanged: (value) {
                    setState(() {
                      selectedReason = value!;
                    });
                  },
                )
              ).toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            child: Text('Back', style: TextStyle(color: primaryBrown)),
            onPressed: () {
              Navigator.of(ctx).pop();
            },
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: Text('Confirm'),
            onPressed: () {
              // Close dialog first
              Navigator.of(ctx).pop();
              
              // Get current user's email
              final user = FirebaseAuth.instance.currentUser;
              final email = user?.email ?? '';
              
              // Process the cancellation
              _orderService.cancelOrder(
                order.id,
                reason: selectedReason,
                email: email,
              );
              
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Order #${order.id.substring(0, 8)} cancelled'),
                  backgroundColor: Colors.red,
                ),
              );
            },
          ),
        ],
      ),
    ),
  );
}

void _showDeleteConfirmationByStatus(OrderStatus? status) {
  String message = 'Are you sure you want to delete ';
  if (status == OrderStatus.completed) {
    message += 'all completed orders?';
  } else if (status == OrderStatus.cancelled) {
    message += 'all cancelled orders?';
  } else if (status == OrderStatus.pending) {
    message += 'all pending orders?';
  } else if (status == OrderStatus.paid) {
    message += 'all paid orders?';
  } else {
    message += 'ALL orders? This action cannot be undone.';
  }

  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Confirm Deletion'),
      content: Text(message),
      actions: [
        TextButton(
          child: Text('Cancel', style: TextStyle(color: primaryBrown)),
          onPressed: () {
            Navigator.of(ctx).pop();
          },
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.red,
          ),
          child: Text('Delete'),
          onPressed: () {
            // Perform deletion based on status
            if (status == null) {
              _orderService.clearAllOrders();
            } else {
              _orderService.clearOrdersByStatus(status);
            }
            
            Navigator.of(ctx).pop();
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(status == null 
                  ? 'All orders have been deleted' 
                  : 'All ${_getStatusText(status).toLowerCase()} orders have been deleted'),
                backgroundColor: Colors.red,
              ),
            );
          },
        ),
      ],
    ),
  );
}

void _showClearOrderHistoryDialog() {
  showDialog(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text('Clear Order History'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Choose which orders to delete:'),
          SizedBox(height: 16),
          ListTile(
            leading: Icon(Icons.check_circle, color: Colors.green),
            title: Text('Delete Completed Orders'),
            dense: true,
            onTap: () {
              Navigator.of(ctx).pop();
              _showDeleteConfirmationByStatus(OrderStatus.completed);
            },
          ),
          ListTile(
            leading: Icon(Icons.cancel, color: Colors.red),
            title: Text('Delete Cancelled Orders'),
            dense: true,
            onTap: () {
              Navigator.of(ctx).pop();
              _showDeleteConfirmationByStatus(OrderStatus.cancelled);
            },
          ),
          ListTile(
            leading: Icon(Icons.pending_actions, color: Colors.amberAccent),
            title: Text('Delete Pending Orders'),
            dense: true,
            onTap: () {
              Navigator.of(ctx).pop();
              _showDeleteConfirmationByStatus(OrderStatus.pending);
            },
          ),
          ListTile(
            leading: Icon(Icons.payment, color: Colors.indigoAccent),
            title: Text('Delete Paid Orders'),
            dense: true,
            onTap: () {
              Navigator.of(ctx).pop();
              _showDeleteConfirmationByStatus(OrderStatus.paid);
            },
          ),
          ListTile(
            leading: Icon(Icons.delete_sweep, color: Colors.grey),
            title: Text('Delete All Orders'),
            dense: true,
            onTap: () {
              Navigator.of(ctx).pop();
              _showDeleteConfirmationByStatus(null);
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          child: Text('Cancel', style: TextStyle(color: primaryBrown)),
          onPressed: () {
            Navigator.of(ctx).pop();
          },
        ),
      ],
    ),
  );
}

  String _formatCurrency(double amount) {
    // Format as Indonesian Rupiah without decimal places
    return amount.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]}.',
        );
  }

  String _getStatusText(OrderStatus status) {
  switch (status) {
    case OrderStatus.pending:
      return 'PENDING';
    case OrderStatus.paid:
      return 'PAID';
    case OrderStatus.processing:
      return 'PREPARING';
    case OrderStatus.ready:
      return 'READY';
    case OrderStatus.completed:
      return 'COMPLETED';
    case OrderStatus.cancelled:
      return 'CANCELLED';
    default:
      return status.toString().split('.').last.toUpperCase();
  }
}
}

