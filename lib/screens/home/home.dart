import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../services/auth_service.dart';
import '../../services/database_service.dart';
import '../../services/theme_service.dart';
import '../../services/analytics_service.dart';
import '../models/user_model.dart';
import 'profile.dart';
import '../product/product_list_screen.dart';

class Home extends StatefulWidget {
  const Home({super.key});
  
  @override
  _HomeState createState() => _HomeState();
}

class _HomeState extends State<Home> {
  @override
  Widget build(BuildContext context) {
    return Consumer<AuthService>(
      builder: (context, authService, _) {
        return StreamBuilder<UserModel?>(
          stream: authService.user,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
            
            if (snapshot.hasError) {
              return Scaffold(
                body: Center(child: Text('Error: ${snapshot.error}')),
              );
            }
            
            final currentUser = snapshot.data;
            if (currentUser == null) {
              return const Scaffold(
                body: Center(child: Text('Please log in')),
              );
            }
            
            return StreamProvider<UserData>.value(
            value: DatabaseService(id: currentUser.uid).userData,
            initialData: UserData(
              uid: currentUser.uid, 
              name: '', 
              bio: '', 
              photoURL: '',
              points: 0,
              redeemedPoints: 0,
              redeemedRewards: [],
              lastUpdated: DateTime.now(),
            ),
            catchError: (_, err) => UserData(
              uid: currentUser.uid, 
              name: 'Error', 
              bio: err.toString(), 
              photoURL: '',
              points: 0,
              redeemedPoints: 0,
              redeemedRewards: [],
              lastUpdated: DateTime.now(),
            ),
            child: ProfileScreen(),
           );
          },
        );
      },
    );
  }
}

class ProfileScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: themeService.isDarkMode ? Colors.brown : Colors.brown,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => ProductListScreen())
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => SettingsScreen())
            ),
            tooltip: 'Settings',
          ),
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _showLogoutDialog(context),
          ),
        ],
      ),
      body: const Profile(),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout', style: TextStyle(color: Colors.brown),),
        content: const Text('Are you sure you want to logout?', style: TextStyle(color: Colors.grey),),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.grey),),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await authService.signOut(context);
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Logout failed: $e')),
                );
              }
            },
            child: const Text('Logout', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

class SettingsScreen extends StatefulWidget {
  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  bool _notificationsEnabled = false;
  bool _darkModeEnabled = false;
  bool _analyticsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadInitialSettings();
  }

  Future<void> _loadInitialSettings() async {
    final themeService = Provider.of<ThemeService>(context, listen: false);
    final analyticsService = Provider.of<AnalyticsService>(context, listen: false);
    
    setState(() {
      _darkModeEnabled = themeService.isDarkMode;
      _analyticsEnabled = analyticsService.enabled;
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    final analyticsService = Provider.of<AnalyticsService>(context);
    final authService = Provider.of<AuthService>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: themeService.isDarkMode ? Colors.brown : Colors.brown,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionHeader('Account Settings', themeService),
            _buildSettingsCard(
              children: [
                _buildListTile(
                  icon: Icons.email,
                  title: 'Change Email',
                  subtitle: 'Update your email address',
                  onTap: () => _showEmailChangeDialog(context),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.lock,
                  title: 'Change Password',
                  subtitle: 'Update your account password',
                  onTap: () => _showPasswordChangeDialog(context),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('App Settings', themeService),
            _buildSettingsCard(
              children: [
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.dark_mode,
                  title: 'Dark Mode',
                  subtitle: 'Toggle dark theme',
                  value: _darkModeEnabled,
                  onChanged: (value) async {
                    setState(() => _darkModeEnabled = value);
                    await themeService.toggleTheme();
                  },
                ),
                const Divider(height: 1),
                _buildSwitchTile(
                  icon: Icons.analytics,
                  title: 'Analytics',
                  subtitle: 'Share usage data',
                  value: _analyticsEnabled,
                  onChanged: (value) async {
                    setState(() => _analyticsEnabled = value);
                    await analyticsService.toggleAnalytics(value);
                  },
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('Privacy', themeService),
            _buildSettingsCard(
              children: [
                _buildListTile(
                  icon: Icons.security,
                  title: 'Privacy Policy',
                  subtitle: 'View our privacy policy',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PrivacyPolicyScreen()),
                  ),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.description,
                  title: 'Terms of Service',
                  subtitle: 'View our terms and conditions',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => TermsOfServiceScreen()),
                  ),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.delete,
                  title: 'Delete Account',
                  subtitle: 'Permanently delete your account',
                  onTap: () => _showDeleteAccountDialog(context, authService),
                ),
              ],
            ),

            const SizedBox(height: 24),
            _buildSectionHeader('About', themeService),
            _buildSettingsCard(
              children: [
                _buildListTile(
                  icon: Icons.help,
                  title: 'Help & Support',
                  subtitle: 'Get help with the app',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => HelpScreen()),
                  ),
                ),
                const Divider(height: 1),
                _buildListTile(
                  icon: Icons.info,
                  title: 'About App',
                  subtitle: 'Version 1.0.0',
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => AboutScreen()),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, ThemeService themeService) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
        ),
      ),
    );
  }

  Widget _buildSettingsCard({required List<Widget> children}) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: children),
    );
  }

  Widget _buildListTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.brown),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right, color: Colors.grey),
      onTap: onTap,
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return ListTile(
      leading: Icon(icon, color: Colors.brown),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500)),
      subtitle: Text(subtitle),
      trailing: Switch(
        value: value,
        onChanged: onChanged,
        activeColor: Colors.brown,
      ),
    );
  }

  void _showEmailChangeDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final _emailController = TextEditingController();
    final _passwordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    String _errorMessage = '';
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Change Email'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _emailController,
                    decoration: const InputDecoration(
                      labelText: 'New Email',
                      prefixIcon: Icon(Icons.email),
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter an email';
                      if (!value.contains('@')) return 'Enter a valid email';
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter your password' : null,
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = '';
                          });
                          try {
                            await authService.changeEmail(
                              newEmail: _emailController.text,
                              password: _passwordController.text,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Verification email sent!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            setState(() {
                              _errorMessage = e.toString().replaceAll('Exception: ', '');
                              _isLoading = false;
                            });
                          }
                        }
                      },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showPasswordChangeDialog(BuildContext context) {
    final authService = Provider.of<AuthService>(context, listen: false);
    final _currentPasswordController = TextEditingController();
    final _newPasswordController = TextEditingController();
    final _confirmPasswordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    String _errorMessage = '';
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Change Password'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _currentPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Current Password',
                      prefixIcon: Icon(Icons.lock_outline),
                    ),
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter current password' : null,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _newPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'New Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value == null || value.isEmpty) return 'Enter new password';
                      if (value.length < 6) return 'Minimum 6 characters';
                      if (!RegExp(r'[A-Z]').hasMatch(value)) {
                        return 'At least 1 uppercase letter';
                      }
                      if (!RegExp(r'[0-9]').hasMatch(value)) {
                        return 'At least 1 number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmPasswordController,
                    decoration: const InputDecoration(
                      labelText: 'Confirm New Password',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) {
                      if (value != _newPasswordController.text) {
                        return 'Passwords do not match';
                      }
                      return null;
                    },
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = '';
                          });
                          try {
                            await authService.changePassword(
                              currentPassword: _currentPasswordController.text,
                              newPassword: _newPasswordController.text,
                            );
                            Navigator.pop(context);
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Password changed successfully!'),
                                duration: Duration(seconds: 2),
                              ),
                            );
                          } catch (e) {
                            setState(() {
                              _errorMessage = e.toString().replaceAll('Exception: ', '');
                              _isLoading = false;
                            });
                          }
                        }
                      },
                child: const Text('Update'),
              ),
            ],
          );
        },
      ),
    );
  }

  void _showDeleteAccountDialog(BuildContext context, AuthService authService) {
    final _passwordController = TextEditingController();
    final _formKey = GlobalKey<FormState>();
    String _errorMessage = '';
    bool _isLoading = false;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) {
          return AlertDialog(
            title: const Text('Delete Account'),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'This will permanently delete your account and all data. This action cannot be undone.',
                    style: TextStyle(color: Colors.red),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(
                      labelText: 'Enter Password to Confirm',
                      prefixIcon: Icon(Icons.lock),
                    ),
                    obscureText: true,
                    validator: (value) =>
                        value == null || value.isEmpty ? 'Enter your password' : null,
                  ),
                  if (_errorMessage.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        _errorMessage,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  if (_isLoading)
                    const Padding(
                      padding: EdgeInsets.only(top: 8),
                      child: CircularProgressIndicator(),
                    ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.red,
                ),
                onPressed: _isLoading
                    ? null
                    : () async {
                        if (_formKey.currentState!.validate()) {
                          setState(() {
                            _isLoading = true;
                            _errorMessage = '';
                          });
                          try {
                            await authService.deleteAccount(
                              password: _passwordController.text,
                            );
                            Navigator.popUntil(context, (route) => route.isFirst);
                          } catch (e) {
                            setState(() {
                              _errorMessage = e.toString().replaceAll('Exception: ', '');
                              _isLoading = false;
                            });
                          }
                        }
                      },
                child: const Text('Delete Account', style: TextStyle(color: Colors.white)),
              ),
            ],
          );
        },
      ),
    );
  }
}

class PrivacyPolicyScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
        backgroundColor: themeService.isDarkMode ? Colors.grey[900] : Colors.brown,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Privacy Policy',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: themeService.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Last Updated: January 1, 2025',
              style: TextStyle(
                color: themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'This Privacy Policy describes how your personal information is collected, used, and shared when you use our application.\n\n'
              '1. Information We Collect\n'
              'We collect personal information you provide, including:\n'
              '- Email address\n'
              '- Profile information\n'
              '- Usage data\n\n'
              '2. How We Use Your Information\n'
              'We use the information to:\n'
              '- Provide and maintain our service\n'
              '- Notify you about changes\n'
              '- Provide customer support\n'
              '- Improve our application\n\n'
              '3. Sharing Your Information\n'
              'We do not sell your personal information. We may share data with:\n'
              '- Service providers\n'
              '- Business transfers\n'
              '- Legal requirements\n\n'
              '4. Security\n'
              'We implement security measures to protect your data.\n\n'
              '5. Changes\n'
              'We may update this policy periodically.',
              style: TextStyle(
                fontSize: 16, 
                height: 1.5,
                color: themeService.isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TermsOfServiceScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
        backgroundColor: themeService.isDarkMode ? Colors.grey[900] : Colors.brown,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Terms of Service',
              style: TextStyle(
                fontSize: 24, 
                fontWeight: FontWeight.bold,
                color: themeService.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Last Updated: January 1, 2025',
              style: TextStyle(
                color: themeService.isDarkMode ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              '1. Acceptance of Terms\n'
              'By accessing or using the CCWC Cafe app, you agree to be bound by these Terms of Service.\n\n'
              '2. Description of Service\n'
              'CCWC Cafe provides a mobile application for browsing and ordering cafe products.\n\n'
              '3. User Accounts\n'
              'You are responsible for maintaining the confidentiality of your account and password.\n\n'
              '4. User Conduct\n'
              'You agree not to use the service to:\n'
              '- Violate any laws\n'
              '- Infringe on intellectual property rights\n'
              '- Transmit harmful or offensive content\n\n'
              '5. Payment and Fees\n'
              'All transactions are final. Refunds are subject to our refund policy.\n\n'
              '6. Termination\n'
              'We may terminate or suspend your account for violation of these terms.\n\n'
              '7. Disclaimer of Warranties\n'
              'The service is provided "as is" without warranties of any kind.\n\n'
              '8. Limitation of Liability\n'
              'CCWC Cafe shall not be liable for any indirect, incidental damages.\n\n'
              '9. Changes to Terms\n'
              'We may modify these terms at any time. Continued use constitutes acceptance.\n\n'
              '10. Governing Law\n'
              'These terms shall be governed by the laws of Indonesia.',
              style: TextStyle(
                fontSize: 16, 
                height: 1.5,
                color: themeService.isDarkMode ? Colors.grey[300] : Colors.grey[800],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class HelpScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Help & Support'),
        backgroundColor: themeService.isDarkMode ? Colors.grey[900] : Colors.brown,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            _buildHelpCard(
              title: 'Getting Started',
              content: 'Learn how to set up your account and use basic features.',
              themeService: themeService,
            ),
            _buildHelpCard(
              title: 'Account Issues',
              content: 'Troubleshoot login, password, and account problems.',
              themeService: themeService,
            ),
            _buildHelpCard(
              title: 'App Features',
              content: 'Understand all the features available in the app.',
              themeService: themeService,
            ),
            _buildHelpCard(
              title: 'Contact Support',
              content: 'Reach out to our support team for personalized help.',
              isContact: true,
              themeService: themeService,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHelpCard({
    required String title,
    required String content,
    bool isContact = false,
    required ThemeService themeService,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      color: themeService.isDarkMode ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 18, 
                fontWeight: FontWeight.bold,
                color: themeService.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              content,
              style: TextStyle(
                color: themeService.isDarkMode ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
            if (isContact) ...[
              const SizedBox(height: 16),
              Text(
                'Email: codewithandi@gmail.com',
                style: TextStyle(
                  color: themeService.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              Text(
                'Phone: +62-89699293319',
                style: TextStyle(
                  color: themeService.isDarkMode ? Colors.grey[300] : Colors.grey[700],
                ),
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

class AboutScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final themeService = Provider.of<ThemeService>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('About'),
        backgroundColor: themeService.isDarkMode ? Colors.grey[900] : Colors.brown,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundImage: AssetImage('assets/logo/ccwc_cafe_no_bg.png'),
              backgroundColor: Colors.transparent,
            ),
            const SizedBox(height: 20),
            Text(
              'CCWC Cafe',
              style: TextStyle(
                fontSize: 28, 
                fontWeight: FontWeight.bold,
                color: themeService.isDarkMode ? Colors.white : Colors.black,
              ),
            ),
            Text(
              'Version 1.0.0',
              style: TextStyle(
                fontSize: 16, 
                color: themeService.isDarkMode ? Colors.grey[400] : Colors.grey,
              ),
            ),
            const SizedBox(height: 30),
            Text(
              '© 2025 CCWC Cafe Inc.',
              style: TextStyle(
                fontSize: 14,
                color: themeService.isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            Text(
              'All rights reserved',
              style: TextStyle(
                fontSize: 14,
                color: themeService.isDarkMode ? Colors.grey[400] : Colors.grey[700],
              ),
            ),
            const SizedBox(height: 30),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => TermsOfServiceScreen()),
              ),
              child: Text(
                'View Terms of Service',
                style: TextStyle(
                  color: themeService.isDarkMode ? Colors.blue[300] : Colors.blue,
                ),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => PrivacyPolicyScreen()),
              ),
              child: Text(
                'View Privacy Policy',
                style: TextStyle(
                  color: themeService.isDarkMode ? Colors.blue[300] : Colors.blue,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}