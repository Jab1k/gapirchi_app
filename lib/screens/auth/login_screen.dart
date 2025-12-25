import 'package:flutter/material.dart';
import 'package:gapirchi_app/screens/main_wrapper.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../main/radio_screen.dart';

class LoginScreen extends StatefulWidget {
  final String phoneNumber;
  const LoginScreen({super.key, required this.phoneNumber});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _passController = TextEditingController();
  final _formKey = GlobalKey<FormState>(); // Ключ для валидации

  void _login() async {
    if (!_formKey.currentState!.validate()) return; // Если не валидно, стоп

    try {
      await Provider.of<AuthProvider>(
        context,
        listen: false,
      ).login(widget.phoneNumber, _passController.text.trim());

      if (!mounted) return;

      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainWrapper()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''))),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Вход")),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Form(
          // Обернули в Form
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                "Ваш номер: ${widget.phoneNumber}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 30),
              TextFormField(
                controller: _passController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: "Пароль",
                  prefixIcon: Icon(Icons.lock),
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Введите пароль';
                  }
                  if (value.length < 4) {
                    return 'Пароль слишком короткий';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF00C853),
                  ),
                  onPressed: isLoading ? null : _login,
                  child: isLoading
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text(
                          "Войти",
                          style: TextStyle(color: Colors.white, fontSize: 16),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
