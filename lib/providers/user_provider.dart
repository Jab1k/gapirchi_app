import 'package:flutter/material.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';

class UserProvider with ChangeNotifier {
  bool _isLoading = false;
  Map<String, dynamic>? _user;
  List<dynamic> _sessions = [];

  bool get isLoading => _isLoading;
  Map<String, dynamic>? get user => _user;
  List<dynamic> get sessions => _sessions;

  // Yordamchi: Tokenni olish
  Future<String?> _getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  // 1. Profilni yuklash
  Future<void> fetchProfile() async {
    _isLoading = true;
    // notifyListeners(); // Ekran pirillamasligi uchun bu yerni o'chirdik
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/user/profile'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
      );

      if (response.statusCode == 200) {
        _user = jsonDecode(response.body);
        notifyListeners();
      }
    } catch (e) {
      print("Profile error: $e");
    } finally {
      _isLoading = false;
      // notifyListeners();
    }
  }

  // 2. Profilni yangilash
  Future<void> updateProfile(Map<String, dynamic> data) async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _getToken();
      final response = await http.put(
        Uri.parse('${AppConfig.apiUrl}/user/profile'),
        headers: {
          "Content-Type": "application/json",
          "Authorization": "Bearer $token"
        },
        body: jsonEncode(data),
      );

      if (response.statusCode == 200) {
        await fetchProfile(); // Yangilangandan keyin qayta yuklaymiz
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

  // 3. Sessiyalarni olish
  Future<void> fetchSessions() async {
    _isLoading = true;
    notifyListeners();
    try {
      final token = await _getToken();
      if (token == null) return;

      final response = await http.get(
        Uri.parse('${AppConfig.apiUrl}/user/sessions'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        _sessions = jsonDecode(response.body);
      }
    } catch (e) {
      print("Error fetching sessions: $e");
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // 4. Sessiyani o'chirish
  Future<void> deleteSession(String sessionId) async {
    try {
      final token = await _getToken();
      final response = await http.delete(
        Uri.parse('${AppConfig.apiUrl}/user/sessions/$sessionId'),
        headers: {"Authorization": "Bearer $token"},
      );

      if (response.statusCode == 200) {
        // Muvaffaqiyatli o'chgach, ro'yxatdan ham olib tashlaymiz
        _sessions.removeWhere((s) => s['_id'] == sessionId);
        notifyListeners();
      } else {
        throw Exception("O'chira olmadim");
      }
    } catch (e) {
      rethrow;
    }
  }
}