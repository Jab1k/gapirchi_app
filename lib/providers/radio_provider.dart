// ignore_for_file: avoid_print

import 'dart:async';
import 'dart:typed_data';
import 'package:flutter/material.dart';
// ignore: library_prefixes
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:sound_stream/sound_stream.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../config/app_config.dart';


enum RadioStatus { idle, speaking, listening }

class RadioProvider with ChangeNotifier {
  IO.Socket? _socket;
  final RecorderStream _recorder = RecorderStream();
  final PlayerStream _player = PlayerStream();
  
  RadioStatus _status = RadioStatus.idle;
  Map<String, dynamic>? _currentSpeaker; // Кто говорит сейчас
  Map<String, dynamic>? _lastSpeaker;    // Кто говорил последним (для жалобы)
  StreamSubscription? _audioSubscription;

  // --- НОВОЕ: Callback для принудительного выхода ---
  Function(String reason)? onLogout;
  // --------------------------------------------------

  RadioStatus get status => _status;
  Map<String, dynamic>? get currentSpeaker => _currentSpeaker;
  Map<String, dynamic>? get lastSpeaker => _lastSpeaker;
  bool get isConnected => _socket != null && _socket!.connected;

  // Инициализация (вызывается при входе на экран)
  Future<void> initRadio() async {
    await _initAudio();
    await _connectSocket();
  }

  // Настройка аудио (Микрофон и Динамик)
  Future<void> _initAudio() async {
    var status = await Permission.microphone.request();
    if (status != PermissionStatus.granted) {
      throw Exception("Нет доступа к микрофону");
    }

    // Используем 16000 Гц - стандарт для передачи голоса
    await _recorder.initialize(sampleRate: 16000);
    await _player.initialize(sampleRate: 16000);
    
    // ВАЖНО: Запускаем плеер сразу
    await _player.start();
  }

  void cleanUpForLogout() {
    disconnect();
    // Boshqa o'zgaruvchilarni ham tozalash
    _currentSpeaker = null;
    _lastSpeaker = null;
    _status = RadioStatus.idle;
  }

  // Подключение к Сокету
  Future<void> _connectSocket() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');
    final userId = prefs.getString('userId');

    if (token == null) return;

    _socket = IO.io(AppConfig.socketUrl, IO.OptionBuilder()
      .setTransports(['websocket'])
      .disableAutoConnect()
      .build());

    _socket!.connect();

    _socket!.onConnect((_) {
      // ignore: duplicate_ignore
      // ignore: avoid_print
      print("Сокет подключен");
      _socket!.emit('join_channel', {'userId': userId, 'token': token});
      notifyListeners();
    });

    // --- НОВОЕ: Обработка кика (Force Logout) ---
    _socket!.on('force_logout_device', (data) async {
      final removedDeviceId = data['deviceId'];
      print("Serverdan o'chirish buyrug'i keldi: $removedDeviceId");

      // O'zimizning ID ni tekshiramiz
      final prefs = await SharedPreferences.getInstance();
      final myDeviceId = prefs.getString('device_unique_id');

      // Agar serverdan kelgan ID bizniki bilan bir xil bo'lsa -> CHIQAMIZ!
      if (myDeviceId != null && myDeviceId == removedDeviceId) {
         if (onLogout != null) {
           onLogout!("Sizning sessiyangiz yakunlandi.");
         }
      }
    });
    // ---------------------------------------------

    // Статус канала
    _socket!.on('channel_status', (data) {
      if (data['isBusy']) {
        _status = RadioStatus.listening;
        _currentSpeaker = data['speaker'];
      } else {
        _status = RadioStatus.idle;
        _currentSpeaker = null;
      }
      notifyListeners();
    });

    // Кто-то начал говорить
    _socket!.on('speaker_active', (data) {
      _status = RadioStatus.listening;
      _currentSpeaker = data;
      notifyListeners();
    });

    // Кто-то закончил говорить
    _socket!.on('speaker_finished', (_) {
      _status = RadioStatus.idle;
      _currentSpeaker = null;
      notifyListeners();
    });

    // Получение аудио
    _socket!.on('audio_stream', (data) {
      try {
        if (data != null) {
          Uint8List audioData = Uint8List.fromList(List<int>.from(data));
          _player.writeChunk(audioData);
        }
      } catch (e) {
        print("Ошибка аудио: $e");
      }
    });

    // Разрешение говорить
    _socket!.on('speak_granted', (_) {
      _status = RadioStatus.speaking;
      notifyListeners();
      _startRecording();
    });

    // Отказ
    _socket!.on('speak_denied', (data) {
      _status = RadioStatus.idle;
      notifyListeners();
    });

    // Последний говорящий (для жалоб)
    _socket!.on('last_speaker_info', (data) {
      _lastSpeaker = data;
      notifyListeners();
    });
  }

  // --- Управление Рацией ---

  void startSpeakingRequest() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('request_to_speak');
      print("Запрос на говорение отправлен");
    }
  }

  void _startRecording() {
    _audioSubscription = _recorder.audioStream.listen((data) {
       if (_socket != null && _status == RadioStatus.speaking) {
         _socket!.emit('audio_stream', data);
         print( "Отправлено аудио: ${data.length} байт");
       }
    });
    _recorder.start();
  }

  void stopSpeaking() {
    if (_status == RadioStatus.speaking) {
      _recorder.stop();
      _audioSubscription?.cancel();
      _socket!.emit('stop_speaking');
      _status = RadioStatus.idle;
      notifyListeners();
    }
  }

  // --- Жалобы ---

  void requestLastSpeaker() {
    if (_socket != null && _socket!.connected) {
      _socket!.emit('get_last_speaker');
    }
  }

  void clearLastSpeaker() {
    _lastSpeaker = null;
    notifyListeners();
  }

  // Полное отключение (при выходе)
  void disconnect() {
    _socket?.disconnect();
    _recorder.stop();
    _socket = null;
    _player.stop();
    _audioSubscription?.cancel();
  }
}