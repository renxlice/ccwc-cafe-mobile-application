import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../models/user_model.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  _ProfileState createState() => _ProfileState();
}

class _ProfileState extends State<Profile> with TickerProviderStateMixin {
  final ImagePicker _picker = ImagePicker();
  final _formKey = GlobalKey<FormState>();

  String? _newPhotoURL;
  File? _localImage;
  String? _editedName;
  String? _editedBio;
  bool isEditing = false;
  bool isSaving = false;

  ImageProvider<Object>? _getImageProvider(String? photoURL) {
    if (photoURL == null || photoURL.isEmpty) {
      return null;
    } else if (_localImage != null) {
      return FileImage(_localImage!);
    } else if (photoURL.startsWith('http')) {
      return NetworkImage(photoURL);
    } else {
      return FileImage(File(photoURL));
    }
  }

  Future<String> _saveImageLocally(File imageFile) async {
    final directory = await getApplicationDocumentsDirectory();
    final fileName = 'profile_picture.jpg';
    final localPath = '${directory.path}/$fileName';
    await imageFile.copy(localPath);
    return localPath;
  }

  Future<void> _pickImage(ImageSource source, UserData userData) async {
    final pickedFile = await _picker.pickImage(source: source);
    if (pickedFile == null) return;

    File imageFile = File(pickedFile.path);
    String localPath = await _saveImageLocally(imageFile);

    setState(() {
      _localImage = imageFile;
    });

    await FirebaseFirestore.instance.collection('users').doc(userData.uid).update({
      'photoURL': localPath,
    });
  }

  Future<void> _removePhoto(UserData userData) async {
    setState(() {
      _newPhotoURL = '';
      _localImage = null;
      isEditing = true;
    });

    await FirebaseFirestore.instance.collection('users').doc(userData.uid).update({'photoURL': ''});
  }

  void _showProfileUpdateNotification(BuildContext context, String message) {
    final overlay = Overlay.of(context);
    late OverlayEntry overlayEntry;
    final animationController = AnimationController(
      duration: Duration(milliseconds: 500),
      vsync: this,
    );
    final fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeInOut,
    );

    overlayEntry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.of(context).size.height * 0.21,
        left: MediaQuery.of(context).size.width * 0.1,
        right: MediaQuery.of(context).size.width * 0.1,
        child: FadeTransition(
          opacity: fadeAnimation,
          child: Material(
            color: Colors.transparent,
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
              decoration: BoxDecoration(
                color: Colors.green.shade700,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black26,
                    blurRadius: 8,
                    spreadRadius: 2,
                    offset: Offset(0, 4),
                  )
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.check_circle, color: Colors.white, size: 24),
                  SizedBox(width: 10),
                  Text(
                    message,
                    style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    overlay.insert(overlayEntry);
    animationController.forward();

    Future.delayed(Duration(seconds: 2), () {
      animationController.reverse().then((_) {
        overlayEntry.remove();
      });
    });
  }

  Future<void> _saveProfileChanges(UserData userData) async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      isSaving = true;
    });

    _formKey.currentState!.save();

    await FirebaseFirestore.instance.collection('users').doc(userData.uid).update({
      'name': _editedName ?? userData.name,
      'bio': _editedBio ?? userData.bio,
    });

    setState(() {
      isEditing = false;
      isSaving = false;
    });

    _showProfileUpdateNotification(context, 'Profile updated successfully!');
  }

  @override
  Widget build(BuildContext context) {
    final userData = Provider.of<UserData>(context);

    return SingleChildScrollView(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Column(
          children: [
            Card(
              elevation: 2,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: EdgeInsets.all(20.0),
                child: Column(
                  children: [
                    Stack(
                      children: [
                        CircleAvatar(
                          radius: 60,
                          backgroundColor: Theme.of(context).primaryColor.withOpacity(0.2),
                          backgroundImage: _getImageProvider(userData.photoURL),
                          child: userData.photoURL.isEmpty
                              ? Text(
                                  userData.name.isNotEmpty ? userData.name[0].toUpperCase() : '?',
                                  style: TextStyle(
                                    fontSize: 40,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown[700], // Changed to brown
                                  ),
                                )
                              : null,
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: PopupMenuButton(
                            icon: Icon(Icons.camera_alt, color: Colors.white),
                            onSelected: (value) {
                              if (value == 'gallery') {
                                _pickImage(ImageSource.gallery, userData);
                              } else if (value == 'camera') {
                                _pickImage(ImageSource.camera, userData);
                              } else if (value == 'remove') {
                                _removePhoto(userData);
                              }
                            },
                            itemBuilder: (context) => [
                              PopupMenuItem(value: 'gallery', child: Text('Pick from Gallery')),
                              PopupMenuItem(value: 'camera', child: Text('Take a Photo')),
                              if (userData.photoURL.isNotEmpty)
                                PopupMenuItem(value: 'remove', child: Text('Remove Photo')),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 16),
                    isEditing
                        ? Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                TextFormField(
                                  initialValue: userData.name,
                                  decoration: InputDecoration(labelText: 'Name'),
                                  validator: (value) => value!.isEmpty ? 'Name cannot be empty' : null,
                                  onSaved: (value) => _editedName = value,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.brown[700]), // Changed to brown
                                ),
                                SizedBox(height: 10),
                                TextFormField(
                                  initialValue: userData.bio,
                                  decoration: InputDecoration(labelText: 'Bio'),
                                  validator: (value) => value!.isEmpty ? 'Bio cannot be empty' : null,
                                  onSaved: (value) => _editedBio = value,
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 20),
                                ElevatedButton.icon(
                                  icon: isSaving ? CircularProgressIndicator() : Icon(Icons.save),
                                  label: Text(isSaving ? 'SAVING...' : 'SAVE CHANGES'),
                                  onPressed: isSaving ? null : () => _saveProfileChanges(userData),
                                  style: ElevatedButton.styleFrom(
                                    foregroundColor: Colors.white,
                                    backgroundColor: Colors.brown[700], // Changed to brown
                                  ),
                                ),
                                SizedBox(height: 10),
                                TextButton(
                                  onPressed: () {
                                    setState(() {
                                      isEditing = false;
                                    });
                                  },
                                  child: Text('CANCEL', style: TextStyle(color: Colors.brown[700])), // Changed to brown
                                ),
                              ],
                            ),
                          )
                        : Column(
                            children: [
                              Text(
                                userData.name,
                                style: TextStyle(
                                  fontSize: 24,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown[700], // Changed to brown
                                ),
                                textAlign: TextAlign.center,
                              ),
                              SizedBox(height: 8),
                              Text(
                                userData.bio,
                                textAlign: TextAlign.center,
                                style: TextStyle(color: Colors.grey[600]),
                              ),
                              SizedBox(height: 20),
                              ElevatedButton.icon(
                                icon: Icon(Icons.edit),
                                label: Text('EDIT PROFILE'),
                                onPressed: () {
                                  setState(() {
                                    isEditing = !isEditing;
                                  });
                                },
                                style: ElevatedButton.styleFrom(
                                  foregroundColor: Colors.white,
                                  backgroundColor: Colors.brown[700], 
                                ),
                              ),
                            ],
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
}