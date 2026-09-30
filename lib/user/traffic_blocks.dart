import 'package:flutter/material.dart';
import '../services/firestore_service.dart';
import '../widgets/report_card.dart';

class TrafficBlocks extends StatelessWidget {
  const TrafficBlocks({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Traffic Blocks')),
      body: FutureBuilder(
        future: FirestoreService().getAllReports(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data!
              .where((d) => (d['category'] ?? '') == 'Traffic Block')
              .toList();
          if (docs.isEmpty) {
            return const Center(child: Text('No traffic blocks reported'));
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