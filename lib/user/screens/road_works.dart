import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../services/firestore_service.dart';
import '../providers/user_provider.dart';

class RoadWorks extends StatefulWidget {
  const RoadWorks({super.key});

  @override
  State<RoadWorks> createState() => _RoadWorksState();
}

class _RoadWorksState extends State<RoadWorks>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _dustCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _dustRise;
  Offset _parallax = Offset.zero;

  bool _loading = true;
  List<QueryDocumentSnapshot> _works = [];

  @override
  void initState() {
    super.initState();
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _orbCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _dustCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
    _dustRise = CurvedAnimation(parent: _dustCtrl, curve: Curves.linear);

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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

  // ============================================================
  // 🔄 LOAD — show works verified/completed by the admin
  // ============================================================
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid =
          Provider.of<UserProvider>(context, listen: false).user?.uid ?? '';
      if (uid.isEmpty) {
        setState(() => _works = []);
        return;
      }

      // All reports submitted by this user
      final snap = await FirestoreService().getUserReports(uid);

      // Keep ones whose category is Road Work AND the admin has finished
      // verifying/completing them
      final done = snap.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final cat = (data['category'] ?? '').toString();
        final status = (data['status'] ?? '').toString();
        final isRoadWork = cat == 'Road Work';
        final isVerified = status == 'Completed' || status == 'Verified';
        return isRoadWork && isVerified;
      }).toList();

      // Newest first
      done.sort((a, b) {
        final ta = (a.data() as Map)['createdAt'];
        final tb = (b.data() as Map)['createdAt'];
        if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
        return 0;
      });

      setState(() => _works = done);
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
        title: const Text('Road Works',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
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
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white))
                          : _works.isEmpty
                              ? _emptyState()
                              : RefreshIndicator(
                                  color: const Color(0xFFF59E0B),
                                  backgroundColor: const Color(0xFF0B1730),
                                  onRefresh: _load,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 40),
                                    itemCount: _works.length,
                                    itemBuilder: (context, i) =>
                                        _workCard(_works[i]),
                                  ),
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
              child: const Icon(Icons.construction_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'No verified road works yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Your reported issues will appear here once the admin verifies them.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _workCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Road Work';
    final desc = data['description'] ?? '';
    final location = data['location'] ?? '—';
    final status = data['status'] ?? 'Completed';
    final imageUrl = data['imageUrl'];
    final completionImage = data['completionImage'];
    final workNote = data['workNote'];
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
                  Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header row
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFFF59E0B).withOpacity(0.20),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withOpacity(0.6),
                            width: 1.2),
                      ),
                      child: const Icon(Icons.construction_rounded,
                          color: Colors.white, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w700),
                      ),
                    ),
                    _statusPill(status),
                  ],
                ),

                if (desc.toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12.5,
                        height: 1.4),
                  ),
                ],

                const SizedBox(height: 10),

                // Location + date
                Row(
                  children: [
                    const Icon(Icons.location_on,
                        color: Colors.redAccent, size: 14),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        location,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11.5),
                      ),
                    ),
                    if (dateStr.isNotEmpty)
                      Text(dateStr,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 10.5)),
                  ],
                ),

                // Before / After photo thumbnails
                if (imageUrl != null || completionImage != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      if (imageUrl != null)
                        Expanded(
                          child: _photoThumb(imageUrl, 'Before'),
                        ),
                      if (imageUrl != null && completionImage != null)
                        const SizedBox(width: 10),
                      if (completionImage != null)
                        Expanded(
                          child: _photoThumb(completionImage, 'After'),
                        ),
                    ],
                  ),
                ],

                if (workNote != null &&
                    workNote.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFF10B981).withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.4),
                          width: 1),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.verified_rounded,
                            color: Color(0xFF10B981), size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Admin: $workNote',
                            style: const TextStyle(
                                color: Color(0xFF10B981),
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
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

  Widget _photoThumb(String url, String label) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: AspectRatio(
        aspectRatio: 4 / 3,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.white10,
                child: const Icon(Icons.broken_image,
                    color: Colors.white54, size: 28),
              ),
            ),
            Positioned(
              left: 6,
              top: 6,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.65),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  label,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusPill(String status) {
    final color = status == 'Completed' || status == 'Verified'
        ? const Color(0xFF10B981)
        : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.65), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
            color: color,
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.5),
      ),
    );
  }

  // ---------- Animated background ----------
  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
                -0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
            radius: 1.5,
            colors: const [
              Color(0xFF2A1B0B),
              Color(0xFF160A04),
              Color(0xFF04060F),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      );

  Widget _orbs(Size size) => Stack(
        children: [
          Positioned(
            left: -size.width * 0.15 + _parallax.dx * -14,
            top: -size.height * 0.18 + _parallax.dy * -10,
            child: _orb(380, const Color(0xFFF59E0B), 0.28),
          ),
          Positioned(
            right: -size.width * 0.12 + _parallax.dx * 14,
            bottom: -size.height * 0.15 + _parallax.dy * 10,
            child: _orb(420, const Color(0xFFEF4444), 0.20),
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
      final x =
          size.width * (0.05 + (i % 9) * 0.11) + math.sin((p + i) * 5) * 20;
      final y = size.height - p * size.height * 0.9;
      final opacity = ((1.0 - p) * 0.35).clamp(0.0, 1.0);
      final r = 1.6 + (i % 3) * 1.4;
      list.add(
        Positioned(
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
                  boxShadow: [
                    BoxShadow(
                        color: Colors.white.withOpacity(0.30),
                        blurRadius: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: list);
  }
}