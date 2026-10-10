import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import 'user_profile.dart';
import 'road_works.dart';
import 'metro_updates.dart';
import 'traffic_blocks.dart';
import 'report_problem.dart';
import 'my_reports.dart';
import 'best_route.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});
  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome>
    with TickerProviderStateMixin {
  int _tabIndex = 0;

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
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Hi, ${user?.name ?? "User"}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const UserProfile())),
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
                    Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: Alignment(-0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
                          radius: 1.5,
                          colors: const [Color(0xFF0B1130), Color(0xFF060A1E), Color(0xFF04060F)],
                          stops: const [0.0, 0.55, 1.0],
                        ),
                      ),
                    ),
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
                    SafeArea(
                      bottom: false,
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 350),
                        child: _buildTab(_tabIndex),
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: _bottomNav(),
    );
  }

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

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const Center(
          child: Text('Profile tab', style: TextStyle(color: Colors.white)),
        );
      case 2:
        return const Center(
          child: Text('Settings tab', style: TextStyle(color: Colors.white)),
        );
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    final items = [
      _Feature('Road Works', Icons.construction_rounded, const Color(0xFFF59E0B), const RoadWorks()),
      _Feature('Metro Updates', Icons.subway_rounded, const Color(0xFF3B82F6), const MetroUpdates()),
      _Feature('Traffic Blocks', Icons.traffic_rounded, const Color(0xFFEF4444), const TrafficBlocks()),
      _Feature('Report Problem', Icons.report_problem_rounded, const Color(0xFFA855F7), const ReportProblem()),
      _Feature('My Reports', Icons.list_alt_rounded, const Color(0xFF10B981), const MyReports()),
      _Feature('Best Route', Icons.alt_route_rounded, const Color(0xFF06B6D4), const BestRoute()),
    ];

    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 14,
        mainAxisSpacing: 14,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (context, i) => _FeatureTile(item: items[i], delay: i * 80),
    );
  }

  Widget _bottomNav() => SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(28),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
              child: Container(
                height: 68,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    const Color(0xFF1B2B54).withOpacity(0.65),
                    const Color(0xFF0C1730).withOpacity(0.55),
                  ]),
                  borderRadius: BorderRadius.circular(28),
                  border: Border.all(color: Colors.white.withOpacity(0.18), width: 1.2),
                ),
                child: Row(
                  children: [
                    _navItem(0, Icons.home_rounded, 'Home'),
                    _navItem(1, Icons.person_rounded, 'Profile'),
                    _navItem(2, Icons.settings_rounded, 'Settings'),
                  ],
                ),
              ),
            ),
          ),
        ),
      );

  Widget _navItem(int index, IconData icon, String label) {
    final selected = _tabIndex == index;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _tabIndex = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 250),
          margin: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: selected
                ? LinearGradient(colors: [
                    const Color(0xFF3B82F6).withOpacity(0.45),
                    const Color(0xFF8B5CF6).withOpacity(0.35),
                  ])
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: selected ? Colors.white : Colors.white.withOpacity(0.55), size: 22),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    color: selected ? Colors.white : Colors.white.withOpacity(0.55),
                    fontSize: 10.5,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                  )),
            ],
          ),
        ),
      ),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  _Feature(this.title, this.icon, this.color, this.page);
}

class _FeatureTile extends StatefulWidget {
  final _Feature item;
  final int delay;
  const _FeatureTile({required this.item, required this.delay});

  @override
  State<_FeatureTile> createState() => _FeatureTileState();
}

class _FeatureTileState extends State<_FeatureTile>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  bool _hover = false;
  bool _press = false;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
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
              context,
              MaterialPageRoute(builder: (_) => item.page),
            ),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 220),
              transform: Matrix4.identity()..scale(_press ? 0.97 : (_hover ? 1.03 : 1.0)),
              transformAlignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: item.color.withOpacity(_hover ? 0.45 : 0.25),
                    blurRadius: _hover ? 28 : 16,
                    offset: Offset(0, _hover ? 10 : 6),
                  ),
                  BoxShadow(color: Colors.black.withOpacity(0.25), blurRadius: 10, offset: const Offset(0, 4)),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.white.withOpacity(_hover ? 0.14 : 0.08),
                        item.color.withOpacity(_hover ? 0.14 : 0.08),
                      ]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                        color: Colors.white.withOpacity(_hover ? 0.55 : 0.28),
                        width: 1.2,
                      ),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: item.color.withOpacity(0.18),
                              border: Border.all(color: item.color.withOpacity(0.55), width: 1.4),
                              boxShadow: [
                                BoxShadow(
                                  color: item.color.withOpacity(_hover ? 0.65 : 0.40),
                                  blurRadius: _hover ? 22 : 14,
                                ),
                              ],
                            ),
                            child: Icon(item.icon, size: 30, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            item.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 13.5,
                              fontWeight: FontWeight.w600,
                              shadows: [Shadow(color: Color(0xAA000000), blurRadius: 8, offset: Offset(0, 1))],
                            ),
                          ),
                        ],
                      ),
                    ),
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