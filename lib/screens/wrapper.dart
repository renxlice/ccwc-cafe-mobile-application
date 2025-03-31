import 'package:crudify/screens/auth/authenticate.dart';
import 'package:crudify/screens/product/product_list_screen.dart';
import 'package:crudify/screens/auth/authenticate.dart';
import 'package:crudify/services/auth_service.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/cart_service.dart';
import 'models/user_model.dart';
import '../screens/home/home.dart'; 

class Wrapper extends StatelessWidget {
  const Wrapper({super.key});

  @override
  Widget build(BuildContext context) {
    // Listen to auth state changes from Firebase
    final authService = AuthService();
    
    return MultiProvider(
      providers: [
        StreamProvider<UserModel?>.value(
          value: authService.user, // This should be a Stream<UserModel?> in your AuthService
          initialData: null,
          catchError: (_, __) => null,
        ),
        Provider<CartService>(
          create: (_) => CartService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          primarySwatch: Colors.blue,
          visualDensity: VisualDensity.adaptivePlatformDensity,
        ),
        home: AuthenticationWrapper(),
      ),
    );
  }
}

// Create a separate widget to handle authentication state
class AuthenticationWrapper extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final user = Provider.of<UserModel?>(context);
    
    // Return Home if user is logged in, otherwise return Authenticate screen
    return user != null ? Home() : Authenticate(); // Replace with your actual screen names
  }
}