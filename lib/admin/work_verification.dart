import 'package:flutter/material.dart';
import '../services/firestore_service.dart';

class WorkVerification extends StatelessWidget {
  const WorkVerification({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Work Verification')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: FutureBuilder(
            future: FirestoreService().getAllReports(),
            builder: (context, snap) {
              if (!snap.hasData) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data!
                  .where((d) =>
                      (d['status'] ?? '') == 'In Progress' ||
                      (d['status'] ?? '') == 'Assigned')
                  .toList();
              if (docs.isEmpty) {
                return const Center(child: Text('Nothing to verify'));
              }
              return ListView.builder(
                itemCount: docs.length,
                itemBuilder: (context, i) {
                  final d = docs[i];
                  final data = d.data() as Map<String, dynamic>;
                  return Card(
                    margin: const EdgeInsets.all(10),
                    child: ListTile(
                      leading: const Icon(Icons.engineering,
                          color: Colors.orange),
                      title: Text(data['title'] ?? ''),
                      subtitle: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Status: ${data['status']}'),
                          if (data['employeeName'] != null)
                            Text('Employee: ${data['employeeName']}'),
                        ],
                      ),
                      trailing: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.green,
                            foregroundColor: Colors.white),
                        onPressed: () async {
                          await FirestoreService()
                              .updateReport(d.id, {'status': 'Completed'});
                          ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                  content:
                                      Text('Marked completed')));
                        },
                        child: const Text('Verify'),
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
}