import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
// Импортируем главный экран, который создадим позже
import '../main/radio_screen.dart'; 

class LoginScreen extends StatefulWidget {
  final String phoneNumber;
  const LoginScreen({super.key, required this.phoneNumber});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passController = TextEditingController();
  
  void _login() async {
    try {
      await Provider.of<AuthProvider>(context, listen: false)
          .login(widget.phoneNumber, _passController.text);
      
      if (!mounted) return;
      // Переход на главный экран рации и удаление истории назад
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RadioScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString())));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Вход")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          children: [
            Text("Номер: ${widget.phoneNumber}", style: const TextStyle(fontSize: 18, color: Colors.grey)),
            const SizedBox(height: 20),
            TextField(
              controller: _passController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Пароль", prefixIcon: Icon(Icons.lock)),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: isLoading ? null : _login,
                child: isLoading ? const CircularProgressIndicator() : const Text("Войти"),
              ),
            ),
          ],
        ),
      ),
    );
  }
}