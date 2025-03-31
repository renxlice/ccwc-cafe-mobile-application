import 'package:flutter/material.dart';
import '../models/product_model.dart';
import '../../services/product_service.dart';

class EditProductScreen extends StatefulWidget {
  final Product product;

  const EditProductScreen({Key? key, required this.product}) : super(key: key);

  @override
  _EditProductScreenState createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final ProductService _productService = ProductService();
  final _formKey = GlobalKey<FormState>();
  
  // Enhanced color scheme
  final Color _primaryColor = Color(0xFF6F4E37); // Rich Coffee Brown
  final Color _accentColor = Color(0xFFD4A76A); // Caramel
  final Color _backgroundColor = Color(0xFFF9F5F0); // Cream
  final Color _textColor = Colors.white;
  final Color _darkTextColor = Color(0xFF3E2723); // Dark Brown
  
  late String _name;
  late String _description;
  late double _price;
  late String _imageUrl;
  late String _category;
  late Map<String, dynamic> _customizationOptions;
  
  final List<String> _categories = ['All', 'Beverages', 'Pastries', 'Meals', 'Desserts'];
  
  late TextEditingController _nameController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;
  late TextEditingController _imageUrlController;
  
  bool _isLoading = false;
  bool _imagePreviewEnabled = true;

  // Customization controllers
  List<Map<String, dynamic>> _customizationGroups = [];
  
  @override
  void initState() {
    super.initState();
    // Initialize variables with the product data
    _name = widget.product.name;
    _description = widget.product.description ?? '';
    _price = widget.product.price;
    _imageUrl = widget.product.imageUrl ?? '';
    _category = widget.product.category ?? 'All';
    
    // Initialize customization options
    _customizationOptions = widget.product.customizationOptions ?? {};
    _initializeCustomizationGroups();
    
    // Initialize controllers
    _nameController = TextEditingController(text: _name);
    _descriptionController = TextEditingController(text: _description);
    _priceController = TextEditingController(text: _price.toString());
    _imageUrlController = TextEditingController(text: _imageUrl);
  }

  void _initializeCustomizationGroups() {
    _customizationGroups = [];
    _customizationOptions.forEach((groupName, options) {
      List<Map<String, dynamic>> optionsList = [];
      
      if (options is Map<String, dynamic>) {
        options.forEach((optionName, optionPrice) {
          optionsList.add({
            'name': optionName,
            'price': optionPrice is double ? optionPrice : double.tryParse(optionPrice.toString()) ?? 0.0,
            'controller': TextEditingController(text: optionPrice.toString())
          });
        });
      }
      
      _customizationGroups.add({
        'groupName': groupName,
        'groupNameController': TextEditingController(text: groupName),
        'options': optionsList
      });
    });
    
    // If no customization groups, add an empty one
    if (_customizationGroups.isEmpty) {
      _addNewCustomizationGroup();
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    _imageUrlController.dispose();
    
    // Dispose all customization controllers
    for (var group in _customizationGroups) {
      (group['groupNameController'] as TextEditingController).dispose();
      for (var option in group['options']) {
        (option['controller'] as TextEditingController).dispose();
      }
    }
    
    super.dispose();
  }

  void _addNewCustomizationGroup() {
    setState(() {
      _customizationGroups.add({
        'groupName': '',
        'groupNameController': TextEditingController(),
        'options': [
          {
            'name': '',
            'price': 0.0,
            'controller': TextEditingController(text: '0')
          }
        ]
      });
    });
  }

  void _addOptionToGroup(int groupIndex) {
    setState(() {
      _customizationGroups[groupIndex]['options'].add({
        'name': '',
        'price': 0.0,
        'controller': TextEditingController(text: '0')
      });
    });
  }

  void _removeCustomizationGroup(int groupIndex) {
    setState(() {
      // Dispose controllers first
      ((_customizationGroups[groupIndex]['groupNameController']) as TextEditingController).dispose();
      for (var option in _customizationGroups[groupIndex]['options']) {
        (option['controller'] as TextEditingController).dispose();
      }
      _customizationGroups.removeAt(groupIndex);
    });
  }

  void _removeOptionFromGroup(int groupIndex, int optionIndex) {
    setState(() {
      // Dispose controller first
      ((_customizationGroups[groupIndex]['options'][optionIndex]['controller']) as TextEditingController).dispose();
      _customizationGroups[groupIndex]['options'].removeAt(optionIndex);
      
      // If no options left, add an empty one
      if (_customizationGroups[groupIndex]['options'].isEmpty) {
        _customizationGroups[groupIndex]['options'].add({
          'name': '',
          'price': 0.0,
          'controller': TextEditingController(text: '0')
        });
      }
    });
  }

  Map<String, dynamic> _buildCustomizationOptions() {
    Map<String, dynamic> result = {};
    
    for (var group in _customizationGroups) {
      String groupName = (group['groupNameController'] as TextEditingController).text.trim();
      if (groupName.isNotEmpty) {
        Map<String, dynamic> options = {};
        
        for (var option in group['options']) {
          String optionName = option['name'].toString().trim();
          // Get value from controller
          double optionPrice = double.tryParse((option['controller'] as TextEditingController).text) ?? 0.0;
          
          if (optionName.isNotEmpty) {
            options[optionName] = optionPrice;
          }
        }
        
        if (options.isNotEmpty) {
          result[groupName.toLowerCase()] = options; // Store with lowercase key for consistency
        }
      }
    }
      
    return result;
  }

  void _updateProduct() async {
    if (_formKey.currentState!.validate()) {
      setState(() {
        _isLoading = true;
      });
      
      // Build customization options map
      Map<String, dynamic> customizationOptions = _buildCustomizationOptions();
      
      final updatedProduct = Product(
        id: widget.product.id,
        name: _nameController.text.trim(),
        description: _descriptionController.text.trim(),
        price: double.tryParse(_priceController.text) ?? 0.0,
        imageUrl: _imageUrlController.text.trim(),
        category: _category,
        customizationOptions: customizationOptions,
      );

      try {
        await _productService.updateProduct(updatedProduct);
        setState(() {
          _isLoading = false;
        });
        
        // Show success message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product updated successfully!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        
        Navigator.pop(context, updatedProduct); // Return the updated product
      } catch (e) {
        setState(() {
          _isLoading = false;
        });
        
        // Show error message
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to update product: $e'),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
            margin: EdgeInsets.all(16),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
      }
    }
  }

  // Reusable input decoration
  InputDecoration _getInputDecoration({
    required String label,
    required IconData icon,
    String? hintText,
    Widget? suffixIcon,
    bool withPrefix = false,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hintText,
      prefixIcon: Icon(icon, color: _primaryColor),
      prefixText: withPrefix ? 'Rp ' : null,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      labelStyle: TextStyle(color: _darkTextColor),
      hintStyle: TextStyle(color: Colors.grey[400]),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.grey[300]!),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: _accentColor, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: Colors.red, width: 1),
      ),
      contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
    );
  }

  // Section header widget
  Widget _buildSectionHeader(String title, {IconData? icon, VoidCallback? onAddPressed}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            if (icon != null) Icon(icon, color: _primaryColor, size: 24),
            if (icon != null) SizedBox(width: 8),
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkTextColor,
              ),
            ),
          ],
        ),
        if (onAddPressed != null)
          IconButton(
            icon: Icon(Icons.add_circle, color: _accentColor, size: 28),
            onPressed: onAddPressed,
            tooltip: 'Add New',
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _backgroundColor,
      appBar: AppBar(
        title: Text(
          'Edit Product',
          style: TextStyle(
            color: _textColor,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: _primaryColor,
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.save, color: _textColor),
            onPressed: _updateProduct,
            tooltip: 'Save Changes',
          ),
        ],
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            bottom: Radius.circular(16),
          ),
        ),
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(
                    color: _primaryColor,
                    strokeWidth: 3,
                  ),
                  SizedBox(height: 16),
                  Text(
                    'Updating product...',
                    style: TextStyle(
                      color: _primaryColor,
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            )
          : SingleChildScrollView(
              padding: EdgeInsets.all(16.0),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Image Preview Section
                    if (_imagePreviewEnabled && _imageUrl.isNotEmpty)
                      Container(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 10,
                              offset: Offset(0, 5),
                            ),
                          ],
                        ),
                        margin: EdgeInsets.only(bottom: 24),
                        child: Stack(
                          children: [
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                _imageUrl,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    height: 220,
                                    width: double.infinity,
                                    decoration: BoxDecoration(
                                      color: Colors.grey[200],
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(Icons.broken_image, size: 64, color: Colors.grey[400]),
                                        SizedBox(height: 16),
                                        Text(
                                          'Image not available',
                                          style: TextStyle(color: Colors.grey[600], fontSize: 16),
                                        ),
                                      ],
                                    ),
                                  );
                                },
                              ),
                            ),
                            Positioned(
                              bottom: 12,
                              right: 12,
                              child: ElevatedButton.icon(
                                icon: Icon(Icons.refresh, size: 18),
                                label: Text('Refresh'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: _accentColor.withOpacity(0.85),
                                  foregroundColor: Colors.white,
                                  elevation: 0,
                                  padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                onPressed: () {
                                  setState(() {
                                    _imageUrl = _imageUrlController.text;
                                  });
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
                    
                    // Product Info Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Product Information', icon: Icons.inventory),
                          SizedBox(height: 20),
                          
                          // Product Name
                          TextFormField(
                            controller: _nameController,
                            decoration: _getInputDecoration(
                              label: 'Product Name',
                              icon: Icons.shopping_bag,
                              hintText: 'Enter product name',
                            ),
                            validator: (value) => value!.isEmpty ? 'Product name is required' : null,
                            onChanged: (value) => _name = value,
                            style: TextStyle(
                              color: _darkTextColor,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Category
                          DropdownButtonFormField<String>(
                            value: _category,
                            decoration: _getInputDecoration(
                              label: 'Category',
                              icon: Icons.category,
                            ),
                            dropdownColor: Colors.white,
                            style: TextStyle(
                              color: _darkTextColor,
                              fontSize: 16,
                            ),
                            items: _categories.map((String category) {
                              return DropdownMenuItem<String>(
                                value: category,
                                child: Text(category),
                              );
                            }).toList(),
                            onChanged: (String? newValue) {
                              setState(() {
                                _category = newValue!;
                              });
                            },
                            validator: (value) => value == null ? 'Please select a category' : null,
                          ),
                          
                          SizedBox(height: 16),
                          
                          // Price
                          TextFormField(
                            controller: _priceController,
                            decoration: _getInputDecoration(
                              label: 'Price',
                              icon: Icons.monetization_on,
                              hintText: 'Enter product price',
                              withPrefix: true,
                            ),
                            keyboardType: TextInputType.number,
                            validator: (value) {
                              if (value!.isEmpty) return 'Price is required';
                              if (double.tryParse(value) == null) return 'Please enter a valid price';
                              return null;
                            },
                            onChanged: (value) => _price = double.tryParse(value) ?? 0.0,
                            style: TextStyle(
                              color: _darkTextColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Image & Description Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader('Image & Description', icon: Icons.photo_library),
                          SizedBox(height: 20),
                          
                          // Image URL
                          TextFormField(
                            controller: _imageUrlController,
                            decoration: _getInputDecoration(
                              label: 'Image URL',
                              icon: Icons.image,
                              hintText: 'Paste image URL here',
                              suffixIcon: IconButton(
                                icon: Icon(Icons.preview, color: _accentColor),
                                onPressed: () {
                                  setState(() {
                                    _imageUrl = _imageUrlController.text;
                                  });
                                },
                                tooltip: 'Preview Image',
                              ),
                            ),
                            validator: (value) => value!.isEmpty ? 'Image URL is required' : null,
                            onChanged: (value) => _imageUrl = value,
                            style: TextStyle(
                              color: _darkTextColor,
                              fontSize: 16,
                            ),
                          ),
                          SizedBox(height: 16),
                          
                          // Description
                          TextFormField(
                            controller: _descriptionController,
                            decoration: _getInputDecoration(
                              label: 'Description',
                              icon: Icons.description,
                              hintText: 'Describe your product...',
                            ),
                            maxLines: 5,
                            validator: (value) => value!.isEmpty ? 'Product description is required' : null,
                            onChanged: (value) => _description = value,
                            style: TextStyle(
                              color: _darkTextColor,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Customization Options Card
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.05),
                            blurRadius: 10,
                            spreadRadius: 2,
                            offset: Offset(0, 2),
                          ),
                        ],
                      ),
                      padding: EdgeInsets.all(20),
                      margin: EdgeInsets.only(bottom: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSectionHeader(
                            'Customization Options', 
                            icon: Icons.tune, 
                            onAddPressed: _addNewCustomizationGroup
                          ),
                          SizedBox(height: 20),
                          
                          // List of customization groups
                          ...List.generate(_customizationGroups.length, (groupIndex) {
                            final group = _customizationGroups[groupIndex];
                            final groupNameController = group['groupNameController'] as TextEditingController;
                            final options = group['options'] as List<dynamic>;
                            
                            return Container(
                              margin: EdgeInsets.only(bottom: 24),
                              decoration: BoxDecoration(
                                color: Colors.grey[50],
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.grey[200]!),
                              ),
                              padding: EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Group name with delete button
                                  Row(
                                    children: [
                                      Expanded(
                                        child: TextFormField(
                                          controller: groupNameController,
                                          decoration: InputDecoration(
                                            labelText: 'Option Group Name',
                                            hintText: 'e.g. Size, Ice Level, Topping',
                                            prefixIcon: Icon(Icons.category, color: _primaryColor),
                                            filled: true,
                                            fillColor: Colors.white,
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: Colors.grey[300]!),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(12),
                                              borderSide: BorderSide(color: _accentColor, width: 2),
                                            ),
                                          ),
                                          onChanged: (value) {
                                            setState(() {
                                              _customizationGroups[groupIndex]['groupName'] = value;
                                            });
                                          },
                                          style: TextStyle(
                                            color: _darkTextColor,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.delete, color: Colors.red[400]),
                                        onPressed: () => _removeCustomizationGroup(groupIndex),
                                        tooltip: 'Remove Group',
                                      ),
                                    ],
                                  ),
                                  SizedBox(height: 16),
                                  
                                  // Options header
                                  Container(
                                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: _primaryColor.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            'Option Name', 
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _primaryColor,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 1,
                                          child: Text(
                                            'Price (Rp)', 
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                              color: _primaryColor,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 40), // Space for delete button
                                      ],
                                    ),
                                  ),
                                  SizedBox(height: 12),
                                  
                                  // Options
                                  ...List.generate(options.length, (optionIndex) {
                                    final option = options[optionIndex];
                                    final priceController = option['controller'] as TextEditingController;
                                    
                                    return Container(
                                      margin: EdgeInsets.only(bottom: 10),
                                      child: Row(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          // Option name
                                          Expanded(
                                            flex: 2,
                                            child: TextFormField(
                                              initialValue: option['name'],
                                              decoration: InputDecoration(
                                                hintText: 'e.g. Small, Medium, Large',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              ),
                                              onChanged: (value) {
                                                setState(() {
                                                  _customizationGroups[groupIndex]['options'][optionIndex]['name'] = value;
                                                });
                                              },
                                              style: TextStyle(
                                                color: _darkTextColor,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          
                                          // Option price
                                          Expanded(
                                            flex: 1,
                                            child: TextFormField(
                                              controller: priceController,
                                              decoration: InputDecoration(
                                                prefixText: 'Rp ',
                                                filled: true,
                                                fillColor: Colors.white,
                                                border: OutlineInputBorder(
                                                  borderRadius: BorderRadius.circular(8),
                                                  borderSide: BorderSide(color: Colors.grey[300]!),
                                                ),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                                              ),
                                              keyboardType: TextInputType.number,
                                              onChanged: (value) {
                                                setState(() {
                                                  _customizationGroups[groupIndex]['options'][optionIndex]['price'] = 
                                                      double.tryParse(value) ?? 0.0;
                                                });
                                              },
                                              style: TextStyle(
                                                color: _darkTextColor,
                                                fontSize: 15,
                                              ),
                                            ),
                                          ),
                                          
                                          // Delete option button
                                          IconButton(
                                            icon: Icon(Icons.remove_circle, color: Colors.red[400], size: 20),
                                            onPressed: () => _removeOptionFromGroup(groupIndex, optionIndex),
                                            tooltip: 'Remove Option',
                                            padding: EdgeInsets.all(8),
                                            constraints: BoxConstraints(),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                  
                                  // Add option button
                                  Center(
                                    child: TextButton.icon(
                                      icon: Icon(Icons.add, size: 18, color: _accentColor),
                                      label: Text(
                                        'Add Option', 
                                        style: TextStyle(
                                          color: _accentColor, 
                                          fontWeight: FontWeight.w500
                                        ),
                                      ),
                                      style: TextButton.styleFrom(
                                        backgroundColor: _accentColor.withOpacity(0.1),
                                        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                        shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(30),
                                        ),
                                      ),
                                      onPressed: () => _addOptionToGroup(groupIndex),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                        ],
                      ),
                    ),
                    
                    // Action Buttons
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            icon: Icon(Icons.save, color: _textColor),
                            label: Text(
                              'Save Changes', 
                              style: TextStyle(
                                color: _textColor, 
                                fontSize: 16, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: _primaryColor,
                              padding: EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 2,
                            ),
                            onPressed: _updateProduct,
                          ),
                        ),
                        SizedBox(width: 16),
                        OutlinedButton.icon(
                          icon: Icon(Icons.cancel, color: _primaryColor),
                          label: Text(
                            'Cancel', 
                            style: TextStyle(
                              color: _primaryColor, 
                              fontSize: 16, 
                              fontWeight: FontWeight.w500
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: _primaryColor,
                            side: BorderSide(color: _primaryColor),
                            padding: EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          onPressed: () => Navigator.of(context).pop(),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
    );
  }
}