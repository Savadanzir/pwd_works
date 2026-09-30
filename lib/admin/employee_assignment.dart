import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class EmployeeAssignment extends StatelessWidget {
  const EmployeeAssignment({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Assign Employee')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: FutureBuilder(
            future: FirestoreService().getAllReports(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = (snap.data ?? [])
                  .where((d) => (d['status'] ?? '') == 'Pending')
                  .toList();
              if (docs.isEmpty) {
                return const Center(child: Text('No pending reports'));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final data = d.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      title: Text(data['title'] ?? ''),
                      subtitle: Text(data['location'] ?? ''),
                      trailing: ElevatedButton(
                        child: const Text('Assign'),
                        onPressed: () =>
                            _showAssignDialog(context, d.id, data),
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ),
      ),
    );
  }

  void _showAssignDialog(
      BuildContext context, String reportId, Map<String, dynamic> data) {
    showDialog(
      context: context,
      builder: (_) => FutureBuilder(
        future: FirestoreService().getAllEmployees(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const AlertDialog(
              content: SizedBox(
                  height: 100,
                  child: Center(child: CircularProgressIndicator())),
            );
          }
          final emps = snap.data!;
          if (emps.isEmpty) {
            return const AlertDialog(
                content: Text('No employees registered yet'));
          }
          return AlertDialog(
            title: const Text('Select Employee'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: emps.length,
                itemBuilder: (context, i) {
                  final e = emps[i].data() as Map<String, dynamic>;
                  return ListTile(
                    leading: const Icon(Icons.engineering),
                    title: Text(e['name'] ?? ''),
                    subtitle: Text(e['email'] ?? ''),
                    onTap: () async {
                      await FirestoreService().updateReport(reportId, {
                        'status': 'Assigned',
                        'assignedTo': e['uid'],
                        'employeeName': e['name'],
                      });
                      if (context.mounted) Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                              content:
                                  Text('Assigned to ${e['name']}')));
                    },
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}