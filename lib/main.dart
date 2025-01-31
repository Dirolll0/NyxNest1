import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:provider/provider.dart';
import 'home_screen.dart';
import 'Auth_Screen.dart';
import 'user_provider.dart'; // Импорт UserProvider
import 'cart_provider.dart'; // Импорт CartProvider
import 'cart_screen.dart'; // Импорт экрана корзины
import 'profile_screen.dart';
import 'wishlist_screen.dart';
import 'wishlist_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Инициализация Supabase
  await Supabase.initialize(
    url: 'https://uxwbnwxwbnqxtvkjfrfe.supabase.co',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InV4d2Jud3h3Ym5xeHR2a2pmcmZlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjg0OTQzMzgsImV4cCI6MjA0NDA3MDMzOH0.lpckYPeZXSjzY_ktSy2YoBPnZli2IjOjDc24BN-fHTg',
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => CartProvider()),
        ChangeNotifierProvider(create: (_) => WishlistProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'NyxNest App',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const AuthScreen(),
      routes: {
        '/home_screen': (context) => HomeScreen(),
        '/cart_screen': (context) => const CartScreen(),
        '/wishlist_screen': (context) => WishListScreen(),
        '/profile_screen': (context) => ProfileScreen(),
      },
    );
  }
}
