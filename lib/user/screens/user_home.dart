import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/foundation.dart' show kIsWeb; // 👈 Added for web checks
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/user_provider.dart';
import 'user_profile.dart';
import '../../services/settings_service.dart';
import '../../services/district_selection.dart';
import '../../services/district_service.dart';
import 'road_works.dart';
import 'metro_updates.dart';
import 'traffic_blocks.dart';
import 'report_problem.dart';
import 'my_reports.dart';
import 'best_route.dart';
import 'alerts_page.dart';
import 'complaints_page.dart';
import 'emergency_page.dart';
import 'fines_page.dart';
import 'transport_page.dart';
import 'help_page.dart';

class UserHome extends StatefulWidget {
  const UserHome({super.key});

  @override
  State<UserHome> createState() => _UserHomeState();
}

class _UserHomeState extends State<UserHome> with TickerProviderStateMixin {
  int _tabIndex = 0;

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
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _dustCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _dustRise = CurvedAnimation(parent: _dustCtrl, curve: Curves.linear);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<UserProvider>(context, listen: false).loadCurrentUser();
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
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text(
          _tabIndex == 1
              ? 'My Profile'
              : _tabIndex == 2
                  ? 'Settings'
                  : 'Hi, ${(user?.name != null && user!.name.isNotEmpty) ? user.name : "User"}',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w600)),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          if (_tabIndex != 1)
            IconButton(
              icon: const Icon(Icons.person),
              onPressed: () => setState(() => _tabIndex = 1),
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

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
            radius: 1.5,
            colors: const [Color(0xFF0B1130), Color(0xFF060A1E), Color(0xFF04060F)],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      );

  Widget _orbs(Size size) => Stack(children: [
        Positioned(
          left: -size.width * 0.15 + _parallax.dx * -14,
          top: -size.height * 0.18 + _parallax.dy * -10,
          child: _orb(380, const Color(0xFF3B82F6), 0.30)),
        Positioned(
          right: -size.width * 0.12 + _parallax.dx * 14,
          bottom: -size.height * 0.15 + _parallax.dy * 10,
          child: _orb(420, const Color(0xFF8B5CF6), 0.24)),
      ]);

  Widget _orb(double size, Color color, double opacity) => IgnorePointer(
        child: Container(
          width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withOpacity(opacity * (0.85 + _orbAnim.value * 0.3)),
              color.withOpacity(0.0),
            ])),
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
      list.add(Positioned(left: x, top: y,
        child: IgnorePointer(child: Opacity(opacity: opacity,
          child: Container(width: r * 2, height: r * 2,
            decoration: BoxDecoration(shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.55)))))));
    }
    return Stack(children: list);
  }

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const UserProfile(isEmbedded: true);
      case 2:
        return _buildSettingsTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildSettingsTab() {
    final settings = Provider.of<SettingsService>(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 140),
      children: [
        const SizedBox(height: 10),
        const Text('Preferences & Settings',
            style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
        const SizedBox(height: 4),
        const Text('Customize your app experience',
            style: TextStyle(color: Colors.white54, fontSize: 13)),
        const SizedBox(height: 20),

        _settingsCard(
          title: 'Notifications',
          icon: Icons.notifications_active_rounded,
          color: const Color(0xFF38BDF8),
          children: [
            _switchTile(
              'Push Notifications',
              'Receive updates on road work and reports',
              settings.pushNotifications,
              settings.setPushNotifications,
            ),
            _switchTile(
              'Sound Alerts',
              'Play sound when high-priority alerts arrive',
              settings.soundAlerts,
              settings.setSoundAlerts,
            ),
          ],
        ),

        const SizedBox(height: 16),

        _settingsCard(
          title: 'Location & Region',
          icon: Icons.location_on_rounded,
          color: const Color(0xFF10B981),
          children: [
            _switchTile(
              'Location Access',
              'Auto-detect GPS location for reporting issues',
              settings.locationTracking,
              settings.setLocationTracking,
            ),
            ListTile(
              title: const Text('Selected District',
                  style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
              subtitle: Text(
                DistrictService.current != null && DistrictService.current!.isNotEmpty
                    ? '${DistrictService.current} District'
                    : 'Tap to select district',
                style: const TextStyle(color: Colors.white54, fontSize: 12),
              ),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (DistrictService.current != null)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF10B981).withOpacity(0.2),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        DistrictService.current!,
                        style: const TextStyle(color: Color(0xFF10B981), fontSize: 11, fontWeight: FontWeight.bold),
                      ),
                    ),
                  const SizedBox(width: 4),
                  const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
                ],
              ),
              onTap: () async {
                await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const DistrictSelection()),
                );
                setState(() {});
              },
            ),
          ],
        ),

        const SizedBox(height: 16),

        _settingsCard(
          title: 'Display & Theme',
          icon: Icons.palette_rounded,
          color: const Color(0xFFA855F7),
          children: [
            _switchTile(
              'Dark Neon Mode',
              'Optimal readability and battery conservation',
              settings.darkMode,
              settings.setDarkMode,
            ),
          ],
        ),

        const SizedBox(height: 16),

        _settingsCard(
          title: 'Help & Citizen Support',
          icon: Icons.support_agent_rounded,
          color: const Color(0xFF0EA5E9),
          children: [
            ListTile(
              title: const Text('Help Center & FAQs',
                  style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
              subtitle: const Text('Guides on reporting issues, tracking status, and SOS',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const HelpPage()),
              ),
            ),
            ListTile(
              title: const Text('File a Complaint / Feedback',
                  style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
              subtitle: const Text('Send grievances or questions to PWD officials',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, color: Colors.white54, size: 14),
              onTap: () => Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ComplaintsPage()),
              ),
            ),
          ],
        ),

        const SizedBox(height: 16),

        _settingsCard(
          title: 'About Application',
          icon: Icons.info_outline_rounded,
          color: const Color(0xFFF59E0B),
          children: const [
            ListTile(
              title: Text('PWD Road Maintenance',
                  style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
              subtitle: Text('Kerala Public Works Department Citizen Portal',
                  style: TextStyle(color: Colors.white54, fontSize: 12)),
              trailing: Text('v1.0.0', style: TextStyle(color: Colors.white70, fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      ],
    );
  }

  Widget _settingsCard({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) =>
      ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.08),
                Colors.white.withOpacity(0.03),
              ]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withOpacity(0.16), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                  child: Row(
                    children: [
                      Icon(icon, color: color, size: 18),
                      const SizedBox(width: 8),
                      Text(title,
                          style: TextStyle(
                              color: color,
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5)),
                    ],
                  ),
                ),
                ...children,
              ],
            ),
          ),
        ),
      );

  Widget _switchTile(String title, String subtitle, bool value, ValueChanged<bool> onChanged) =>
      SwitchListTile(
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
        value: value,
        activeColor: const Color(0xFF38BDF8),
        onChanged: onChanged,
      );

  // ============================================================
  // 🏠 HOME TAB — News Slideshow + Services (4 + View All) + Authorities
  // ============================================================
  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 140),
      children: const [
        // 1. 📰 News Slideshow
        _NewsSlideshowSection(),
        SizedBox(height: 22),

        // 2. 🛠️ Services Grid
        _SectionHeader(
          title: 'Services',
          subtitle: 'Everything you need in one place',
          icon: Icons.grid_view_rounded,
        ),
        SizedBox(height: 12),
        _ServicesGrid(),
        SizedBox(height: 24),

        // 3. 📞 Authorities
        _SectionHeader(
          title: 'Authorities',
          subtitle: 'Reach out to the right person',
          icon: Icons.support_agent_rounded,
        ),
        SizedBox(height: 12),
        _AuthoritySection(),
        SizedBox(height: 20),
      ],
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
                  boxShadow: [
                    BoxShadow(color: Colors.black.withOpacity(0.45), blurRadius: 30, offset: const Offset(0, 10)),
                  ],
                ),
                child: Row(children: [
                  _navItem(0, Icons.home_rounded, 'Home'),
                  _navItem(1, Icons.person_rounded, 'Profile'),
                  _navItem(2, Icons.settings_rounded, 'Settings'),
                ]),
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
            boxShadow: selected
                ? [BoxShadow(color: const Color(0xFF3B82F6).withOpacity(0.45), blurRadius: 18)]
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

// ============================================================
// 📰 NEWS SLIDESHOW SECTION — auto-playing
// ============================================================
class _NewsSlideshowSection extends StatefulWidget {
  const _NewsSlideshowSection();

  @override
  State<_NewsSlideshowSection> createState() => _NewsSlideshowSectionState();
}

class _NewsSlideshowSectionState extends State<_NewsSlideshowSection> {
  late final PageController _pc;
  Timer? _timer;
  int _current = 0;

  final _slides = const [
    _Slide(
      title: 'Multi-vehicle accident on NH-44',
      body: '3 injured near Devanahalli toll. Traffic diverted via service road. Expect 40-min delay.',
      emoji: '🚗',
      tag: 'ACCIDENT',
      color: Color(0xFFEF4444),
    ),
    _Slide(
      title: 'MVD announces e-challan drive',
      body: 'Motor Vehicles Dept to run a 10-day drive against helmet & seatbelt violations.',
      emoji: '📢',
      tag: 'MVD NEWS',
      color: Color(0xFF3B82F6),
    ),
    _Slide(
      title: 'Night pothole repairs — ORR',
      body: 'Hebbal to KR Puram stretch closing tonight 11 PM – 5 AM. Use service roads.',
      emoji: '🚧',
      tag: 'ROAD WORK',
      color: Color(0xFFF59E0B),
    ),
    _Slide(
      title: 'Smart signal rollout — Phase 2',
      body: 'AI traffic signals now live at 24 more junctions. Average commute down 18%.',
      emoji: '🚦',
      tag: 'TRAFFIC',
      color: Color(0xFF10B981),
    ),
    _Slide(
      title: 'Heavy rain warning — 48 hrs',
      body: 'IMD warns of heavy rain. Avoid underpasses. Emergency helpline: 1077.',
      emoji: '🌧️',
      tag: 'ALERT',
      color: Color(0xFF06B6D4),
    ),
  ];

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: 0.9);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _slides.length;
      _pc.animateToPage(
        next,
        duration: const Duration(milliseconds: 600),
        curve: Curves.easeInOutCubic,
      );
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pc.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.fromLTRB(20, 6, 20, 4),
          child: Row(
            children: [
              Icon(Icons.newspaper_rounded, color: Colors.white, size: 20),
              SizedBox(width: 8),
              Text(
                'Latest News',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
              SizedBox(width: 8),
              _LiveDot(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text(
            'Accidents, MVD updates & road alerts',
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 12.5,
            ),
          ),
        ),
        SizedBox(
          height: 200,
          child: PageView.builder(
            controller: _pc,
            itemCount: _slides.length,
            onPageChanged: (i) => setState(() => _current = i),
            itemBuilder: (context, i) => _NewsSlideCard(slide: _slides[i]),
          ),
        ),
        const SizedBox(height: 10),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _slides.length,
            (i) => AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              margin: const EdgeInsets.symmetric(horizontal: 3),
              width: i == _current ? 22 : 7,
              height: 7,
              decoration: BoxDecoration(
                color: i == _current
                    ? _slides[_current].color
                    : Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(8),
                boxShadow: i == _current
                    ? [BoxShadow(
                        color: _slides[_current].color.withOpacity(0.7),
                        blurRadius: 12)]
                    : null,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _Slide {
  final String title;
  final String body;
  final String emoji;
  final String tag;
  final Color color;
  const _Slide({
    required this.title,
    required this.body,
    required this.emoji,
    required this.tag,
    required this.color,
  });
}

class _NewsSlideCard extends StatelessWidget {
  final _Slide slide;
  const _NewsSlideCard({required this.slide});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  slide.color.withOpacity(0.30),
                  slide.color.withOpacity(0.10),
                  Colors.white.withOpacity(0.05),
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(
                color: Colors.white.withOpacity(0.32),
                width: 1.3,
              ),
              boxShadow: [
                BoxShadow(
                  color: slide.color.withOpacity(0.35),
                  blurRadius: 26,
                  offset: const Offset(0, 10),
                ),
                BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 18,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Stack(
              children: [
                Positioned(
                  top: 0,
                  left: 24,
                  right: 24,
                  child: Container(
                    height: 1.4,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.white.withOpacity(0.0),
                          Colors.white.withOpacity(0.85),
                          Colors.white.withOpacity(0.0),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(18),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: slide.color.withOpacity(0.25),
                              border: Border.all(
                                color: slide.color.withOpacity(0.65),
                                width: 1.2,
                              ),
                            ),
                            child: Text(slide.emoji,
                                style: const TextStyle(fontSize: 22)),
                          ),
                          const SizedBox(width: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: slide.color.withOpacity(0.28),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: slide.color.withOpacity(0.7),
                                width: 1,
                              ),
                            ),
                            child: Text(
                              slide.tag,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                letterSpacing: 1.2,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        slide.title,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 15.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Color(0xAA000000),
                              blurRadius: 8,
                              offset: Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Expanded(
                        child: Text(
                          slide.body,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.85),
                            fontSize: 12.5,
                            height: 1.45,
                          ),
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
    );
  }
}

class _LiveDot extends StatefulWidget {
  const _LiveDot();

  @override
  State<_LiveDot> createState() => _LiveDotState();
}

class _LiveDotState extends State<_LiveDot>
    with SingleTickerProviderStateMixin {
  late AnimationController _c;

  @override
  void initState() {
    super.initState();
    _c = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _c,
      builder: (context, _) {
        return Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red,
            boxShadow: [
              BoxShadow(
                color: Colors.red.withOpacity(0.4 + _c.value * 0.6),
                blurRadius: 10 + _c.value * 10,
              ),
            ],
          ),
        );
      },
    );
  }
}

// ============================================================
// 🛠️ SECTION HEADER
// ============================================================
class _SectionHeader extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  const _SectionHeader({
    required this.title,
    required this.subtitle,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withOpacity(0.18),
                          Colors.white.withOpacity(0.06),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.35),
                        width: 1.1,
                      ),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            subtitle,
            style: TextStyle(
              color: Colors.white.withOpacity(0.65),
              fontSize: 12.5,
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 🛠️ SERVICES GRID — 4 visible + View All toggle
// ============================================================
class _ServicesGrid extends StatefulWidget {
  const _ServicesGrid();

  @override
  State<_ServicesGrid> createState() => _ServicesGridState();
}

class _ServicesGridState extends State<_ServicesGrid> {
  bool _expanded = false;
  static const int _visibleCount = 4;

  final List<_Feature> _all = const [
    _Feature('Road Works', Icons.construction_rounded, Color(0xFFF59E0B), RoadWorks()),
    _Feature('Metro Updates', Icons.subway_rounded, Color(0xFF3B82F6), MetroUpdates()),
    _Feature('Traffic Blocks', Icons.traffic_rounded, Color(0xFFEF4444), TrafficBlocks()),
    _Feature('Report Problem', Icons.report_problem_rounded, Color(0xFFA855F7), ReportProblem()),
    _Feature('My Reports', Icons.list_alt_rounded, Color(0xFF10B981), MyReports()),
    _Feature('Best Route', Icons.alt_route_rounded, Color(0xFF06B6D4), BestRoute()),
    _Feature('Alerts', Icons.notifications_active_rounded, Color(0xFFE11D48), AlertsPage()),
    _Feature('Complaints', Icons.forum_rounded, Color(0xFF8B5CF6), ComplaintsPage()),
    _Feature('Emergency SOS', Icons.emergency_rounded, Color(0xFFDC2626), EmergencyPage()),
    _Feature('Fines & Challans', Icons.receipt_long_rounded, Color(0xFFF59E0B), FinesPage()),
    _Feature('Public Transport', Icons.directions_bus_rounded, Color(0xFF22C55E), TransportPage()),
    _Feature('Help Center', Icons.help_center_rounded, Color(0xFF0EA5E9), HelpPage()),
  ];

  @override
  Widget build(BuildContext context) {
    final visible = _expanded ? _all : _all.take(_visibleCount).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 14,
              mainAxisSpacing: 14,
              childAspectRatio: 0.95,
            ),
            itemCount: visible.length,
            itemBuilder: (context, i) => _FeatureTile(
              key: ValueKey(visible[i].title),
              item: visible[i],
              delay: (i % _visibleCount) * 60,
            ),
          ),
          const SizedBox(height: 16),
          _ViewAllButton(
            expanded: _expanded,
            onTap: () => setState(() => _expanded = !_expanded),
          ),
        ],
      ),
    );
  }
}

class _Feature {
  final String title;
  final IconData icon;
  final Color color;
  final Widget page;
  const _Feature(this.title, this.icon, this.color, this.page);
}

// ============================================================
// 🔽 View All / Show Less pill
// ============================================================
class _ViewAllButton extends StatefulWidget {
  final bool expanded;
  final VoidCallback onTap;
  const _ViewAllButton({required this.expanded, required this.onTap});

  @override
  State<_ViewAllButton> createState() => _ViewAllButtonState();
}

class _ViewAllButtonState extends State<_ViewAllButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOut,
          height: 54,
          padding: const EdgeInsets.symmetric(horizontal: 26),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF3B82F6).withOpacity(_hover ? 0.65 : 0.35),
                blurRadius: _hover ? 34 : 20,
                offset: Offset(0, _hover ? 12 : 6),
              ),
              BoxShadow(
                color: Colors.black.withOpacity(0.30),
                blurRadius: 14,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(100),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      const Color(0xFF3B82F6).withOpacity(_hover ? 0.45 : 0.28),
                      const Color(0xFF8B5CF6).withOpacity(_hover ? 0.35 : 0.20),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                    color: Colors.white.withOpacity(_hover ? 0.90 : 0.55),
                    width: 1.3,
                  ),
                ),
                child: Stack(
                  children: [
                    Positioned(
                      top: 0,
                      left: 30,
                      right: 30,
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
                    Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedRotation(
                            turns: widget.expanded ? 0.5 : 0.0,
                            duration: const Duration(milliseconds: 300),
                            curve: Curves.easeOutCubic,
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: Colors.white,
                              size: 22,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(
                            widget.expanded ? 'Show Less' : 'View All Services',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.5,
                              shadows: [
                                Shadow(
                                  color: Color(0xAA000000),
                                  blurRadius: 10,
                                  offset: Offset(0, 1),
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
// 🎯 Feature Tile
// ============================================================
class _FeatureTile extends StatefulWidget {
  final _Feature item;
  final int delay;
  const _FeatureTile({super.key, required this.item, required this.delay});

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
            onTap: () => Navigator.push(context,
                MaterialPageRoute(builder: (_) => item.page)),
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
                            child: Icon(item.icon, size: 28, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(
                              item.title,
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12.5,
                                fontWeight: FontWeight.w600,
                                shadows: [Shadow(color: Color(0xAA000000), blurRadius: 8, offset: Offset(0, 1))],
                              ),
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

// ============================================================
// 📞 AUTHORITY SECTION — with tap-to-call
// ============================================================
class _AuthoritySection extends StatelessWidget {
  const _AuthoritySection();

  @override
  Widget build(BuildContext context) {
    final contacts = const [
      _Authority(name: 'Rajesh Kumar', role: 'Road Maintenance Manager', phone: '+91 98XXX 11111', emoji: '👨‍💼', color: Color(0xFF3B82F6)),
      _Authority(name: 'Priya Sharma', role: 'Road Safety Officer', phone: '+91 98XXX 22222', emoji: '👮‍♀️', color: Color(0xFF10B981)),
      _Authority(name: 'Arjun Mehta', role: 'Traffic Control Head', phone: '+91 98XXX 33333', emoji: '🚦', color: Color(0xFFF59E0B)),
      _Authority(name: 'Emergency Helpline', role: '24×7 Ambulance / Police', phone: '112 / 100 / 108', emoji: '🚨', color: Color(0xFFEF4444)),
    ];

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: contacts.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _AuthorityTile(a: contacts[i]),
    );
  }
}

class _Authority {
  final String name;
  final String role;
  final String phone;
  final String emoji;
  final Color color;
  const _Authority({
    required this.name,
    required this.role,
    required this.phone,
    required this.emoji,
    required this.color,
  });
}

class _AuthorityTile extends StatelessWidget {
  final _Authority a;
  const _AuthorityTile({required this.a});

  Future<void> _call(BuildContext context) async {
    final cleaned = a.phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri);
      } else {
        if (!kIsWeb && context.mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Could not launch phone dialer.')),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white.withOpacity(0.10),
              a.color.withOpacity(0.10),
            ]),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.1),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48, height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: a.color.withOpacity(0.22),
                  border: Border.all(color: a.color.withOpacity(0.6), width: 1.2),
                ),
                child: Text(a.emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(a.name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(a.role,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11.5)),
                    const SizedBox(height: 3),
                    Text(a.phone,
                        style: TextStyle(
                            color: a.color.withOpacity(0.95),
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => _call(context),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: a.color.withOpacity(0.20),
                      border: Border.all(color: a.color.withOpacity(0.5)),
                    ),
                    child: Icon(Icons.call_rounded, color: a.color, size: 20),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}