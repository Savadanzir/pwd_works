import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/employee_provider.dart';
import 'employee_home.dart';

class EmployeeLogin extends StatefulWidget {
  const EmployeeLogin({super.key});
  @override
  State<EmployeeLogin> createState() => _EmployeeLoginState();
}

class _EmployeeLoginState extends State<EmployeeLogin>
    with TickerProviderStateMixin {
  final _email = TextEditingController();
  final _pass = TextEditingController();

  late AnimationController _bgCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _dustCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _logoCtrl;
  late AnimationController _formCtrl;

  late Animation<double> _bgAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _dustRise;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;
  late Animation<double> _logoRotate;
  late Animation<Offset> _formSlide;

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

    _cardCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1000));
    _cardScale = Tween<double>(begin: 0.9, end: 1.0).animate(
        CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic));
    _cardFade = CurvedAnimation(
        parent: _cardCtrl,
        curve: const Interval(0.0, 0.7, curve: Curves.easeOut));

    _logoCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    _logoRotate = Tween<double>(begin: -0.15, end: 0.0)
        .animate(CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut));

    _formCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900));
    _formSlide = Tween<Offset>(begin: const Offset(0, 0.4), end: Offset.zero)
        .animate(
            CurvedAnimation(parent: _formCtrl, curve: Curves.easeOutCubic));

    _cardCtrl.forward();
    _logoCtrl.forward();
    Future.delayed(const Duration(milliseconds: 300), () {
      if (mounted) _formCtrl.forward();
    });
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _orbCtrl.dispose();
    _dustCtrl.dispose();
    _cardCtrl.dispose();
    _logoCtrl.dispose();
    _formCtrl.dispose();
    _email.dispose();
    _pass.dispose();
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
              style: TextStyle(color: Colors.white, fontSize: 18)),
        ),
      );
    }

    final prov = Provider.of<EmployeeProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: const Text('Employee Login',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
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
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.fromLTRB(24, 40, 24, 24),
                          child: FadeTransition(
                            opacity: _cardFade,
                            child: ScaleTransition(
                              scale: _cardScale,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 440),
                                child: _glassCard(prov),
                              ),
                            ),
                          ),
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
              Color(0xFF0B1130),
              Color(0xFF060A1E),
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
            child: _orb(420, const Color(0xFFEF4444), 0.22)),
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

  Widget _glassCard(EmployeeProvider prov) => ClipRRect(
        borderRadius: BorderRadius.circular(32),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 24, sigmaY: 24),
          child: Container(
            decoration: BoxDecoration(
                gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF1B2B54).withOpacity(0.55),
                      const Color(0xFF0C1730).withOpacity(0.45),
                      const Color(0xFF0A1024).withOpacity(0.55)
                    ],
                    stops: const [
                      0.0,
                      0.5,
                      1.0
                    ]),
                borderRadius: BorderRadius.circular(32),
                border: Border.all(
                    color: Colors.white.withOpacity(0.18), width: 1.3),
                boxShadow: [
                  BoxShadow(
                      color: Colors.black.withOpacity(0.55),
                      blurRadius: 60,
                      offset: const Offset(0, 28)),
                  BoxShadow(
                      color: const Color(0xFFF59E0B).withOpacity(0.25),
                      blurRadius: 50,
                      offset: const Offset(0, 12))
                ]),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 36),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                RotationTransition(
                    turns: _logoRotate,
                    child: Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: const LinearGradient(
                                colors: [Color(0xFFF59E0B), Color(0xFFEF4444)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            boxShadow: [
                              BoxShadow(
                                  color:
                                      const Color(0xFFF59E0B).withOpacity(0.55),
                                  blurRadius: 34,
                                  spreadRadius: 3)
                            ]),
                        child: const Icon(Icons.engineering_rounded,
                            size: 52, color: Colors.white))),
                const SizedBox(height: 22),
                const Text('Employee Login',
                    style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 0.3,
                        shadows: [
                          Shadow(
                              color: Color(0x88000000),
                              blurRadius: 12,
                              offset: Offset(0, 2))
                        ])),
                const SizedBox(height: 6),
                Text('Sign in with your assigned credentials',
                    style: TextStyle(
                        fontSize: 13, color: Colors.white.withOpacity(0.70))),
                const SizedBox(height: 26),
                SlideTransition(
                    position: _formSlide,
                    child: Column(children: [
                      _glassField(_email, 'Email', Icons.email_rounded,
                          keyboard: TextInputType.emailAddress),
                      const SizedBox(height: 14),
                      _glassField(_pass, 'Password', Icons.lock_rounded,
                          obscure: true),
                      const SizedBox(height: 26),
                      _primaryButton(prov),
                      const SizedBox(height: 18),
                      _infoPill()
                    ])),
              ]),
            ),
          ),
        ),
      );

  Widget _glassField(TextEditingController c, String hint, IconData icon,
      {bool obscure = false, TextInputType? keyboard}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04)
              ]),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.28), width: 1.2)),
          child: TextField(
              controller: c,
              obscureText: obscure,
              keyboardType: keyboard,
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w500),
              cursorColor: const Color(0xFFFBBF24),
              decoration: InputDecoration(
                  hintText: hint,
                  hintStyle: TextStyle(
                      color: Colors.white.withOpacity(0.55), fontSize: 14.5),
                  prefixIcon: Icon(icon,
                      color: Colors.white.withOpacity(0.85), size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 4))),
        ),
      ),
    );
  }

  Widget _primaryButton(EmployeeProvider prov) => GestureDetector(
        onTap: prov.loading
            ? null
            : () async {
                final err = await prov.login(_email.text.trim(), _pass.text);
                if (err == null && mounted) {
                  Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const EmployeeHome()),
                      (_) => false);
                } else if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                      content: Text(err ?? 'Login failed'),
                      backgroundColor: const Color(0xFFB91C1C),
                      behavior: SnackBarBehavior.floating));
                }
              },
        child: Container(
          height: 58,
          width: double.infinity,
          decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              gradient: const LinearGradient(
                  colors: [Color(0xFFF59E0B), Color(0xFFEF4444)]),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFF59E0B).withOpacity(0.55),
                    blurRadius: 26,
                    offset: const Offset(0, 10))
              ]),
          child: Center(
              child: prov.loading
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2))
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                          Text('Login',
                              style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16.5,
                                  fontWeight: FontWeight.w700)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded,
                              color: Colors.white, size: 20)
                        ])),
        ),
      );

  Widget _infoPill() => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.08),
                  const Color(0xFFF59E0B).withOpacity(0.08)
                ]),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                    color: Colors.white.withOpacity(0.22), width: 1.1)),
            child: Row(children: [
              Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFF59E0B).withOpacity(0.20),
                      border: Border.all(
                          color: const Color(0xFFF59E0B).withOpacity(0.55),
                          width: 1.2)),
                  child: const Icon(Icons.info_outline_rounded,
                      color: Color(0xFFFBBF24), size: 14)),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(
                      "Credentials are provided by your admin. Contact your supervisor if you don't have one.",
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.80),
                          fontSize: 11.5,
                          height: 1.4))),
            ]),
          ),
        ),
      );
}
