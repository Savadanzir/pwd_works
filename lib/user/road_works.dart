import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/report_card.dart';

class RoadWorks extends StatelessWidget {
  const RoadWorks({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Road Works')),
      body: FutureBuilder(
        future: FirestoreService().getAllReports(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!
              .where((d) => (d['category'] ?? '') == 'Road Work')
              .toList();
          if (docs.isEmpty) {
            return const Center(child: Text('No road works reported'));
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