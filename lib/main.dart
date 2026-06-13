import 'package:clothing/pages/bottom_nav.dart';
import 'package:clothing/pages/login.dart';
import 'package:clothing/pages/splash_screen.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp();
  FirebaseFirestore.instance.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Velora',
      debugShowCheckedModeBanner: false,
      home: const SplashScreen(), 
    );
  }
}

class AuthWrapper extends StatefulWidget {
  const AuthWrapper({super.key});

  @override
  State<AuthWrapper> createState() => _AuthWrapperState();
}

class _AuthWrapperState extends State<AuthWrapper> {
  bool? _isAuthenticated;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    try {
      final user = FirebaseAuth.instance.currentUser;

      if (user == null) {
        if (mounted) setState(() => _isAuthenticated = false);
        return;
      }
      await user.reload();
      final freshUser = FirebaseAuth.instance.currentUser;

      if (freshUser != null && freshUser.emailVerified) {
        if (mounted) setState(() => _isAuthenticated = true);
      } else {
        await FirebaseAuth.instance.signOut();
        if (mounted) setState(() => _isAuthenticated = false);
      }
    } catch (e) {
      await FirebaseAuth.instance.signOut();
      if (mounted) setState(() => _isAuthenticated = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isAuthenticated == null) {
      return const Scaffold(
        backgroundColor: Color(0xFFF7F3EF),
        body: Center(
          child: CircularProgressIndicator(color: Color(0xff6e5038)),
        ),
      );
    }

    return _isAuthenticated! ? const BottomNav() : const Login();
  }
}