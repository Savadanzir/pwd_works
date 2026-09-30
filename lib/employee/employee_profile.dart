import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../main.dart';
import 'employee_provider.dart';

class EmployeeProfile extends StatelessWidget {
  const EmployeeProfile({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<EmployeeProvider>(context);
    final e = prov.employee;
    return Scaffold(
      appBar: AppBar(title: const Text('Employee Profile')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                const CircleAvatar(
                    radius: 50, child: Icon(Icons.engineering, size: 50)),
                const SizedBox(height: 20),
                _row('Name', e?.name ?? '-'),
                _row('Email', e?.email ?? '-'),
                _row('Phone', e?.phone ?? '-'),
                _row('Department', e?.department ?? '-'),
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

  Widget _row(String label, String val) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Row(
          children: [
            Text(label,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.grey)),
            const Spacer(),
            Text(val),
          ],
        ),
      );
}