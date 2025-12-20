// ignore_for_file: use_build_context_synchronously, deprecated_member_use

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../../providers/radio_provider.dart';
import '../../services/api_service.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  final updater = ShorebirdUpdater();
  final Duration _updateDuration = const Duration(seconds: 15);
  Future<void> restartApp() async {
    SystemChannels.platform.invokeMethod('SystemNavigator.pop');
  }

  Future<void> _checkForUpdates() async {
    await Future.delayed(const Duration(seconds: 2));
    final status = await updater.checkForUpdate();
    print('Update status: $status');
    if (status == UpdateStatus.outdated) {
      _showUpdateAvailable();
    } else if (status == UpdateStatus.restartRequired) {
      _showRestartSnackBar();
    }
  }

  Future<void> _showRestartSnackBar() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        margin: const EdgeInsets.all(10),
        content: Text('Update is installed. Please restart the app.'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 500),
        action: SnackBarAction(label: 'Restart', onPressed: restartApp),
      ),
    );
  }

  bool patchFailed = false;
  Future<void> _showUpdateAvailable() async {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        margin: const EdgeInsets.all(10),
        content: Text('An update is available!'),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 500),
        action: SnackBarAction(
          label: 'Update',
          onPressed: () async {
            try {
              // Hide the initial snackbar
              ScaffoldMessenger.of(context).hideCurrentSnackBar();

              await updater.update();
              // Show the downloading progress snackbar
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  margin: const EdgeInsets.all(10),
                  content: _downloadProgress(),
                  behavior: SnackBarBehavior.floating,
                  duration: _updateDuration,
                ),
              );
            } on UpdateException catch (error) {
              patchFailed = true;
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('${error.message}'),
                  duration: const Duration(seconds: 500),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Close',
                    onPressed: () {
                      ScaffoldMessenger.of(context).hideCurrentSnackBar();
                    },
                  ),
                ),
              );
            }
          },
        ),
      ),
    );
  }

  Widget _downloadProgress() {
    return TweenAnimationBuilder<double>(
      duration: _updateDuration,
      tween: Tween(begin: 0.0, end: 1.0),
      onEnd: () {
        if (patchFailed) {
          return;
        }
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        _showRestartSnackBar();
      },
      builder: (BuildContext context, double value, Widget? child) {
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 5),
          child: Row(
            children: [
              CircularProgressIndicator(value: value),
              SizedBox(width: 20),
              Text('Downloading update...'),
            ],
          ),
        );
      },
    );
  }

  @override
  void initState() {
    super.initState();
    _checkForUpdates();
    updater.readCurrentPatch().then((currentPatch) {
      print('The current patch number is: ${currentPatch?.number}');
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final radio = Provider.of<RadioProvider>(context, listen: false);
      radio.initRadio();

      // Слушаем кик
      radio.onLogout = (reason) {
        if (!mounted) return;

        // Показываем диалог и выходим
        showDialog(
          context: context,
          barrierDismissible: false, // Нельзя закрыть нажав мимо
          builder: (ctx) => AlertDialog(
            title: const Text("Вход на другом устройстве"),
            content: Text(reason),
            actions: [
              TextButton(
                onPressed: () {
                  // Переход на экран ввода номера (полная перезагрузка)
                  Navigator.of(
                    context,
                  ).pushNamedAndRemoveUntil('/', (route) => false);
                  // Или если не используешь именованные маршруты:
                  // Navigator.pushAndRemoveUntil(context, MaterialPageRoute(builder: (_) => PhoneInputScreen()), (r) => false);
                },
                child: const Text("ОК"),
              ),
            ],
          ),
        );
      };
    });
  }

  // Функция показа окна жалобы
  void _showComplaintDialog(
    BuildContext context,
    Map<String, dynamic> offenderData,
  ) {
    final reasons = [
      "Оскорбление",
      "Мат",
      "Шум / Музыка",
      "Реклама",
      "Политика",
    ];

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Пожаловаться"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("Нарушитель: ${offenderData['userInfo']['firstName']}"),
            Text(
              "Авто: ${offenderData['userInfo']['carBrand']} ${offenderData['userInfo']['carNumber']}",
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 15),
            const Text("Выберите причину:"),
          ],
        ),
        actions: reasons.map((reason) {
          return TextButton(
            onPressed: () async {
              Navigator.pop(ctx); // Закрыть окно
              await _sendComplaintToServer(offenderData['userId'], reason);
            },
            child: Text(
              reason,
              style: const TextStyle(color: Colors.redAccent),
            ),
          );
        }).toList(),
      ),
    );
  }

  Future<void> _sendComplaintToServer(String targetId, String reason) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final myId = prefs.getString('userId');

      if (myId != null) {
        await ApiService().sendComplaint(myId, targetId, reason);
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Жалоба отправлена. Админ рассмотрит её."),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Ошибка: $e"), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    // Слушаем провайдер
    final radio = context.watch<RadioProvider>();

    // Если пришли данные о нарушителе -> сразу показываем окно и очищаем данные
    if (radio.lastSpeaker != null) {
      // Используем микро-задержку, чтобы не было конфликта рендера
      Future.delayed(Duration.zero, () {
        _showComplaintDialog(context, radio.lastSpeaker!);
        radio.clearLastSpeaker(); // Сбрасываем, чтобы окно не открывалось вечно
      });
    }

    Color statusColor;
    String statusText;

    switch (radio.status) {
      case RadioStatus.speaking:
        statusColor = Colors.orange;
        statusText = "ГОВОРИТЕ...";
        break;
      case RadioStatus.listening:
        statusColor = Colors.red;
        statusText = "ЭФИР ЗАНЯТ";
        break;
      case RadioStatus.idle:
        statusColor = const Color(0xFF00C853);
        statusText = "НАЖМИ, ЧТОБЫ ГОВОРИТЬ";
        break;
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Gapirchi"),
        actions: [
          ElevatedButton(
            child: Text('Check for update'),
            onPressed: _checkForUpdates,
          ),
          // КНОПКА ЖАЛОБЫ
          IconButton(
            icon: const Icon(Icons.report_problem, color: Colors.grey),
            onPressed: () {
              // Просим сервер: "Кто говорил последним?"
              radio.requestLastSpeaker();
              // Сервер ответит, и сработает if (radio.lastSpeaker != null) выше
            },
          ),
          const SizedBox(width: 10),
          Icon(
            Icons.circle,
            size: 12,
            color: radio.isConnected ? Colors.green : Colors.red,
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            flex: 2,
            child: Center(
              child: radio.currentSpeaker != null
                  ? Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Сейчас говорит:",
                          style: TextStyle(color: Colors.grey),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          radio.currentSpeaker!['firstName'] ?? 'Неизвестный',
                          style: const TextStyle(
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          "${radio.currentSpeaker!['carBrand']} | ${radio.currentSpeaker!['carNumber']}",
                          style: const TextStyle(
                            fontSize: 18,
                            color: Colors.orange,
                          ),
                        ),
                        const SizedBox(height: 20),
                        const Icon(
                          Icons.volume_up,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ],
                    )
                  : const Text(
                      "Эфир свободен",
                      style: TextStyle(fontSize: 18, color: Colors.grey),
                    ),
            ),
          ),

          Expanded(
            flex: 3,
            child: Center(
              child: GestureDetector(
                onTapDown: (_) {
                  if (radio.status == RadioStatus.idle) {
                    radio.startSpeakingRequest();
                  }
                },
                onTapUp: (_) => radio.stopSpeaking(),
                onTapCancel: () => radio.stopSpeaking(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 200,
                  height: 200,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.2),
                    shape: BoxShape.circle,
                    border: Border.all(color: statusColor, width: 4),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 5,
                      ),
                    ],
                  ),
                  child: Center(
                    child: radio.status == RadioStatus.speaking
                        ? const Icon(Icons.mic, size: 80, color: Colors.white)
                        : const Icon(
                            Icons.mic_none,
                            size: 80,
                            color: Colors.white70,
                          ),
                  ),
                ),
              ),
            ),
          ),

          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
