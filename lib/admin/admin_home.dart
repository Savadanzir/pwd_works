import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'admin_provider.dart';
import 'applications.dart';
import 'employee_assignment.dart';
import 'work_verification.dart';
import 'admin_profile.dart';

class AdminHome extends StatelessWidget {
  const AdminHome({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text('Admin panel is only available on the Web.'),
        ),
      );
    }

    final admin = Provider.of<AdminProvider>(context).admin;
    final items = [
      _Item('Applications', Icons.list_alt, Colors.blue, const Applications()),
      _Item('Assign Work', Icons.assignment_ind, Colors.orange,
          const EmployeeAssignment()),
      _Item('Verify Work', Icons.verified, Colors.green,
          const WorkVerification()),
    ];

    return Scaffold(
      appBar: AppBar(
        title: Text('Admin: ${admin?.name ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminProfile())),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: GridView.builder(
            padding: const EdgeInsets.all(16),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 1.2,
            ),
            itemCount: items.length,
            itemBuilder: (context, i) {
              final it = items[i];
              return InkWell(
                onTap: () => Navigator.push(
                    context, MaterialPageRoute(builder: (_) => it.page)),
                borderRadius: BorderRadius.circular(14),
                child: Card(
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircleAvatar(
                        radius: 28,
                        backgroundColor: it.color.withOpacity(0.15),
                        child: Icon(it.icon, size: 30, color: it.color),
                      ),
                      const SizedBox(height: 10),
                      Text(it.title,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _Item {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  _Item(this.title, this.icon, this.color, this.page);
}