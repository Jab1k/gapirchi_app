import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'config/themes.dart';
import 'providers/auth_provider.dart';
import 'providers/radio_provider.dart'; // <--- Импорт
import 'screens/auth/phone_input_screen.dart';
import 'screens/main/radio_screen.dart'; // <--- Импорт
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Простая проверка, был ли вход ранее
  final prefs = await SharedPreferences.getInstance();
  final bool isLoggedIn = prefs.containsKey('token');

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;
  const MyApp({super.key, required this.isLoggedIn});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => RadioProvider()),
      ],
      child: MaterialApp(
        title: 'Gapirchi',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.darkTheme,
        // Если уже вошли -> Рация, иначе -> Ввод номера
        home: isLoggedIn ? const PhoneInputScreen() : const PhoneInputScreen(),
      ),
    );
  }
}
