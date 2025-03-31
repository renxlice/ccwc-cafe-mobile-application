import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'services/auth_service.dart';
import 'services/cart_service.dart';
import 'services/firestore_service.dart';
import 'services/theme_service.dart';
import 'services/analytics_service.dart';
import 'screens/auth/authenticate.dart';
import 'screens/product/product_list_screen.dart';
import 'screens/product/product_detail_screen.dart';
import 'screens/models/user_model.dart';
import 'screens/models/product_model.dart';
import 'widgets/loading.dart';
import 'services/loyalty_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await _initializeApp();
  runApp(const MyApp());
}

Future<void> _initializeApp() async {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  await Firebase.initializeApp();
  FirestoreService();
  SystemChannels.textInput.invokeMethod('TextInput.setImeTransitionAnimationDuration', 0);
}

class MyApp extends StatefulWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final FirestoreService _firestoreService = FirestoreService();
  final AuthService _authService = AuthService();
  final ThemeService _themeService = ThemeService();
  final AnalyticsService _analyticsService = AnalyticsService();

  @override
  void initState() {
    super.initState();
    _initializeServices();
  }

  Future<void> _initializeServices() async {
    FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        _firestoreService.cancelAllSubscriptions();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AuthService>.value(value: _authService),
        StreamProvider<UserModel?>.value(
          value: _authService.user,
          initialData: null,
        ),
        ChangeNotifierProvider(create: (_) => CartService()),
        ChangeNotifierProvider(create: (_) => _themeService),
        Provider<FirestoreService>.value(value: _firestoreService),
        Provider<AnalyticsService>.value(value: _analyticsService),
        Provider<LoyaltyService>(create: (_) => LoyaltyService()),
      ],
      child: Consumer<ThemeService>(
        builder: (context, themeService, child) {
          return MaterialApp(
            title: 'CCWC Cafe',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              brightness: Brightness.light,
              textTheme: GoogleFonts.poppinsTextTheme(),
              colorScheme: ColorScheme.light(
                primary: Colors.indigo,
                secondary: Colors.tealAccent,
              ),
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
                ),
              ),
              inputDecorationTheme: InputDecorationTheme(
                filled: true,
                fillColor: Colors.grey[100],
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              textTheme: GoogleFonts.poppinsTextTheme(),
              colorScheme: ColorScheme.dark(
                primary: Colors.indigo,
                secondary: Colors.tealAccent,
              ),
            ),
            themeMode: themeService.themeMode,
            home: StreamBuilder<User?>(
              stream: FirebaseAuth.instance.authStateChanges(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Loading(
                    backgroundColor: Colors.brown,
                    loadingText: 'Loading...',
                    spinnerColor: Colors.tealAccent,
                    spinnerSize: 60.0,
                    logoSize: 300.0,
                    alignment: MainAxisAlignment.center,
                    padding: EdgeInsets.only(top: 20),
                  );
                }
                return snapshot.hasData ? ProductListScreen() : const Authenticate();
              },
            ),
            routes: {
              '/products': (context) => ProductListScreen(),
              '/product-detail': (context) {
                final args = ModalRoute.of(context)!.settings.arguments;
                if (args == null || args is! Product) {
                  return const Scaffold(
                    body: Center(child: Text('Product not found')),
                  );
                }
                return ProductDetailScreen(product: args);
              },
            },
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _firestoreService.cancelAllSubscriptions();
    super.dispose();
  }
}