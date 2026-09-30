import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';

import 'firebase_options.dart';

import 'user/user_provider.dart';
import 'admin/admin_provider.dart';
import 'employee/employee_provider.dart';
import 'user/user_login.dart';
import 'admin/admin_login.dart';
import 'employee/employee_login.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e, st) {
    debugPrint('❌ Firebase init failed: $e\n$st');
    runApp(_ErrorApp(error: e.toString()));
    return;
  }
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
      ],
      child: MaterialApp(
        title: 'Road Maintenance',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          useMaterial3: true,
          primarySwatch: Colors.blue,
          scaffoldBackgroundColor: const Color(0xFF04060F),
        ),
        home: const PlatformGate(),
      ),
    );
  }
}

class PlatformGate extends StatelessWidget {
  const PlatformGate({super.key});
  @override
  Widget build(BuildContext context) {
    if (kIsWeb) return const WebPortalScreen();
    return const UserLogin();
  }
}

// ============================================================
// ============ ROUNDED PILL WEB PORTAL =======================
// ============================================================

class WebPortalScreen extends StatefulWidget {
  const WebPortalScreen({super.key});
  @override
  State<WebPortalScreen> createState() => _WebPortalScreenState();
}

class _WebPortalScreenState extends State<WebPortalScreen>
    with TickerProviderStateMixin {
  // Ambience
  late AnimationController _bgCtrl;
  late AnimationController _auroraCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _logoCtrl;

  // Workers
  late AnimationController _w1Ctrl;
  late AnimationController _w2Ctrl;
  late AnimationController _w3Ctrl;

  // Extras
  late AnimationController _dustCtrl;

  late Animation<double> _bgAnim;
  late Animation<double> _auroraAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;
  late Animation<double> _logoRotate;

  late Animation<double> _w1Bob;
  late Animation<double> _w1Arm;
  late Animation<double> _w2Bob;
  late Animation<double> _w2Arm;
  late Animation<double> _w3Bob;
  late Animation<double> _w3Arm;

  late Animation<double> _dustRise;

  Offset _parallax = Offset.zero;

  @override
  void initState() {
    super.initState();

    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 12))
          ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _auroraCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 18))
          ..repeat(reverse: true);
    _auroraAnim =
        CurvedAnimation(parent: _auroraCtrl, curve: Curves.easeInOut);

    _orbCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _cardCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _cardScale = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _cardCtrl, curve: Curves.easeOutCubic),
    );
    _cardFade = CurvedAnimation(
      parent: _cardCtrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOut),
    );

    _logoCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _logoRotate = Tween<double>(begin: -0.15, end: 0.0).animate(
      CurvedAnimation(parent: _logoCtrl, curve: Curves.elasticOut),
    );

    _w1Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
    _w1Bob = Tween<double>(begin: 0, end: -4).animate(
      CurvedAnimation(parent: _w1Ctrl, curve: Curves.easeInOut),
    );
    _w1Arm = Tween<double>(begin: -0.35, end: 0.45).animate(
      CurvedAnimation(parent: _w1Ctrl, curve: Curves.easeInOut),
    );

    _w2Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);
    _w2Bob = Tween<double>(begin: 0, end: -3).animate(
      CurvedAnimation(parent: _w2Ctrl, curve: Curves.easeInOut),
    );
    _w2Arm = Tween<double>(begin: -0.12, end: 0.12).animate(
      CurvedAnimation(parent: _w2Ctrl, curve: Curves.easeInOut),
    );

    _w3Ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1600),
    )..repeat(reverse: true);
    _w3Bob = Tween<double>(begin: 0, end: -3).animate(
      CurvedAnimation(parent: _w3Ctrl, curve: Curves.easeInOut),
    );
    _w3Arm = Tween<double>(begin: -0.25, end: 0.25).animate(
      CurvedAnimation(parent: _w3Ctrl, curve: Curves.easeInOut),
    );

    _dustCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 6))
          ..repeat();
    _dustRise = CurvedAnimation(parent: _dustCtrl, curve: Curves.linear);

    _cardCtrl.forward();
    _logoCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _auroraCtrl.dispose();
    _orbCtrl.dispose();
    _cardCtrl.dispose();
    _logoCtrl.dispose();
    _w1Ctrl.dispose();
    _w2Ctrl.dispose();
    _w3Ctrl.dispose();
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
    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      body: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return MouseRegion(
            onHover: (e) => _onHover(e, size),
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _bgAnim,
                _auroraAnim,
                _orbAnim,
                _w1Bob, _w1Arm,
                _w2Bob, _w2Arm,
                _w3Bob, _w3Arm,
                _dustRise,
              ]),
              builder: (context, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildGradientBase(),
                    _buildAuroraStreaks(size),
                    _buildOrbs(size),
                    _buildGlassScene(size),
                    SafeArea(
                      child: Center(
                        child: SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: FadeTransition(
                            opacity: _cardFade,
                            child: ScaleTransition(
                              scale: _cardScale,
                              child: ConstrainedBox(
                                constraints:
                                    const BoxConstraints(maxWidth: 460),
                                child: _buildRoundedCard(),
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

  Widget _buildGradientBase() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(
            -0.4 + _bgAnim.value * 0.2,
            -0.6 + _bgAnim.value * 0.15,
          ),
          radius: 1.5,
          colors: const [
            Color(0xFF0B1130),
            Color(0xFF060A1E),
            Color(0xFF04060F),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }

  Widget _buildAuroraStreaks(Size size) {
    final t = _auroraAnim.value;
    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: -size.width * 0.3 + t * 80,
            top: size.height * 0.10,
            child: Transform.rotate(
              angle: -0.5,
              child: Container(
                width: 240,
                height: size.height * 0.9,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFF22D3EE).withOpacity(0.0),
                      const Color(0xFF22D3EE).withOpacity(0.16),
                      const Color(0xFF6366F1).withOpacity(0.10),
                      const Color(0xFF22D3EE).withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.35, 0.7, 1.0],
                  ),
                ),
              ),
            ),
          ),
          Positioned(
            right: -size.width * 0.25 - t * 60,
            top: size.height * 0.05,
            child: Transform.rotate(
              angle: 0.55,
              child: Container(
                width: 280,
                height: size.height,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      const Color(0xFFA78BFA).withOpacity(0.0),
                      const Color(0xFFA78BFA).withOpacity(0.14),
                      const Color(0xFFEC4899).withOpacity(0.08),
                      const Color(0xFFA78BFA).withOpacity(0.0),
                    ],
                    stops: const [0.0, 0.4, 0.75, 1.0],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildOrbs(Size size) {
    return Stack(
      children: [
        Positioned(
          left: -size.width * 0.15 + _parallax.dx * -14,
          top: -size.height * 0.20 + _parallax.dy * -10,
          child: _orb(
            size: 440,
            color: const Color(0xFF3B82F6),
            opacity: 0.30,
          ),
        ),
        Positioned(
          right: -size.width * 0.12 + _parallax.dx * 14,
          bottom: -size.height * 0.15 + _parallax.dy * 10,
          child: _orb(
            size: 480,
            color: const Color(0xFF8B5CF6),
            opacity: 0.24,
          ),
        ),
        Positioned(
          right: size.width * 0.12 + _parallax.dx * 8,
          top: size.height * 0.18 + _parallax.dy * 6,
          child: _orb(
            size: 260,
            color: const Color(0xFF06B6D4),
            opacity: 0.22,
          ),
        ),
      ],
    );
  }

  Widget _orb({
    required double size,
    required Color color,
    required double opacity,
  }) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity * (0.85 + _orbAnim.value * 0.3)),
              color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassScene(Size size) {
    final roadHeight = 140.0;
    final roadTop = size.height - roadHeight - 40;

    return IgnorePointer(
      child: Stack(
        children: [
          Positioned(
            left: 24,
            right: 24,
            top: roadTop,
            height: roadHeight,
            child: _glassRoadPanel(),
          ),
          Positioned(
            left: 24,
            right: 24,
            top: roadTop + roadHeight / 2 - 1,
            child: _dashedLine(),
          ),
          ..._buildDust(size, roadTop),
          Positioned(
            left: size.width * 0.18,
            top: roadTop - 110 + _w1Bob.value,
            child: _glassWorker(
              armAngle: _w1Arm.value,
              toolKind: _ToolKind.pickaxe,
              accent: const Color(0xFF60A5FA),
            ),
          ),
          Positioned(
            left: size.width * 0.50 - 40,
            top: roadTop - 100 + _w2Bob.value,
            child: _glassWorker(
              armAngle: _w2Arm.value,
              toolKind: _ToolKind.clipboard,
              accent: const Color(0xFF93C5FD),
            ),
          ),
          Positioned(
            right: size.width * 0.18,
            top: roadTop - 105 + _w3Bob.value,
            child: _glassWorker(
              armAngle: _w3Arm.value,
              toolKind: _ToolKind.wrench,
              accent: const Color(0xFFA5B4FC),
            ),
          ),
          Positioned(
            left: 60,
            top: roadTop + roadHeight - 40,
            child: _glassCone(),
          ),
          Positioned(
            right: 60,
            top: roadTop + roadHeight - 40,
            child: _glassCone(),
          ),
        ],
      ),
    );
  }

  Widget _glassRoadPanel() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.05),
                Colors.white.withOpacity(0.015),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.15),
              width: 1.0,
            ),
          ),
        ),
      ),
    );
  }

  Widget _dashedLine() {
    return LayoutBuilder(
      builder: (context, c) {
        const dashW = 34.0;
        const gapW = 26.0;
        final count = ((c.maxWidth) / (dashW + gapW)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            count,
            (_) => Container(
              width: dashW,
              height: 2,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.20),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _glassWorker({
    required double armAngle,
    required _ToolKind toolKind,
    required Color accent,
  }) {
    return SizedBox(
      width: 100,
      height: 130,
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          Container(
            width: 110,
            height: 110,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  accent.withOpacity(0.16),
                  accent.withOpacity(0.0),
                ],
              ),
            ),
          ),
          CustomPaint(
            size: const Size(70, 120),
            painter: _GlassWorkerPainter(
              armAngle: armAngle,
              accent: accent,
              tool: toolKind,
            ),
          ),
        ],
      ),
    );
  }

  Widget _glassCone() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(6),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          width: 24,
          height: 32,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.white.withOpacity(0.18),
                Colors.white.withOpacity(0.05),
              ],
            ),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.0,
            ),
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 2,
              color: Colors.white.withOpacity(0.4),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildDust(Size size, double roadTop) {
    final list = <Widget>[];
    for (int i = 0; i < 14; i++) {
      final seed = (i * 0.137) % 1.0;
      final p = (_dustRise.value + seed) % 1.0;
      final x =
          size.width * (0.15 + (i % 7) * 0.1) + math.sin((p + i) * 5) * 18;
      final y = roadTop + 40 - p * 90;
      final opacity = ((1.0 - p) * 0.30).clamp(0.0, 1.0);
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
                      blurRadius: 6,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
    }
    return list;
  }

  // ============================================================
  // 💊 Rounded pill card
  // ============================================================
  Widget _buildRoundedCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 26, sigmaY: 26),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF1B2B54).withOpacity(0.55),
                const Color(0xFF0C1730).withOpacity(0.45),
                const Color(0xFF0A1024).withOpacity(0.55),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withOpacity(0.16),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 60,
                offset: const Offset(0, 28),
              ),
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.30),
                blurRadius: 50,
                offset: const Offset(0, 12),
              ),
              BoxShadow(
                color: const Color(0xFF8B5CF6).withOpacity(0.18),
                blurRadius: 60,
                offset: const Offset(0, -8),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo in a rounded squircle badge
                RotationTransition(
                  turns: _logoRotate,
                  child: Container(
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF3B82F6).withOpacity(0.55),
                          blurRadius: 40,
                          spreadRadius: 4,
                        ),
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withOpacity(0.35),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Text(
                      '🏗️',
                      style: TextStyle(fontSize: 46),
                    ),
                  ),
                ),

                const SizedBox(height: 22),

                const Text(
                  'Road Maintenance',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 0.3,
                    shadows: [
                      Shadow(
                        color: Color(0x88000000),
                        blurRadius: 16,
                        offset: Offset(0, 2),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'W E B   P O R T A L',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withOpacity(0.65),
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  height: 1.2,
                  width: 68,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)],
                    ),
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.7),
                        blurRadius: 12,
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Choose your role to continue',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.75),
                    fontSize: 13,
                    letterSpacing: 0.4,
                  ),
                ),
                const SizedBox(height: 30),

                // ---- ROUNDED EMOJI PILLS ----
                _AnimatedEntry(
                  delay: 180,
                  child: _EmojiPillButton(
                    emoji: '👤',
                    label: 'User Login',
                    subtitle: 'Report road issues',
                    accent: const Color(0xFF10B981),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const UserLogin()),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _AnimatedEntry(
                  delay: 320,
                  child: _EmojiPillButton(
                    emoji: '🛡️',
                    label: 'Admin Login',
                    subtitle: 'Manage & assign',
                    accent: const Color(0xFF3B82F6),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminLogin()),
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _AnimatedEntry(
                  delay: 460,
                  child: _EmojiPillButton(
                    emoji: '👷',
                    label: 'Employee Login',
                    subtitle: 'Complete field work',
                    accent: const Color(0xFFF59E0B),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const EmployeeLogin()),
                    ),
                  ),
                ),

                const SizedBox(height: 28),

                Text(
                  'Web portal — for testing all roles.\n'
                  'Mobile app — User role only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: Colors.white.withOpacity(0.55),
                    height: 1.5,
                    letterSpacing: 0.3,
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

// ============================================================
// Tool kinds
// ============================================================
enum _ToolKind { pickaxe, clipboard, wrench }

// ============================================================
// 🎨 Worker painter
// ============================================================
class _GlassWorkerPainter extends CustomPainter {
  final double armAngle;
  final Color accent;
  final _ToolKind tool;

  _GlassWorkerPainter({
    required this.armAngle,
    required this.accent,
    required this.tool,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;

    final fill = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Colors.white.withOpacity(0.24),
          Colors.white.withOpacity(0.05),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final stroke = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2
      ..color = Colors.white.withOpacity(0.50);

    final accentGlow = Paint()
      ..shader = RadialGradient(
        colors: [
          accent.withOpacity(0.35),
          accent.withOpacity(0.0),
        ],
      ).createShader(Rect.fromCircle(
        center: Offset(cx, size.height / 2),
        radius: size.width,
      ));

    final headCenter = Offset(cx, 22);
    canvas.drawCircle(headCenter, 14, accentGlow);
    canvas.drawCircle(headCenter, 14, fill);
    canvas.drawCircle(headCenter, 14, stroke);

    final helmetPath = Path()
      ..moveTo(cx - 15, 20)
      ..quadraticBezierTo(cx, 2, cx + 15, 20)
      ..lineTo(cx + 15, 20);
    canvas.drawPath(
      helmetPath,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.4
        ..color = Colors.white.withOpacity(0.7),
    );

    final torso = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 18, 40, 36, 46),
      const Radius.circular(10),
    );
    canvas.drawRRect(torso, fill);
    canvas.drawRRect(torso, stroke);

    final legL = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx - 15, 84, 12, 32),
      const Radius.circular(5),
    );
    final legR = RRect.fromRectAndRadius(
      Rect.fromLTWH(cx + 3, 84, 12, 32),
      const Radius.circular(5),
    );
    canvas.drawRRect(legL, fill);
    canvas.drawRRect(legL, stroke);
    canvas.drawRRect(legR, fill);
    canvas.drawRRect(legR, stroke);

    final shoulder = Offset(cx + 16, 50);
    final armLen = 26.0;
    final tip = Offset(
      shoulder.dx + math.cos(-1.2 + armAngle) * armLen,
      shoulder.dy + math.sin(-1.2 + armAngle) * armLen,
    );
    canvas.drawLine(
      shoulder,
      tip,
      Paint()
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.24),
            Colors.white.withOpacity(0.08),
          ],
        ).createShader(Rect.fromPoints(shoulder, tip)),
    );
    canvas.drawLine(
      shoulder,
      tip,
      Paint()
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.5),
    );

    _drawTool(canvas, tip, armAngle);

    final lShoulder = Offset(cx - 16, 50);
    final lTip = Offset(lShoulder.dx - 6, lShoulder.dy + 24);
    canvas.drawLine(
      lShoulder,
      lTip,
      Paint()
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round
        ..shader = LinearGradient(
          colors: [
            Colors.white.withOpacity(0.24),
            Colors.white.withOpacity(0.08),
          ],
        ).createShader(Rect.fromPoints(lShoulder, lTip)),
    );
    canvas.drawLine(
      lShoulder,
      lTip,
      Paint()
        ..strokeWidth = 1.2
        ..strokeCap = StrokeCap.round
        ..color = Colors.white.withOpacity(0.5),
    );
  }

  void _drawTool(Canvas canvas, Offset tip, double angle) {
    final glass = Paint()
      ..color = Colors.white.withOpacity(0.7)
      ..strokeWidth = 2.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final accentStroke = Paint()
      ..color = accent.withOpacity(0.85)
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    switch (tool) {
      case _ToolKind.pickaxe:
        final handleEnd = Offset(
          tip.dx + math.cos(angle) * 16,
          tip.dy + math.sin(angle) * 16,
        );
        canvas.drawLine(tip, handleEnd, glass);
        final perpA = Offset(
          tip.dx + math.cos(angle - math.pi / 2) * 8,
          tip.dy + math.sin(angle - math.pi / 2) * 8,
        );
        final perpB = Offset(
          tip.dx + math.cos(angle + math.pi / 2) * 8,
          tip.dy + math.sin(angle + math.pi / 2) * 8,
        );
        canvas.drawLine(perpA, perpB, accentStroke);
        break;
      case _ToolKind.clipboard:
        final r = Rect.fromCenter(center: tip, width: 14, height: 18);
        canvas.drawRRect(
          RRect.fromRectAndRadius(r, const Radius.circular(2)),
          glass,
        );
        canvas.drawLine(
          Offset(tip.dx - 4, tip.dy - 3),
          Offset(tip.dx + 4, tip.dy - 3),
          glass,
        );
        canvas.drawLine(
          Offset(tip.dx - 4, tip.dy + 1),
          Offset(tip.dx + 4, tip.dy + 1),
          glass,
        );
        break;
      case _ToolKind.wrench:
        final end = Offset(tip.dx + 10, tip.dy + 6);
        canvas.drawLine(tip, end, glass);
        canvas.drawCircle(end, 5, accentStroke);
        canvas.drawCircle(tip, 3, accentStroke);
        break;
    }
  }

  @override
  bool shouldRepaint(covariant _GlassWorkerPainter old) =>
      old.armAngle != armAngle || old.accent != accent || old.tool != tool;
}

// ============================================================
// Staggered fade + slide
// ============================================================
class _AnimatedEntry extends StatefulWidget {
  final Widget child;
  final int delay;
  const _AnimatedEntry({required this.child, required this.delay});

  @override
  State<_AnimatedEntry> createState() => _AnimatedEntryState();
}

class _AnimatedEntryState extends State<_AnimatedEntry>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _fade = CurvedAnimation(parent: _c, curve: Curves.easeOut);
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.35),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _c, curve: Curves.easeOutCubic));
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
    return FadeTransition(
      opacity: _fade,
      child: SlideTransition(position: _slide, child: widget.child),
    );
  }
}

// ============================================================
// 💊 Emoji Pill Button — rounded, emoji badge, glass tint
// ============================================================
class _EmojiPillButton extends StatefulWidget {
  final String emoji;
  final String label;
  final String subtitle;
  final Color accent;
  final VoidCallback onTap;

  const _EmojiPillButton({
    required this.emoji,
    required this.label,
    required this.subtitle,
    required this.accent,
    required this.onTap,
  });

  @override
  State<_EmojiPillButton> createState() => _EmojiPillButtonState();
}

class _EmojiPillButtonState extends State<_EmojiPillButton> {
  bool _hover = false;
  bool _press = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _press = true),
        onTapUp: (_) => setState(() => _press = false),
        onTapCancel: () => setState(() => _press = false),
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          width: double.infinity,
          height: 76,
          transform: Matrix4.identity()
            ..scale(_press ? 0.98 : (_hover ? 1.02 : 1.0)),
          transformAlignment: Alignment.center,
          decoration: BoxDecoration(
            // Fully rounded pill
            borderRadius: BorderRadius.circular(100),
            // Outer glow in accent color
            boxShadow: [
              BoxShadow(
                color: widget.accent.withOpacity(_hover ? 0.65 : 0.40),
                blurRadius: _hover ? 40 : 24,
                offset: Offset(0, _hover ? 14 : 8),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 12,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
              child: Container(
                decoration: BoxDecoration(
                  // Glass body — barely-there white + accent tint
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(_hover ? 0.22 : 0.14),
                      widget.accent.withOpacity(_hover ? 0.24 : 0.14),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  // Bright rim
                  border: Border.all(
                    color: Colors.white.withOpacity(_hover ? 0.95 : 0.65),
                    width: 1.3,
                  ),
                ),
                child: Stack(
                  children: [
                    // Top-edge shine line
                    Positioned(
                      top: 0,
                      left: 28,
                      right: 28,
                      child: Container(
                        height: 1.4,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.0),
                            ],
                          ),
                        ),
                      ),
                    ),

                    // Left accent strip in the pill curve
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 5,
                        decoration: BoxDecoration(
                          color: widget.accent,
                          boxShadow: [
                            BoxShadow(
                              color: widget.accent.withOpacity(0.9),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Content
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          // Emoji badge — rounded circle with accent glow
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: _hover ? 54 : 50,
                            height: _hover ? 54 : 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: widget.accent.withOpacity(0.22),
                              border: Border.all(
                                color: widget.accent.withOpacity(0.75),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: widget.accent
                                      .withOpacity(_hover ? 0.8 : 0.5),
                                  blurRadius: _hover ? 22 : 14,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                widget.emoji,
                                style: const TextStyle(fontSize: 26),
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),

                          // Text block
                          Expanded(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  widget.label,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 16.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                        color: Color(0xAA000000),
                                        blurRadius: 8,
                                        offset: Offset(0, 1),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  widget.subtitle,
                                  style: TextStyle(
                                    color: Colors.white.withOpacity(0.75),
                                    fontSize: 11.5,
                                    fontWeight: FontWeight.w500,
                                    letterSpacing: 0.3,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Trailing arrow
                          AnimatedSlide(
                            duration: const Duration(milliseconds: 220),
                            offset:
                                _hover ? const Offset(0.15, 0) : Offset.zero,
                            child: Icon(
                              Icons.arrow_forward_rounded,
                              color: Colors.white.withOpacity(0.9),
                              size: 20,
                              shadows: const [
                                Shadow(
                                  color: Color(0x88000000),
                                  blurRadius: 6,
                                ),
                              ],
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
        ),
      ),
    );
  }
}

// ============================================================
// Error fallback
// ============================================================
class _ErrorApp extends StatelessWidget {
  final String error;
  const _ErrorApp({required this.error});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        backgroundColor: Colors.red[50],
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 70, color: Colors.red),
                const SizedBox(height: 16),
                const Text('Firebase failed to initialize',
                    style: TextStyle(
                        fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                Text(error, textAlign: TextAlign.center),
                const SizedBox(height: 20),
                const Text(
                  'Run "flutterfire configure" and make sure\n'
                  'lib/firebase_options.dart exists.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}