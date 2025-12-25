class AppConfig {
  // ВАЖНО: Замени на IP своего компьютера, если запускаешь на реальном телефоне!
  // Для эмулятора Android оставь 'http://10.0.2.2:5000'
  static const String baseUrl = 'http://10.0.2.2:5000'; 
  
  static const String apiUrl = '$baseUrl/api';
  static const String socketUrl = baseUrl;
}