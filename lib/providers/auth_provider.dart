import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/car_brand_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _token;
  List<CarBrand> _availableBrands = [];

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  List<CarBrand> get availableBrands => _availableBrands;

  // Проверка номера телефона
  Future<Map<String, dynamic>> checkPhone(String phone) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.checkPhone(phone);
      
      // Если пользователя нет, сервер пришлет список машин
      if (result['exists'] == false && result['carBrands'] != null) {
        _availableBrands = (result['carBrands'] as List)
            .map((item) => CarBrand.fromJson(item))
            .toList();
      }
      
      _isLoading = false;
      notifyListeners();
      return result; // Возвращаем результат UI, чтобы знать куда идти
    } catch (e) {
      _isLoading = false;
      notifyListeners();
      rethrow;
    }
  }

  // Логин
  Future<void> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      final result = await _apiService.login(phone, password);
      _token = result['token'];
      
      // Сохраняем токен в памяти телефона
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

  // Регистрация
  Future<void> register(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
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