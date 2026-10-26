import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:provider/provider.dart';
import 'package:road_maintenance/services/settings_service.dart';

import 'firebase_options.dart';

// ============================================================
// USER MODULE
// ============================================================
import 'user/providers/user_provider.dart';
import 'user/providers/report_provider.dart';
import 'user/providers/road_work_provider.dart';
import 'user/providers/metro_update_provider.dart';
import 'user/providers/traffic_provider.dart';
import 'user/providers/best_route_provider.dart';
import 'user/screens/user_login.dart';

// ============================================================
// ADMIN MODULE
// ============================================================
import 'admin/providers/admin_provider.dart';
import 'admin/providers/applications_provider.dart';
import 'admin/providers/assignment_provider.dart';
import 'admin/providers/verification_provider.dart';
import 'admin/providers/employee_management_provider.dart';
import 'admin/providers/alerts_provider.dart';
import 'admin/providers/news_provider.dart';
import 'admin/providers/authorities_provider.dart';
import 'admin/providers/complaints_provider.dart';
import 'admin/providers/fines_provider.dart';
import 'admin/screens/admin_login.dart';

// ============================================================
// EMPLOYEE MODULE
// ============================================================
import 'employee/providers/employee_provider.dart';
import 'employee/providers/assigned_works_provider.dart';
import 'employee/providers/work_update_provider.dart';
import 'employee/providers/repair_evidence_provider.dart';
import 'employee/providers/work_history_provider.dart';
import 'employee/providers/performance_provider.dart';
import 'employee/providers/notifications_provider.dart';
import 'employee/providers/daily_report_provider.dart';
import 'employee/providers/leave_request_provider.dart';
import 'employee/providers/emergency_provider.dart';
import 'employee/screens/employee_login.dart';

// ============================================================
// WIDGETS
// ============================================================
import 'widgets/road_logo.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    debugPrint('✅ Firebase initialized');
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
        // ============ USER MODULE ============
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => ReportProvider()),
        ChangeNotifierProvider(create: (_) => RoadWorkProvider()),
        ChangeNotifierProvider(create: (_) => MetroUpdateProvider()),
        ChangeNotifierProvider(create: (_) => TrafficProvider()),
        ChangeNotifierProvider(create: (_) => BestRouteProvider()),
        ChangeNotifierProvider(create: (_) => SettingsService()..load()),

        // ============ ADMIN MODULE ============
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => ApplicationsProvider()),
        ChangeNotifierProvider(create: (_) => AssignmentProvider()),
        ChangeNotifierProvider(create: (_) => VerificationProvider()),
        ChangeNotifierProvider(create: (_) => EmployeeManagementProvider()),
        ChangeNotifierProvider(create: (_) => AlertsProvider()),
        ChangeNotifierProvider(create: (_) => NewsProvider()),
        ChangeNotifierProvider(create: (_) => AuthoritiesProvider()),
        ChangeNotifierProvider(create: (_) => ComplaintsProvider()),
        ChangeNotifierProvider(create: (_) => FinesProvider()),

        // ============ EMPLOYEE MODULE ============
        ChangeNotifierProvider(create: (_) => EmployeeProvider()),
        ChangeNotifierProvider(create: (_) => AssignedWorksProvider()),
        ChangeNotifierProvider(create: (_) => WorkUpdateProvider()),
        ChangeNotifierProvider(create: (_) => RepairEvidenceProvider()),
        ChangeNotifierProvider(create: (_) => WorkHistoryProvider()),
        ChangeNotifierProvider(create: (_) => PerformanceProvider()),
        ChangeNotifierProvider(create: (_) => NotificationsProvider()),
        ChangeNotifierProvider(create: (_) => DailyReportProvider()),
        ChangeNotifierProvider(create: (_) => LeaveRequestProvider()),
        ChangeNotifierProvider(create: (_) => EmergencyProvider()),
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

// ============================================================
// 🌐 PLATFORM GATE
// 📱 Mobile  → User login ONLY
// 🖥️ Web     → Admin & Employee login ONLY
// ============================================================
class PlatformGate extends StatelessWidget {
  const PlatformGate({super.key});

  @override
  Widget build(BuildContext context) {
    // If Mobile -> Go straight to User Login
    if (!kIsWeb) {
      return const UserLogin();
    }
    // If Web -> Show the Web Portal (Admin & Employee)
    return const WebPortalScreen();
  }
}

// ============================================================
// 🖥️ Web Portal — Admin + Employee Only
// ============================================================
class WebPortalScreen extends StatefulWidget {
  const WebPortalScreen({super.key});
  @override
  State<WebPortalScreen> createState() => _WebPortalScreenState();
}

class _WebPortalScreenState extends State<WebPortalScreen>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _dustCtrl;
  late AnimationController _cardCtrl;
  late AnimationController _logoCtrl;

  late Animation<double> _bgAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _dustRise;
  late Animation<double> _cardScale;
  late Animation<double> _cardFade;
  late Animation<double> _logoRotate;

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

    _cardCtrl.forward();
    _logoCtrl.forward();
  }

  @override
  void dispose() {
    _bgCtrl.dispose();
    _orbCtrl.dispose();
    _dustCtrl.dispose();
    _cardCtrl.dispose();
    _logoCtrl.dispose();
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
              animation: Listenable.merge([_bgAnim, _orbAnim, _dustRise]),
              builder: (context, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _buildGradientBase(),
                    _buildOrbs(size),
                    _buildDust(size),
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
                                child: _buildGlassCard(),
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

  // ---------------- Background ----------------
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

  Widget _buildOrbs(Size size) {
    return Stack(
      children: [
        Positioned(
          left: -size.width * 0.15 + _parallax.dx * -14,
          top: -size.height * 0.18 + _parallax.dy * -10,
          child: _orb(380, const Color(0xFF3B82F6), 0.30),
        ),
        Positioned(
          right: -size.width * 0.12 + _parallax.dx * 14,
          bottom: -size.height * 0.15 + _parallax.dy * 10,
          child: _orb(420, const Color(0xFF8B5CF6), 0.24),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color, double opacity) {
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

  Widget _buildDust(Size size) {
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
    return Stack(children: list);
  }

  // ---------------- Glass Card ----------------
  Widget _buildGlassCard() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
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
                const Color(0xFF0A1024).withOpacity(0.55),
              ],
              stops: const [0.0, 0.5, 1.0],
            ),
            borderRadius: BorderRadius.circular(40),
            border: Border.all(
              color: Colors.white.withOpacity(0.18),
              width: 1.3,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.55),
                blurRadius: 60,
                offset: const Offset(0, 28),
              ),
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(0.28),
                blurRadius: 50,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 40),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Logo
                RotationTransition(
                  turns: _logoRotate,
                  child: const RoadLogo(
                    width: 240,
                    glowColor: Color(0xFFF59E0B),
                  ),
                ),
                const SizedBox(height: 12),
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
                  ),
                ),
                const SizedBox(height: 30),

                // ---- ADMIN Button ----
                _AnimatedEntry(
                  delay: 120,
                  child: _WebRoleButton(
                    icon: Icons.admin_panel_settings_rounded,
                    label: 'Admin Login',
                    subtitle: 'Manage & assign',
                    colors: const [Color(0xFF3B82F6), Color(0xFF6366F1)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const AdminLogin()),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // ---- EMPLOYEE Button ----
                _AnimatedEntry(
                  delay: 260,
                  child: _WebRoleButton(
                    icon: Icons.engineering_rounded,
                    label: 'Employee Login',
                    subtitle: 'Complete field work',
                    colors: const [Color(0xFFF59E0B), Color(0xFFEF4444)],
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(builder: (_) => const EmployeeLogin()),
                    ),
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
// 🎯 Web role button
// ============================================================
class _WebRoleButton extends StatefulWidget {
  final IconData icon;
  final String label;
  final String subtitle;
  final List<Color> colors;
  final VoidCallback onTap;

  const _WebRoleButton({
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.colors,
    required this.onTap,
  });

  @override
  State<_WebRoleButton> createState() => _WebRoleButtonState();
}

class _WebRoleButtonState extends State<_WebRoleButton> {
  bool _hover = false;
  bool _press = false;

  @override
  Widget build(BuildContext context) {
    final accent = widget.colors.first;

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
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: accent.withOpacity(_hover ? 0.65 : 0.40),
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
                  gradient: LinearGradient(
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                    colors: [
                      Colors.white.withOpacity(_hover ? 0.22 : 0.14),
                      accent.withOpacity(_hover ? 0.24 : 0.14),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withOpacity(_hover ? 0.95 : 0.65),
                    width: 1.3,
                  ),
                ),
                child: Stack(
                  children: [
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
                    Positioned(
                      left: 0,
                      top: 0,
                      bottom: 0,
                      child: Container(
                        width: 5,
                        decoration: BoxDecoration(
                          color: accent,
                          boxShadow: [
                            BoxShadow(
                              color: accent.withOpacity(0.9),
                              blurRadius: 14,
                            ),
                          ],
                        ),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: Row(
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 220),
                            width: _hover ? 54 : 50,
                            height: _hover ? 54 : 50,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: accent.withOpacity(0.22),
                              border: Border.all(
                                color: accent.withOpacity(0.75),
                                width: 1.4,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: accent.withOpacity(_hover ? 0.8 : 0.5),
                                  blurRadius: _hover ? 22 : 14,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                            child: Icon(widget.icon,
                                color: Colors.white, size: 26),
                          ),
                          const SizedBox(width: 16),
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
                                  ),
                                ),
                              ],
                            ),
                          ),
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
// 🎬 Staggered fade + slide entry
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
// ❌ Error fallback
// ============================================================
class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.error});
  final String error;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        backgroundColor: const Color(0xFF0B1730),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 70, color: Colors.redAccent),
                const SizedBox(height: 16),
                const Text(
                  'Firebase failed to initialize',
                  style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: Colors.white),
                ),
                const SizedBox(height: 16),
                Text(
                  error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white70),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}