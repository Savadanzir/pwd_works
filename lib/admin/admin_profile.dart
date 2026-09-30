import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'admin_provider.dart';

class AdminProfile extends StatelessWidget {
  const AdminProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<AdminProvider>(context);
    final a = prov.admin;
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                    radius: 50,
                    child: Icon(Icons.admin_panel_settings, size: 50)),
                const SizedBox(height: 20),
                Text(a?.name ?? '',
                    style: const TextStyle(
                        fontSize: 20, fontWeight: FontWeight.bold)),
                Text(a?.email ?? ''),
                const Spacer(),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    icon: const Icon(Icons.logout),
                    label: const Text('Logout'),
                    style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        foregroundColor: Colors.white),
                    onPressed: () async {
                      await prov.logout();
                      if (context.mounted) {
                        Navigator.pushAndRemoveUntil(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const WebPortalScreen()),
                            (_) => false);
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}