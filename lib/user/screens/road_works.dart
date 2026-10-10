import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../providers/road_work_provider.dart';

class RoadWorks extends StatefulWidget {
  const RoadWorks({super.key});
  @override
  State<RoadWorks> createState() => _RoadWorksState();
}

class _RoadWorksState extends State<RoadWorks>
    with TickerProviderStateMixin {
  String _filter = 'active';

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
      Provider.of<RoadWorkProvider>(context, listen: false).loadActiveWorks();
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
    final prov = Provider.of<RoadWorkProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Road Works', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.loadActiveWorks(),
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
                          : prov.activeWorks.isEmpty
                              ? _emptyState()
                              : ListView.builder(
                                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                                  itemCount: prov.activeWorks.length,
                                  itemBuilder: (context, i) {
                                    final r = prov.activeWorks[i];
                                    return _RoadWorkCard(report: r);
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
            colors: const [Color(0xFF3A2A08), Color(0xFF16100A), Color(0xFF04060F)],
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
            const Text('🛠️', style: TextStyle(fontSize: 64)),
            const SizedBox(height: 16),
            Text(
              'No active road works right now',
              style: TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 15),
            ),
          ],
        ),
      );
}

class _RoadWorkCard extends StatelessWidget {
  final dynamic report;
  const _RoadWorkCard({required this.report});

  Color _statusColor(String s) {
    switch (s) {
      case 'Approved': return const Color(0xFF3B82F6);
      case 'Assigned': return const Color(0xFFA855F7);
      case 'In Progress': return const Color(0xFF6366F1);
      case 'Completed': return const Color(0xFF10B981);
      default: return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(report.status);
    final dateStr = report.createdAt != null
        ? DateFormat('dd MMM yyyy').format(report.createdAt!.toDate())
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
                color.withOpacity(0.10),
              ]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(report.imageUrl!, fit: BoxFit.cover),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              report.title,
                              style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: color.withOpacity(0.20),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(color: color.withOpacity(0.65), width: 1),
                            ),
                            child: Text(report.status,
                                style: TextStyle(color: color, fontSize: 10.5, fontWeight: FontWeight.w800)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (report.description.isNotEmpty)
                        Text(
                          report.description,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              report.location,
                              style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12),
                            ),
                          ),
                          Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
                        ],
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