import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/work_model.dart';
import 'update_work.dart';

class WorkDetails extends StatelessWidget {
  final WorkModel work;
  const WorkDetails({super.key, required this.work, required String reportId, required Map<dynamic, dynamic> data});

  Color _statusColor(String s) {
    switch (s) {
      case 'Assigned': return const Color(0xFFA855F7);
      case 'In Progress': return const Color(0xFF6366F1);
      case 'Completed': return const Color(0xFF10B981);
      case 'Rejected': return const Color(0xFFEF4444);
      default: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(work.status);
    final dateStr = work.createdAt != null
        ? DateFormat('dd MMM yyyy • HH:mm').format(work.createdAt!.toDate())
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Work Details',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF2E1E06), Color(0xFF140D02), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0])),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.white.withOpacity(0.10),
                      color.withOpacity(0.10)]),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    if (work.imageUrl != null && work.imageUrl!.isNotEmpty)
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(aspectRatio: 16 / 10,
                          child: Image.network(work.imageUrl!, fit: BoxFit.cover)),
                      ),
                    if (work.imageUrl != null && work.imageUrl!.isNotEmpty)
                      const SizedBox(height: 16),
                    Row(children: [
                      Expanded(child: Text(work.title,
                        style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: color.withOpacity(0.65), width: 1)),
                        child: Text(work.status,
                          style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))),
                    ]),
                    const SizedBox(height: 16),
                    _tile('Category', work.category),
                    _tile('Description', work.description),
                    _tile('Location', work.location),
                    if (dateStr.isNotEmpty) _tile('Reported', dateStr),
                    if ((work.workNote ?? '').isNotEmpty) _tile('Your Note', work.workNote!),
                    if ((work.adminReply ?? '').isNotEmpty) _tile('Admin reply', work.adminReply!),
                    if (work.completionImage != null && work.completionImage!.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      const Text('Completion Evidence',
                        style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: AspectRatio(aspectRatio: 16 / 10,
                          child: Image.network(work.completionImage!, fit: BoxFit.cover)),
                      ),
                    ],
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.edit, size: 18),
                        label: const Text('Update Work',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFF59E0B),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          elevation: 0),
                        onPressed: () => Navigator.push(context,
                          MaterialPageRoute(
                            builder: (_) => UpdateWork(
                              work: work,
                            ),
                          )),
                    ),
                    )
                  ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _tile(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 110, child: Text(label,
            style: const TextStyle(color: Colors.white54, fontSize: 12.5, fontWeight: FontWeight.bold))),
          Expanded(child: Text(value,
            style: const TextStyle(color: Colors.white, fontSize: 13.5))),
        ]),
      );
}