import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class AdminDailyReports extends StatefulWidget {
  const AdminDailyReports({super.key});

  @override
  State<AdminDailyReports> createState() => _AdminDailyReportsState();
}

class _AdminDailyReportsState extends State<AdminDailyReports> {
  bool _loading = true;
  List<QueryDocumentSnapshot> _reports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('daily_reports')
          .orderBy('createdAt', descending: true)
          .get();
      setState(() => _reports = snap.docs);
    } catch (e) {
      _snack('❌ Failed to load: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Daily Reports',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF2A1B0B), Color(0xFF160A04), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _reports.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: const Color(0xFFF59E0B),
                      backgroundColor: const Color(0xFF0B1730),
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        itemCount: _reports.length,
                        itemBuilder: (context, i) => _reportCard(_reports[i]),
                      ),
                    ),
        ),
      ),
    );
  }

  Widget _emptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.5),
                    width: 1.5),
              ),
              child: const Icon(Icons.assignment_outlined,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'No daily reports yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Reports from employees will appear here.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _reportCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final name = data['employeeName'] ?? 'Employee';
    final dept = data['department'] ?? '';
    final hours = data['hoursWorked'] ?? '—';
    final tasks = data['tasksCompleted'] ?? '—';
    final blockers = data['blockers'] ?? '';
    final createdAt = data['createdAt'];
    final dateStr = createdAt is Timestamp
        ? DateFormat('dd MMM yyyy • HH:mm').format(createdAt.toDate())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                const Color(0xFFF59E0B).withOpacity(0.08),
              ]),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(dateStr,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 11)),
                  ],
                ),
                if (dept.toString().isNotEmpty) ...[
                  const SizedBox(height: 3),
                  Text(dept,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11.5)),
                ],
                const SizedBox(height: 12),

                // Hours
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded,
                        color: Color(0xFFF59E0B), size: 16),
                    const SizedBox(width: 8),
                    Text('Hours: $hours',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 10),

                // Tasks
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.10)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Tasks Completed',
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.55),
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8)),
                      const SizedBox(height: 4),
                      Text(tasks,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              height: 1.4)),
                    ],
                  ),
                ),

                // Blockers (optional)
                if (blockers.toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.redAccent.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: Colors.redAccent.withOpacity(0.35), width: 1),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Blockers / Notes',
                            style: TextStyle(
                                color: Colors.redAccent.withOpacity(0.9),
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.8)),
                        const SizedBox(height: 4),
                        Text(blockers,
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13,
                                height: 1.4)),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}