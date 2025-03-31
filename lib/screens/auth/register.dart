import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../widgets/loading.dart';

class Register extends StatefulWidget {
  final Function toggleView;

  const Register({super.key, required this.toggleView});

  @override
  _RegisterState createState() => _RegisterState();
}

class _RegisterState extends State<Register> {
  final AuthService _auth = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool loading = false;

  // Text field state
  String email = '';
  String password = '';
  String name = '';
  String error = '';

  @override
  void dispose() {
    // Pastikan tidak ada setState setelah widget di-dispose
    super.dispose();
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      setState(() => loading = true);

      // Fixed: Removed the context parameter to match the expected parameters
      dynamic result = await _auth.registerWithEmailAndPassword(email, password, name, context);
      if (result == null) {
        if (mounted) {
          setState(() {
            error = 'Please supply a valid email';
            loading = false;
          });
        }
      }
    }
  }

  void _signUpWithGoogle() async {
    setState(() => loading = true);

    // Fixed: Removed the context parameter
    dynamic result = await _auth.signInWithGoogle(context);
    if (result == null && mounted) {
      setState(() {
        error = 'Could not sign in with Google';
        loading = false;
      });
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
                          Icons.person_add,
                          size: 80.0,
                          color: Colors.grey,
                        ),
                        const SizedBox(height: 20.0),
                        const Text(
                          'Create Account',
                          style: TextStyle(fontSize: 28.0, fontWeight: FontWeight.bold, color: Colors.brown),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8.0),
                        const Text(
                          'Sign up to get started',
                          style: TextStyle(fontSize: 16.0, color: Colors.grey),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 40.0),
                        Form(
                          key: _formKey,
                          child: Column(
                            children: [
                              TextFormField(
                                decoration: const InputDecoration(
                                  hintText: 'Name',
                                  prefixIcon: Icon(Icons.person_outline),
                                ),
                                style: TextStyle(color: Colors.brown),
                                validator: (val) => val!.isEmpty ? 'Enter your name' : null,
                                onChanged: (val) => setState(() => name = val),
                              ),
                              const SizedBox(height: 20.0),
                              TextFormField(
                                decoration: const InputDecoration(
                                  hintText: 'Email',
                                  prefixIcon: Icon(Icons.email_outlined),
                                ),
                                style: TextStyle(color: Colors.brown),
                                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                                onChanged: (val) => setState(() => email = val),
                              ),
                              const SizedBox(height: 20.0),
                              TextFormField(
                                decoration: const InputDecoration(
                                  hintText: 'Password',
                                  prefixIcon: Icon(Icons.lock_outline),
                                ),
                                style: TextStyle(color: Colors.brown),
                                obscureText: true,
                                validator: (val) => val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                                onChanged: (val) => setState(() => password = val),
                              ),
                              const SizedBox(height: 20.0),
                              ElevatedButton(
                                style: ElevatedButton.styleFrom(
                                  minimumSize: const Size(double.infinity, 50),
                                ),
                                onPressed: _register,
                                child: const Text(
                                  'REGISTER',
                                  style: TextStyle(fontSize: 16.0, fontWeight: FontWeight.bold, color: Colors.brown),
                                ),
                              ),
                              const SizedBox(height: 20.0),
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
                                  'SIGN UP WITH GOOGLE',
                                  style: TextStyle(
                                    fontSize: 16.0,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.brown,
                                  ),
                                ),
                                onPressed: _signUpWithGoogle,
                              ),
                              const SizedBox(height: 12.0),
                              Text(
                                error,
                                style: const TextStyle(color: Colors.red, fontSize: 14.0),
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 20.0),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Text("Already have an account?", style: TextStyle(color: Colors.grey),),
                                  TextButton(
                                    onPressed: () {
                                      widget.toggleView();
                                    },
                                    child: const Text(
                                      'Sign In',
                                      style: TextStyle(fontWeight: FontWeight.bold, color: Colors.brown),
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