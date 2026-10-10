import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/work_history_provider.dart';
import '../providers/employee_provider.dart';
import '../models/work_model.dart';

class WorkHistory extends StatefulWidget {
  const WorkHistory({super.key});
  @override
  State<WorkHistory> createState() => _WorkHistoryState();
}

class _WorkHistoryState extends State<WorkHistory>
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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid =
          Provider.of<EmployeeProvider>(context, listen: false).employee?.uid;
      if (uid != null) {
        Provider.of<WorkHistoryProvider>(context, listen: false)
            .loadHistory(uid);
      }
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
    final prov = Provider.of<WorkHistoryProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Work History',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                final uid =
                    Provider.of<EmployeeProvider>(context, listen: false)
                        .employee
                        ?.uid;
                if (uid != null) prov.loadHistory(uid);
              }),
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

  Widget _body(WorkHistoryProvider prov) {
    if (prov.loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (prov.history.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.history_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No completed works yet',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Completed tasks will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
              ])));
    }

    return RefreshIndicator(
      onRefresh: () {
        final uid =
            Provider.of<EmployeeProvider>(context, listen: false).employee?.uid;
        return prov.loadHistory(uid ?? '');
      },
      color: const Color(0xFF3B82F6),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: prov.history.length,
        itemBuilder: (context, i) => _HistoryCard(work: prov.history[i]),
      ),
    );
  }

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
            gradient: RadialGradient(
                center: Alignment(
                    -0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
                radius: 1.5,
                colors: const [
              Color(0xFF0B1D3A),
              Color(0xFF04101F),
              Color(0xFF04060F)
            ],
                stops: const [
              0.0,
              0.55,
              1.0
            ])),
      );

  Widget _orbs(Size size) => Stack(children: [
        Positioned(
            left: -size.width * 0.15 + _parallax.dx * -14,
            top: -size.height * 0.18 + _parallax.dy * -10,
            child: _orb(380, const Color(0xFF3B82F6), 0.28)),
        Positioned(
            right: -size.width * 0.12 + _parallax.dx * 14,
            bottom: -size.height * 0.15 + _parallax.dy * 10,
            child: _orb(420, const Color(0xFF8B5CF6), 0.20)),
      ]);

  Widget _orb(double size, Color color, double opacity) => IgnorePointer(
        child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  color.withOpacity(opacity * (0.85 + _orbAnim.value * 0.3)),
                  color.withOpacity(0.0)
                ]))),
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
                          color: Colors.white.withOpacity(0.55)))))));
    }
    return Stack(children: list);
  }
}

class _HistoryCard extends StatelessWidget {
  final WorkModel work;
  const _HistoryCard({required this.work});

  @override
  Widget build(BuildContext context) {
    final dateStr = work.updatedAt != null
        ? DateFormat('dd MMM yyyy').format(work.updatedAt!.toDate())
        : (work.createdAt != null
            ? DateFormat('dd MMM yyyy').format(work.createdAt!.toDate())
            : '');

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.10),
                  const Color(0xFF10B981).withOpacity(0.10)
                ]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25), width: 1.2)),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: const Color(0xFF10B981).withOpacity(0.18),
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.55),
                          width: 1.2),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFF10B981).withOpacity(0.35),
                            blurRadius: 12)
                      ]),
                  child: const Icon(Icons.check_circle_rounded,
                      color: Color(0xFF10B981), size: 20)),
              const SizedBox(width: 14),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(work.title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 4),
                    Text('Completed  •  $dateStr',
                        style: const TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700)),
                  ])),
            ]),
          ),
        ),
      ),
    );
  }
}
