import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/admin_provider.dart';
import 'applications.dart';
import 'employee_assignment.dart';
import 'work_verification.dart';
import 'manage_employees.dart';
import 'admin_profile.dart';
import 'manage_alerts.dart';
import 'manage_news.dart';
import 'manage_authorities.dart';
import 'manage_complaints.dart';
import 'manage_fines.dart' hide ManageNews;
import 'admin_metro_updates.dart';
import 'admin_leave_requests.dart';
import 'admin_daily_reports.dart';
import 'admin_traffic_blocks.dart'; // 👈 NEW

class AdminHome extends StatefulWidget {
  const AdminHome({super.key});
  @override
  State<AdminHome> createState() => _AdminHomeState();
}

class _AdminHomeState extends State<AdminHome> with TickerProviderStateMixin {
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
          child: Text(
            'Admin panel is only available on the Web.',
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      );
    }

    final admin = Provider.of<AdminProvider>(context).admin;

    // ============================================================
    // WORKFLOW
    // ============================================================
    final workflowItems = [
      _Item(
        'Applications',
        Icons.list_alt_rounded,
        const Color(0xFF3B82F6),
        const Color(0xFF0B1D3A),
        const Color(0xFF04101F),
        const Applications(),
      ),
      _Item(
        'Assign Work',
        Icons.assignment_ind_rounded,
        const Color(0xFFF59E0B),
        const Color(0xFF2E1E06),
        const Color(0xFF140D02),
        const EmployeeAssignment(),
      ),
      _Item(
        'Metro Updates',
        Icons.subway_rounded,
        const Color(0xFF06B6D4),
        const Color(0xFF052A33),
        const Color(0xFF02141A),
        const AdminMetroUpdates(),
      ),
      _Item(
        'Verify Work',
        Icons.verified_rounded,
        const Color(0xFF10B981),
        const Color(0xFF062A1E),
        const Color(0xFF021410),
        const WorkVerification(),
      ),
      _Item(
        'Manage Employees',
        Icons.people_alt_rounded,
        const Color(0xFFA855F7),
        const Color(0xFF1E0B3A),
        const Color(0xFF0D031A),
        const ManageEmployees(),
      ),
      _Item(
        'Leave Requests',
        Icons.event_note_rounded,
        const Color(0xFF06B6D4),
        const Color(0xFF052A33),
        const Color(0xFF02141A),
        const AdminLeaveRequests(),
      ),
      _Item(
        'Daily Reports',
        Icons.assignment_turned_in_rounded,
        const Color(0xFFF59E0B),
        const Color(0xFF2E1E06),
        const Color(0xFF140D02),
        const AdminDailyReports(),
      ),
      // 👇 NEW: Traffic Blocks tile
      _Item(
        'Traffic Blocks',
        Icons.traffic_rounded,
        const Color(0xFFEF4444),
        const Color(0xFF3A0A18),
        const Color(0xFF16040A),
        const AdminTrafficBlocks(),
      ),
    ];

    // ============================================================
    // CONTENT
    // ============================================================
    final contentItems = [
      _Item(
        'Manage Alerts',
        Icons.notifications_active_rounded,
        const Color(0xFFE11D48),
        const Color(0xFF3A0A18),
        const Color(0xFF16040A),
        const ManageAlerts(),
      ),
      _Item(
        'Manage News',
        Icons.newspaper_rounded,
        const Color(0xFF06B6D4),
        const Color(0xFF052A33),
        const Color(0xFF02141A),
        const ManageNews(),
      ),
      _Item(
        'Authorities',
        Icons.support_agent_rounded,
        const Color(0xFFF97316),
        const Color(0xFF2A1505),
        const Color(0xFF130902),
        const ManageAuthorities(),
      ),
      _Item(
        'Complaints',
        Icons.forum_rounded,
        const Color(0xFF8B5CF6),
        const Color(0xFF1E0E3A),
        const Color(0xFF0D061A),
        const ManageComplaints(),
      ),
      _Item(
        'Fines & Challans',
        Icons.receipt_long_rounded,
        const Color(0xFFDC2626),
        const Color(0xFF320A0A),
        const Color(0xFF140404),
        const ManageFines(),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: Text(
          'Admin: ${admin?.name ?? "Admin"}',
          style:
              const TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => const AdminProfile())),
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
                      child: SingleChildScrollView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        child: Center(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 950),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                _welcomeHeader(admin),
                                const SizedBox(height: 20),
                                _sectionLabel('WORKFLOW'),
                                const SizedBox(height: 12),
                                _grid(workflowItems, 0),
                                const SizedBox(height: 22),
                                _sectionLabel('CONTENT'),
                                const SizedBox(height: 12),
                                _grid(contentItems, 8),
                              ],
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

  Widget _grid(List<_Item> items, int startIndex) => GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.0,
        ),
        itemCount: items.length,
        itemBuilder: (context, i) => _AdminTile(
          item: items[i],
          delay: (startIndex + i) * 70,
        ),
      );

  Widget _sectionLabel(String text) => Text(
        text,
        style: TextStyle(
          color: Colors.white.withOpacity(0.55),
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.5,
        ),
      );

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
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      );

  Widget _orbs(Size size) => Stack(children: [
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
        Positioned(
          right: size.width * 0.10 + _parallax.dx * 8,
          top: size.height * 0.20 + _parallax.dy * 6,
          child: _orb(220, const Color(0xFF06B6D4), 0.22),
        ),
      ]);

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
                boxShadow: [
                  BoxShadow(
                      color: Colors.white.withOpacity(0.30), blurRadius: 6)
                ],
              ),
            ),
          ),
        ),
      ));
    }
    return Stack(children: list);
  }

  Widget _welcomeHeader(dynamic admin) => ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(18),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                const Color(0xFF3B82F6).withOpacity(0.10),
              ]),
              borderRadius: BorderRadius.circular(28),
              border:
                  Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
            ),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(18),
                  gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.55),
                        blurRadius: 22,
                        spreadRadius: 1)
                  ],
                ),
                child: const Icon(Icons.admin_panel_settings_rounded,
                    color: Colors.white, size: 26),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(admin?.name ?? 'Admin',
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800)),
                    const SizedBox(height: 4),
                    Text('Control center — approve, assign, verify & manage',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.75),
                            fontSize: 12.5)),
                  ],
                ),
              ),
            ]),
          ),
        ),
      );
}

// ============================================================
// _Item
// ============================================================
class _Item {
  final String title;
  final IconData icon;
  final Color color;
  final Color gradientTop;
  final Color gradientBottom;
  final Widget page;
  _Item(this.title, this.icon, this.color, this.gradientTop,
      this.gradientBottom, this.page);
}

// ============================================================
// _AdminTile
// ============================================================
class _AdminTile extends StatefulWidget {
  final _Item item;
  final int delay;
  const _AdminTile({required this.item, required this.delay});
  @override
  State<_AdminTile> createState() => _AdminTileState();
}

class _AdminTileState extends State<_AdminTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _hover = false;
  bool _press = false;
  static const double _radius = 48;

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
    final item = widget.item;
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
            onTap: () => Navigator.push(
                context, MaterialPageRoute(builder: (_) => item.page)),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              transform: Matrix4.identity()
                ..scale(_press ? 0.97 : (_hover ? 1.03 : 1.0)),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(_radius),
                boxShadow: [
                  BoxShadow(
                      color: item.color.withOpacity(_hover ? 0.55 : 0.30),
                      blurRadius: _hover ? 32 : 18,
                      offset: Offset(0, _hover ? 12 : 8)),
                  BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 6)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(_radius),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [item.gradientTop, item.gradientBottom],
                      ),
                      borderRadius: BorderRadius.circular(_radius),
                      border: Border.all(
                          color: item.color.withOpacity(_hover ? 0.85 : 0.45),
                          width: 1.4),
                    ),
                    child: Stack(children: [
                      Positioned.fill(
                        child: IgnorePointer(
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: RadialGradient(
                                center: Alignment.topRight,
                                radius: 1.1,
                                colors: [
                                  item.color.withOpacity(_hover ? 0.35 : 0.20),
                                  item.color.withOpacity(0.0),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                      Positioned(
                        top: 0,
                        left: 40,
                        right: 40,
                        child: Container(
                          height: 1.4,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.85),
                              Colors.white.withOpacity(0.0),
                            ]),
                          ),
                        ),
                      ),
                      Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 220),
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(22),
                                gradient: LinearGradient(colors: [
                                  item.color.withOpacity(_hover ? 0.45 : 0.30),
                                  item.color.withOpacity(_hover ? 0.18 : 0.10),
                                ]),
                                border: Border.all(
                                    color: item.color
                                        .withOpacity(_hover ? 0.85 : 0.60),
                                    width: 1.4),
                                boxShadow: [
                                  BoxShadow(
                                      color: item.color
                                          .withOpacity(_hover ? 0.85 : 0.55),
                                      blurRadius: _hover ? 30 : 18,
                                      spreadRadius: 1)
                                ],
                              ),
                              child: Icon(item.icon,
                                  size: 28,
                                  color: Colors.white,
                                  shadows: const [
                                    Shadow(
                                        color: Color(0xAA000000), blurRadius: 8)
                                  ]),
                            ),
                            const SizedBox(height: 14),
                            Padding(
                              padding:
                                  const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                item.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 13.5,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 0.3,
                                    shadows: [
                                      Shadow(
                                          color: Color(0xAA000000),
                                          blurRadius: 10,
                                          offset: Offset(0, 1))
                                    ]),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ]),
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
