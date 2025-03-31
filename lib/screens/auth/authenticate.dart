import 'package:flutter/material.dart';
import 'sign_in.dart';
import 'register.dart';
import 'forgot_password.dart';  

class Authenticate extends StatefulWidget {
  const Authenticate({super.key});

  @override
  _AuthenticateState createState() => _AuthenticateState();
}

class _AuthenticateState extends State<Authenticate> {
  int currentView = 0;  // 0: SignIn, 1: Register, 2: ForgotPassword
  
  void toggleView() {
    setState(() {
      // Cycle through SignIn and Register
      currentView = (currentView + 1) % 2;
    });
  }

  void navigateToForgotPassword() {
    setState(() {
      currentView = 2;
    });
  }

  void returnToSignIn() {
    setState(() {
      currentView = 0;
    });
  }
  
  @override
  Widget build(BuildContext context) {
    switch (currentView) {
      case 0:
        return SignIn(
          toggleView: toggleView, 
          navigateToForgotPassword: navigateToForgotPassword
        );
      case 1:
        return Register(toggleView: toggleView);
      case 2:
        return ForgotPasswordScreen(toggleView: returnToSignIn);
      default:
        return SignIn(
          toggleView: toggleView, 
          navigateToForgotPassword: navigateToForgotPassword
        );
    }
  }
}