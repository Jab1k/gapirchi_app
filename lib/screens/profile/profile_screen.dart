import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../config/themes.dart';
import '../../providers/user_provider.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final _nameCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    // Ekranga kirganda profilni yuklaymiz
    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).fetchProfile();
    });
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.user;

    if (user == null) {
      return const Scaffold(
        backgroundColor: AppColors.darkBg,
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final bool isDriver = user['userType'] == 'driver';
    
    // Mashina ma'lumotlarini chiroyli olish
    String brandName = "Noma'lum";
    String modelName = "";
    if (user['carBrand'] is Map) brandName = user['carBrand']['name'];
    if (user['carModel'] is Map) modelName = user['carModel']['name'];

    return Scaffold(
      backgroundColor: AppColors.darkBg,
      appBar: AppBar(
        title: const Text("Mening Profilim"),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit, color: AppColors.accent),
            onPressed: () => _showEditDialog(context, user['firstName']),
          )
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            const CircleAvatar(
              radius: 50,
              backgroundColor: AppColors.cardBg,
              child: Icon(Icons.person, size: 50, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              user['firstName'] ?? "Ism yo'q",
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.white),
            ),
            Text(
              user['phoneNumber'] ?? "",
              style: const TextStyle(color: Colors.grey, fontSize: 16),
            ),
            
            const SizedBox(height: 30),

            // Faqat Haydovchilar uchun mashina kartasi
            if (isDriver)
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.directions_car, color: AppColors.accent),
                        SizedBox(width: 10),
                        Text("Avtomobil", style: TextStyle(color: Colors.grey)),
                      ],
                    ),
                    const Divider(color: Colors.white24, height: 20),
                    _infoRow("Marka", brandName),
                    _infoRow("Model", modelName),
                    _infoRow("Davlat Raqami", user['carNumber'] ?? "-"),
                  ],
                ),
              ),
              
            if (!isDriver)
               Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: AppColors.cardBg,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Text("Siz yo'lovchi rejimidasiz", style: TextStyle(color: Colors.white70)),
               )
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.white70)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.accent)),
        ],
      ),
    );
  }

  // Ismni o'zgartirish oynasi
  void _showEditDialog(BuildContext context, String currentName) {
    _nameCtrl.text = currentName;
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        title: const Text("Ismni o'zgartirish", style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: _nameCtrl,
          style: const TextStyle(color: Colors.white),
          decoration: const InputDecoration(labelText: "Ismingiz"),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text("Bekor qilish")),
          TextButton(
            onPressed: () async {
              if (_nameCtrl.text.isNotEmpty) {
                await Provider.of<UserProvider>(context, listen: false)
                    .updateProfile({"firstName": _nameCtrl.text.trim()});
                Navigator.pop(ctx);
              }
            },
            child: const Text("Saqlash", style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );
  }
}