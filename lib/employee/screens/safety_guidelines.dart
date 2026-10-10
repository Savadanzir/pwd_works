import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';

class SafetyGuidelines extends StatefulWidget {
  const SafetyGuidelines({super.key});
  @override
  State<SafetyGuidelines> createState() => _SafetyGuidelinesState();
}

class _SafetyGuidelinesState extends State<SafetyGuidelines>
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
    final dos = const [
      'Wear a helmet and high-visibility vest at all times',
      'Place warning cones before starting any work',
      'Wear reflective gear at night or in low visibility',
      'Keep the work area clearly marked and barricaded',
      'Stay hydrated and take breaks in extreme heat',
      'Report unsafe conditions to your supervisor',
    ];
    final donts = const [
      'Never work alone on high-speed roads',
      'Do not remove safety barriers until work is fully complete',
      'Never use damaged tools or equipment',
      'Do not leave tools unattended on the road',
      'Avoid working during heavy rain or storms',
      'Do not ignore pain or injuries — report immediately',
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Safety Guidelines',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
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
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        children: [
                          // Hero banner
                          ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Container(
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(24),
                                  gradient: const LinearGradient(colors: [
                                    Color(0xFFF59E0B),
                                    Color(0xFFEF4444)
                                  ]),
                                  border: Border.all(
                                      color: Colors.white.withOpacity(0.35),
                                      width: 1.3),
                                  boxShadow: [
                                    BoxShadow(
                                        color: const Color(0xFFF59E0B)
                                            .withOpacity(0.45),
                                        blurRadius: 30,
                                        offset: const Offset(0, 12))
                                  ]),
                              child: const Row(children: [
                                Icon(Icons.health_and_safety_rounded,
                                    color: Colors.white, size: 44),
                                SizedBox(width: 16),
                                Expanded(
                                    child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                      Text('Safety First',
                                          style: TextStyle(
                                              color: Colors.white,
                                              fontSize: 20,
                                              fontWeight: FontWeight.w900,
                                              letterSpacing: 0.3)),
                                      SizedBox(height: 4),
                                      Text('Your safety matters most',
                                          style: TextStyle(
                                              color: Colors.white70,
                                              fontSize: 13)),
                                    ])),
                              ]),
                            ),
                          ),
                          const SizedBox(height: 22),
                          _sectionHeader('DO\'S', Icons.check_circle_rounded,
                              const Color(0xFF10B981)),
                          const SizedBox(height: 10),
                          ...dos.map((d) => _ruleCard(
                              text: d,
                              color: const Color(0xFF10B981),
                              icon: Icons.check_rounded)),
                          const SizedBox(height: 20),
                          _sectionHeader('DON\'TS', Icons.cancel_rounded,
                              const Color(0xFFEF4444)),
                          const SizedBox(height: 10),
                          ...donts.map((d) => _ruleCard(
                              text: d,
                              color: const Color(0xFFEF4444),
                              icon: Icons.close_rounded)),
                          const SizedBox(height: 24),
                          Text('EMERGENCY NUMBERS',
                              style: TextStyle(
                                  color: Colors.white.withOpacity(0.55),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 1.5)),
                          const SizedBox(height: 10),
                          _contactRow(
                              'Ambulance', '108', const Color(0xFFDC2626)),
                          _contactRow('Police', '100', const Color(0xFF3B82F6)),
                          _contactRow(
                              'Fire Brigade', '101', const Color(0xFFF59E0B)),
                          _contactRow('All Emergencies', '112',
                              const Color(0xFFEF4444)),
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

  Widget _sectionHeader(String title, IconData icon, Color color) =>
      Row(children: [
        Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: color.withOpacity(0.18),
                border: Border.all(color: color.withOpacity(0.55), width: 1.1)),
            child: Icon(icon, color: color, size: 14)),
        const SizedBox(width: 10),
        Text(title,
            style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w800,
                letterSpacing: 1.2)),
      ]);

  Widget _ruleCard(
      {required String text, required Color color, required IconData icon}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.08),
                  color.withOpacity(0.10)
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.22), width: 1.1),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.20),
                      blurRadius: 12,
                      offset: const Offset(0, 4))
                ]),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color.withOpacity(0.20),
                      border: Border.all(
                          color: color.withOpacity(0.55), width: 1.1)),
                  child: Icon(icon, color: color, size: 12)),
              const SizedBox(width: 12),
              Expanded(
                  child: Text(text,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13, height: 1.5))),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _contactRow(String name, String number, Color color) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.08),
                  color.withOpacity(0.08)
                ]),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                    color: Colors.white.withOpacity(0.20), width: 1.1)),
            child: Row(children: [
              Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: color,
                      boxShadow: [
                        BoxShadow(color: color.withOpacity(0.7), blurRadius: 8)
                      ])),
              const SizedBox(width: 12),
              Text(name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13.5,
                      fontWeight: FontWeight.w600)),
              const Spacer(),
              Text(number,
                  style: TextStyle(
                      color: color,
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.5)),
            ]),
          ),
        ),
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
              Color(0xFF062A33),
              Color(0xFF02141A),
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
            child: _orb(380, const Color(0xFF06B6D4), 0.28)),
        Positioned(
            right: -size.width * 0.12 + _parallax.dx * 14,
            bottom: -size.height * 0.15 + _parallax.dy * 10,
            child: _orb(420, const Color(0xFFF59E0B), 0.20)),
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
