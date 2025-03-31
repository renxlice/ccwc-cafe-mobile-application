import 'package:crudify/screens/admin/admin_screen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'firestore_service.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../screens/models/user_model.dart';
import '../screens/product/product_list_screen.dart';
import 'database_service.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirestoreService _firestoreService = FirestoreService();
  final GoogleSignIn _googleSignIn = GoogleSignIn();
  
  // Convert Firebase User to our UserModel
  UserModel? _userFromFirebaseUser(User? user) {
    return user != null ? UserModel(uid: user.uid) : null;
  }
  
  // Auth change user stream
  Stream<UserModel?> get user {
    return _auth.authStateChanges().map(_userFromFirebaseUser);
  }
  
  // Sign in with email & password
Future<UserModel?> signInWithEmailAndPassword(String email, String password, BuildContext context) async {
  try {
    // Display loading indicator
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    
    UserCredential result = await _auth.signInWithEmailAndPassword(
      email: email, 
      password: password
    );
    User? user = result.user;

    // Close loading indicator
    Navigator.of(context).pop();
    
    if (user != null) {
      // Check if user is admin
      if (user.email == 'admin@cafe.com') { 
        // Admin user - go to AdminScreen and remove all previous routes
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (context) => AdminScreen()),
          (route) => false,
        );
      } else {
        // Regular user - go to ProductListScreen
        Navigator.pushReplacement(
          context, 
          MaterialPageRoute(builder: (context) => ProductListScreen())
        );
      }
    }
    
    return _userFromFirebaseUser(user);
  } catch (e) {
    print('Sign in error: $e');
    // Close loading indicator if still showing
    if (context.mounted) {
      Navigator.of(context).pop();
      // Show error dialog
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign In Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
    return null;
  }
}
  
  // Register with email & password
  Future<UserModel?> registerWithEmailAndPassword(
    String email, 
    String password, 
    String name,
    BuildContext context,
  ) async {
    try {
      // Display loading indicator
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );
      
      UserCredential result = await _auth.createUserWithEmailAndPassword(
        email: email, 
        password: password
      );
      User? user = result.user;
      
      // Create user document in Firestore
      if (user != null) {
        // Create UserData document in Firestore
        await _firestore.collection('users').doc(user.uid).set({
          'uid': user.uid,
          'email': email,
          'name': name,
          'bio': 'Hey there! I am using CRUDify',
          'photoURL': user.photoURL ?? '',
          'createdAt': FieldValue.serverTimestamp(),
        });
        
        // Update display name in Firebase Auth
        await user.updateDisplayName(name);
      }
      
      // Close loading indicator
      if (context.mounted) {
        Navigator.of(context).pop();
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => ProductListScreen()));
      }
      
      return _userFromFirebaseUser(user);
    } catch (e) {
      print('Registration error: $e');
      // Close loading indicator if still showing
      if (context.mounted) {
        Navigator.of(context).pop();
        // Show error dialog
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Registration Error'),
            content: Text(e.toString()),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('OK'),
              ),
            ],
          ),
        );
      }
      return null;
    }
  }
  
  // Sign in with Google
Future<UserModel?> signInWithGoogle(BuildContext context) async {
  try {
    // Ensure Google Sign In is properly configured
    final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
    
    if (googleUser == null) {
      // User cancelled sign-in
      return null;
    }

    // Get authentication details
    final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
    
    // Create credential
    final credential = GoogleAuthProvider.credential(
      accessToken: googleAuth.accessToken,
      idToken: googleAuth.idToken,
    );

    // Sign in to Firebase
    UserCredential result = await _auth.signInWithCredential(credential);
    User? user = result.user;

    if (user == null) {
      throw Exception('Google Sign In failed: No user returned');
    }

    // Handle new user registration
    if (result.additionalUserInfo?.isNewUser ?? false) {
      await _firestore.collection('users').doc(user.uid).set({
        'uid': user.uid,
        'email': user.email,
        'name': user.displayName ?? 'Google User',
        'bio': 'Hey there! I am using CRUDify',
        'photoURL': user.photoURL ?? '',
        'createdAt': FieldValue.serverTimestamp(),
      });
    }

    // Navigate to ProductListScreen
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => ProductListScreen()),
    );

    return _userFromFirebaseUser(user);

  } on FirebaseAuthException catch (e) {
    print('Firebase Auth Error during Google Sign In: ${e.code}');
    
    String errorMessage;
    switch (e.code) {
      case 'account-exists-with-different-credential':
        errorMessage = 'An account already exists with a different credential';
        break;
      case 'invalid-credential':
        errorMessage = 'Invalid Google Sign In credentials';
        break;
      case 'operation-not-allowed':
        errorMessage = 'Google Sign In is not enabled for this project';
        break;
      default:
        errorMessage = 'Google Sign In failed: ${e.message}';
    }
    
    // Show error dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Error'),
        content: Text(errorMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    return null;
  } catch (e) {
    print('Unexpected Google Sign In Error: $e');
    
    // Show generic error dialog
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign In Error'),
        content: Text('An unexpected error occurred: ${e.toString()}'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
    
    return null;
  }
}
  
  Future<void> signOut(BuildContext context) async {
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );

    // Cancel all listeners before logout
    await _firestoreService.cancelAllSubscriptions();

    // Logout from Google if user used Google Sign-In
    if (await _googleSignIn.isSignedIn()) {
      await _googleSignIn.signOut();
    }

    // Logout from Firebase
    await _auth.signOut();

    print('User signed out successfully');

    // Make sure the app returns to the login page
    if (context.mounted) {
      Navigator.of(context).pop(); // Close the loading dialog
      
      // Navigate back to Authenticate screen instead of using named route
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const ProductListScreen()),
        (route) => false,
      );
    }
  } catch (e) {
    print('Sign out error: $e');
    if (context.mounted) {
      Navigator.of(context).pop();
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Sign Out Error'),
          content: Text(e.toString()),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    }
  }
}

Future<void> resetPassword(String email) async {
  try {
    await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
    // Remove the throw UnimplementedError line - this was causing the failure
  } catch (e) {
    print('Password reset error: $e');
    // Re-throw the error with more specific handling if needed
    if (e is FirebaseAuthException) {
      // You can add specific handling for different error codes here
      throw e;
    } else {
      throw Exception('Failed to send password reset email');
    }
  }
}

Future<void> changePassword({
  required String currentPassword,
  required String newPassword,
}) async {
  try {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) throw Exception('User not logged in');
    
    if (user.email == null) throw Exception('No email associated with account');

    // Reauthenticate user
    final cred = EmailAuthProvider.credential(
      email: user.email!,
      password: currentPassword,
    );
    await user.reauthenticateWithCredential(cred);
    
    // Validate new password meets requirements
    if (newPassword.length < 6) {
      throw Exception('Password must be at least 6 characters');
    }
    if (!RegExp(r'[A-Z]').hasMatch(newPassword)) {
      throw Exception('Password must contain at least one uppercase letter');
    }
    if (!RegExp(r'[0-9]').hasMatch(newPassword)) {
      throw Exception('Password must contain at least one number');
    }
    
    // Update password
    await user.updatePassword(newPassword);
    
    // Optional: Send email notification about password change
    await user.sendEmailVerification();
  } on FirebaseAuthException catch (e) {
    String errorMessage;
    switch (e.code) {
      case 'wrong-password':
        errorMessage = 'Current password is incorrect';
        break;
      case 'weak-password':
        errorMessage =
            'New password is too weak. Use at least 6 characters with a mix of letters and numbers';
        break;
      case 'requires-recent-login':
        errorMessage =
            'This operation is sensitive and requires recent authentication. Please log in again';
        break;
      default:
        errorMessage = 'Failed to change password: ${e.message}';
    }
    throw Exception(errorMessage);
  } catch (e) {
    rethrow;
  }
}

Future<void> changeEmail({required String newEmail, required String password}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not logged in');
  
  // Reauthenticate
  final cred = EmailAuthProvider.credential(
    email: user.email!,
    password: password,
  );
  await user.reauthenticateWithCredential(cred);
  
  // Update email
  await user.verifyBeforeUpdateEmail(newEmail);
}

Future<void> deleteAccount({required String password}) async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) throw Exception('User not logged in');
  
  // Reauthenticate first
  final cred = EmailAuthProvider.credential(
    email: user.email!,
    password: password,
  );
  await user.reauthenticateWithCredential(cred);
  
  await user.delete();
}
}