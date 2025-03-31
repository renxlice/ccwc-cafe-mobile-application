import 'package:flutter/material.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import '../models/product_model.dart';
import '../../services/product_service.dart';

class AddProductScreen extends StatefulWidget {
  @override
  _AddProductScreenState createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final ProductService _productService = ProductService();
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _picker = ImagePicker();
  
  // Updated color scheme
  final Color _primaryColor = Color(0xFF6D4C41); // Darker brown
  final Color _accentColor = Color(0xFFD7CCC8); // Light brown
  final Color _textColor = Colors.white;
  final Color _darkTextColor = Colors.grey[800]!;
  
  String _name = '';
  String _description = '';
  double _price = 0.0;
  String _imageUrl = '';
  File? _imageFile;
  bool _isLoading = false;
  String _category = 'All';
  final List<String> _categories = ['All', 'Beverages', 'Pastries', 'Meals', 'Desserts'];
  
  Map<String, List<CustomizationOption>> _customizationGroups = {};
  List<String> _customizationGroupNames = [];
  Map<String, bool> _enabledCustomizationGroups = {};
  
  final TextEditingController _newGroupNameController = TextEditingController();
  final TextEditingController _newOptionNameController = TextEditingController();
  final TextEditingController _newOptionPriceController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (_customizationGroups.isEmpty) {
      _addDefaultCustomizationGroups();
    }
  }
  
  @override
  void dispose() {
    _newGroupNameController.dispose();
    _newOptionNameController.dispose();
    _newOptionPriceController.dispose();
    super.dispose();
  }
  
  void _addDefaultCustomizationGroups() {
    _addCustomizationGroup('Sugar Level');
    _addCustomizationOption('Sugar Level', 'Low Sugar', 0.0);
    _addCustomizationOption('Sugar Level', 'Medium Sugar', 0.0);
    _addCustomizationOption('Sugar Level', 'Normal Sugar', 0.0);
    
    _addCustomizationGroup('Shot Options');
    _addCustomizationOption('Shot Options', 'Single Shot', 0.0);
    _addCustomizationOption('ShotOptions', 'Double Shot', 5000.0);
    _addCustomizationOption('Shot Options', 'Triple Shot', 10000.0);
    
    _addCustomizationGroup('Size Options');
    _addCustomizationOption('Size Options', 'Small', 0.0);
    _addCustomizationOption('Size Options', 'Medium', 5000.0);
    _addCustomizationOption('Size Options', 'Large', 10000.0);
    
    _addCustomizationGroup('Toppings');
    _addCustomizationOption('Toppings', 'Whipped Cream', 5000.0);
    _addCustomizationOption('Toppings', 'Chocolate Chips', 5000.0);
    _addCustomizationOption('Toppings', 'Caramel Drizzle', 5000.0);
    _addCustomizationOption('Toppings', 'No Topping', 0.0);
    
    for (var groupName in _customizationGroupNames) {
      _enabledCustomizationGroups[groupName] = false;
    }
  }

  Future<void> _pickImage() async {
    final XFile? pickedImage = await _picker.pickImage(source: ImageSource.gallery);
    if (pickedImage != null) {
      setState(() {
        _imageFile = File(pickedImage.path);
        _imageUrl = pickedImage.path;
      });
    }
  }

  void _addProduct() async {
    if (_formKey.currentState!.validate()) {
      if (_imageUrl.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Please add an image for the product'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
          ),
        );
        return;
      }
      
      setState(() {
        _isLoading = true;
      });

      try {
        Map<String, dynamic> customizationOptions = {};
        
        _customizationGroups.forEach((groupName, options) {
          if (_enabledCustomizationGroups[groupName] == true && options.isNotEmpty) {
            Map<String, double> optionsMap = {};
            for (var option in options) {
              optionsMap[option.name] = option.priceAdjustment;
            }
            customizationOptions[groupName] = optionsMap;
          }
        });
        
        final product = Product(
          id: '',
          name: _name,
          description: _description,
          price: _price,
          imageUrl: _imageUrl,
          category: _category,
          customizationOptions: customizationOptions.isEmpty ? null : customizationOptions,
        );

        await _productService.addProduct(product);
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Product added successfully!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context);
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to add product: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(10),
            ),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }
  
  void _toggleCustomizationGroup(String groupName, bool enabled) {
    setState(() {
      _enabledCustomizationGroups[groupName] = enabled;
    });
  }
  
  void _addCustomizationGroup(String groupName) {
    if (groupName.isEmpty) return;
    
    setState(() {
      if (!_customizationGroups.containsKey(groupName)) {
        _customizationGroups[groupName] = [];
        _customizationGroupNames = _customizationGroups.keys.toList();
        _enabledCustomizationGroups[groupName] = false;
      }
    });
  }
  
  void _addCustomizationOption(String groupName, String optionName, double price) {
    if (groupName.isEmpty || optionName.isEmpty) return;
    
    setState(() {
      if (_customizationGroups.containsKey(groupName)) {
        bool optionExists = _customizationGroups[groupName]!
            .any((option) => option.name == optionName);
            
        if (!optionExists) {
          _customizationGroups[groupName]!.add(
            CustomizationOption(
              name: optionName,
              priceAdjustment: price,
            ),
          );
        }
      }
    });
  }
  
  void _removeCustomizationGroup(String groupName) {
    setState(() {
      _customizationGroups.remove(groupName);
      _enabledCustomizationGroups.remove(groupName);
      _customizationGroupNames = _customizationGroups.keys.toList();
    });
  }
  
  void _removeCustomizationOption(String groupName, String optionName) {
    setState(() {
      if (_customizationGroups.containsKey(groupName)) {
        _customizationGroups[groupName] = _customizationGroups[groupName]!
            .where((option) => option.name != optionName)
            .toList();
      }
    });
  }
  
  void _updateOptionPrice(String groupName, String optionName, double newPrice) {
    setState(() {
      if (_customizationGroups.containsKey(groupName)) {
        int index = _customizationGroups[groupName]!
            .indexWhere((option) => option.name == optionName);
            
        if (index != -1) {
          _customizationGroups[groupName]![index] = CustomizationOption(
            name: optionName,
            priceAdjustment: newPrice,
          );
        }
      }
    });
  }

  Future<void> _showAddCustomizationGroupDialog() async {
    _newGroupNameController.clear();
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Customization Group', style: TextStyle(color: _primaryColor)),
          content: TextField(
            controller: _newGroupNameController,
            decoration: InputDecoration(
              labelText: 'Group Name',
              hintText: 'e.g. Size, Topping, Ice Level',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _primaryColor),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
                borderSide: BorderSide(color: _primaryColor, width: 2),
              ),
            ),
            autofocus: true,
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: _darkTextColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (_newGroupNameController.text.isNotEmpty) {
                  _addCustomizationGroup(_newGroupNameController.text);
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }
  
  Future<void> _showAddCustomizationOptionDialog(String groupName) async {
    _newOptionNameController.clear();
    _newOptionPriceController.text = '0.0';
    
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Option to $groupName', style: TextStyle(color: _primaryColor)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: _newOptionNameController,
                decoration: InputDecoration(
                  labelText: 'Option Name',
                  hintText: 'e.g. Large, Extra Cream',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                ),
                autofocus: true,
              ),
              SizedBox(height: 16),
              TextField(
                controller: _newOptionPriceController,
                decoration: InputDecoration(
                  labelText: 'Price Adjustment',
                  hintText: 'Additional price',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _primaryColor),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: BorderSide(color: _primaryColor, width: 2),
                  ),
                ),
                keyboardType: TextInputType.numberWithOptions(decimal: true),
              ),
            ],
          ),
          actions: <Widget>[
            TextButton(
              child: Text('Cancel', style: TextStyle(color: _darkTextColor)),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            ElevatedButton(
              child: Text('Add'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () {
                if (_newOptionNameController.text.isNotEmpty) {
                  double price = double.tryParse(_newOptionPriceController.text) ?? 0.0;
                  _addCustomizationOption(
                    groupName, 
                    _newOptionNameController.text, 
                    price
                  );
                  Navigator.of(context).pop();
                }
              },
            ),
          ],
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        );
      },
    );
  }

  Widget _buildCustomizationGroups() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'Customization Options',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: _darkTextColor,
              ),
            ),
            ElevatedButton.icon(
              onPressed: _showAddCustomizationGroupDialog,
              icon: Icon(Icons.add, size: 16),
              label: Text('Add Group'),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                foregroundColor: _textColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        SizedBox(height: 8),
        Text(
          'Select which customization options to enable for this product:',
          style: TextStyle(
            color: Colors.grey[700],
            fontStyle: FontStyle.italic,
          ),
        ),
        SizedBox(height: 16),
        
        if (_customizationGroups.isEmpty)
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: _accentColor.withOpacity(0.3),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Center(
              child: Text(
                'No customization groups added yet',
                style: TextStyle(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ),
          )
        else
          ..._customizationGroupNames.map((groupName) {
            bool isEnabled = _enabledCustomizationGroups[groupName] ?? false;
            
            return Card(
              elevation: 2,
              margin: EdgeInsets.only(bottom: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isEnabled ? _primaryColor.withOpacity(0.1) : Colors.transparent,
                      borderRadius: BorderRadius.vertical(top: Radius.circular(12)),
                    ),
                    child: ListTile(
                      title: Text(
                        groupName,
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                          color: _darkTextColor,
                        ),
                      ),
                      leading: Checkbox(
                        value: isEnabled,
                        onChanged: (bool? value) {
                          _toggleCustomizationGroup(groupName, value ?? false);
                        },
                        activeColor: _primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(4),
                        ),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            icon: Icon(Icons.add_circle_outline, color: _primaryColor),
                            tooltip: 'Add Option',
                            onPressed: () => _showAddCustomizationOptionDialog(groupName),
                          ),
                          IconButton(
                            icon: Icon(Icons.delete_outline, color: Colors.red[400]),
                            tooltip: 'Remove Group',
                            onPressed: () => _removeCustomizationGroup(groupName),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  if (isEnabled)
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.vertical(bottom: Radius.circular(12)),
                      ),
                      child: _customizationGroups[groupName]!.isEmpty
                        ? Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            child: Text(
                              'No options added yet',
                              style: TextStyle(
                                fontStyle: FontStyle.italic,
                                color: Colors.grey[600],
                              ),
                            ),
                          )
                        : Padding(
                            padding: EdgeInsets.all(16),
                            child: Column(
                              children: _customizationGroups[groupName]!.map((option) {
                                final priceController = TextEditingController(
                                  text: option.priceAdjustment.toStringAsFixed(0)
                                );
                                
                                return Padding(
                                  padding: EdgeInsets.only(bottom: 12),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 2,
                                        child: Text(
                                          option.name,
                                          style: TextStyle(color: _darkTextColor),
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Expanded(
                                        flex: 3,
                                        child: TextFormField(
                                          controller: priceController,
                                          decoration: InputDecoration(
                                            contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                            border: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: Colors.grey),
                                            ),
                                            focusedBorder: OutlineInputBorder(
                                              borderRadius: BorderRadius.circular(8),
                                              borderSide: BorderSide(color: _primaryColor, width: 1.5),
                                            ),
                                            prefixText: 'Rp ',
                                            isDense: true,
                                          ),
                                          keyboardType: TextInputType.number,
                                          onChanged: (value) {
                                            double newPrice = double.tryParse(value) ?? 0.0;
                                            _updateOptionPrice(groupName, option.name, newPrice);
                                          },
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      IconButton(
                                        icon: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                                        padding: EdgeInsets.all(4),
                                        constraints: BoxConstraints(),
                                        onPressed: () => _removeCustomizationOption(groupName, option.name),
                                      ),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                    ),
                ],
              ),
            );
          }).toList(),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add New Product', style: TextStyle(color: _textColor)),
        elevation: 0,
        backgroundColor: _primaryColor,
        iconTheme: IconThemeData(color: _textColor),
        centerTitle: true,
      ),
      body: _isLoading
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircularProgressIndicator(color: _primaryColor),
                  SizedBox(height: 16),
                  Text('Processing...', style: TextStyle(fontSize: 16, color: _darkTextColor)),
                ],
              ),
            )
          : SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Image Picker
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Product Image',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _darkTextColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          GestureDetector(
                            onTap: _pickImage,
                            child: Container(
                              height: 200,
                              decoration: BoxDecoration(
                                color: _accentColor.withOpacity(0.3),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: _primaryColor.withOpacity(0.5),
                                  width: 1.5,
                                ),
                              ),
                              child: _imageFile != null
                                  ? ClipRRect(
                                      borderRadius: BorderRadius.circular(12),
                                      child: Image.file(_imageFile!, fit: BoxFit.cover),
                                    )
                                  : Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Icon(
                                          Icons.add_photo_alternate,
                                          size: 50,
                                          color: _primaryColor.withOpacity(0.5),
                                        ),
                                        SizedBox(height: 8),
                                        Text(
                                          'Tap to add product image',
                                          style: TextStyle(
                                            color: _primaryColor.withOpacity(0.7),
                                          ),
                                        ),
                                      ],
                                    ),
                            ),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      
                      // Category Selection
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Category',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: _darkTextColor,
                            ),
                          ),
                          SizedBox(height: 8),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: _categories.map((category) {
                              return ChoiceChip(
                                label: Text(category),
                                selected: _category == category,
                                onSelected: (selected) {
                                  if (selected) {
                                    setState(() {
                                      _category = category;
                                    });
                                  }
                                },
                                backgroundColor: Colors.grey[200],
                                selectedColor: _primaryColor.withOpacity(0.3),
                                labelStyle: TextStyle(
                                  color: _category == category ? _primaryColor : Colors.grey[700],
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  side: BorderSide(
                                    color: _category == category ? _primaryColor : Colors.grey[300]!,
                                  ),
                                ),
                              );
                            }).toList(),
                          ),
                        ],
                      ),
                      SizedBox(height: 24),
                      
                      // Product Name
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Product Name',
                          labelStyle: TextStyle(color: _darkTextColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryColor, width: 1.5),
                          ),
                          prefixIcon: Icon(Icons.shopping_bag_outlined, color: _primaryColor),
                        ),
                        style: TextStyle(color: _darkTextColor),
                        validator: (value) => value!.isEmpty ? 'Enter product name' : null,
                        onChanged: (value) => _name = value,
                      ),
                      SizedBox(height: 16),
                      
                      // Price
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Price',
                          labelStyle: TextStyle(color: _darkTextColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryColor, width: 1.5),
                          ),
                          prefixIcon: Icon(Icons.attach_money, color: _primaryColor),
                          prefixText: 'Rp ',
                        ),
                        style: TextStyle(color: _darkTextColor),
                        keyboardType: TextInputType.number,
                        validator: (value) => value!.isEmpty ? 'Enter price' : null,
                        onChanged: (value) => _price = double.tryParse(value) ?? 0.0,
                      ),
                      SizedBox(height: 16),
                      
                      // Description
                      TextFormField(
                        decoration: InputDecoration(
                          labelText: 'Description',
                          labelStyle: TextStyle(color: _darkTextColor),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: Colors.grey),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: _primaryColor, width: 1.5),
                          ),
                          alignLabelWithHint: true,
                        ),
                        style: TextStyle(color: _darkTextColor),
                        maxLines: 4,
                        validator: (value) => value!.isEmpty ? 'Enter description' : null,
                        onChanged: (value) => _description = value,
                      ),
                      
                      // Image URL
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0),
                        child: TextFormField(
                          decoration: InputDecoration(
                            labelText: 'Image URL (optional)',
                            labelStyle: TextStyle(color: _darkTextColor),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: Colors.grey),
                            ),
                            focusedBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8),
                              borderSide: BorderSide(color: _primaryColor, width: 1.5),
                            ),
                            prefixIcon: Icon(Icons.link, color: _primaryColor),
                            helperText: 'Enter URL or pick an image above',
                          ),
                          style: TextStyle(color: _darkTextColor),
                          initialValue: _imageUrl,
                          onChanged: (value) {
                            if (value.isNotEmpty) {
                              setState(() {
                                _imageUrl = value;
                                _imageFile = null;
                              });
                            }
                          },
                        ),
                      ),
                      
                      SizedBox(height: 24),
                      
                      // Customization Options Section
                      Divider(
                        height: 32,
                        thickness: 1,
                        color: _primaryColor.withOpacity(0.2),
                      ),
                      _buildCustomizationGroups(),
                      
                      SizedBox(height: 32),
                      // Submit Button
                      Container(
                        width: double.infinity,
                        height: 50, 
                        child: ElevatedButton(
                          onPressed: _addProduct,
                          child: Text(
                            'Add Product',
                            style: TextStyle(
                              fontSize: 16, 
                              fontWeight: FontWeight.bold,
                              color: _textColor, 
                            ),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _primaryColor,
                            elevation: 2,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12), 
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
    );
  }
}

class CustomizationOption {
  final String name;
  final double priceAdjustment;
  
  CustomizationOption({
    required this.name, 
    required this.priceAdjustment,
  });
}