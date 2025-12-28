import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/radio_provider.dart';
import '../../services/api_service.dart';
import '../../config/themes.dart'; // Ranglar
import '../auth/phone_input_screen.dart'; 
import 'package:shared_preferences/shared_preferences.dart';

class RadioScreen extends StatefulWidget {
  const RadioScreen({super.key});

  @override
  State<RadioScreen> createState() => _RadioScreenState();
}

class _RadioScreenState extends State<RadioScreen> {
  
  @override
  void initState() {
    super.initState();
    // Ekrana chizilib bo'lgandan so'ng ishga tushadi
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final radio = Provider.of<RadioProvider>(context, listen: false);
      radio.initRadio();

      // "Majburiy chiqish" (Force Logout) logikasi
      radio.onLogout = (reason) {
        if (!mounted) return;
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.cardBg,
            title: const Text("Diqqat", style: TextStyle(color: Colors.white)),
            content: Text(reason, style: const TextStyle(color: Colors.white70)),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => const PhoneInputScreen()), 
                    (route) => false
                  );
                },
                child: const Text("OK", style: TextStyle(color: AppColors.accent)),
              ),
            ],
          ),
        );
      };
    });
  }

  // --- Logika: Ma'lumotlarni ko'rsatish ---
  Widget _buildSpeakerInfo(Map<String, dynamic> speaker) {
    // Agar "carNumber" bor bo'lsa, demak u Haydovchi. 
    // Agar backenddan 'userType' kelsa, shuni ishlatish afzalroq: speaker['userType'] == 'driver'
    final bool isDriver = speaker['carNumber'] != null && speaker['carNumber'].toString().isNotEmpty;
    
    final String name = speaker['firstName'] ?? 'Noma\'lum';
    final String phone = speaker['phoneNumber'] ?? ''; // Telefon raqamni backenddan yuborish kerak
    final String carInfo = "${speaker['carBrand'] ?? ''} ${speaker['carNumber'] ?? ''}".trim();

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Text("HOZIR GAPIRMOQDA:", style: TextStyle(color: Colors.grey, fontSize: 12, letterSpacing: 1.5)),
        const SizedBox(height: 15),
        
        // 1. Ism
        Text(
          name,
          style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: Colors.white),
        ),
        
        // 2. Telefon (Mijoz uchun ham, Haydovchi uchun ham)
        if (phone.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 5),
            child: Text(
              phone, 
              style: const TextStyle(fontSize: 16, color: AppColors.textLight),
            ),
          ),

        // 3. Mashina (FAQAT HAYDOVCHI UCHUN)
        if (isDriver) ...[
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.cardBg, // To'q fon
              borderRadius: BorderRadius.circular(15),
              border: Border.all(color: AppColors.primary, width: 1), // Moviy hoshiya
              boxShadow: [
                BoxShadow(color: AppColors.primary.withOpacity(0.3), blurRadius: 10, spreadRadius: 1)
              ]
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.directions_car, color: AppColors.accent),
                const SizedBox(width: 10),
                Text(
                  carInfo,
                  style: const TextStyle(fontSize: 20, color: AppColors.accent, fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ]
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final radio = context.watch<RadioProvider>();

    // Holatga qarab rang va matn
    Color statusColor;
    String statusText;

    switch (radio.status) {
      case RadioStatus.speaking:
        statusColor = Colors.orange; // Gapirganda olovrang
        statusText = "GAPIRILYAPTI...";
        break;
      case RadioStatus.listening:
        statusColor = Colors.redAccent; // Eshitganda qizil
        statusText = "EFIR BAND";
        break;
      case RadioStatus.idle:
        statusColor = AppColors.primary; // Bo'sh bo'lganda moviy
        statusText = "GAPIRISH UCHUN BOSING";
        break;
    }

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        backgroundColor: AppColors.darkBg,
        title: const Text("Gapirchi 20.0", style: TextStyle(fontWeight: FontWeight.bold)),
        actions: [
          // Shikoyat tugmasi
          IconButton(
            icon: const Icon(Icons.report_problem_outlined, color: Colors.grey),
            onPressed: () => radio.requestLastSpeaker(),
          ),
          const SizedBox(width: 10),
          // Online status indikatori
          Container(
            margin: const EdgeInsets.only(right: 16),
            width: 12, height: 12,
            decoration: BoxDecoration(
              color: radio.isConnected ? AppColors.primary : Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                 if (radio.isConnected) 
                   BoxShadow(color: AppColors.primary.withOpacity(0.6), blurRadius: 8, spreadRadius: 2)
              ]
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // --- Yuqori qism: Info ---
          Expanded(
            flex: 2,
            child: Center(
              child: radio.currentSpeaker != null
                  ? _buildSpeakerInfo(radio.currentSpeaker!)
                  : Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.waves, size: 80, color: AppColors.cardBg),
                        const SizedBox(height: 20),
                        const Text(
                          "Efir bo'sh",
                          style: TextStyle(fontSize: 20, color: Colors.grey),
                        ),
                      ],
                    ),
            ),
          ),

          // --- O'rta qism: Tugma ---
          Expanded(
            flex: 3,
            child: Center(
              child: GestureDetector(
                onTapDown: (_) {
                  if (radio.status == RadioStatus.idle) {
                    print("Started speaking");
                    radio.startSpeakingRequest();
                  }
                },
                onTapUp: (_) => radio.stopSpeaking(),
                onTapCancel: () => radio.stopSpeaking(),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  width: 220,
                  height: 220,
                  decoration: BoxDecoration(
                    color: statusColor.withOpacity(0.1),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: statusColor, 
                      width: radio.status == RadioStatus.speaking ? 6 : 2
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withOpacity(radio.status == RadioStatus.idle ? 0.2 : 0.5),
                        blurRadius: radio.status == RadioStatus.speaking ? 40 : 20,
                        spreadRadius: radio.status == RadioStatus.speaking ? 10 : 2,
                      ),
                    ],
                  ),
                  child: Center(
                    // Keyinchalik bu yerga Rive animatsiyasini qo'yasiz
                    child: Icon(
                      radio.status == RadioStatus.speaking ? Icons.mic : Icons.mic_none,
                      size: 80,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),

          // --- Pastki qism: Status matni ---
          Padding(
            padding: const EdgeInsets.only(bottom: 40),
            child: Text(
              statusText,
              style: TextStyle(
                color: statusColor,
                fontSize: 16,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.2
              ),
            ),
          ),
        ],
      ),
    );
  }
}