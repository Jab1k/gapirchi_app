import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Нужен для фильтрации ввода цифр
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import 'login_screen.dart';
import 'registration_screen.dart';

class PhoneInputScreen extends StatefulWidget {
  const PhoneInputScreen({super.key});

  @override
  State<PhoneInputScreen> createState() => _PhoneInputScreenState();
}

class _PhoneInputScreenState extends State<PhoneInputScreen> with TickerProviderStateMixin {
  // Контроллер теперь хранит только цифры ПОСЛЕ кода +998
  final _phoneController = TextEditingController();
  
  // Переменная для отслеживания валидности номера (для показа кнопки)
  bool _isPhoneValid = false;

  // Контроллеры анимации
  late AnimationController _entryAnimationController; // Для появления экрана
  late AnimationController _btnAnimationController;   // Для появления кнопки

  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideTextAnimation;
  late Animation<Offset> _slideInputAnimation;
  late Animation<double> _scaleButtonAnimation;

  @override
  void initState() {
    super.initState();

    // --- 1. Настройка анимации появления элементов экрана ---
    _entryAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _entryAnimationController, curve: Curves.easeIn),
    );

    // Анимация заголовка
    _slideTextAnimation = Tween<Offset>(begin: const Offset(0, -0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryAnimationController, curve: const Interval(0.0, 0.6, curve: Curves.easeOutBack)),
    );

    // Анимация поля ввода (появляется чуть позже заголовка - Interval 0.3-1.0)
    _slideInputAnimation = Tween<Offset>(begin: const Offset(0, 0.5), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryAnimationController, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );

    _entryAnimationController.forward();


    // --- 2. Настройка анимации кнопки (Scale/Zoom эффект) ---
    _btnAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 500),
    );

    _scaleButtonAnimation = CurvedAnimation(
      parent: _btnAnimationController,
      curve: Curves.elasticOut, // Эффект пружины при появлении
    );

    // Слушатель ввода текста для проверки длины номера
    _phoneController.addListener(_validatePhoneInput);
  }

  void _validatePhoneInput() {
    // В Узбекистане 9 цифр после кода +998
    final isValid = _phoneController.text.length == 9;
    
    if (isValid && !_isPhoneValid) {
      setState(() => _isPhoneValid = true);
      _btnAnimationController.forward(); // Показать кнопку
    } else if (!isValid && _isPhoneValid) {
      setState(() => _isPhoneValid = false);
      _btnAnimationController.reverse(); // Скрыть кнопку
    }
  }

  @override
  void dispose() {
    _entryAnimationController.dispose();
    _btnAnimationController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (!_isPhoneValid) return; // Двойная защита

    final provider = Provider.of<AuthProvider>(context, listen: false);
    // Собираем полный номер для отправки
    final fullPhone = "+998${_phoneController.text.trim()}";

    try {
      final result = await provider.checkPhone(fullPhone);

      if (!mounted) return;

      if (result['exists'] == true) {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => LoginScreen(phoneNumber: fullPhone)),
        );
      } else {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => RegistrationScreen(phoneNumber: fullPhone)),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: ${e.toString()}")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // --- Анимированный Заголовок ---
            SlideTransition(
              position: _slideTextAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: const Text(
                  "Gapirchi",
                  style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00C853)),
                ),
              ),
            ),
            
            const SizedBox(height: 40),

            // --- Анимированное Поле Ввода ---
            SlideTransition(
              position: _slideInputAnimation,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: TextField(
                  controller: _phoneController,
                  keyboardType: TextInputType.number,
                  // Ограничиваем ввод только цифрами и макс. 9 символов
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(9),
                  ],
                  decoration: const InputDecoration(
                    labelText: "Номер телефона",
                    // prefixText делает +998 частью стиля, его нельзя стереть курсором
                    prefixText: "+998 ", 
                    prefixStyle: TextStyle(color: Colors.green, fontSize: 16, fontWeight: FontWeight.bold),
                    prefixIcon: Icon(Icons.phone),
                    border: OutlineInputBorder(),
                  ),
                ),
              ),
            ),
            
            const SizedBox(height: 20),

            // --- Анимированная Кнопка (ScaleTransition) ---
            // Используем SizeTransition или ScaleTransition, чтобы кнопка не занимала место, пока скрыта,
            // или просто была невидимой. Scale выглядит эффектнее.
            ScaleTransition(
              scale: _scaleButtonAnimation,
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: const Color(0xFF00C853), // Зеленый цвет кнопки
                  ),
                  child: isLoading
                      ? const SizedBox(
                          height: 20, 
                          width: 20, 
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                        )
                      : const Text("Продолжить", style: TextStyle(fontSize: 16, color: Colors.white)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}