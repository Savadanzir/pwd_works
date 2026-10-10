import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/verification_provider.dart';
import '../models/report_model.dart';

class WorkVerification extends StatefulWidget {
  const WorkVerification({super.key});
  @override
  State<WorkVerification> createState() => _WorkVerificationState();
}

class _WorkVerificationState extends State<WorkVerification>
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
      Provider.of<VerificationProvider>(context, listen: false).loadToVerify();
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
    final prov = Provider.of<VerificationProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Work Verification',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.loadToVerify(),
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
                    SafeArea(bottom: false, child: _body(prov)),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _body(VerificationProvider prov) {
    if (prov.loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (prov.toVerify.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.verified_outlined, size: 64, color: Colors.grey),
              const SizedBox(height: 16),
              Text('Nothing to verify',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75),
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Text(
                'Reports appear here once an employee is assigned\nor starts working on them.',
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: Colors.white.withOpacity(0.5),
                    fontSize: 12.5,
                    height: 1.5),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: prov.loadToVerify,
      color: const Color(0xFF10B981),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: prov.toVerify.length,
        itemBuilder: (context, i) => _VerificationCard(
          report: prov.toVerify[i],
          onVerify: () => prov.markCompleted(prov.toVerify[i].id),
        ),
      ),
    );
  }

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
            radius: 1.5,
            colors: const [Color(0xFF062A1E), Color(0xFF04140F), Color(0xFF04060F)],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      );

  Widget _orbs(Size size) => Stack(children: [
        Positioned(
          left: -size.width * 0.15 + _parallax.dx * -14,
          top: -size.height * 0.18 + _parallax.dy * -10,
          child: _orb(380, const Color(0xFF10B981), 0.30)),
        Positioned(
          right: -size.width * 0.12 + _parallax.dx * 14,
          bottom: -size.height * 0.15 + _parallax.dy * 10,
          child: _orb(420, const Color(0xFF06B6D4), 0.22)),
      ]);

  Widget _orb(double size, Color color, double opacity) => IgnorePointer(
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withOpacity(opacity * (0.85 + _orbAnim.value * 0.3)),
              color.withOpacity(0.0)]))),
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

class _VerificationCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onVerify;
  const _VerificationCard({required this.report, required this.onVerify});

  Color _statusColor(String s) {
    switch (s) {
      case 'Assigned': return const Color(0xFFA855F7);
      case 'In Progress': return const Color(0xFF6366F1);
      default: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(report.status);
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
                color.withOpacity(0.10)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.35), blurRadius: 24, offset: const Offset(0, 10))],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (report.completionImage != null && report.completionImage!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: AspectRatio(aspectRatio: 16 / 10,
                      child: Image.network(report.completionImage!, fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(color: Colors.black26,
                          child: const Center(child: Icon(Icons.broken_image_outlined, color: Colors.white54, size: 40))))),
                  )
                else if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
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
                            color: color.withOpacity(0.20),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: color.withOpacity(0.65), width: 1)),
                          child: Text(report.status,
                            style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.4))),
                      ]),
                      const SizedBox(height: 8),
                      if (report.description.isNotEmpty)
                        Text(report.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.5)),
                      const SizedBox(height: 10),
                      Row(children: [
                        const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 14),
                        const SizedBox(width: 4),
                        Expanded(child: Text(report.location, overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12))),
                        if (dateStr.isNotEmpty)
                          Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
                      ]),
                      if ((report.employeeName ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFA855F7).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.35), width: 1)),
                          child: Row(children: [
                            const Icon(Icons.engineering_rounded, color: Color(0xFFA855F7), size: 14),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Working: ${report.employeeName}',
                              style: const TextStyle(color: Color(0xFFA855F7), fontSize: 11.5, fontWeight: FontWeight.w700))),
                          ]),
                        ),
                      ],
                      if ((report.workNote ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFF06B6D4).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFF06B6D4).withOpacity(0.35), width: 1)),
                          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                            const Icon(Icons.note_alt_rounded, color: Color(0xFF06B6D4), size: 14),
                            const SizedBox(width: 8),
                            Expanded(child: Text('Note: ${report.workNote}',
                              style: const TextStyle(color: Color(0xFF67E8F9), fontSize: 11.5, height: 1.4))),
                          ]),
                        ),
                      ],
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          icon: const Icon(Icons.verified_rounded, size: 18),
                          label: const Text('Verify & Mark Completed',
                            style: TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            elevation: 0),
                          onPressed: () async {
                            final ok = await showDialog<bool>(
                              context: context,
                              builder: (_) => AlertDialog(
                                backgroundColor: const Color(0xFF0B1730),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                title: const Text('Verify work?',
                                  style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
                                content: Text('Mark "${report.title}" as completed?',
                                  style: const TextStyle(color: Colors.white70)),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, false),
                                    child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
                                  TextButton(
                                    onPressed: () => Navigator.pop(context, true),
                                    style: TextButton.styleFrom(foregroundColor: const Color(0xFF10B981)),
                                    child: const Text('Verify')),
                                ],
                              ),
                            );
                            if (ok == true) onVerify();
                          },
                        ),
                      ),
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
}