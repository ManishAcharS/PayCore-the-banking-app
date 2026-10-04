import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';
import '../services/auth_service.dart';
import 'login_screen.dart';
import 'home_screen.dart';
import 'set_pin_screen.dart';
import '../services/api_service.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  final LocalAuthentication auth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    final authService = Provider.of<AuthService>(context, listen: false);
    await authService.loadFromPrefs();
    Timer(const Duration(seconds: 2), () {
      if (authService.isAuthenticated) {
        _checkBiometric();
      } else {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const LoginScreen()));
      }
    });
  }

  Future<void> _checkBiometric() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      if (canCheck) {
        final didAuthenticate = await auth.authenticate(
          localizedReason: 'Authenticate to access PayCore',
          options: const AuthenticationOptions(biometricOnly: false),
        );
        if (didAuthenticate) {
          _navigateToHome();
          return;
        }
      }
    } catch (e) {
      // fall through
    }
    _navigateToHome();
  }

  void _navigateToHome() {
    Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomeScreen()));
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_balance_wallet, size: 80, color: Colors.blue),
            SizedBox(height: 16),
            Text('PayCore', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            SizedBox(height: 8),
            Text('Banking & Payments Demo', style: TextStyle(color: Colors.grey)),
          ],
        ),
      ),
    );
  }
}
