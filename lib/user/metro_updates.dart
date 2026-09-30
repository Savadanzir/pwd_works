import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/report_card.dart';

class MetroUpdates extends StatelessWidget {
  const MetroUpdates({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Metro Updates')),
      body: FutureBuilder(
        future: FirestoreService().getAllReports(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!
              .where((d) => (d['category'] ?? '') == 'Metro')
              .toList();
          if (docs.isEmpty) {
            return const Center(child: Text('No metro updates'));
          }
          return ListView(
            children: docs
                .map((d) => ReportCard(data: d.data() as Map<String, dynamic>))
                .toList(),
          );
        },
      ),
    );
  }
}