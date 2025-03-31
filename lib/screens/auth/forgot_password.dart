import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final Function toggleView;
  
  const ForgotPasswordScreen({super.key, required this.toggleView});
  
  @override
  _ForgotPasswordScreenState createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  
  String email = '';
  String message = '';
  bool isSuccess = false;
  
  void _resetPassword() async {
  if (_formKey.currentState!.validate()) {
    setState(() {
      loading = true;
      message = ''; // Clear previous messages
    });

    try {
      await _auth.resetPassword(email);
      setState(() {
        message = 'Password reset email sent to $email. Check your inbox.';
        isSuccess = true;
        loading = false;
      });
    } catch (e) {
      String errorMessage = 'Failed to send reset email. Please try again.';
      
      if (e is FirebaseAuthException) {
        switch (e.code) {
          case 'user-not-found':
            errorMessage = 'No user found with this email address.';
            break;
          case 'invalid-email':
            errorMessage = 'The email address is not valid.';
            break;
          case 'too-many-requests':
            errorMessage = 'Too many requests. Try again later.';
            break;
          default:
            errorMessage = 'An error occurred. Please try again.';
        }
      }
      
      setState(() {
        message = errorMessage;
        isSuccess = false;
        loading = false;
      });
    }
  }
}
  
  @override
  Widget build(BuildContext context) {
    return loading 
      ? const Loading() 
      : Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      body: SafeArea(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Center(
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20.0),
                  Icon(
                    Icons.lock_reset,
                    size: 80.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20.0),
                  const Text(
                    'Reset Password',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  const Text(
                    'Enter your email to reset your password',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40.0),
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Email',
                            prefixIcon: Icon(Icons.email_outlined),
                          ),
                          style: TextStyle(color: Colors.brown),
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Enter an email';
                            } else if (!val.contains('@')) {
                              return 'Email must contain @';
                            } else if (!RegExp(r"^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$").hasMatch(val)) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                          onChanged: (val) {
                            setState(() => email = val);
                          },
                        ),
                        const SizedBox(height: 20.0),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: _resetPassword,
                          child: const Text(
                            'RESET PASSWORD',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        if (message.isNotEmpty)
                          Text(
                            message,
                            style: TextStyle(
                              color: isSuccess ? Colors.green : Colors.red,
                              fontSize: 14.0,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        const SizedBox(height: 20.0),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Remember your password?", style: TextStyle(color: Colors.grey),),
                            TextButton(
                              onPressed: () {
                                widget.toggleView();
                              },
                              child: const Text(
                                'Sign In',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown,
                                ),
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
        ),
      ),
    );
  }
}