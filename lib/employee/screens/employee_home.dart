import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/employee_provider.dart';
import 'employee_profile.dart';
import 'assigned_works.dart';
import 'work_history.dart';
import 'report_road_issue.dart';
import 'performance.dart';
import 'notifications.dart';
import 'daily_report.dart';
import 'leave_requests.dart';
import 'emergency_sos.dart';
import 'safety_guidelines.dart';

class EmployeeHome extends StatefulWidget {
  const EmployeeHome({super.key});
  @override
  State<EmployeeHome> createState() => _EmployeeHomeState();
}

class _EmployeeHomeState extends State<EmployeeHome>
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
    if (!kIsWeb) {
      return const Scaffold(
        backgroundColor: Color(0xFF04060F),
        body: Center(
            child: Text('Employee portal is only available on the Web.',
                style: TextStyle(color: Colors.white, fontSize: 18))),
      );
    }

    final emp = Provider.of<EmployeeProvider>(context).employee;

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Employee: ${emp?.name ?? ""}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => Navigator.push(context,
                  MaterialPageRoute(builder: (_) => const EmployeeProfile()))),
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        child: Center(
                          child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 800),
                              child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    _profileCard(emp),
                                    const SizedBox(height: 18),
                                    _heroAssignedWorksTile(),
                                    const SizedBox(height: 22),
                                    _sectionLabel('Quick Actions'),
                                    const SizedBox(height: 12),
                                    _quickActionsGrid(context)
                                  ])),
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

  Widget _profileCard(dynamic emp) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.10),
                  const Color(0xFFF59E0B).withOpacity(0.10)
                ]),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25), width: 1.2),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 12))
                ]),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                          colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                      boxShadow: [
                        BoxShadow(
                            color: const Color(0xFFF59E0B).withOpacity(0.55),
                            blurRadius: 22,
                            spreadRadius: 1)
                      ]),
                  child: const Icon(Icons.engineering_rounded,
                      color: Colors.white, size: 28)),
              const SizedBox(width: 16),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(emp?.name ?? '',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.3)),
                    const SizedBox(height: 4),
                    Text('Dept: ${emp?.department ?? '—'}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 13)),
                  ])),
              Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(20),
                      color: const Color(0xFF10B981).withOpacity(0.20),
                      border: Border.all(
                          color: const Color(0xFF10B981).withOpacity(0.65),
                          width: 1.1)),
                  child: const Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.circle, color: Color(0xFF10B981), size: 8),
                    SizedBox(width: 6),
                    Text('On Duty',
                        style: TextStyle(
                            color: Color(0xFF10B981),
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5)),
                  ])),
            ]),
          ),
        ),
      );

  Widget _heroAssignedWorksTile() => InkWell(
        onTap: () => Navigator.push(
            context, MaterialPageRoute(builder: (_) => const AssignedWorks())),
        borderRadius: BorderRadius.circular(28),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 40, horizontal: 20),
              decoration: BoxDecoration(
                  gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFFF59E0B).withOpacity(0.22),
                        const Color(0xFFEF4444).withOpacity(0.16),
                        Colors.white.withOpacity(0.05)
                      ],
                      stops: const [
                        0.0,
                        0.55,
                        1.0
                      ]),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(
                      color: Colors.white.withOpacity(0.28), width: 1.3),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFFF59E0B).withOpacity(0.30),
                        blurRadius: 34,
                        offset: const Offset(0, 12)),
                    BoxShadow(
                        color: Colors.black.withOpacity(0.35),
                        blurRadius: 24,
                        offset: const Offset(0, 10))
                  ]),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: const LinearGradient(
                            colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
                        boxShadow: [
                          BoxShadow(
                              color: const Color(0xFFF59E0B).withOpacity(0.60),
                              blurRadius: 32,
                              spreadRadius: 3)
                        ]),
                    child: const Icon(Icons.assignment_rounded,
                        size: 46, color: Colors.white)),
                const SizedBox(height: 18),
                const Text('View Assigned Works',
                    style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                              color: Color(0xAA000000),
                              blurRadius: 10,
                              offset: Offset(0, 2))
                        ])),
                const SizedBox(height: 6),
                Text('Tap to see your assigned tasks',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.72), fontSize: 13)),
              ]),
            ),
          ),
        ),
      );

  Widget _sectionLabel(String text) => Text(text.toUpperCase(),
      style: TextStyle(
          color: Colors.white.withOpacity(0.55),
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.5));

  Widget _quickActionsGrid(BuildContext context) {
    final actions = [
      _Action(
          'Work History',
          Icons.history_rounded,
          const Color(0xFF3B82F6),
          () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const WorkHistory()))),
      _Action(
          'Report Road Issue',
          Icons.report_problem_rounded,
          const Color(0xFFEF4444),
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ReportRoadIssue()))),
      _Action(
          'My Performance',
          Icons.bar_chart_rounded,
          const Color(0xFF10B981),
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const PerformancePage()))),
      _Action(
          'Notifications',
          Icons.notifications_active_rounded,
          const Color(0xFFA855F7),
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const NotificationsPage()))),
      _Action(
          'Daily Report',
          Icons.assignment_turned_in_rounded,
          const Color(0xFFF59E0B),
          () => Navigator.push(
              context, MaterialPageRoute(builder: (_) => const DailyReport()))),
      _Action(
          'Leave Request',
          Icons.event_busy_rounded,
          const Color(0xFF8B5CF6),
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const LeaveRequests()))),
      _Action(
          'Emergency SOS',
          Icons.emergency_rounded,
          const Color(0xFFDC2626),
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const EmergencySOS()))),
      _Action(
          'Safety Guide',
          Icons.health_and_safety_rounded,
          const Color(0xFF06B6D4),
          () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const SafetyGuidelines()))),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 14,
          mainAxisSpacing: 14,
          childAspectRatio: 1.15),
      itemCount: actions.length,
      itemBuilder: (context, i) =>
          _ActionTile(action: actions[i], delay: i * 70),
    );
  }
}

class _Action {
  final String title;
  final IconData icon;
  final Color color;
  final VoidCallback onTap;
  _Action(this.title, this.icon, this.color, this.onTap);
}

class _ActionTile extends StatefulWidget {
  final _Action action;
  final int delay;
  const _ActionTile({required this.action, required this.delay});
  @override
  State<_ActionTile> createState() => _ActionTileState();
}

class _ActionTileState extends State<_ActionTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _hover = false;
  bool _press = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 650));
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(begin: const Offset(0, 0.25), end: Offset.zero)
        .animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
    Future.delayed(Duration(milliseconds: widget.delay), () {
      if (mounted) _c.forward();
    });
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final a = widget.action;
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(
        position: _slide,
        child: MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: GestureDetector(
            onTapDown: (_) => setState(() => _press = true),
            onTapUp: (_) => setState(() => _press = false),
            onTapCancel: () => setState(() => _press = false),
            onTap: a.onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              transform: Matrix4.identity()
                ..scale(_press ? 0.97 : (_hover ? 1.03 : 1.0)),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: [
                    BoxShadow(
                        color: a.color.withOpacity(_hover ? 0.50 : 0.25),
                        blurRadius: _hover ? 28 : 16,
                        offset: Offset(0, _hover ? 10 : 6)),
                    BoxShadow(
                        color: Colors.black.withOpacity(0.30),
                        blurRadius: 12,
                        offset: const Offset(0, 5))
                  ]),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(colors: [
                          Colors.white.withOpacity(_hover ? 0.14 : 0.09),
                          a.color.withOpacity(_hover ? 0.14 : 0.08)
                        ]),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(
                            color:
                                Colors.white.withOpacity(_hover ? 0.55 : 0.28),
                            width: 1.2)),
                    child: Center(
                        child:
                            Column(mainAxisSize: MainAxisSize.min, children: [
                      Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
                              gradient: LinearGradient(colors: [
                                a.color.withOpacity(0.35),
                                a.color.withOpacity(0.12)
                              ]),
                              border: Border.all(
                                  color: a.color.withOpacity(0.65), width: 1.4),
                              boxShadow: [
                                BoxShadow(
                                    color: a.color
                                        .withOpacity(_hover ? 0.75 : 0.45),
                                    blurRadius: _hover ? 24 : 14,
                                    spreadRadius: 1)
                              ]),
                          child: Icon(a.icon,
                              size: 24,
                              color: Colors.white,
                              shadows: const [
                                Shadow(color: Color(0xAA000000), blurRadius: 8)
                              ])),
                      const SizedBox(height: 12),
                      Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          child: Text(a.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.3,
                                  shadows: [
                                    Shadow(
                                        color: Color(0xAA000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 1))
                                  ]))),
                    ])),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
