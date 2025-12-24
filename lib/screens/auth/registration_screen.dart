import 'package:flutter/material.dart';
import 'package:intl/intl.dart'; // Не забудь добавить intl в pubspec.yaml
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/uzbek_license_plate.dart';
import '../../models/car_brand_model.dart';
import '../main/radio_screen.dart';

class RegistrationScreen extends StatefulWidget {
  final String phoneNumber;
  const RegistrationScreen({super.key, required this.phoneNumber});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> {
  final PageController _pageController = PageController();

  // --- Контроллеры и Ключи ---
  // Шаг 1: Личные данные
  final _step1FormKey = GlobalKey<FormState>();
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController(); // Gmail
  final _dobCtrl = TextEditingController();   // Дата рождения
  DateTime? _selectedDate;

  // Шаг 2: Машина
  // (Здесь валидация будет ручная, так как виджет кастомный)
  final _plateRegionCtrl = TextEditingController();
  final _plateSeriesCtrl = TextEditingController();
  final _plateNumberCtrl = TextEditingController();
  final _plateSuffixCtrl = TextEditingController();
  CarBrand? _selectedBrand;

  // Шаг 3: Пароль
  final _step3FormKey = GlobalKey<FormState>();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  bool _obscurePass = true;

  // Шаг 4: Соглашения
  bool _acceptedPolicy = false;

  @override
  void dispose() {
    _pageController.dispose();
    _firstNameCtrl.dispose(); _lastNameCtrl.dispose();
    _emailCtrl.dispose(); _dobCtrl.dispose();
    _plateRegionCtrl.dispose(); _plateSeriesCtrl.dispose();
    _plateNumberCtrl.dispose(); _plateSuffixCtrl.dispose();
    _passCtrl.dispose(); _confirmPassCtrl.dispose();
    super.dispose();
  }

  // --- Логика переходов ---

  void _nextPage() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    FocusScope.of(context).unfocus();
  }

  void _previousPage() {
    _pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
    FocusScope.of(context).unfocus();
  }

  // --- Валидаторы ---

  void _validateAndNextStep1() {
    if (_step1FormKey.currentState!.validate()) {
      _nextPage();
    }
  }

  void _validateAndNextStep2() {
    // 1. Проверка бренда
    if (_selectedBrand == null) {
      _showError("Выберите марку автомобиля");
      return;
    }
    // 2. Проверка номера (70 A 123 AA)
    if (_plateRegionCtrl.text.length != 2) {
      _showError("Код региона должен быть 2 цифры (например, 70)");
      return;
    }
    if (_plateSeriesCtrl.text.isEmpty) {
      _showError("Введите серию номера (например, A)");
      return;
    }
    if (_plateNumberCtrl.text.length != 3) {
      _showError("Номер должен состоять из 3 цифр");
      return;
    }
    if (_plateSuffixCtrl.text.length != 2) {
      _showError("Суффикс должен быть 2 буквы (например, AA)");
      return;
    }

    _nextPage();
  }

  void _validateAndNextStep3() {
    if (_step3FormKey.currentState!.validate()) {
      _nextPage();
    }
  }

  // --- Финальная отправка ---

  void _finish() async {
    if (!_acceptedPolicy) {
      _showError("Вы должны принять условия использования");
      return;
    }

    // Собираем полный номер: 70 A 123 AA
    String fullCarNumber =
        "${_plateRegionCtrl.text} ${_plateSeriesCtrl.text} ${_plateNumberCtrl.text} ${_plateSuffixCtrl.text}"
            .toUpperCase();

    final data = {
      "phoneNumber": widget.phoneNumber,
      "email": _emailCtrl.text.trim(),
      "firstName": _firstNameCtrl.text.trim(),
      "lastName": _lastNameCtrl.text.trim(),
      "birthDate": _selectedDate?.toIso8601String(), // Отправляем как ISO строку
      "password": _passCtrl.text,
      "carBrandId": _selectedBrand?.id,
      "carNumber": fullCarNumber,
      // "photo": "base64_string_or_url" // Если будет фото
    };

    try {
      await Provider.of<AuthProvider>(context, listen: false).register(data);
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RadioScreen()),
        (route) => false,
      );
    } catch (e) {
      _showError("Ошибка: ${e.toString().replaceAll('Exception: ', '')}");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  // --- Выбор даты ---
  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(2000),
      firstDate: DateTime(1950),
      lastDate: DateTime(now.year - 16), // Водитель должен быть старше 16?
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dobCtrl.text = DateFormat('dd.MM.yyyy').format(picked);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Регистрация"),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            // Если мы не на первой странице, возвращаемся назад в PageView
            if (_pageController.hasClients && _pageController.page! > 0) {
              _previousPage();
            } else {
              Navigator.pop(context);
            }
          },
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: AnimatedBuilder(
            animation: _pageController,
            builder: (ctx, _) {
              double percent = 0.2;
              if (_pageController.hasClients) {
                percent = ((_pageController.page ?? 0) + 1) / 4;
              }
              return LinearProgressIndicator(
                value: percent,
                backgroundColor: Colors.grey[200],
                color: const Color(0xFF00C853),
                minHeight: 4,
              );
            },
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics: const NeverScrollableScrollPhysics(), // Блокируем свайп рукой
        children: [
          _step1Personal(),
          _step2Car(),
          _step3Password(),
          _step4Review(),
        ],
      ),
    );
  }

  // --- UI ШАГОВ ---

  Widget _step1Personal() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step1FormKey,
        child: Column(
          children: [
            const Text("Личные данные", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 20),
            
            // Фото (Заглушка)
            GestureDetector(
              onTap: () {
                _showError("Функция добавления фото в разработке"); 
                // Сюда потом подключишь image_picker
              },
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                child: const Icon(Icons.camera_alt, size: 40, color: Colors.grey),
              ),
            ),
            const SizedBox(height: 20),

            TextFormField(
              controller: _firstNameCtrl,
              decoration: const InputDecoration(labelText: "Имя", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Введите имя" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _lastNameCtrl,
              decoration: const InputDecoration(labelText: "Фамилия", border: OutlineInputBorder()),
              validator: (v) => v!.isEmpty ? "Введите фамилию" : null,
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(labelText: "Gmail", border: OutlineInputBorder()),
              validator: (v) {
                if (v!.isEmpty) return "Введите Email";
                if (!v.contains('@')) return "Некорректный Email";
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _dobCtrl,
              readOnly: true,
              onTap: _pickDate,
              decoration: const InputDecoration(
                labelText: "Дата рождения", 
                border: OutlineInputBorder(),
                suffixIcon: Icon(Icons.calendar_today),
              ),
              validator: (v) => v!.isEmpty ? "Выберите дату рождения" : null,
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndNextStep1,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text("Далее"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step2Car() {
    final brands = Provider.of<AuthProvider>(context, listen: false).availableBrands;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Text("Ваш транспорт", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 30),

          DropdownButtonFormField<CarBrand>(
            decoration: const InputDecoration(labelText: "Выберите марку", border: OutlineInputBorder()),
            items: brands.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
            onChanged: (val) => setState(() => _selectedBrand = val),
            value: _selectedBrand,
          ),
          const SizedBox(height: 30),

          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Гос. номер (UZ):", style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          const SizedBox(height: 10),

          UzbekLicensePlateInput(
            regionController: _plateRegionCtrl,
            lettersController: _plateSeriesCtrl,
            numbersController: _plateNumberCtrl,
            suffixController: _plateSuffixCtrl,
          ),
          
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _validateAndNextStep2,
              style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
              child: const Text("Далее"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _step3Password() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _step3FormKey,
        child: Column(
          children: [
            const Text("Безопасность", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            const SizedBox(height: 30),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              decoration: InputDecoration(
                labelText: "Пароль",
                border: const OutlineInputBorder(),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? Icons.visibility : Icons.visibility_off),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              validator: (v) {
                if (v == null || v.isEmpty) return "Придумайте пароль";
                if (v.length < 6) return "Минимум 6 символов";
                return null;
              },
            ),
            const SizedBox(height: 15),
            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: _obscurePass,
              decoration: const InputDecoration(
                labelText: "Повторите пароль",
                border: OutlineInputBorder(),
              ),
              validator: (v) {
                if (v != _passCtrl.text) return "Пароли не совпадают";
                return null;
              },
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _validateAndNextStep3,
                style: ElevatedButton.styleFrom(padding: const EdgeInsets.symmetric(vertical: 15)),
                child: const Text("Далее"),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _step4Review() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          const Icon(Icons.verified_user_outlined, size: 80, color: Color(0xFF00C853)),
          const SizedBox(height: 20),
          const Text("Итоговая проверка", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
          const SizedBox(height: 20),
          
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              children: [
                _infoRow("Телефон", widget.phoneNumber),
                const Divider(),
                _infoRow("ФИО", "${_firstNameCtrl.text} ${_lastNameCtrl.text}"),
                _infoRow("Email", _emailCtrl.text),
                _infoRow("Д.Р.", _dobCtrl.text),
                const Divider(),
                _infoRow("Авто", _selectedBrand?.name ?? "-"),
                _infoRow("Номер", 
                  "${_plateRegionCtrl.text} ${_plateSeriesCtrl.text} ${_plateNumberCtrl.text} ${_plateSuffixCtrl.text}".toUpperCase()
                ),
              ],
            ),
          ),
          
          const Spacer(),

          // Privacy Policy
          Row(
            children: [
              Checkbox(
                value: _acceptedPolicy,
                activeColor: const Color(0xFF00C853),
                onChanged: (v) => setState(() => _acceptedPolicy = v!),
              ),
              Expanded(
                child: GestureDetector(
                  onTap: () {
                    // Здесь можно открыть WebView или Dialog с правилами
                    _showError("Открытие правил использования...");
                  },
                  child: const Text(
                    "Я соглашаюсь с Политикой конфиденциальности",
                    style: TextStyle(decoration: TextDecoration.underline, color: Colors.blue),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finish,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF00C853),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text("СОЗДАТЬ АККАУНТ", style: TextStyle(color: Colors.white, fontSize: 16)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}