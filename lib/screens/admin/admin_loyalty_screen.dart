import 'dart:io';
import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crudify/screens/models/loyalty_reward.dart';
import 'package:crudify/services/loyalty_service.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:provider/provider.dart';
import '../product/loyalty_screen.dart';

class AdminLoyaltyScreen extends StatefulWidget {
  const AdminLoyaltyScreen({Key? key}) : super(key: key);

  @override
  _AdminLoyaltyScreenState createState() => _AdminLoyaltyScreenState();
}

class _AdminLoyaltyScreenState extends State<AdminLoyaltyScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _pointsController = TextEditingController();
  final _stockController = TextEditingController();

  bool _isActive = true;
  bool _isEditing = false;
  String? _editingRewardId;
  bool _showOnlyActiveRewards = false;
  bool _isFormExpanded = false;
  File? _selectedImage;
  String _imageUrl = '';

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _pointsController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  Widget _buildImageWidget(String? imageData, {bool isActive = true}) {
    if (imageData == null || imageData.isEmpty) {
      return _buildErrorWidget();
    }

    try {
      // Handle network images
      if (imageData.startsWith('http')) {
        return ColorFiltered(
          colorFilter: isActive 
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
          child: Image.network(
            imageData,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  value: loadingProgress.expectedTotalBytes != null
                      ? loadingProgress.cumulativeBytesLoaded /
                          loadingProgress.expectedTotalBytes!
                      : null,
                ),
              );
            },
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          ),
        );
      }
      // Handle base64 encoded images
      else if (imageData.startsWith('data:image')) {
        final bytes = base64Decode(imageData.split(',').last);
        return ColorFiltered(
          colorFilter: isActive 
              ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
              : ColorFilter.matrix(<double>[
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0.2126, 0.7152, 0.0722, 0, 0,
                  0,      0,      0,      1, 0,
                ]),
          child: Image.memory(
            bytes,
            fit: BoxFit.cover,
            width: double.infinity,
            height: double.infinity,
            errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
          ),
        );
      }
      // Handle raw base64 strings
      else {
        try {
          final bytes = base64Decode(imageData);
          return ColorFiltered(
            colorFilter: isActive 
                ? const ColorFilter.mode(Colors.transparent, BlendMode.multiply)
                : ColorFilter.matrix(<double>[
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0.2126, 0.7152, 0.0722, 0, 0,
                    0,      0,      0,      1, 0,
                  ]),
            child: Image.memory(
              bytes,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
              errorBuilder: (context, error, stackTrace) => _buildErrorWidget(),
            ),
          );
        } catch (_) {
          return _buildErrorWidget();
        }
      }
    } catch (e) {
      debugPrint('Error loading image: $e');
      return _buildErrorWidget();
    }
  }

  Widget _buildErrorWidget() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.broken_image, size: 40, color: Colors.grey[400]),
          SizedBox(height: 4),
          Text(
            'Could not load image',
            style: TextStyle(color: Colors.grey[600], fontSize: 12),
          ),
        ],
      ),
    );
  }

  void _showSuccessMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.check_circle, color: Colors.white),
            SizedBox(width: 8),
            Text(message),
          ],
        ),
        backgroundColor: Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
        duration: Duration(seconds: 2),
      ),
    );
  }

  void _showErrorMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(Icons.error, color: Colors.white),
            SizedBox(width: 8),
            Expanded(child: Text(message)),
          ],
        ),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );
  }

  void _clearForm() {
    setState(() {
      _nameController.clear();
      _descriptionController.clear();
      _pointsController.clear();
      _stockController.clear();
      _isActive = true;
      _isEditing = false;
      _editingRewardId = null;
      _selectedImage = null;
      _imageUrl = '';
    });
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedImage = File(pickedFile.path);
        _imageUrl = '';
      });
    }
  }

  void _editReward(LoyaltyReward reward) {
    setState(() {
      _nameController.text = reward.name;
      _descriptionController.text = reward.description;
      _pointsController.text = reward.pointsRequired.toString();
      _stockController.text = reward.stock.toString();
      _isActive = reward.isActive;
      _isEditing = true;
      _editingRewardId = reward.id;
      _isFormExpanded = true;
      _selectedImage = null;
      _imageUrl = reward.imageUrl;
    });
  }

  Future<String?> _getImageData() async {
    if (_selectedImage != null) {
      final bytes = await _selectedImage!.readAsBytes();
      return base64Encode(bytes);
    }
    return _imageUrl.isNotEmpty ? _imageUrl : null;
  }

  Future<void> _submitForm() async {
    if (!_formKey.currentState!.validate()) return;

    try {
      final imageData = await _getImageData();
      if (imageData == null) {
        _showErrorMessage('Please select an image');
        return;
      }

      final reward = LoyaltyReward(
        id: _editingRewardId ?? '',
        name: _nameController.text,
        description: _descriptionController.text,
        imageUrl: imageData,
        pointsRequired: int.parse(_pointsController.text),
        stock: int.parse(_stockController.text),
        isActive: _isActive,
        createdAt: DateTime.now(),
      );

      if (_isEditing) {
        await Provider.of<LoyaltyService>(context, listen: false)
            .updateReward(_editingRewardId!, reward);
        _showSuccessMessage('Reward updated successfully');
      } else {
        await Provider.of<LoyaltyService>(context, listen: false)
            .addReward(reward);
        _showSuccessMessage('Reward added successfully');
      }
      
      _clearForm();
      setState(() {
        _isFormExpanded = false;
      });
    } catch (e) {
      _showErrorMessage('Error: ${e.toString()}');
    }
  }

  Future<void> _confirmDeleteReward(String rewardId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Confirm Delete'),
        content: Text('Are you sure you want to delete this reward? This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: Text('CANCEL'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: Text('DELETE', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await Provider.of<LoyaltyService>(context, listen: false)
            .deleteReward(rewardId);
        _showSuccessMessage('Reward deleted successfully');
      } catch (e) {
        _showErrorMessage('Error deleting reward: ${e.toString()}');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (!_isFormExpanded)
            FloatingActionButton(
              backgroundColor: Colors.brown[700],
              foregroundColor: Colors.white,
              child: Icon(Icons.add),
              onPressed: () {
                setState(() {
                  _isFormExpanded = true;
                  _clearForm();
                });
              },
              tooltip: 'Add New Reward',
            ),
          SizedBox(height: 16),
          FloatingActionButton(
            backgroundColor: Colors.amber,
            mini: true,
            child: Icon(Icons.refresh),
            onPressed: _clearForm,
            tooltip: 'Reset Form',
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.brown[50]!, Colors.white],
              ),
            ),
            child: Column(
              children: [
                if (_isFormExpanded)
                  SizedBox(
                    height: constraints.maxHeight * 0.6,
                    child: SingleChildScrollView(
                      child: Card(
                        margin: EdgeInsets.fromLTRB(16, 16, 16, 8),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Padding(
                              padding: EdgeInsets.fromLTRB(16, 16, 16, 0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      Icon(
                                        _isEditing ? Icons.edit : Icons.card_giftcard,
                                        color: Colors.brown[700],
                                      ),
                                      SizedBox(width: 8),
                                      Text(
                                        _isEditing ? 'Edit Reward' : 'Create New Reward',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 18,
                                          color: Colors.brown[800],
                                        ),
                                      ),
                                    ],
                                  ),
                                  IconButton(
                                    icon: Icon(Icons.close),
                                    onPressed: () {
                                      setState(() {
                                        _isFormExpanded = false;
                                      });
                                    },
                                    tooltip: 'Close Form',
                                  ),
                                ],
                              ),
                            ),
                            Padding(
                              padding: EdgeInsets.all(16),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Reward Image',
                                          style: TextStyle(
                                            fontWeight: FontWeight.w500,
                                            color: Colors.grey,
                                            fontSize: 14,
                                          ),
                                        ),
                                        SizedBox(height: 8),
                                        GestureDetector(
                                          onTap: _pickImage,
                                          child: Container(
                                            height: 150,
                                            decoration: BoxDecoration(
                                              borderRadius: BorderRadius.circular(12),
                                              border: Border.all(
                                                color: Colors.grey[300]!,
                                                width: 1,
                                              ),
                                              color: Colors.grey[100],
                                            ),
                                            child: _selectedImage != null
                                              ? ClipRRect(
                                                  borderRadius: BorderRadius.circular(12),
                                                  child: Image.file(
                                                    _selectedImage!,
                                                    fit: BoxFit.cover,
                                                    width: double.infinity,
                                                    height: double.infinity,
                                                  ),
                                                )
                                              : _imageUrl.isNotEmpty
                                                  ? _buildImageWidget(_imageUrl, isActive: _isActive)
                                                  : Column(
                                                      mainAxisAlignment: MainAxisAlignment.center,
                                                      children: [
                                                        Icon(
                                                          Icons.add_photo_alternate,
                                                          size: 40,
                                                          color: Colors.grey[400],
                                                        ),
                                                        SizedBox(height: 8),
                                                        Text(
                                                          'Tap to add image',
                                                          style: TextStyle(
                                                            color: Colors.grey[600],
                                                          ),
                                                        ),
                                                      ],
                                                    ),
                                          ),
                                        ),
                                        if (_selectedImage != null)
                                          Padding(
                                            padding: EdgeInsets.only(top: 8),
                                            child: Text(
                                              'Image selected: ${_selectedImage!.path.split('/').last}',
                                              style: TextStyle(
                                                color: Colors.grey[600],
                                                fontSize: 12,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    CustomTextFormField(
                                      controller: _nameController,
                                      labelText: 'Reward Name',
                                      prefixIcon: Icons.title,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a reward name';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    CustomTextFormField(
                                      controller: _descriptionController,
                                      labelText: 'Description',
                                      prefixIcon: Icons.description,
                                      maxLines: 2,
                                      validator: (value) {
                                        if (value == null || value.isEmpty) {
                                          return 'Please enter a description';
                                        }
                                        return null;
                                      },
                                    ),
                                    SizedBox(height: 16),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: CustomTextFormField(
                                            controller: _pointsController,
                                            labelText: 'Points Required',
                                            prefixIcon: Icons.stars,
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter points';
                                              }
                                              if (int.tryParse(value) == null) {
                                                return 'Valid number please';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                        SizedBox(width: 16),
                                        Expanded(
                                          child: CustomTextFormField(
                                            controller: _stockController,
                                            labelText: 'Stock',
                                            prefixIcon: Icons.inventory,
                                            keyboardType: TextInputType.number,
                                            validator: (value) {
                                              if (value == null || value.isEmpty) {
                                                return 'Please enter stock';
                                              }
                                              if (int.tryParse(value) == null) {
                                                return 'Valid number please';
                                              }
                                              return null;
                                            },
                                          ),
                                        ),
                                      ],
                                    ),
                                    SizedBox(height: 16),
                                    Container(
                                      decoration: BoxDecoration(
                                        color: _isActive ? Colors.green[50] : Colors.grey[50],
                                        borderRadius: BorderRadius.circular(10),
                                        border: Border.all(
                                          color: _isActive ? Colors.green[300]! : Colors.grey[300]!,
                                        ),
                                      ),
                                      child: SwitchListTile(
                                        title: Row(
                                          children: [
                                            Icon(
                                              _isActive ? Icons.toggle_on : Icons.toggle_off,
                                              color: _isActive ? Colors.green[600] : Colors.grey[600],
                                            ),
                                            SizedBox(width: 8),
                                            Text(
                                              'Reward Status: ${_isActive ? 'Active' : 'Inactive'}',
                                              style: TextStyle(
                                                color: _isActive ? Colors.green[800] : Colors.grey[800],
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        value: _isActive,
                                        activeColor: Colors.green,
                                        onChanged: (value) {
                                          setState(() {
                                            _isActive = value;
                                          });
                                        },
                                      ),
                                    ),
                                    SizedBox(height: 24),
                                    Row(
                                      children: [
                                        Expanded(
                                          child: ElevatedButton.icon(
                                            onPressed: _submitForm,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.brown[700],
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              elevation: 2,
                                            ),
                                            icon: Icon(_isEditing ? Icons.update : Icons.add),
                                            label: Text(
                                              _isEditing ? 'UPDATE REWARD' : 'ADD REWARD',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ),
                                        if (_isEditing) ...[
                                          SizedBox(width: 6),
                                          ElevatedButton.icon(
                                            onPressed: _clearForm,
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.indigo[700],
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              elevation: 2,
                                            ),
                                            icon: Icon(Icons.refresh),
                                            label: Text(
                                              'Reset',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 6),
                                          ElevatedButton.icon(
                                            onPressed: () => _confirmDeleteReward(_editingRewardId!),
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.red[700],
                                              foregroundColor: Colors.white,
                                              padding: EdgeInsets.symmetric(vertical: 16),
                                              shape: RoundedRectangleBorder(
                                                borderRadius: BorderRadius.circular(10),
                                              ),
                                              elevation: 2,
                                            ),
                                            icon: Icon(Icons.delete),
                                            label: Text(
                                              'Delete',
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                Padding(
                  padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.grey.withOpacity(0.2),
                          spreadRadius: 1,
                          blurRadius: 6,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.filter_list, color: Colors.grey),
                        SizedBox(width: 8),
                        Text(
                          'Filter:',
                          style: TextStyle(
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        Switch(
                          value: _showOnlyActiveRewards,
                          activeColor: Colors.brown[700],
                          onChanged: (value) {
                            setState(() {
                              _showOnlyActiveRewards = value;
                            });
                          },
                        ),
                        Text(
                          'Active Only',
                          style: TextStyle(
                            color: _showOnlyActiveRewards ? Colors.brown[800] : Colors.grey[800],
                          ),
                        ),
                        Spacer(),
                        Consumer<LoyaltyService>(
                          builder: (context, loyaltyService, _) => Container(
                            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.amber[50],
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: Colors.amber[300]!),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.star, color: Colors.amber, size: 16),
                                SizedBox(width: 4),
                                Text(
                                  '${_getActiveRewardsCount()} Active',
                                  style: TextStyle(
                                    color: Colors.amber[800],
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                Expanded(
                  child: _buildRewardsList(),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildRewardsList() {
    return Consumer<LoyaltyService>(
      builder: (context, loyaltyService, child) {
        return StreamBuilder<List<LoyaltyReward>>(
          stream: loyaltyService.getAllRewards(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.brown),
                    ),
                    SizedBox(height: 16),
                    Text(
                      'Loading rewards...',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                  ],
                ),
              );
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.card_giftcard,
                        size: 80, color: Colors.brown[200]),
                    SizedBox(height: 16),
                    Text(
                      'No rewards added yet',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        setState(() {
                          _isFormExpanded = true;
                          _clearForm();
                        });
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown[700],
                        foregroundColor: Colors.white,
                        padding: EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(Icons.add),
                      label: Text('Add Your First Reward'),
                    ),
                  ],
                ),
              );
            }

            List<LoyaltyReward> rewards = snapshot.data!;
            if (_showOnlyActiveRewards) {
              rewards = rewards.where((reward) => reward.isActive).toList();
            }

            if (rewards.isEmpty) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.filter_alt, size: 80, color: Colors.grey[300]),
                    SizedBox(height: 16),
                    Text(
                      'No active rewards found',
                      style: TextStyle(
                        color: Colors.grey[600],
                        fontSize: 18,
                      ),
                    ),
                    SizedBox(height: 8),
                    OutlinedButton.icon(
                      onPressed: () {
                        setState(() {
                          _showOnlyActiveRewards = false;
                        });
                      },
                      style: OutlinedButton.styleFrom(
                        side: BorderSide(color: Colors.brown[700]!),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      icon: Icon(Icons.filter_list_off),
                      label: Text('Show All Rewards'),
                    ),
                  ],
                ),
              );
            }

            return ListView.builder(
              padding: EdgeInsets.fromLTRB(16, 0, 16, 16),
              itemCount: rewards.length,
              itemBuilder: (context, index) {
                final reward = rewards[index];
                return AnimatedContainer(
                  duration: Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                  margin: EdgeInsets.only(bottom: 12),
                  child: Card(
                    elevation: 3,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                      side: BorderSide(
                        color: reward.isActive
                            ? Colors.brown[100]!
                            : Colors.grey[300]!,
                        width: 1,
                      ),
                    ),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(16),
                      onTap: () => _editReward(reward),
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            decoration: BoxDecoration(
                              color: reward.isActive ? Colors.brown[700] : Colors.grey,
                              borderRadius: BorderRadius.only(
                                topLeft: Radius.circular(16),
                                topRight: Radius.circular(16),
                              ),
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(12),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(12),
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    child: _buildImageWidget(reward.imageUrl, isActive: reward.isActive),
                                  ),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              reward.name,
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 16,
                                                color: reward.isActive
                                                    ? Colors.brown[800]
                                                    : Colors.grey[700],
                                              ),
                                            ),
                                          ),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: reward.isActive
                                                  ? Colors.green[50]
                                                  : Colors.grey[100],
                                              borderRadius: BorderRadius.circular(20),
                                              border: Border.all(
                                                color: reward.isActive
                                                    ? Colors.green[200]!
                                                    : Colors.grey[300]!,
                                              ),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  reward.isActive
                                                      ? Icons.check_circle
                                                      : Icons.cancel,
                                                  size: 12,
                                                  color: reward.isActive
                                                      ? Colors.green[700]
                                                      : Colors.grey[600],
                                                ),
                                                SizedBox(width: 4),
                                                Text(
                                                  reward.isActive
                                                      ? 'Active'
                                                      : 'Inactive',
                                                  style: TextStyle(
                                                    fontSize: 12,
                                                    fontWeight: FontWeight.w500,
                                                    color: reward.isActive
                                                        ? Colors.green[700]
                                                        : Colors.grey[600],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 6),
                                      Text(
                                        reward.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          color: reward.isActive
                                              ? Colors.grey[700]
                                              : Colors.grey[500],
                                          fontSize: 13,
                                        ),
                                      ),
                                      SizedBox(height: 6),
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Flexible(
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: reward.isActive ? Colors.amber[100] : Colors.grey[200],
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.star,
                                                        size: 14,
                                                        color: reward.isActive ? Colors.amber[800] : Colors.grey[600],
                                                      ),
                                                      SizedBox(width: 1),
                                                      Text(
                                                        '${reward.pointsRequired}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: reward.isActive ? Colors.amber[800] : Colors.grey[600],
                                                        ),
                                                      ),
                                                      Text(
                                                        ' pts',
                                                        style: TextStyle(
                                                          fontSize: 12,
                                                          color: reward.isActive ? Colors.amber[800] : Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                                SizedBox(width: 3),
                                                Container(
                                                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: reward.isActive
                                                        ? (reward.stock > 0 ? Colors.blue[50] : Colors.red[50])
                                                        : Colors.grey[200],
                                                    borderRadius: BorderRadius.circular(20),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      Icon(
                                                        Icons.inventory,
                                                        size: 14,
                                                        color: reward.isActive
                                                            ? (reward.stock > 0 ? Colors.blue[800] : Colors.red[800])
                                                            : Colors.grey[600],
                                                      ),
                                                      SizedBox(width: 3),
                                                      Text(
                                                        '${reward.stock}',
                                                        style: TextStyle(
                                                          fontWeight: FontWeight.bold,
                                                          color: reward.isActive
                                                              ? (reward.stock > 0 ? Colors.blue[800] : Colors.red[800])
                                                              : Colors.grey[600],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                          SizedBox(width: 1),
                                          Flexible(
                                            child: SingleChildScrollView(
                                              scrollDirection: Axis.horizontal,
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.edit,
                                                      color: Colors.brown[700],
                                                      size: 20,  
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints: BoxConstraints(),
                                                    onPressed: () => _editReward(reward),
                                                    tooltip: 'Edit Reward',
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      reward.isActive ? Icons.toggle_on : Icons.toggle_off,
                                                      color: reward.isActive ? Colors.green[600] : Colors.grey[400],
                                                      size: 20,  
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints: BoxConstraints(),
                                                    onPressed: () {
                                                      loyaltyService.toggleRewardStatus(
                                                        reward.id,
                                                        !reward.isActive,
                                                      );
                                                    },
                                                    tooltip: reward.isActive ? 'Deactivate' : 'Activate',
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.delete,
                                                      color: Colors.red,
                                                      size: 20,  
                                                    ),
                                                    padding: EdgeInsets.zero,
                                                    constraints: BoxConstraints(),
                                                    onPressed: () => _confirmDeleteReward(reward.id),
                                                    tooltip: 'Delete Reward',
                                                  ),
                                                ],
                                              ),
                                            ),
                                          )
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  int _getActiveRewardsCount() {
    final loyaltyService = Provider.of<LoyaltyService>(context, listen: false);
    return loyaltyService.activeRewardsCount;
  }
}

class CustomTextFormField extends StatelessWidget {
  final TextEditingController controller;
  final String labelText;
  final IconData prefixIcon;
  final int? maxLines;
  final TextInputType? keyboardType;
  final String? Function(String?)? validator;

  const CustomTextFormField({
    Key? key,
    required this.controller,
    required this.labelText,
    required this.prefixIcon,
    this.maxLines = 1,
    this.keyboardType,
    this.validator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      decoration: InputDecoration(
        labelText: labelText,
        prefixIcon: Icon(prefixIcon),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      maxLines: maxLines,
      keyboardType: keyboardType,
      validator: validator,
    );
  }
}