import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../services/firestore_service.dart';
import '../widgets/report_card.dart';
import 'user_provider.dart';

class MyReports extends StatelessWidget {
  const MyReports({super.key});

  @override
  Widget build(BuildContext context) {
    final uid = Provider.of<UserProvider>(context).user?.uid ?? '';
    return Scaffold(
      appBar: AppBar(title: const Text('My Reports')),
      body: FutureBuilder(
        future: FirestoreService().getUserReports(uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snap.data ?? [];
          if (docs.isEmpty) {
            return const Center(child: Text('No reports yet'));
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