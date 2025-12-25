import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart'; // Sana uchun
import 'package:shared_preferences/shared_preferences.dart';
import '../../config/themes.dart';
import '../../providers/settings_provider.dart';
import '../../providers/user_provider.dart';
import '../../providers/radio_provider.dart';
import '../auth/phone_input_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String? _myDeviceId; // O'zimizning ID

  @override
  void initState() {
    super.initState();
    // Kirganda yuklaymiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchSessions();
    });
  }

  // Chiqish (Log Out)
  void _logout() async {
    Provider.of<RadioProvider>(
      context,
      listen: false,
    ).disconnect(); // Ratsiyani uzamiz
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const PhoneInputScreen()),
      (route) => false,
    );
  }

  Future<void> _loadMyDeviceId() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _myDeviceId = prefs.getString('device_unique_id');
    });
  }

  void _confirmDelete(
    String sessionId,
    String deviceName,
    String deviceIdOfSession,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1E1E1E),
        title: const Text("Diqqat", style: TextStyle(color: Colors.white)),
        content: Text(
          "Haqiqatan ham '$deviceName' qurilmasini hisobdan chiqarmoqchimisiz?",
          style: const TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Yo'q", style: TextStyle(color: Colors.grey)),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              try {
                // 1. Serverdan o'chiramiz
                await Provider.of<UserProvider>(
                  context,
                  listen: false,
                ).deleteSession(sessionId);

                // 2. TEKSHIRAMIZ: Agar bu o'zimiz bo'lsak -> Chiqib ketamiz
                if (_myDeviceId != null && _myDeviceId == deviceIdOfSession) {
                  _logout(); // <-- AVTOMATIK CHIQISH
                } else {
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Qurilma o'chirildi"),
                        backgroundColor: Colors.green,
                      ),
                    );
                  }
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Xatolik yuz berdi"),
                      backgroundColor: Colors.red,
                    ),
                  );
                }
              }
            },
            child: const Text(
              "Ha, o'chir",
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsProvider>(context);
    final userProvider = context.watch<UserProvider>();
    final sessions = userProvider.sessions;
    final isLoading = userProvider.isLoading;

    return Scaffold(
      appBar: AppBar(title: const Text("Sozlamalar")),
      body: ListView(
        children: [
          _sectionHeader("Ilova"),
          SwitchListTile(
            activeColor: AppTheme.darkTheme.primaryColor,
            tileColor: const Color(0xFF1E1E1E),
            title: const Text(
              "Tungi rejim",
              style: TextStyle(color: Colors.white),
            ),
            value: settings.themeMode == ThemeMode.dark,
            onChanged: (val) => settings.toggleTheme(val),
          ),

          const SizedBox(height: 20),
          _sectionHeader("Faol Qurilmalar"),

          if (isLoading)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(),
              ),
            )
          else if (sessions.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Text(
                "Faol qurilmalar ro'yxati bo'sh.",
                style: TextStyle(color: Colors.grey),
                textAlign: TextAlign.center,
              ),
            )
          else
            ...sessions.map((session) {
              // 1. Sanani formatlash
              String dateStr = "Noma'lum vaqt";
              if (session['lastActive'] != null) {
                final dt = DateTime.parse(session['lastActive']).toLocal();
                dateStr = DateFormat('dd.MM.yyyy HH:mm').format(dt);
              }

              // 2. Qurilma nomi
              final deviceName = session['deviceName'] ?? "Noma'lum";
              final sessionId = session['_id'];
              final deviceId = session['deviceId']; // Serverdan kelgan ID

              // Bu bizning qurilmamizmi?
              final isMe = (_myDeviceId != null && _myDeviceId == deviceId);

              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: isMe
                      ? Colors.green.withOpacity(0.1)
                      : const Color(
                          0xFF1E1E1E,
                        ), // O'zimizni ajratib ko'rsatamiz
                  borderRadius: BorderRadius.circular(10),
                  border: isMe
                      ? Border.all(color: Colors.green.withOpacity(0.5))
                      : null,
                ),
                child: ListTile(
                  leading: Icon(
                    Icons.phone_android,
                    color: isMe ? Colors.green : Colors.blueGrey,
                    size: 30,
                  ),
                  title: Text(
                    isMe ? "$deviceName (Bu qurilma)" : deviceName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  subtitle: Text(
                    "Oxirgi faollik: $dateStr",
                    style: const TextStyle(color: Colors.grey, fontSize: 12),
                  ),
                  trailing: IconButton(
                    icon: const Icon(
                      Icons.delete_forever,
                      color: Colors.redAccent,
                    ),
                    onPressed: () => _confirmDelete(
                      sessionId,
                      deviceName,
                      deviceId,
                    ), // ID ni ham beramiz
                  ),
                ),
              );
            }),

          const SizedBox(height: 40),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.withOpacity(0.8),
                padding: const EdgeInsets.symmetric(vertical: 15),
              ),
              icon: const Icon(Icons.logout, color: Colors.white),
              label: const Text(
                "Akkauntdan Chiqish",
                style: TextStyle(color: Colors.white, fontSize: 16),
              ),
              onPressed: _logout,
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 20, 10),
      child: Text(
        title.toUpperCase(),
        style: const TextStyle(
          color: Colors.blue,
          fontWeight: FontWeight.bold,
          fontSize: 13,
        ),
      ),
    );
  }
}
