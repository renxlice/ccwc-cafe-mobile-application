import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading.dart';

class SignIn extends StatefulWidget {
  final Function toggleView;
  final Function navigateToForgotPassword;
  
  const SignIn({
    super.key, 
    required this.toggleView, 
    required this.navigateToForgotPassword,
  });
  
  @override
  _SignInState createState() => _SignInState();
}

class _SignInState extends State<SignIn> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;
  
  // Text field state
  String email = '';
  String password = '';
  String error = '';
  
  @override
  Widget build(BuildContext context) {
    return loading ? const Loading() : Scaffold(
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
                  // Logo or icon
                  Icon(
                    Icons.account_circle,
                    size: 80.0,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 20.0),
                  // Title
                  const Text(
                    'Welcome Back',
                    style: TextStyle(
                      fontSize: 28.0,
                      fontWeight: FontWeight.bold,
                      color: Colors.brown
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8.0),
                  // Subtitle
                  const Text(
                    'Sign in to continue',
                    style: TextStyle(
                      fontSize: 16.0,
                      color: Colors.grey,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 40.0),
                  // Form
                  Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        // Email field
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
                        // Password field
                        TextFormField(
                          decoration: const InputDecoration(
                            hintText: 'Password',
                            prefixIcon: Icon(Icons.lock_outline),
                          ),
                          style: TextStyle(color: Colors.brown),
                          obscureText: true,
                          validator: (val) {
                            if (val == null || val.isEmpty) {
                              return 'Password cannot be empty';
                            } else if (val.length < 6) {
                              return 'Password must consist of at least 6 characters';
                            } else if (!RegExp(r'(?=.*?[A-Z])').hasMatch(val)) {
                              return 'Password must have at least 1 uppercase letter';
                            } else if (!RegExp(r'(?=.*?[0-9])').hasMatch(val)) {
                              return 'Password must have at least 1 number';
                            } else if (!RegExp(r'(?=.*?[!@#\$&*~])').hasMatch(val)) {
                              return 'Password must have at least 1 special character';
                            }
                            return null;
                          },
                          onChanged: (val) {
                            setState(() => password = val);
                          },
                        ),
                        // Forgot password link
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () => widget.navigateToForgotPassword(),
                            child: const Text(
                              'Forgot Password?',
                              style: TextStyle(
                                color: Colors.brown,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        // Sign in button
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                          ),
                          onPressed: () async {
                            if (_formKey.currentState!.validate()) {
                              setState(() => loading = true);
                              dynamic result = await _auth.signInWithEmailAndPassword(email, password, context);
                              if (mounted) { // Check if widget is still mounted
                                setState(() {
                                  if (result == null) {
                                    error = 'Could not sign in with those credentials';
                                  }
                                  loading = false;
                                });
                              }
                            }
                          },
                          child: const Text(
                            'SIGN IN',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown
                            ),
                          ),
                        ),
                        const SizedBox(height: 20.0),
                        // Google sign in button
                        OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            minimumSize: const Size(double.infinity, 50),
                            side: BorderSide(color: Colors.grey[400]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          icon: Image.network(
                            'https://cdn-icons-png.flaticon.com/512/2991/2991148.png',
                            height: 24.0,
                          ),
                          label: Text(
                            'SIGN IN WITH GOOGLE',
                            style: TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                              color: Colors.brown,
                            ),
                          ),
                          onPressed: () async {
                            setState(() => loading = true);
                            dynamic result = await _auth.signInWithGoogle(context);
                            if (mounted) { // Check if widget is still mounted
                              setState(() {
                                if (result == null) {
                                  error = 'Could not sign in with Google';
                                }
                                loading = false;
                              });
                            }
                          },
                        ),
                        const SizedBox(height: 12.0),
                        // Error text
                        Text(
                          error,
                          style: const TextStyle(
                            color: Colors.red,
                            fontSize: 14.0,
                          ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 20.0),
                        // Register link
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Text("Don't have an account?", style: TextStyle(color: Colors.grey),),
                            TextButton(
                              onPressed: () => widget.toggleView(),
                              child: const Text(
                                'Register',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: Colors.brown
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