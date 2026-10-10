import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/applications_provider.dart';
import '../providers/admin_provider.dart';
import '../models/report_model.dart';

class Applications extends StatefulWidget {
  const Applications({super.key});
  @override
  State<Applications> createState() => _ApplicationsState();
}

class _ApplicationsState extends State<Applications>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _dustCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _dustRise;
  Offset _parallax = Offset.zero;

  @override
  void initState() {
    super.initState();
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);
    _dustCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _dustRise = CurvedAnimation(parent: _dustCtrl, curve: Curves.linear);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<ApplicationsProvider>(context, listen: false).loadAll();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _orbCtrl.dispose();
    _dustCtrl.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent e, Size size) {
    final dx = (e.localPosition.dx / size.width - 0.5) * 2;
    final dy = (e.localPosition.dy / size.height - 0.5) * 2;
    setState(() => _parallax = Offset(dx, dy));
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<ApplicationsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Applications',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.loadAll(),
          ),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return MouseRegion(
            onHover: (e) => _onHover(e, size),
            child: AnimatedBuilder(
              animation: Listenable.merge([_bgAnim, _orbAnim, _dustRise]),
              builder: (context, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _gradientBase(),
                    _orbs(size),
                    _dust(size),
                    SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          _filterChips(prov),
                          Expanded(child: _body(prov)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _filterChips(ApplicationsProvider prov) {
    final filters = [
      ('Pending', Icons.hourglass_top_rounded, const Color(0xFFF59E0B)),
      ('Approved', Icons.check_circle_rounded, const Color(0xFF3B82F6)),
      ('Rejected', Icons.cancel_rounded, const Color(0xFFEF4444)),
      ('All', Icons.list_alt_rounded, const Color(0xFF06B6D4)),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: filters.map((f) {
            final selected = prov.filter == f.$1;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: GestureDetector(
                onTap: () => prov.setFilter(f.$1),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: selected ? f.$3.withOpacity(0.20) : Colors.white.withOpacity(0.06),
                    borderRadius: BorderRadius.circular(100),
                    border: Border.all(
                      color: selected ? f.$3.withOpacity(0.75) : Colors.white.withOpacity(0.20),
                      width: 1.3,
                    ),
                    boxShadow: selected
                        ? [BoxShadow(color: f.$3.withOpacity(0.40), blurRadius: 14, offset: const Offset(0, 4))]
                        : null,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(f.$2, size: 16,
                          color: selected ? f.$3 : Colors.white.withOpacity(0.7)),
                      const SizedBox(width: 8),
                      Text(f.$1,
                          style: TextStyle(
                            color: selected ? f.$3 : Colors.white.withOpacity(0.7),
                            fontSize: 13, fontWeight: FontWeight.w700, letterSpacing: 0.3)),
                    ],
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }

  Widget _body(ApplicationsProvider prov) {
    if (prov.loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (prov.error != null) {
      return Center(child: Padding(padding: const EdgeInsets.all(24),
        child: Text('Error: ${prov.error}',
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white70))));
    }

    final docs = prov.visibleReports;
    if (docs.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.inbox_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No ${prov.filter.toLowerCase()} applications',
              style: TextStyle(color: Colors.white.withOpacity(0.75),
                fontSize: 15, fontWeight: FontWeight.w700)),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: prov.loadAll,
      color: const Color(0xFF3B82F6),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 40),
        itemCount: docs.length,
        itemBuilder: (context, i) => _ApplicationCard(
          report: docs[i],
          onChanged: prov.loadAll,
          onApprove: () async {
            final admin = Provider.of<AdminProvider>(context, listen: false).admin;
            await prov.approve(docs[i].id, admin?.name);
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Approved → ready to assign'),
                  backgroundColor: Color(0xFF10B981),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            }
          },
          onReject: (reason) async {
            final admin = Provider.of<AdminProvider>(context, listen: false).admin;
            await prov.reject(docs[i].id, reason, admin?.name);
          },
        ),
      ),
    );
  }

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
            radius: 1.5,
            colors: const [Color(0xFF0B1130), Color(0xFF060A1E), Color(0xFF04060F)],
            stops: const [0.0, 0.55, 1.0]),
        ),
      );

  Widget _orbs(Size size) => Stack(children: [
        Positioned(
          left: -size.width * 0.15 + _parallax.dx * -14,
          top: -size.height * 0.18 + _parallax.dy * -10,
          child: _orb(380, const Color(0xFF3B82F6), 0.30)),
        Positioned(
          right: -size.width * 0.12 + _parallax.dx * 14,
          bottom: -size.height * 0.15 + _parallax.dy * 10,
          child: _orb(420, const Color(0xFF8B5CF6), 0.24)),
      ]);

  Widget _orb(double size, Color color, double opacity) => IgnorePointer(
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withOpacity(opacity * (0.85 + _orbAnim.value * 0.3)),
              color.withOpacity(0.0)])),
        ),
      );

  Widget _dust(Size size) {
    final list = <Widget>[];
    for (int i = 0; i < 18; i++) {
      final seed = (i * 0.137) % 1.0;
      final p = (_dustRise.value + seed) % 1.0;
      final x = size.width * (0.05 + (i % 9) * 0.11) + math.sin((p + i) * 5) * 20;
      final y = size.height - p * size.height * 0.9;
      final opacity = ((1.0 - p) * 0.35).clamp(0.0, 1.0);
      final r = 1.6 + (i % 3) * 1.4;
      list.add(Positioned(left: x, top: y,
        child: IgnorePointer(child: Opacity(opacity: opacity,
          child: Container(width: r * 2, height: r * 2,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.55)))))));
    }
    return Stack(children: list);
  }
}

class _ApplicationCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onChanged;
  final VoidCallback onApprove;
  final Function(String reason) onReject;

  const _ApplicationCard({
    required this.report,
    required this.onChanged,
    required this.onApprove,
    required this.onReject,
  });

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
    final statusColor = _statusColor(report.status);
    final isPending = report.status == 'Pending';
    final dateStr = report.createdAt != null
        ? DateFormat('dd MMM yyyy • HH:mm').format(report.createdAt!.toDate())
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                statusColor.withOpacity(0.10)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: isPending ? statusColor.withOpacity(0.65) : Colors.white.withOpacity(0.25),
                width: isPending ? 1.5 : 1.2),
              boxShadow: [
                BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10)),
                if (isPending) BoxShadow(color: statusColor.withOpacity(0.25), blurRadius: 20, offset: const Offset(0, 6)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: AspectRatio(aspectRatio: 16 / 10,
                      child: Image.network(report.imageUrl!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.black26,
                          child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 40))))),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Expanded(child: Text(report.title,
                          style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: statusColor.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: statusColor.withOpacity(0.65), width: 1)),
                          child: Text(report.status,
                            style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.4))),
                      ]),
                      const SizedBox(height: 10),
                      if (report.description.isNotEmpty)
                        Text(report.description, maxLines: 3, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.5)),
                      const SizedBox(height: 12),
                      _row('Reporter', report.userName),
                      _row('Category', report.category),
                      _row('Location', report.location),
                      if (report.status == 'Rejected' && (report.adminReply ?? '').isNotEmpty)
                        _row('Reply', report.adminReply!),
                      if ((report.employeeName ?? '').isNotEmpty)
                        _row('Assigned to', report.employeeName!),
                      const SizedBox(height: 12),
                      if (dateStr.isNotEmpty)
                        Row(children: [
                          Icon(Icons.schedule_rounded, size: 12, color: Colors.white.withOpacity(0.45)),
                          const SizedBox(width: 4),
                          Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
                        ]),
                      if (isPending) ...[
                        const SizedBox(height: 14),
                        Row(children: [
                          Expanded(child: OutlinedButton.icon(
                            icon: const Icon(Icons.close_rounded, size: 18),
                            label: const Text('Reject'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: Colors.redAccent,
                              side: const BorderSide(color: Colors.redAccent, width: 1.4),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14)),
                            onPressed: () => _showRejectDialog(context))),
                          const SizedBox(width: 10),
                          Expanded(child: ElevatedButton.icon(
                            icon: const Icon(Icons.check_rounded, size: 18),
                            label: const Text('Approve'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF10B981),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              elevation: 0),
                            onPressed: onApprove)),
                        ]),
                      ],
                      if (report.status == 'Approved') ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF3B82F6).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.35), width: 1)),
                          child: const Row(children: [
                            Icon(Icons.info_outline, size: 16, color: Color(0xFF3B82F6)),
                            SizedBox(width: 8),
                            Expanded(child: Text('Ready to assign → open "Assign Work"',
                              style: TextStyle(color: Color(0xFF3B82F6), fontSize: 12, fontWeight: FontWeight.w700))),
                          ]),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _row(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
          SizedBox(width: 92, child: Text(label,
            style: TextStyle(fontSize: 12.5, color: Colors.white.withOpacity(0.55), fontWeight: FontWeight.w500))),
          Expanded(child: Text(value, style: const TextStyle(color: Colors.white, fontSize: 13))),
        ]),
      );

  void _showRejectDialog(BuildContext context) {
    final reason = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0B1730),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Application',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, children: [
          Text('This message will be sent to the user.',
            style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12.5)),
          const SizedBox(height: 12),
          TextField(
            controller: reason, maxLines: 3,
            style: const TextStyle(color: Colors.white),
            cursorColor: const Color(0xFFEF4444),
            decoration: InputDecoration(
              labelText: 'Reason / reply message',
              labelStyle: TextStyle(color: Colors.white.withOpacity(0.70)),
              hintText: 'e.g. Duplicate report / Insufficient detail',
              hintStyle: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 12.5),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.2)),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFFEF4444), width: 1.4)),
            )),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          TextButton(
            onPressed: () {
              final msg = reason.text.trim();
              if (msg.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please write a reply message'),
                    backgroundColor: Colors.red, behavior: SnackBarBehavior.floating));
                return;
              }
              Navigator.pop(context);
              onReject(msg);
            },
            style: TextButton.styleFrom(foregroundColor: const Color(0xFFEF4444)),
            child: const Text('Reject')),
        ],
      ),
    );
  }
}