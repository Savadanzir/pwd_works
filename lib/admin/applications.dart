import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/report_card.dart';
import 'application_details.dart';

class Applications extends StatelessWidget {
  const Applications({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Applications')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: FutureBuilder(
            future: FirestoreService().getAllReports(),
            builder: (context, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }
              final docs = snap.data ?? [];
              if (docs.isEmpty) {
                return const Center(child: Text('No applications'));
              }
              return ListView(
                children: docs.map((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return ReportCard(
                    data: data,
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => ApplicationDetails(
                            reportId: d.id, data: data),
                      ),
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