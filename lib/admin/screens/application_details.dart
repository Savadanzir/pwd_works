import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../models/report_model.dart';

class ApplicationDetails extends StatelessWidget {
  final ReportModel report;
  const ApplicationDetails({super.key, required this.report});

  Color _statusColor(String s) {
    switch (s) {
      case 'Pending': return const Color(0xFFF59E0B);
      case 'Approved': return const Color(0xFF3B82F6);
      case 'Assigned': return const Color(0xFFA855F7);
      case 'In Progress': return const Color(0xFF6366F1);
      case 'Completed': return const Color(0xFF10B981);
      case 'Rejected': return const Color(0xFFEF4444);
      default: return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(report.status);
    final dateStr = report.createdAt != null
        ? DateFormat('dd MMM yyyy • HH:mm').format(report.createdAt!.toDate())
        : '';

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Application Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF0B1130), Color(0xFF060A1E), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0])),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.white.withOpacity(0.10),
                      color.withOpacity(0.10)]),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(aspectRatio: 16 / 10,
                            child: Image.network(report.imageUrl!, fit: BoxFit.cover)),
                        ),
                      if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
                        const SizedBox(height: 16),
                      Row(children: [
                        Expanded(child: Text(report.title,
                          style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.65), width: 1)),
                          child: Text(report.status,
                            style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w800))),
                      ]),
                      const SizedBox(height: 16),
                      _tile('Reporter', report.userName),
                      _tile('Phone', report.userPhone),
                      _tile('Category', report.category),
                      _tile('Description', report.description),
                      _tile('Location', report.location),
                      if (dateStr.isNotEmpty) _tile('Reported', dateStr),
                      if ((report.adminReply ?? '').isNotEmpty)
                        _tile('Admin reply', report.adminReply!),
                      if ((report.employeeName ?? '').isNotEmpty)
                        _tile('Assigned to', report.employeeName!),
                      if ((report.workNote ?? '').isNotEmpty)
                        _tile('Work note', report.workNote!),
                      if (report.completionImage != null && report.completionImage!.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text('Completion Evidence',
                          style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.bold)),
                        const SizedBox(height: 8),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: AspectRatio(aspectRatio: 16 / 10,
                            child: Image.network(report.completionImage!, fit: BoxFit.cover)),
                        ),
                      ],
                    ],
                  ),
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