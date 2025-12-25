import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../models/car_brand_model.dart';
import '../models/car_model.dart'; // <--- YANGI IMPORTNI QO'SHDIK

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();

  bool _isLoading = false;
  String? _token;

  // Brendlar ro'yxati
  List<CarBrand> _availableBrands = [];

  // --- YANGI: Modellar ro'yxati ---
  List<CarModel> _availableModels = [];

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  List<CarBrand> get availableBrands => _availableBrands;

  // --- YANGI: Getter ---
  List<CarModel> get availableModels => _availableModels;

  // 1. Telefon raqamni tekshirish
  Future<Map<String, dynamic>> checkPhone(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.checkPhone(phone);

      if (result['exists'] == false && result['carBrands'] != null) {
        _availableBrands = (result['carBrands'] as List)
            .map((item) => CarBrand.fromJson(item))
            .toList();
      }

      _isLoading = false;
      notifyListeners();
      return result;
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // --- YANGI: Mashina modellarini yuklash ---
  Future<void> loadCarModels(String brandId) async {
    // Kichik yuklanish bo'lsa ham, UI qotib qolmasligi uchun _isLoading ni yoqmaymiz,
    // yoki faqat dropdown uchun alohida loading qilish mumkin.
    try {
      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/auth/car-models/$brandId'),
      );

      if (response.statusCode == 200) {
        final List data = jsonDecode(response.body);
        _availableModels = data.map((e) => CarModel.fromJson(e)).toList();
        notifyListeners();
      }
    } catch (e) {
      print("Model yuklash xatosi: $e");
    }
  }

  // 3. Login
  Future<void> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Bu yerda deviceId logikasini oldingi suhbatda qo'shgan bo'lsangiz, o'shani qoldiring.
      // Hozir oddiy login varianti:
      final result = await _apiService.login(phone, password);
      _token = result['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('userId', result['user']['id']);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // 4. Registratsiya
  Future<void> register(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      // Device ID logikasi kerak bo'lsa, shu yerga qo'shiladi
      final result = await _apiService.register(data);
      _token = result['token'];

      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('token', _token!);
      await prefs.setString('userId', result['user']['id']);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }
}
