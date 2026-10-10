import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/fines_provider.dart';

class ManageFines extends StatefulWidget {
  const ManageFines({super.key});
  @override
  State<ManageFines> createState() => _ManageFinesState();
}

class _ManageFinesState extends State<ManageFines>
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
      Provider.of<FinesProvider>(context, listen: false).loadAll();
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
    final prov = Provider.of<FinesProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Fines & Challans',
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

  Widget _body(FinesProvider prov) {
    if (prov.loading) return const Center(child: CircularProgressIndicator(color: Colors.white));

    if (prov.fines.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.receipt_long_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No fines yet',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Tap "Issue Fine" below to add the first one.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
        ])));
    }

    return RefreshIndicator(
      onRefresh: prov.loadAll,
      color: const Color(0xFFDC2626),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: prov.fines.length,
        itemBuilder: (context, i) {
          final d = prov.fines[i];
          final data = d.data() as Map<String, dynamic>;
          return _FineCard(data: data, onDelete: () => prov.delete(d.id));
        },
      ),
    );
  }

  Widget _glassFab(BuildContext context, FinesProvider prov) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: const LinearGradient(colors: [Color(0xFFDC2626), Color(0xFFB91C1C)]),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.3),
              boxShadow: [
                BoxShadow(color: const Color(0xFFDC2626).withOpacity(0.55), blurRadius: 28, offset: const Offset(0, 10)),
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
                    Text('Issue Fine',
                      style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  ]),
                )))),
      ),
      )
    );
  }

  Future<void> _openCreate(BuildContext context, FinesProvider prov) async {
    final email = TextEditingController();
    final reason = TextEditingController();
    final amount = TextEditingController();
    String status = 'UNPAID';

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF0B1730),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Issue Fine',
              style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              _dialogField(email, 'User Email', keyboard: TextInputType.emailAddress),
              const SizedBox(height: 12),
              _dialogField(reason, 'Reason'),
              const SizedBox(height: 12),
              _dialogField(amount, 'Amount (₹)', keyboard: TextInputType.number),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: status,
                dropdownColor: const Color(0xFF1B2B54),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  labelText: 'Status', labelStyle: TextStyle(color: Colors.white.withOpacity(0.70)),
                  enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.2))),
                items: const [
                  DropdownMenuItem(value: 'UNPAID', child: Text('UNPAID', style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(value: 'PAID', child: Text('PAID', style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setSt(() => status = v!)),
            ]),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
            TextButton(onPressed: () async {
              if (email.text.trim().isEmpty || amount.text.trim().isEmpty) return;
              await prov.create(
                userEmail: email.text.trim(),
                reason: reason.text.trim(),
                amount: double.tryParse(amount.text.trim()) ?? 0,
                status: status);
              if (context.mounted) Navigator.pop(context);
            }, style: TextButton.styleFrom(foregroundColor: const Color(0xFFDC2626)),
              child: const Text('Issue')),
          ],
        ),
      ),
    );
  }

  Widget _dialogField(TextEditingController c, String label, {TextInputType? keyboard}) => TextField(
        controller: c, keyboardType: keyboard,
        style: const TextStyle(color: Colors.white),
        decoration: InputDecoration(
          labelText: label, labelStyle: TextStyle(color: Colors.white.withOpacity(0.70)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.2)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFFDC2626), width: 1.4))),
      );

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
            radius: 1.5,
            colors: const [Color(0xFF320A0A), Color(0xFF140404), Color(0xFF04060F)],
            stops: const [0.0, 0.55, 1.0])),
      );

  Widget _orbs(Size size) => Stack(children: [
        Positioned(left: -size.width * 0.15 + _parallax.dx * -14,
          top: -size.height * 0.18 + _parallax.dy * -10,
          child: _orb(380, const Color(0xFFDC2626), 0.30)),
        Positioned(right: -size.width * 0.12 + _parallax.dx * 14,
          bottom: -size.height * 0.15 + _parallax.dy * 10,
          child: _orb(420, const Color(0xFFEF4444), 0.22)),
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

class _FineCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onDelete;
  const _FineCard({required this.data, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final paid = (data['status'] ?? '') == 'PAID';
    final statusColor = paid ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final ts = data['createdAt'];
    String dateStr = '';
    if (ts is Timestamp) {
      dateStr = DateFormat('dd MMM yyyy').format(ts.toDate());
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
                statusColor.withOpacity(0.10)]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Row(children: [
              Container(padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: statusColor.withOpacity(0.18),
                  border: Border.all(color: statusColor.withOpacity(0.55), width: 1.2),
                  boxShadow: [BoxShadow(color: statusColor.withOpacity(0.35), blurRadius: 12)]),
                child: Icon(paid ? Icons.check_circle_rounded : Icons.warning_rounded,
                  color: statusColor, size: 20)),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(data['reason'] ?? 'Untitled',
                  style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700)),
                const SizedBox(height: 2),
                Text('₹${data['amount'] ?? 0}',
                  style: TextStyle(color: statusColor, fontSize: 14, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                const SizedBox(height: 3),
                Row(children: [
                  Expanded(child: Text(data['userEmail'] ?? '',
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 11.5))),
                  if (dateStr.isNotEmpty)
                    Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 10.5)),
                ]),
              ])),
              Container(padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.20),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: statusColor.withOpacity(0.55), width: 1)),
                child: Text(data['status'] ?? 'UNPAID',
                  style: TextStyle(color: statusColor, fontSize: 9.5, fontWeight: FontWeight.w800, letterSpacing: 0.5))),
              const SizedBox(width: 8),
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