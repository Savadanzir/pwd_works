import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/alerts_provider.dart';

class ManageAlerts extends StatefulWidget {
  const ManageAlerts({super.key});
  @override
  State<ManageAlerts> createState() => _ManageAlertsState();
}

class _ManageAlertsState extends State<ManageAlerts>
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
    _bgCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 10))..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);
    _orbCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 14))..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);
    _dustCtrl = AnimationController(vsync: this, duration: const Duration(seconds: 6))..repeat();
    _dustRise = CurvedAnimation(parent: _dustCtrl, curve: Curves.linear);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<AlertsProvider>(context, listen: false).loadAll();
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
    final prov = Provider.of<AlertsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Manage Alerts',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(icon: const Icon(Icons.refresh_rounded), onPressed: () => prov.loadAll()),
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
      floatingActionButton: _glassFab(context, prov),
    );
  }

  Widget _body(AlertsProvider prov) {
    if (prov.loading) return const Center(child: CircularProgressIndicator(color: Colors.white));

    if (prov.alerts.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.notifications_none_rounded, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No alerts yet',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Tap "New Alert" below to broadcast the first one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
        ])));
    }

    return RefreshIndicator(
      onRefresh: prov.loadAll,
      color: const Color(0xFFE11D48),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: prov.alerts.length,
        itemBuilder: (context, i) {
          final d = prov.alerts[i];
          final data = d.data() as Map<String, dynamic>;
          return _AlertCard(data: data, onDelete: () => prov.delete(d.id));
        },
      ),
    );
  }

  Widget _glassFab(BuildContext context, AlertsProvider prov) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: const LinearGradient(colors: [Color(0xFFE11D48), Color(0xFFBE123C)]),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.3),
              boxShadow: [
                BoxShadow(color: const Color(0xFFE11D48).withOpacity(0.55), blurRadius: 28, offset: const Offset(0, 10)),
                BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6))]),
            child: Material(color: Colors.transparent,
              child: InkWell(
                onTap: () => _openCreate(context, prov),
                borderRadius: BorderRadius.circular(100),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.add_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 8),
                    Text('New Alert',
                      style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  ]),
                )))),
      ),
      )
    );
  }

  Future<void> _openCreate(BuildContext context, AlertsProvider prov) async {
    final title = TextEditingController();
    final body = TextEditingController();
    String severity = 'info';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF0B1730),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('New Alert',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: Column(mainAxisSize: MainAxisSize.min, children: [
            TextField(controller: title,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Title', labelStyle: TextStyle(color: Colors.white.withOpacity(0.70)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.2)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.4)))),
            const SizedBox(height: 12),
            TextField(controller: body, maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Message', labelStyle: TextStyle(color: Colors.white.withOpacity(0.70)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.2)),
                focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0xFFE11D48), width: 1.4)))),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: severity,
              dropdownColor: const Color(0xFF1B2B54),
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                labelText: 'Severity', labelStyle: TextStyle(color: Colors.white.withOpacity(0.70)),
                enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.2))),
              items: const [
                DropdownMenuItem(value: 'info', child: Text('🔵 Info', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'warning', child: Text('🟡 Warning', style: TextStyle(color: Colors.white))),
                DropdownMenuItem(value: 'critical', child: Text('🔴 Critical', style: TextStyle(color: Colors.white))),
              ],
              onChanged: (v) => setSt(() => severity = v!)),
          ]),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
            TextButton(onPressed: () async {
              if (title.text.trim().isEmpty) return;
              await prov.create(title: title.text.trim(), body: body.text.trim(), severity: severity);
              if (context.mounted) Navigator.pop(context);
            }, style: TextButton.styleFrom(foregroundColor: const Color(0xFFE11D48)),
              child: const Text('Publish')),
          ],
        ),
      ),
    );
  }

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
            radius: 1.5,
            colors: const [Color(0xFF3A0A18), Color(0xFF16040A), Color(0xFF04060F)],
            stops: const [0.0, 0.55, 1.0])),
      );

  Widget _orbs(Size size) => Stack(children: [
        Positioned(left: -size.width * 0.15 + _parallax.dx * -14,
          top: -size.height * 0.18 + _parallax.dy * -10,
          child: _orb(380, const Color(0xFFE11D48), 0.30)),
        Positioned(right: -size.width * 0.12 + _parallax.dx * 14,
          bottom: -size.height * 0.15 + _parallax.dy * 10,
          child: _orb(420, const Color(0xFFF43F5E), 0.24)),
      ]);

  Widget _orb(double size, Color color, double opacity) => IgnorePointer(
        child: Container(width: size, height: size,
          decoration: BoxDecoration(shape: BoxShape.circle,
            gradient: RadialGradient(colors: [
              color.withOpacity(opacity * (0.85 + _orbAnim.value * 0.3)),
              color.withOpacity(0.0)]))),
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
}

class _AlertCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  const _AlertCard({required this.data, required this.onDelete});

  Color _sevColor(String s) {
    switch (s) {
      case 'critical': return const Color(0xFFDC2626);
      case 'warning': return const Color(0xFFF59E0B);
      default: return const Color(0xFF3B82F6);
    }
  }

  IconData _sevIcon(String s) {
    switch (s) {
      case 'critical': return Icons.error_rounded;
      case 'warning': return Icons.warning_amber_rounded;
      default: return Icons.info_rounded;
    }
  }

  @override
  Widget build(BuildContext context) {
    final severity = (data['severity'] ?? 'info').toString();
    final sevColor = _sevColor(severity);
    final ts = data['createdAt'];
    String dateStr = '';
    if (ts is Timestamp) {
      dateStr = DateFormat('dd MMM yyyy • HH:mm').format(ts.toDate());
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                sevColor.withOpacity(0.10)]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2)),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Container(padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(14),
                  color: sevColor.withOpacity(0.18),
                  border: Border.all(color: sevColor.withOpacity(0.55), width: 1.2),
                  boxShadow: [BoxShadow(color: sevColor.withOpacity(0.35), blurRadius: 12)]),
                child: Icon(_sevIcon(severity), color: sevColor, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['title'] ?? 'Untitled',
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                if ((data['body'] ?? '').toString().isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(data['body'], maxLines: 3, overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12.5, height: 1.5)),
                ],
                const SizedBox(height: 6),
                Row(children: [
                  Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: sevColor.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: sevColor.withOpacity(0.55), width: 1)),
                    child: Text(severity.toUpperCase(),
                      style: TextStyle(color: sevColor, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.8))),
                  if (dateStr.isNotEmpty)
                    Padding(padding: const EdgeInsets.only(left: 8),
                      child: Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10.5))),
                ]),
              ])),
              GestureDetector(onTap: onDelete,
                child: Container(padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: const Color(0xFFEF4444).withOpacity(0.15),
                    border: Border.all(color: const Color(0xFFEF4444).withOpacity(0.45), width: 1.1)),
                  child: const Icon(Icons.delete_rounded, color: Color(0xFFEF4444), size: 16))),
            ]),
          ),
        ),
      ),
    );
  }
}