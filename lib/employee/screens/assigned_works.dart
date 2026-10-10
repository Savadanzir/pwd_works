import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/assigned_works_provider.dart';
import '../providers/employee_provider.dart';
import '../models/work_model.dart';
import 'work_details.dart';

class AssignedWorks extends StatefulWidget {
  const AssignedWorks({super.key});
  @override
  State<AssignedWorks> createState() => _AssignedWorksState();
}

class _AssignedWorksState extends State<AssignedWorks>
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
        Provider.of<AssignedWorksProvider>(context, listen: false)
            .loadForEmployee(uid);
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
    final prov = Provider.of<AssignedWorksProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Assigned Works',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                final uid =
                    Provider.of<EmployeeProvider>(context, listen: false)
                        .employee
                        ?.uid;
                if (uid != null) prov.loadForEmployee(uid);
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

  Widget _body(AssignedWorksProvider prov) {
    if (prov.loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (prov.works.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.assignment_outlined,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No works assigned',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('New tasks assigned by the admin will appear here.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
              ])));
    }

    return RefreshIndicator(
      onRefresh: () {
        final uid =
            Provider.of<EmployeeProvider>(context, listen: false).employee?.uid;
        return prov.loadForEmployee(uid ?? '');
      },
      color: const Color(0xFFF59E0B),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: prov.works.length,
        itemBuilder: (context, i) {
          final w = prov.works[i];
          return _WorkCard(
            work: w,
            onTap: () async {
              await Navigator.push(context,
                  MaterialPageRoute(builder: (_) => WorkDetails(work: w, reportId: '', data: {},)));
              final uid = Provider.of<EmployeeProvider>(context, listen: false)
                  .employee
                  ?.uid;
              if (uid != null) prov.loadForEmployee(uid);
            },
          );
        },
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
              Color(0xFF2E1E06),
              Color(0xFF140D02),
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
            child: _orb(380, const Color(0xFFF59E0B), 0.28)),
        Positioned(
            right: -size.width * 0.12 + _parallax.dx * 14,
            bottom: -size.height * 0.15 + _parallax.dy * 10,
            child: _orb(420, const Color(0xFFEF4444), 0.20)),
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

class _WorkCard extends StatelessWidget {
  final WorkModel work;
  final VoidCallback onTap;
  const _WorkCard({required this.work, required this.onTap});

  Color _statusColor(String s) {
    switch (s) {
      case 'Assigned':
        return const Color(0xFFA855F7);
      case 'In Progress':
        return const Color(0xFF6366F1);
      case 'Completed':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(work.status);
    final dateStr = work.createdAt != null
        ? DateFormat('dd MMM yyyy • HH:mm').format(work.createdAt!.toDate())
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                    gradient: LinearGradient(colors: [
                      Colors.white.withOpacity(0.10),
                      statusColor.withOpacity(0.10)
                    ]),
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.25), width: 1.2),
                    boxShadow: [
                      BoxShadow(
                          color: Colors.black.withOpacity(0.30),
                          blurRadius: 20,
                          offset: const Offset(0, 10))
                    ]),
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      if (work.imageUrl != null && work.imageUrl!.isNotEmpty)
                        ClipRRect(
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(24)),
                            child: AspectRatio(
                                aspectRatio: 16 / 10,
                                child: Image.network(work.imageUrl!,
                                    fit: BoxFit.cover,
                                    errorBuilder: (_, __, ___) => Container(
                                        color: Colors.black26,
                                        child: const Center(
                                            child: Icon(
                                                Icons.broken_image_outlined,
                                                color: Colors.white54,
                                                size: 40)))))),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(children: [
                                Expanded(
                                    child: Text(work.title,
                                        style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 15.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.2))),
                                Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 10, vertical: 4),
                                    decoration: BoxDecoration(
                                        color: statusColor.withOpacity(0.20),
                                        borderRadius: BorderRadius.circular(20),
                                        border: Border.all(
                                            color:
                                                statusColor.withOpacity(0.65),
                                            width: 1)),
                                    child: Text(work.status,
                                        style: TextStyle(
                                            color: statusColor,
                                            fontSize: 10.5,
                                            fontWeight: FontWeight.w800,
                                            letterSpacing: 0.4))),
                              ]),
                              const SizedBox(height: 8),
                              if (work.description.isNotEmpty)
                                Text(work.description,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.85),
                                        fontSize: 13,
                                        height: 1.5)),
                              const SizedBox(height: 10),
                              Row(children: [
                                const Icon(Icons.location_on_rounded,
                                    color: Color(0xFFEF4444), size: 14),
                                const SizedBox(width: 4),
                                Expanded(
                                    child: Text(work.location,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                            color:
                                                Colors.white.withOpacity(0.75),
                                            fontSize: 12))),
                                if (dateStr.isNotEmpty)
                                  Text(dateStr,
                                      style: TextStyle(
                                          color: Colors.white.withOpacity(0.55),
                                          fontSize: 11)),
                              ]),
                              const SizedBox(height: 10),
                              Row(children: [
                                Icon(Icons.touch_app_rounded,
                                    size: 14,
                                    color: Colors.white.withOpacity(0.5)),
                                const SizedBox(width: 6),
                                Text('Tap to view details & update',
                                    style: TextStyle(
                                        color: Colors.white.withOpacity(0.55),
                                        fontSize: 11.5)),
                              ]),
                            ]),
                      ),
                    ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
