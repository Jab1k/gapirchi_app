import 'dart:convert';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ApiService {
  // 1. Проверка номера
  Future<Map<String, dynamic>> checkPhone(String phone) async {
    try {
      final response = await http.post(
        Uri.parse('${AppConfig.apiUrl}/auth/check-phone'),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({"phoneNumber": phone}),
      );
      
      return jsonDecode(response.body);
    } catch (e) {
      throw Exception('Ошибка сети: $e');
    }
  }

  // 2. Логин
  Future<Map<String, dynamic>> login(String phone, String password) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/auth/login'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "phoneNumber": phone,
        "password": password
      }),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка входа');
    }
  }

  // 3. Регистрация
  Future<Map<String, dynamic>> register(Map<String, dynamic> data) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/auth/register'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(data),
    );

    if (response.statusCode == 201) {
      return jsonDecode(response.body);
    } else {
      final error = jsonDecode(response.body);
      throw Exception(error['message'] ?? 'Ошибка регистрации');
    }
  }

  Future<void> sendComplaint(String senderId, String targetId, String reason) async {
    final response = await http.post(
      Uri.parse('${AppConfig.apiUrl}/complaints/add'),
      headers: {"Content-Type": "application/json"},
      body: jsonEncode({
        "senderId": senderId,
        "targetId": targetId,
        "reason": reason
      }),
    );

    if (response.statusCode == 201) {
      return; // Все ок
    } else {
      // Пытаемся прочитать текст ошибки от сервера
      try {
        final body = jsonDecode(response.body);
        throw Exception(body['message'] ?? 'Не удалось отправить жалобу');
      } catch (e) {
        // Если пришел не JSON, или другая ошибка
        if (e is Exception) rethrow; // Прокидываем уже созданную ошибку
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    }
  }
  
}