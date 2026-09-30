import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../widgets/report_card.dart';
import 'employee_provider.dart';
import 'work_details.dart';

class AssignedWorks extends StatelessWidget {
  const AssignedWorks({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<EmployeeProvider>(context).employee?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('Assigned Works')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: FutureBuilder(
            future: FirestoreService().getEmployeeWorks(uid),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No works assigned'));
              }
              return ListView(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return ReportCard(
                    data: data,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) =>
                              WorkDetails(reportId: d.id, data: data)),
                    ),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ),
    );
  }
}