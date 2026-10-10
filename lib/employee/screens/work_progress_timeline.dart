import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class WorkProgressTimeline extends StatelessWidget {
  final String reportId;
  const WorkProgressTimeline({super.key, required this.reportId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      appBar: AppBar(
        title: const Text('Progress Timeline'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('reports')
            .doc(reportId)
            .snapshots(),
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(
                child: CircularProgressIndicator(color: Colors.white));
          }
          final data = snap.data!.data() as Map<String, dynamic>;

          // Build the timeline events from the document
          final events = <_TLEvent>[];
          if (data['createdAt'] != null) {
            events.add(_TLEvent(
              icon: Icons.report_problem_rounded,
              color: const Color(0xFFF59E0B),
              title: 'Report Submitted',
              subtitle: 'By ${data['userName'] ?? 'user'}',
              time: _fmt(data['createdAt']),
            ));
          }
          if (data['approvedAt'] != null) {
            events.add(_TLEvent(
              icon: Icons.check_circle_rounded,
              color: const Color(0xFF3B82F6),
              title: 'Approved by Admin',
              subtitle: 'By ${data['approvedBy'] ?? 'admin'}',
              time: _fmt(data['approvedAt']),
            ));
          }
          if (data['assignedAt'] != null) {
            events.add(_TLEvent(
              icon: Icons.person_add_alt_1_rounded,
              color: const Color(0xFFA855F7),
              title: 'Assigned to Employee',
              subtitle: data['employeeName'] ?? '—',
              time: _fmt(data['assignedAt']),
            ));
          }
          if (data['startedAt'] != null) {
            events.add(_TLEvent(
              icon: Icons.play_circle_fill_rounded,
              color: const Color(0xFF6366F1),
              title: 'Work Started',
              subtitle: data['workNote'] ?? '',
              time: _fmt(data['startedAt']),
            ));
          }
          if (data['completedAt'] != null) {
            events.add(_TLEvent(
              icon: Icons.verified_rounded,
              color: const Color(0xFF10B981),
              title: 'Completed',
              subtitle: data['workNote'] ?? '',
              time: _fmt(data['completedAt']),
            ));
          }
          if (data['rejectedAt'] != null) {
            events.add(_TLEvent(
              icon: Icons.cancel_rounded,
              color: const Color(0xFFEF4444),
              title: 'Rejected',
              subtitle: data['adminReply'] ?? '',
              time: _fmt(data['rejectedAt']),
            ));
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Report summary
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      const Color(0xFFF59E0B).withOpacity(0.15),
                      Colors.white.withOpacity(0.05),
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.25),
                      width: 1.2,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        data['title'] ?? 'Untitled',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        data['description'] ?? '',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                // Timeline
                ...events.asMap().entries.map((e) {
                  final isLast = e.key == events.length - 1;
                  return _TimelineTile(event: e.value, isLast: isLast);
                }),
              ],
            ),
          );
        },
      ),
    );
  }

  static String _fmt(dynamic ts) {
    if (ts is Timestamp) {
      return DateFormat('dd MMM yyyy • HH:mm').format(ts.toDate());
    }
    return '';
  }
}

class _TLEvent {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final String time;
  _TLEvent({
    required this.icon,
    required this.color,
    required this.title,
    required this.subtitle,
    required this.time,
  });
}

class _TimelineTile extends StatelessWidget {
  final _TLEvent event;
  final bool isLast;
  const _TimelineTile({required this.event, required this.isLast});

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Icon column
          Column(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: event.color.withOpacity(0.20),
                  border: Border.all(
                    color: event.color.withOpacity(0.60),
                    width: 1.4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: event.color.withOpacity(0.45),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Icon(event.icon, color: event.color, size: 18),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    color: event.color.withOpacity(0.35),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 14),
          // Content
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    event.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  if (event.subtitle.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Text(
                      event.subtitle,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.70),
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                  const SizedBox(height: 4),
                  Text(
                    event.time,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.5),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}