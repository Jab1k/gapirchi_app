import 'package:flutter/material.dart';
import 'package:gapirchi_app/models/car_model.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/car_brand_model.dart';
import '../../widgets/uzbek_license_plate.dart';
import '../main_wrapper.dart'; // Wrapperga o'tish uchun
import '../../config/themes.dart';

class RegistrationScreen extends StatefulWidget {
  final String phoneNumber;
  const RegistrationScreen({super.key, required this.phoneNumber});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _formKey = GlobalKey<FormState>();

  // Umumiy
  final _nameController = TextEditingController();
  final _passController = TextEditingController();
  
  // Mashina (Faqat haydovchi uchun)
  CarBrand? _selectedBrand;
  CarModel? _selectedModel;
  
  // Raqam (UzbekLicensePlateInput uchun)
  final _regionCtrl = TextEditingController();
  final _lettersCtrl = TextEditingController();
  final _numbersCtrl = TextEditingController();
  final _suffixCtrl = TextEditingController();

  String _userType = 'driver'; // 'driver' yoki 'client'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _userType = _tabController.index == 0 ? 'driver' : 'client';
      });
    });
  }

  void _submit() async {
    // 1. Umumiy tekshiruvlar (Form validatorlari orqali)
    if (!_formKey.currentState!.validate()) {
      return; // Agar ism yoki parol qizil bo'lsa, to'xtatamiz
    }

    // 2. Parol uzunligini qo'shimcha tekshirish
    if (_passController.text.trim().length < 6) {
      _showError("Parol kamida 6 ta belgidan iborat bo'lishi kerak");
      return;
    }

    // 3. Agar HAYDOVCHI bo'lsa, mashina ma'lumotlarini juda qattiq tekshiramiz
    if (_userType == 'driver') {
      
      // A. Marka va Model tanlanganmi?
      if (_selectedBrand == null) {
        _showError("Iltimos, mashina markasini tanlang (Chevrolet, Kia...)");
        return;
      }
      if (_selectedModel == null) {
        _showError("Iltimos, mashina modelini tanlang (Matiz, Nexia...)");
        return;
      }

      // B. Mashina raqami to'liqmi? (Har bir katakni tekshiramiz)
      // Region: 2 ta raqam bo'lishi shart (masalan: 01, 70, 80)
      if (_regionCtrl.text.trim().length != 2) {
        _showError("Mashina raqami: Hudud kodi 2 xonali bo'lishi kerak (01, 80...)");
        return;
      }
      // Seriya harfi: 1 ta harf (A)
      if (_lettersCtrl.text.trim().isEmpty) {
        _showError("Mashina raqami: Seriya harfini kiriting (A, B...)");
        return;
      }
      // Raqamlar: 3 ta raqam (123)
      if (_numbersCtrl.text.trim().length != 3) {
        _showError("Mashina raqami: O'rtadagi raqam 3 xonali bo'lishi kerak (123)");
        return;
      }
      // Oxirgi harflar: 2 ta harf (AA)
      if (_suffixCtrl.text.trim().length != 2) {
        _showError("Mashina raqami: Oxirgi harflar 2 ta bo'lishi kerak (AA)");
        return;
      }
    }

    // 4. Hamma tekshiruvlardan o'tdi, endi ma'lumot yig'amiz
    // Raqamni yig'ish (70 A 123 AA) -> Hammasini katta harf qilamiz
    String fullCarNumber = "";
    if (_userType == 'driver') {
      fullCarNumber = "${_regionCtrl.text}${_lettersCtrl.text}${_numbersCtrl.text}${_suffixCtrl.text}".toUpperCase().replaceAll(" ", ""); 
      // Natija: 70A123AA (Probelssiz saqlash qulayroq bo'lishi mumkin yoki probel bilan:
      // fullCarNumber = "${_regionCtrl.text} ${_lettersCtrl.text} ${_numbersCtrl.text} ${_suffixCtrl.text}".toUpperCase();
    }

    final data = {
      "phoneNumber": widget.phoneNumber,
      "firstName": _nameController.text.trim(),
      "password": _passController.text.trim(),
      "userType": _userType,
      // Haydovchi bo'lsa IDlar, bo'lmasa null
      "carBrandId": _userType == 'driver' ? _selectedBrand?.id : null,
      "carModelId": _userType == 'driver' ? _selectedModel?.id : null,
      "carNumber": _userType == 'driver' ? fullCarNumber : null,
    };

    try {
      await Provider.of<AuthProvider>(context, listen: false).register(data);
      
      if (!mounted) return;
      
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainWrapper()),
        (route) => false,
      );
    } catch (e) {
      _showError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  // Xato ko'rsatish uchun yordamchi funksiya
  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLoading = context.watch<AuthProvider>().isLoading;

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text("Ro'yxatdan o'tish"),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: AppColors.accent,
          labelColor: AppColors.accent,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Men Haydovchiman", icon: Icon(Icons.drive_eta)),
            Tab(text: "Men Yo'lovchiman", icon: Icon(Icons.person)),
          ],
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildDriverForm(), // 1. Haydovchi formasi
                  _buildClientForm(), // 2. Mijoz formasi
                ],
              ),
            ),
            
            // "Saqlash" tugmasi har doim pastda turadi
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _submit,
                  child: isLoading 
                    ? const CircularProgressIndicator(color: Colors.white) 
                    : const Text("TAYYOR"),
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  // --- HAYDOVCHI FORMASI ---
  Widget _buildDriverForm() {
    final authProvider = Provider.of<AuthProvider>(context);
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text("Shaxsiy ma'lumotlar", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          _buildTextField("Ismingiz", _nameController, Icons.person),
          const SizedBox(height: 15),
          _buildTextField("Parol o'ylab toping", _passController, Icons.lock, isPass: true),
          
          const SizedBox(height: 30),
          const Text("Avtomobil ma'lumotlari", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          
          // 1. Brend Tanlash
          DropdownButtonFormField<CarBrand>(
            dropdownColor: AppColors.cardBg,
            decoration: const InputDecoration(labelText: "Marka (Chevrolet, Kia...)"),
            items: authProvider.availableBrands.map((b) => DropdownMenuItem(value: b, child: Text(b.name))).toList(),
            onChanged: (val) {
              setState(() {
                _selectedBrand = val;
                _selectedModel = null; // Brend o'zgarsa modelni tozalaymiz
              });
              if (val != null) {
                authProvider.loadCarModels(val.id); // Modellarni yuklaymiz
              }
            },
            value: _selectedBrand,
          ),
          const SizedBox(height: 15),

          // 2. Model Tanlash (Faqat Brend tanlangandan keyin chiqadi)
          if (_selectedBrand != null)
             DropdownButtonFormField<CarModel>(
              dropdownColor: AppColors.cardBg,
              decoration: const InputDecoration(labelText: "Model (Nexia 3, Cobalt...)"),
              items: authProvider.availableModels.map((m) => DropdownMenuItem(value: m, child: Text(m.name))).toList(),
              onChanged: (val) => setState(() => _selectedModel = val),
              value: _selectedModel,
            ),
          
          const SizedBox(height: 20),
          const Text("Davlat raqami:", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          
          // 3. Raqam kiritish
          UzbekLicensePlateInput(
            regionController: _regionCtrl,
            lettersController: _lettersCtrl,
            numbersController: _numbersCtrl,
            suffixController: _suffixCtrl,
          ),
        ],
      ),
    );
  }

  // --- MIJOZ FORMASI ---
  Widget _buildClientForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(child: Icon(Icons.emoji_people, size: 80, color: AppColors.primary)),
          const SizedBox(height: 20),
          const Text(
            "Mijoz sifatida siz faqat ismingizni kiritishingiz kifoya. Biz sizdan mashina so'ramaymiz.",
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.textLight),
          ),
          const SizedBox(height: 30),
          
          const Text("Ma'lumotlar", style: TextStyle(color: Colors.grey)),
          const SizedBox(height: 10),
          _buildTextField("Ismingiz", _nameController, Icons.person),
          const SizedBox(height: 15),
          _buildTextField("Parol o'ylab toping", _passController, Icons.lock, isPass: true),
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController ctrl, IconData icon, {bool isPass = false}) {
    return TextFormField(
      controller: ctrl,
      obscureText: isPass,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textLight),
      ),
      validator: (v) => v!.isEmpty ? "To'ldirish shart" : null,
    );
  }
}