import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:gapirchi_app/screens/profile/profile_screen.dart';
import 'package:gapirchi_app/screens/settings/settings_screen.dart';
import 'package:shorebird_code_push/shorebird_code_push.dart';
import '../config/themes.dart'; // Ranglar uchun
import 'main/radio_screen.dart';
// import 'settings/settings_screen.dart'; // Keyinroq yaratasiz
// import 'profile/profile_screen.dart';   // Keyinroq yaratasiz

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  int _currentIndex = 0;

  // --- Shorebird (Yangilanish) O'zgaruvchilari ---
  final _updater = ShorebirdUpdater();
  bool _isPatchDownloading = false;
  // -----------------------------------------------

  final List<Widget> _pages = [
    const RadioScreen(), // 0: Ratsiya
    const SettingsScreen(), // 1: Sozlamalar (Vaqtinchalik)
    const ProfileScreen(), // 2: Profil (Vaqtinchalik)
  ];

  @override
  void initState() {
    super.initState();
    // Ilova ochilishi bilan yangilanishni tekshiramiz
    _checkForUpdates();
  }

  // --- Shorebird Logikasi ---
  Future<void> _checkForUpdates() async {
    try {
      final status = await _updater.checkForUpdate();
      if (status == UpdateStatus.outdated) {
        _showUpdateAvailable();
      }
    } catch (e) {
      debugPrint('Yangilanish tekshirishda xato: $e');
    }
  }

  void _showUpdateAvailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Yangi versiya mavjud!'),
        action: SnackBarAction(label: 'Yangilash', onPressed: _downloadUpdate),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppColors.primary,
      ),
    );
  }

  Future<void> _downloadUpdate() async {
    setState(() => _isPatchDownloading = true);

    // Yuklanishni ko'rsatish uchun Snackbar
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Yangilanish yuklanmoqda...'),
        duration: Duration(minutes: 5), // Uzoqroq turishi uchun
        behavior: SnackBarBehavior.floating,
      ),
    );

    try {
      await _updater.update();
      if (!mounted) return;

      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      _showRestartDialog();
    } on UpdateException catch (e) {
      ScaffoldMessenger.of(context).hideCurrentSnackBar();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Xatolik: ${e.message}')));
    } finally {
      if (mounted) setState(() => _isPatchDownloading = false);
    }
  }

  void _showRestartDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Yangilanish tayyor"),
        content: const Text(
          "O'zgarishlar kuchga kirishi uchun ilovani qayta ishga tushiring.",
        ),
        actions: [
          TextButton(
            onPressed: () {
              SystemChannels.platform.invokeMethod('SystemNavigator.pop');
            },
            child: const Text("Chiqish va Qayta kirish"),
          ),
        ],
      ),
    );
  }
  // -----------------------------------------------

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.darkBg, // To'q fon
      body: IndexedStack(index: _currentIndex, children: _pages),
      bottomNavigationBar: BottomNavigationBar(
        backgroundColor: AppColors.darkBg,
        selectedItemColor: AppColors.accent, // Ochiq ko'k
        unselectedItemColor: Colors.grey,
        currentIndex: _currentIndex,
        onTap: (index) => setState(() => _currentIndex = index),
        type: BottomNavigationBarType.fixed,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.radio), label: "Ratsiya"),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: "Sozlamalar",
          ),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: "Profil"),
        ],
      ),
    );
  }
}
