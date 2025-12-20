import 'package:flutter/material.dart';
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

  // Данные
  final _firstNameCtrl = TextEditingController();
  final _lastNameCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();
  final _plateRegionCtrl = TextEditingController(); // для 70
  final _plateSeriesCtrl = TextEditingController(); // для AA
  final _plateNumberCtrl = TextEditingController(); // для 123
  final _plateSuffixCtrl = TextEditingController(); // для A

  CarBrand? _selectedBrand;
  bool _obscurePass = true;

  // Переход на след. страницу
  void _next() {
    _pageController.nextPage(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOut,
    );
    FocusScope.of(context).unfocus(); // Скрыть клавиатуру
  }

  // Финальная регистрация
  void _finish() async {
    if (_passCtrl.text != _confirmPassCtrl.text) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text("Пароли не совпадают")));
      return;
    }

    // Собираем полный номер авто: 70 A 123 AA
    String fullCarNumber =
        "${_plateRegionCtrl.text} ${_plateSeriesCtrl.text} ${_plateNumberCtrl.text} ${_plateSuffixCtrl.text}"
            .toUpperCase();

    final data = {
      "phoneNumber": widget.phoneNumber,
      "password": _passCtrl.text,
      "firstName": _firstNameCtrl.text,
      "lastName": _lastNameCtrl.text,
      "carBrandId": _selectedBrand?.id,
      "carNumber": fullCarNumber,
    };

    try {
      await Provider.of<AuthProvider>(context, listen: false).register(data);
      if (!mounted) return;
      // Успех -> Идем в рацию
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const RadioScreen()),
        (route) => false,
      );
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("Ошибка: $e")));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Регистрация"),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4.0),
          child: SizedBox(
            height: 4,
            // Индикатор прогресса (анимированная полоска)
            child: AnimatedBuilder(
              animation: _pageController,
              builder: (ctx, _) {
                double percent = 0.25;
                if (_pageController.hasClients) {
                  percent = ((_pageController.page ?? 0) + 1) / 4;
                }
                return LinearProgressIndicator(
                  value: percent,
                  backgroundColor: Colors.grey[800],
                  color: const Color(0xFF00C853),
                );
              },
            ),
          ),
        ),
      ),
      body: PageView(
        controller: _pageController,
        physics:
            const NeverScrollableScrollPhysics(), // Нельзя свайпать рукой, только кнопкой
        children: [_step1Name(), _step2Car(), _step3Password(), _step4Review()],
      ),
    );
  }

  // ШАГ 1: Имя и Фамилия
  Widget _step1Name() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.person_outline, size: 80, color: Color(0xFF00C853)),
          const SizedBox(height: 20),
          const Text(
            "Давайте знакомиться!",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          TextFormField(
            controller: _firstNameCtrl,
            decoration: const InputDecoration(labelText: "Ваше Имя"),
          ),
          const SizedBox(height: 15),
          TextFormField(
            controller: _lastNameCtrl,
            decoration: const InputDecoration(labelText: "Ваша Фамилия"),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _next, child: const Text("Далее")),
          ),
        ],
      ),
    );
  }

  // ШАГ 2: Машина
  Widget _step2Car() {
    final brands = Provider.of<AuthProvider>(
      context,
      listen: false,
    ).availableBrands;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_car, size: 80, color: Colors.orange),
          const SizedBox(height: 20),
          const Text(
            "Ошыбка при регистрации: Заполните все бланки",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.red,
            ),
          ),
          const Text(
            "Ваш автомобиль",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),

          DropdownButtonFormField<CarBrand>(
            decoration: const InputDecoration(labelText: "Выберите марку"),
            items: brands
                .map((b) => DropdownMenuItem(value: b, child: Text(b.name)))
                .toList(),
            onChanged: (val) => setState(() => _selectedBrand = val),
          ),
          const SizedBox(height: 20),
          const Align(
            alignment: Alignment.centerLeft,
            child: Text("Гос. номер:", style: TextStyle(color: Colors.grey)),
          ),
          const SizedBox(height: 10),

          // НАШ КРАСИВЫЙ ВИДЖЕТ
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
              onPressed: () {
                // print("Alek");
                print("${_selectedBrand}");
                if (_plateNumberCtrl.text.isNotEmpty ||
                    _plateRegionCtrl.text.isNotEmpty ||
                    _plateSeriesCtrl.text.isNotEmpty ||
                    _plateSuffixCtrl.text.isNotEmpty ||
                    _selectedBrand == null) {
                  print("salom");
                } else {
                  _next();
                }
              },
              child: const Text("Далее"),
            ),
          ),
        ],
      ),
    );
  }

  // ШАГ 3: Пароль
  Widget _step3Password() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.lock_outline, size: 80, color: Colors.blue),
          const SizedBox(height: 20),
          const Text(
            "Безопасность",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          TextField(
            controller: _passCtrl,
            obscureText: _obscurePass,
            decoration: InputDecoration(
              labelText: "Пароль",
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePass ? Icons.visibility : Icons.visibility_off,
                ),
                onPressed: () => setState(() => _obscurePass = !_obscurePass),
              ),
            ),
          ),
          const SizedBox(height: 15),
          TextField(
            controller: _confirmPassCtrl,
            obscureText: _obscurePass,
            decoration: const InputDecoration(labelText: "Повторите пароль"),
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(onPressed: _next, child: const Text("Далее")),
          ),
        ],
      ),
    );
  }

  // ШАГ 4: Проверка
  Widget _step4Review() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle_outline, size: 80, color: Colors.green),
          const SizedBox(height: 20),
          const Text(
            "Все верно?",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 30),
          _infoRow("Телефон", widget.phoneNumber),
          _infoRow("Имя", "${_firstNameCtrl.text} ${_lastNameCtrl.text}"),
          _infoRow(
            "Авто",
            "${_selectedBrand?.name ?? ''} | ${"${_plateRegionCtrl.text} ${_plateSeriesCtrl.text} ${_plateNumberCtrl.text} ${_plateSuffixCtrl.text}".toUpperCase()}",
          ),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _finish,
              child: const Text("СОЗДАТЬ АККАУНТ"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ],
      ),
    );
  }
}
