import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'assigned_works.dart';
import 'employee_profile.dart';
import 'employee_provider.dart';

class EmployeeHome extends StatelessWidget {
  const EmployeeHome({super.key});

  @override
  Widget build(BuildContext context) {
    if (!kIsWeb) {
      return const Scaffold(
        body: Center(
          child: Text('Employee portal is only available on the Web.'),
        ),
      );
    }

    final emp = Provider.of<EmployeeProvider>(context).employee;
    return Scaffold(
      appBar: AppBar(
        title: Text('Employee: ${emp?.name ?? ""}'),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const EmployeeProfile())),
          ),
        ],
      ),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 800),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Card(
                  child: ListTile(
                    leading:
                        const Icon(Icons.engineering, color: Colors.blue),
                    title: Text(emp?.name ?? ''),
                    subtitle: Text('Dept: ${emp?.department ?? ''}'),
                  ),
                ),
                const SizedBox(height: 20),
                Expanded(
                  child: InkWell(
                    onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => const AssignedWorks())),
                    borderRadius: BorderRadius.circular(14),
                    child: Card(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.assignment,
                              size: 80, color: Colors.orange),
                          const SizedBox(height: 10),
                          const Text('View Assigned Works',
                              style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold)),
                          const SizedBox(height: 6),
                          Text('Tap to see your tasks',
                              style: TextStyle(color: Colors.grey[600])),
                        ],
                      ),
                    ),
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