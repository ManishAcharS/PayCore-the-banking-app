import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'services/auth_service.dart';
import 'services/api_service.dart';
import 'screens/splash_screen.dart';
import 'theme/paycore_theme.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PayCoreApp());
}

class PayCoreApp extends StatelessWidget {
  const PayCoreApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthService()),
        ChangeNotifierProvider(create: (_) => ApiService()),
      ],
      child: MaterialApp(
        title: 'PayCore',
        debugShowCheckedModeBanner: false,
        theme: PayCoreTheme.dark(),
        home: const SplashScreen(),
      ),
    );
  }
}