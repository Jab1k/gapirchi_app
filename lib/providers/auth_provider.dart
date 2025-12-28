import 'package:flutter/material.dart';
import 'dart:convert';
import 'dart:math'; // Random uchun
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';
import '../services/api_service.dart';
import '../models/car_brand_model.dart';
import '../models/car_model.dart'; 

class AuthProvider with ChangeNotifier {
  final ApiService _apiService = ApiService();
  
  bool _isLoading = false;
  String? _token;
  List<CarBrand> _availableBrands = [];
  List<CarModel> _availableModels = []; 

  bool get isLoading => _isLoading;
  bool get isAuthenticated => _token != null;
  List<CarBrand> get availableBrands => _availableBrands;
  List<CarModel> get availableModels => _availableModels; 

  // --- YANGI: Qurilma ID sini generatsiya qilish ---
  Future<Map<String, String>> _getDeviceInfo() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 1. Agar ID oldin yaratilgan bo'lsa, o'shani olamiz. Bo'lmasa yangisini yaratamiz.
    String? deviceId = prefs.getString('device_unique_id');
    if (deviceId == null) {
      // Tasodifiy unikal ID yaratish
      deviceId = "${DateTime.now().millisecondsSinceEpoch}-${Random().nextInt(9999)}";
      await prefs.setString('device_unique_id', deviceId);
    }

    // 2. Qurilma nomi (Android Emulator yoki shunga o'xshash)
    String deviceName = "Device-${deviceId.substring(deviceId.length - 4)}";

    return {
      "deviceId": deviceId,
      "deviceName": deviceName
    };
  }
  // --------------------------------------------------

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
      return result;
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> loadCarModels(String brandId) async {
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

  // LOGIN (YANGILANDI)
  Future<void> login(String phone, String password) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Qurilma ma'lumotlarini olamiz
      final deviceInfo = await _getDeviceInfo();

      // 2. Serverga ID bilan birga jo'natamiz
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/auth/login'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "phoneNumber": phone,
          "password": password,
          "deviceId": deviceInfo['deviceId'],   // <--- MUHIM
          "deviceName": deviceInfo['deviceName'] // <--- MUHIM
        }),
      );

      if (response.statusCode == 200) {
        final result = jsonDecode(response.body);
        _token = result['token'];
        
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userId', result['user']['id']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Xatolik');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // REGISTRATSIYA (YANGILANDI)
  Future<void> register(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();

    try {
      // 1. Qurilma ma'lumotlarini olamiz
      final deviceInfo = await _getDeviceInfo();
      
      // 2. Ma'lumotlarga qo'shamiz
      data['deviceId'] = deviceInfo['deviceId'];
      data['deviceName'] = deviceInfo['deviceName'];

      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/auth/register'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      );

      if (response.statusCode == 201) {
        final result = jsonDecode(response.body);
        _token = result['token'];
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('token', _token!);
        await prefs.setString('userId', result['user']['id']);
      } else {
        final error = jsonDecode(response.body);
        throw Exception(error['message'] ?? 'Xatolik');
      }
    } catch (e) {
      rethrow;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}