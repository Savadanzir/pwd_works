import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/user_provider.dart';
import '../providers/report_provider.dart';
import '../models/report_model.dart';

class MyReports extends StatefulWidget {
  const MyReports({super.key});
  @override
  State<MyReports> createState() => _MyReportsState();
}

class _MyReportsState extends State<MyReports>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl, _orbCtrl, _dustCtrl;
  late Animation<double> _bgAnim, _orbAnim, _dustRise;
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
      final uid = Provider.of<UserProvider>(context, listen: false).user?.uid ?? '';
      Provider.of<ReportProvider>(context, listen: false).loadMyReports(uid);
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
    final prov = Provider.of<ReportProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('My Reports', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () {
              final uid = Provider.of<UserProvider>(context, listen: false).user?.uid ?? '';
              prov.loadMyReports(uid);
            },
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
                      child: prov.loading
                          ? const Center(child: CircularProgressIndicator(color: Colors.white))
                          : prov.myReports.isEmpty
                              ? _emptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                                  itemCount: prov.myReports.length,
                                  itemBuilder: (context, i) {
                                    final r = prov.myReports[i];
                                    return _reportCard(r);
                                  },
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

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
            radius: 1.5,
            colors: const [Color(0xFF062A1E), Color(0xFF040F0C), Color(0xFF04060F)],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      );

  Widget _orbs(Size size) => Stack(
        children: [
          Positioned(
            left: -size.width * 0.15 + _parallax.dx * -14,
            top: -size.height * 0.18 + _parallax.dy * -10,
            child: _orb(380, const Color(0xFF10B981), 0.28),
          ),
          Positioned(
            right: -size.width * 0.12 + _parallax.dx * 14,
            bottom: -size.height * 0.15 + _parallax.dy * 10,
            child: _orb(420, const Color(0xFF06B6D4), 0.22),
          ),
        ],
      );

  Widget _orb(double size, Color color, double opacity) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withOpacity(opacity * (0.85 + _orbAnim.value * 0.3)),
              color.withOpacity(0.0),
            ]),
          ),
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
      list.add(Positioned(
        left: x,
        top: y,
        child: IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Container(
              width: r * 2,
              height: r * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withOpacity(0.55),
              ),
            ),
          ),
        ),
      ));
    }
    return Stack(children: list);
  }

  Widget _emptyState() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('📋', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              "You haven't filed any reports yet",
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
            ),
          ],
        ),
      );

  Widget _reportCard(ReportModel r) {
    final statusColor = _statusColor(r.status);
    final dateStr = r.createdAt != null
        ? DateFormat('dd MMM yyyy • HH:mm').format(r.createdAt!.toDate())
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                statusColor.withOpacity(0.10),
              ]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (r.imageUrl != null && r.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                    child: AspectRatio(
                      aspectRatio: 16 / 9,
                      child: Image.network(r.imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              r.title,
                              style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: statusColor.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: statusColor.withOpacity(0.60), width: 1),
                            ),
                            child: Text(r.status, style: TextStyle(color: statusColor, fontSize: 10.5, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      if (r.description.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(r.description, maxLines: 3, overflow: TextOverflow.ellipsis,
                            style: TextStyle(color: Colors.white.withOpacity(0.80), fontSize: 12.5)),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 13),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(r.location, overflow: TextOverflow.ellipsis,
                                style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 11.5)),
                          ),
                          if (dateStr.isNotEmpty)
                            Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.50), fontSize: 10.5)),
                        ],
                      ),
                      if (r.status == 'Rejected' && (r.adminReply ?? '').isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withOpacity(0.10),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.35), width: 1),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(Icons.reply_rounded, color: Color(0xFFEF4444), size: 14),
                              const SizedBox(width: 8),
                              Expanded(child: Text(r.adminReply!, style: const TextStyle(color: Color(0xFFFCA5A5), fontSize: 11.5))),
                            ],
                          ),
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
}