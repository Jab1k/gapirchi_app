import 'package:flutter/material.dart';
import '../../config/themes.dart';
import '../auth/phone_input_screen.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg,
      body: Stack(
        children: [
          // PageView
          PageView(
            controller: _pageController,
            onPageChanged: (index) => setState(() => _currentPage = index),
            children: [
              _buildLanguagePage(),
              _buildInfoPage(),
              _buildActionPage(),
            ],
          ),

          // Pastki navigatsiya nuqtalari
          Positioned(
            bottom: 50,
            left: 0,
            right: 0,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: List.generate(3, (index) => AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                margin: const EdgeInsets.symmetric(horizontal: 5),
                width: _currentPage == index ? 20 : 8,
                height: 8,
                decoration: BoxDecoration(
                  color: _currentPage == index ? AppColors.accent : Colors.grey.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
              )),
            ),
          )
        ],
      ),
    );
  }

  // 1-Sahifa: Til tanlash
  Widget _buildLanguagePage() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.language, size: 80, color: AppColors.textLight),
        const SizedBox(height: 30),
        const Text("Tilni tanlang / Выберите язык", style: TextStyle(color: Colors.white, fontSize: 20)),
        const SizedBox(height: 30),
        _langButton("O'zbekcha", () => _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease)),
        const SizedBox(height: 15),
        _langButton("Русский", () => _pageController.nextPage(duration: const Duration(milliseconds: 500), curve: Curves.ease)),
      ],
    );
  }

  Widget _langButton(String text, VoidCallback onTap) {
    return SizedBox(
      width: 200,
      child: OutlinedButton(
        onPressed: onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: AppColors.accent),
          padding: const EdgeInsets.symmetric(vertical: 15),
        ),
        child: Text(text, style: const TextStyle(color: Colors.white)),
      ),
    );
  }

  // 2-Sahifa: Ma'lumot
  Widget _buildInfoPage() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Bu yerga Rive animatsiyasini qo'yishingiz mumkin
          const Icon(Icons.spatial_audio_off, size: 100, color: AppColors.accent),
          const SizedBox(height: 30),
          const Text(
            "Gapirchi - Yo'ldagi yordamchingiz",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
          ),
          const SizedBox(height: 20),
          const Text(
            "Haydovchilar bilan oson aloqa, tirbandliklar haqida xabar va quvnoq suhbatlar.",
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 16, color: AppColors.textLight),
          ),
        ],
      ),
    );
  }

  // 3-Sahifa: Harakat
  Widget _buildActionPage() {
    return Padding(
      padding: const EdgeInsets.all(30.0),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text("Boshlashga tayyormisiz?", style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white)),
          const SizedBox(height: 40),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const PhoneInputScreen()));
              },
              child: const Text("Ro'yxatdan o'tish / Kirish"),
            ),
          ),
        ],
      ),
    );
  }
}