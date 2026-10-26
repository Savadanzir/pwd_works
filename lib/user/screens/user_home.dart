import 'dart:async';
import 'dart:math' as math;
import 'dart:ui';
import 'package:audioplayers/audioplayers.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:road_maintenance/services/settings_service.dart';
import 'package:url_launcher/url_launcher.dart';

import '../providers/user_provider.dart';

import 'road_works.dart';
import 'metro_updates.dart';
import 'traffic_blocks.dart';
import 'report_problem.dart';
import 'my_reports.dart';
import 'best_route.dart';
import 'alerts_page.dart';
import 'emergency_page.dart';
import 'fines_page.dart';
import 'transport_page.dart';
import 'help_page.dart';
import 'news_page.dart';

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
    final user = Provider.of<UserProvider>(context).user;

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        title: Text('Hi, ${user?.name ?? "User"}',
            style: const TextStyle(
                color: Colors.white, fontWeight: FontWeight.w600)),
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
            child: _orb(380, const Color(0xFF3B82F6), 0.30)),
        Positioned(
            right: -size.width * 0.12 + _parallax.dx * 14,
            bottom: -size.height * 0.15 + _parallax.dy * 10,
            child: _orb(420, const Color(0xFF8B5CF6), 0.24)),
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
              ])),
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
                          color: Colors.white.withOpacity(0.55)))))));
    }
    return Stack(children: list);
  }

  Widget _buildTab(int i) {
    switch (i) {
      case 0:
        return _buildHomeTab();
      case 1:
        return const _ProfileTab();
      case 2:
        return const _SettingsTab();
      default:
        return _buildHomeTab();
    }
  }

  Widget _buildHomeTab() {
    return ListView(
      padding: const EdgeInsets.fromLTRB(0, 8, 0, 140),
      children: const [
        _NewsSlideshowSection(),
        SizedBox(height: 22),
        _SectionHeader(
          title: 'Services',
          subtitle: 'Everything you need in one place',
          icon: Icons.grid_view_rounded,
        ),
        SizedBox(height: 12),
        _ServicesGrid(),
        SizedBox(height: 24),
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
                  border: Border.all(
                      color: Colors.white.withOpacity(0.18), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                        color: Colors.black.withOpacity(0.45),
                        blurRadius: 30,
                        offset: const Offset(0, 10)),
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
                ? [
                    BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.45),
                        blurRadius: 18)
                  ]
                : null,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon,
                  color:
                      selected ? Colors.white : Colors.white.withOpacity(0.55),
                  size: 22),
              const SizedBox(height: 2),
              Text(label,
                  style: TextStyle(
                    color: selected
                        ? Colors.white
                        : Colors.white.withOpacity(0.55),
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
// ⚙️ SETTINGS TAB
// ============================================================
class _SettingsTab extends StatefulWidget {
  const _SettingsTab();
  @override
  State<_SettingsTab> createState() => _SettingsTabState();
}

class _SettingsTabState extends State<_SettingsTab> {
  final AudioPlayer _audioPlayer = AudioPlayer();

  @override
  void dispose() {
    _audioPlayer.dispose();
    super.dispose();
  }

  Future<void> _testSound() async {
    try {
      await _audioPlayer.play(AssetSource('sounds/alert.mp3'));
    } catch (e) {
      debugPrint('Sound asset missing, using system beep: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    final settings = Provider.of<SettingsService>(context);
    final userProvider = Provider.of<UserProvider>(context);

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
      children: [
        Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                    colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                boxShadow: [
                  BoxShadow(
                      color: const Color(0xFF3B82F6).withOpacity(0.4),
                      blurRadius: 16)
                ],
              ),
              child: const Icon(Icons.settings_rounded,
                  color: Colors.white, size: 24),
            ),
            const SizedBox(width: 14),
            const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Settings',
                    style: TextStyle(
                        color: Colors.white,
                        fontSize: 24,
                        fontWeight: FontWeight.bold)),
                Text('Manage your preferences',
                    style: TextStyle(color: Colors.white54, fontSize: 12)),
              ],
            ),
          ],
        ),
        const SizedBox(height: 30),
        _SettingsSectionTitle(title: 'Preferences', icon: Icons.tune_rounded),
        _SettingsToggleTile(
          icon: Icons.notifications_active_outlined,
          title: 'Push Notifications',
          subtitle: settings.pushNotifications
              ? 'Alerts for road works & news enabled'
              : 'You will not receive any alerts',
          value: settings.pushNotifications,
          color: const Color(0xFF3B82F6),
          onChanged: (v) async {
            await settings.setPushNotifications(v);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(v
                    ? '✅ Push notifications turned ON'
                    : '🔕 Push notifications turned OFF'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        _SettingsToggleTile(
          icon: Icons.dark_mode_outlined,
          title: 'Dark Mode',
          subtitle: settings.darkMode
              ? 'Dark theme is active'
              : 'Light theme will be applied',
          value: settings.darkMode,
          color: const Color(0xFF8B5CF6),
          onChanged: (v) async {
            await settings.setDarkMode(v);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content:
                    Text(v ? '🌙 Dark mode enabled' : '☀️ Light mode enabled'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        _SettingsToggleTile(
          icon: Icons.location_on_outlined,
          title: 'Location Tracking',
          subtitle: settings.locationTracking
              ? 'App can use your location for reports'
              : 'Location access is blocked',
          value: settings.locationTracking,
          color: const Color(0xFF10B981),
          onChanged: (v) async {
            await settings.setLocationTracking(v);
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(v
                    ? '📍 Location tracking enabled'
                    : '🚫 Location tracking disabled'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        _SettingsToggleTile(
          icon: Icons.volume_up_outlined,
          title: 'Sound Alerts',
          subtitle: settings.soundAlerts
              ? 'Plays sound on emergency alerts'
              : 'Silent mode for emergency alerts',
          value: settings.soundAlerts,
          color: const Color(0xFFF59E0B),
          onChanged: (v) async {
            await settings.setSoundAlerts(v);
            if (!mounted) return;
            if (v) {
              await _testSound();
            }
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(v
                    ? '🔊 Sound alerts turned ON — preview playing'
                    : '🔇 Sound alerts turned OFF'),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        ),
        const SizedBox(height: 24),
        _SettingsSectionTitle(
            title: 'Account', icon: Icons.manage_accounts_outlined),
        _SettingsActionTile(
          icon: Icons.lock_outline,
          title: 'Change Password',
          color: const Color(0xFF06B6D4),
          onTap: () => _showChangePasswordSheet(context),
        ),
        _SettingsActionTile(
          icon: Icons.language_outlined,
          title: 'Language',
          trailing: 'English',
          color: const Color(0xFFA855F7),
          onTap: () => _showLanguageSheet(context),
        ),
        _SettingsActionTile(
          icon: Icons.privacy_tip_outlined,
          title: 'Privacy Policy',
          color: const Color(0xFF22C55E),
          onTap: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Opening privacy policy...')),
            );
          },
        ),
        _SettingsActionTile(
          icon: Icons.info_outline,
          title: 'About App',
          trailing: 'v1.0.0',
          color: const Color(0xFF0EA5E9),
          onTap: () {
            showAboutDialog(
              context: context,
              applicationName: 'Road Maintenance App',
              applicationVersion: '1.0.0',
              applicationIcon:
                  const Icon(Icons.construction, color: Colors.blue, size: 40),
            );
          },
        ),
        const SizedBox(height: 24),
        _SettingsSectionTitle(
            title: 'Danger Zone',
            icon: Icons.warning_amber_rounded,
            color: Colors.redAccent),
        _SettingsActionTile(
          icon: Icons.delete_forever_outlined,
          title: 'Delete Account',
          color: Colors.redAccent,
          onTap: () => _confirmDelete(context, userProvider),
        ),
        const SizedBox(height: 20),
      ],
    );
  }

  void _showChangePasswordSheet(BuildContext context) {
    final oldPass = TextEditingController();
    final newPass = TextEditingController();

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1130),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 20,
          right: 20,
          top: 20,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Change Password',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 20,
                    fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            TextField(
              controller: oldPass,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Current Password',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: newPass,
              obscureText: true,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'New Password',
                labelStyle: const TextStyle(color: Colors.white54),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF3B82F6),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: () async {
                  if (newPass.text.length < 6) {
                    ScaffoldMessenger.of(ctx).showSnackBar(
                      const SnackBar(
                          content:
                              Text('Password must be at least 6 characters')),
                    );
                    return;
                  }
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('✅ Password updated successfully')),
                  );
                },
                child: const Text('Update Password',
                    style: TextStyle(
                        color: Colors.white, fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showLanguageSheet(BuildContext context) {
    final langs = ['English', 'हिन्दी', 'ಕನ್ನಡ', 'தமிழ்', 'తెలుగు'];
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0B1130),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => ListView(
        shrinkWrap: true,
        padding: const EdgeInsets.all(20),
        children: [
          const Text('Select Language',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
          const SizedBox(height: 12),
          ...langs.map((l) => ListTile(
                title: Text(l, style: const TextStyle(color: Colors.white)),
                trailing: l == 'English'
                    ? const Icon(Icons.check_circle, color: Color(0xFF3B82F6))
                    : null,
                onTap: () {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Language set to $l')),
                  );
                },
              )),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, UserProvider userProvider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF0B1130),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Account?',
            style: TextStyle(color: Colors.white)),
        content: const Text(
          'This action is permanent and cannot be undone. All your reports and data will be lost.',
          style: TextStyle(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () async {
              Navigator.pop(ctx);
              await userProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// 🧩 SETTINGS HELPER WIDGETS
// ============================================================

class _SettingsSectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  const _SettingsSectionTitle(
      {required this.title, required this.icon, this.color = Colors.white70});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10, left: 4, top: 8),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Text(
            title.toUpperCase(),
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _SettingsToggleTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final Color color;
  final ValueChanged<bool> onChanged;

  const _SettingsToggleTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.color,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: color, size: 20),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      child: Text(
                        subtitle,
                        key: ValueKey(subtitle),
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11.5),
                      ),
                    ),
                  ],
                ),
              ),
              Switch.adaptive(
                value: value,
                activeColor: color,
                activeTrackColor: color.withOpacity(0.3),
                inactiveThumbColor: Colors.white54,
                inactiveTrackColor: Colors.white12,
                onChanged: onChanged,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsActionTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? trailing;
  final Color color;
  final VoidCallback onTap;

  const _SettingsActionTile({
    required this.icon,
    required this.title,
    required this.color,
    required this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTap,
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(9),
                      decoration: BoxDecoration(
                          color: color.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10)),
                      child: Icon(icon, color: color, size: 20),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                              fontWeight: FontWeight.w600)),
                    ),
                    if (trailing != null)
                      Text(trailing!,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.5),
                              fontSize: 12.5)),
                    const SizedBox(width: 6),
                    Icon(Icons.arrow_forward_ios_rounded,
                        color: Colors.white.withOpacity(0.4), size: 14),
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
// 👤 PROFILE TAB WIDGET
// ============================================================
class _ProfileTab extends StatelessWidget {
  const _ProfileTab();

  @override
  Widget build(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context);
    final user = userProvider.user;

    if (user == null) {
      return const Center(
          child: Text('No user data found',
              style: TextStyle(color: Colors.white)));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 140),
      children: [
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(
                      colors: [Color(0xFF3B82F6), Color(0xFF8B5CF6)]),
                  boxShadow: [
                    BoxShadow(
                        color: const Color(0xFF3B82F6).withOpacity(0.4),
                        blurRadius: 20,
                        spreadRadius: 2)
                  ],
                ),
                child: const CircleAvatar(
                  radius: 50,
                  backgroundColor: Color(0xFF0B1130),
                  child: Icon(Icons.person, size: 55, color: Colors.white),
                ),
              ),
              const SizedBox(height: 16),
              Text(user.name,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold)),
              const SizedBox(height: 4),
              Text(user.email,
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.6), fontSize: 14)),
            ],
          ),
        ),
        const SizedBox(height: 40),
        _ProfileInfoCard(
            icon: Icons.person_outline,
            label: 'Full Name',
            value: user.name,
            color: const Color(0xFF3B82F6)),
        const SizedBox(height: 12),
        _ProfileInfoCard(
            icon: Icons.email_outlined,
            label: 'Email Address',
            value: user.email,
            color: const Color(0xFF10B981)),
        const SizedBox(height: 12),
        _ProfileInfoCard(
            icon: Icons.phone_outlined,
            label: 'Phone Number',
            value: user.phone,
            color: const Color(0xFFF59E0B)),
        const SizedBox(height: 30),
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Logout',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFEF4444).withOpacity(0.8),
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16)),
              elevation: 0,
            ),
            onPressed: () async {
              await userProvider.logout();
              if (context.mounted) {
                Navigator.pushNamedAndRemoveUntil(
                    context, '/', (route) => false);
              }
            },
          ),
        ),
      ],
    );
  }
}

class _ProfileInfoCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  const _ProfileInfoCard(
      {required this.icon,
      required this.label,
      required this.value,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(18),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: Colors.white.withOpacity(0.1)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: color.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12)),
                child: Icon(icon, color: color, size: 22),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(label,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 12)),
                    const SizedBox(height: 4),
                    Text(value,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// 📰 NEWS SLIDESHOW SECTION
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
        body:
            '3 injured near Devanahalli toll. Traffic diverted via service road. Expect 40-min delay.',
        emoji: '🚗',
        tag: 'ACCIDENT',
        color: Color(0xFFEF4444)),
    _Slide(
        title: 'MVD announces e-challan drive',
        body:
            'Motor Vehicles Dept to run a 10-day drive against helmet & seatbelt violations.',
        emoji: '📢',
        tag: 'MVD NEWS',
        color: Color(0xFF3B82F6)),
    _Slide(
        title: 'Night pothole repairs — ORR',
        body:
            'Hebbal to KR Puram stretch closing tonight 11 PM – 5 AM. Use service roads.',
        emoji: '🚧',
        tag: 'ROAD WORK',
        color: Color(0xFFF59E0B)),
    _Slide(
        title: 'Smart signal rollout — Phase 2',
        body:
            'AI traffic signals now live at 24 more junctions. Average commute down 18%.',
        emoji: '🚦',
        tag: 'TRAFFIC',
        color: Color(0xFF10B981)),
    _Slide(
        title: 'Heavy rain warning — 48 hrs',
        body:
            'IMD warns of heavy rain. Avoid underpasses. Emergency helpline: 1077.',
        emoji: '🌧️',
        tag: 'ALERT',
        color: Color(0xFF06B6D4)),
  ];

  @override
  void initState() {
    super.initState();
    _pc = PageController(viewportFraction: 0.9);
    _timer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted) return;
      final next = (_current + 1) % _slides.length;
      _pc.animateToPage(next,
          duration: const Duration(milliseconds: 600),
          curve: Curves.easeInOutCubic);
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
              Text('Latest News',
                  style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3)),
              SizedBox(width: 8),
              _LiveDot(),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
          child: Text('Accidents, MVD updates & road alerts',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 12.5)),
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
                    ? [
                        BoxShadow(
                            color: _slides[_current].color.withOpacity(0.7),
                            blurRadius: 12)
                      ]
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
  const _Slide(
      {required this.title,
      required this.body,
      required this.emoji,
      required this.tag,
      required this.color});
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
                  Colors.white.withOpacity(0.05)
                ],
                stops: const [0.0, 0.55, 1.0],
              ),
              borderRadius: BorderRadius.circular(28),
              border:
                  Border.all(color: Colors.white.withOpacity(0.32), width: 1.3),
              boxShadow: [
                BoxShadow(
                    color: slide.color.withOpacity(0.35),
                    blurRadius: 26,
                    offset: const Offset(0, 10)),
                BoxShadow(
                    color: Colors.black.withOpacity(0.30),
                    blurRadius: 18,
                    offset: const Offset(0, 8)),
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
                      gradient: LinearGradient(colors: [
                        Colors.white.withOpacity(0.0),
                        Colors.white.withOpacity(0.85),
                        Colors.white.withOpacity(0.0)
                      ]),
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
                                  width: 1.2),
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
                                  width: 1),
                            ),
                            child: Text(slide.tag,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2)),
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
                                  offset: Offset(0, 1))
                            ]),
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
                              height: 1.45),
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
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat(reverse: true);
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
                  blurRadius: 10 + _c.value * 10)
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
  const _SectionHeader(
      {required this.title, required this.subtitle, required this.icon});

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
                            Colors.white.withOpacity(0.06)
                          ]),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.35), width: 1.1),
                    ),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(title,
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.3)),
            ],
          ),
          const SizedBox(height: 6),
          Text(subtitle,
              style: TextStyle(
                  color: Colors.white.withOpacity(0.65), fontSize: 12.5)),
        ],
      ),
    );
  }
}

// ============================================================
// 🛠️ SERVICES GRID
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
    _Feature('Road Works', Icons.construction_rounded, Color(0xFFF59E0B),
        RoadWorks()),
    _Feature('Metro Updates', Icons.subway_rounded, Color(0xFF3B82F6),
        MetroUpdates()),
    _Feature('Traffic Blocks', Icons.traffic_rounded, Color(0xFFEF4444),
        TrafficBlocks()),
    _Feature('Report Problem', Icons.report_problem_rounded, Color(0xFFA855F7),
        ReportProblem()),
    _Feature(
        'My Reports', Icons.list_alt_rounded, Color(0xFF10B981), MyReports()),
    _Feature(
        'Best Route', Icons.alt_route_rounded, Color(0xFF06B6D4), BestRoute()),
    _Feature('Alerts', Icons.notifications_active_rounded, Color(0xFFE11D48),
        AlertsPage()),
    _Feature(
        'Live News', Icons.newspaper_rounded, Color(0xFF06B6D4), NewsPage()),
    _Feature('Emergency SOS', Icons.emergency_rounded, Color(0xFFDC2626),
        EmergencyPage()),
    _Feature('Fines & Challans', Icons.receipt_long_rounded, Color(0xFFF59E0B),
        FinesPage()),
    _Feature('Public Transport', Icons.directions_bus_rounded,
        Color(0xFF22C55E), TransportPage()),
    _Feature('Help Center', Icons.help_center_rounded, Color(0xFF0EA5E9),
        HelpPage()),
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
                childAspectRatio: 0.95),
            itemCount: visible.length,
            itemBuilder: (context, i) => _FeatureTile(
                key: ValueKey(visible[i].title),
                item: visible[i],
                delay: (i % _visibleCount) * 60),
          ),
          const SizedBox(height: 16),
          _ViewAllButton(
              expanded: _expanded,
              onTap: () => setState(() => _expanded = !_expanded)),
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
// 🔽 View All Button
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
                  color:
                      const Color(0xFF3B82F6).withOpacity(_hover ? 0.65 : 0.35),
                  blurRadius: _hover ? 34 : 20,
                  offset: Offset(0, _hover ? 12 : 6)),
              BoxShadow(
                  color: Colors.black.withOpacity(0.30),
                  blurRadius: 14,
                  offset: const Offset(0, 6)),
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
                        const Color(0xFF3B82F6)
                            .withOpacity(_hover ? 0.45 : 0.28),
                        const Color(0xFF8B5CF6)
                            .withOpacity(_hover ? 0.35 : 0.20)
                      ]),
                  borderRadius: BorderRadius.circular(100),
                  border: Border.all(
                      color: Colors.white.withOpacity(_hover ? 0.90 : 0.55),
                      width: 1.3),
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
                                gradient: LinearGradient(colors: [
                              Colors.white.withOpacity(0.0),
                              Colors.white.withOpacity(0.95),
                              Colors.white.withOpacity(0.0)
                            ])))),
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
                                  size: 22)),
                          const SizedBox(width: 10),
                          Text(
                              widget.expanded
                                  ? 'Show Less'
                                  : 'View All Services',
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: 0.5,
                                  shadows: [
                                    Shadow(
                                        color: Color(0xAA000000),
                                        blurRadius: 10,
                                        offset: Offset(0, 1))
                                  ])),
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
    _c = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 700));
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
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                      color: item.color.withOpacity(_hover ? 0.45 : 0.25),
                      blurRadius: _hover ? 28 : 16,
                      offset: Offset(0, _hover ? 10 : 6)),
                  BoxShadow(
                      color: Colors.black.withOpacity(0.25),
                      blurRadius: 10,
                      offset: const Offset(0, 4)),
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
                        item.color.withOpacity(_hover ? 0.14 : 0.08)
                      ]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withOpacity(_hover ? 0.55 : 0.28),
                          width: 1.2),
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
                              border: Border.all(
                                  color: item.color.withOpacity(0.55),
                                  width: 1.4),
                              boxShadow: [
                                BoxShadow(
                                    color: item.color
                                        .withOpacity(_hover ? 0.65 : 0.40),
                                    blurRadius: _hover ? 22 : 14)
                              ],
                            ),
                            child:
                                Icon(item.icon, size: 28, color: Colors.white),
                          ),
                          const SizedBox(height: 12),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 8),
                            child: Text(item.title,
                                textAlign: TextAlign.center,
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w600,
                                    shadows: [
                                      Shadow(
                                          color: Color(0xAA000000),
                                          blurRadius: 8,
                                          offset: Offset(0, 1))
                                    ])),
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
// 📞 AUTHORITY SECTION (NOW DYNAMIC FROM FIRESTORE)
// ============================================================
class _AuthoritySection extends StatefulWidget {
  const _AuthoritySection();

  @override
  State<_AuthoritySection> createState() => _AuthoritySectionState();
}

class _AuthoritySectionState extends State<_AuthoritySection> {
  bool _loading = true;
  List<QueryDocumentSnapshot> _authorities = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final snap =
          await FirebaseFirestore.instance.collection('authorities').get();
      if (mounted) {
        setState(() {
          _authorities = snap.docs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        debugPrint('Error loading authorities: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(20),
          child: CircularProgressIndicator(color: Colors.white54),
        ),
      );
    }

    if (_authorities.isEmpty) {
      return const Center(
        child: Text('No authorities listed.',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 20),
      itemCount: _authorities.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, i) => _AuthorityTile(doc: _authorities[i]),
    );
  }
}

class _AuthorityTile extends StatelessWidget {
  final QueryDocumentSnapshot doc;
  const _AuthorityTile({required this.doc});

  Future<void> _call(String phone) async {
    final cleaned = phone.replaceAll(RegExp(r'[^0-9+]'), '');
    final uri = Uri.parse('tel:$cleaned');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  @override
  Widget build(BuildContext context) {
    final data = doc.data() as Map<String, dynamic>;
    final emoji = data['emoji'] ?? '👤';
    final name = data['name'] ?? 'Name';
    final role = data['role'] ?? 'Role';
    final phone = data['phone'] ?? '';

    Color accentColor;
    if (role.toLowerCase().contains('emergency') ||
        role.toLowerCase().contains('police')) {
      accentColor = const Color(0xFFEF4444);
    } else if (role.toLowerCase().contains('traffic')) {
      accentColor = const Color(0xFFF59E0B);
    } else if (role.toLowerCase().contains('safety')) {
      accentColor = const Color(0xFF10B981);
    } else {
      accentColor = const Color(0xFF3B82F6);
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(colors: [
              Colors.white.withOpacity(0.10),
              accentColor.withOpacity(0.10)
            ]),
            borderRadius: BorderRadius.circular(20),
            border:
                Border.all(color: Colors.white.withOpacity(0.25), width: 1.1),
          ),
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: accentColor.withOpacity(0.22),
                    border: Border.all(
                        color: accentColor.withOpacity(0.6), width: 1.2)),
                child: Text(emoji, style: const TextStyle(fontSize: 22)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(name,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(role,
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 11.5)),
                    const SizedBox(height: 3),
                    Text(phone,
                        style: TextStyle(
                            color: accentColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
              Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: BorderRadius.circular(30),
                  onTap: () => _call(phone),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(colors: [
                        accentColor.withOpacity(0.8),
                        accentColor.withOpacity(0.4)
                      ]),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.5), width: 1),
                      boxShadow: [
                        BoxShadow(
                            color: accentColor.withOpacity(0.5), blurRadius: 14)
                      ],
                    ),
                    child: const Icon(Icons.call_rounded,
                        color: Colors.white, size: 18),
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
