import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/complaints_provider.dart';

class ManageComplaints extends StatefulWidget {
  const ManageComplaints({super.key});
  @override
  State<ManageComplaints> createState() => _ManageComplaintsState();
}

class _ManageComplaintsState extends State<ManageComplaints>
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
      Provider.of<ComplaintsProvider>(context, listen: false).loadAll();
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
    final prov = Provider.of<ComplaintsProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Complaints',
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
    );
  }

  Widget _body(ComplaintsProvider prov) {
    if (prov.loading) return const Center(child: CircularProgressIndicator(color: Colors.white));

    if (prov.complaints.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.forum_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No complaints yet',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Complaints submitted by users will appear here.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
        ])));
    }

    return RefreshIndicator(
      onRefresh: prov.loadAll,
      color: const Color(0xFF8B5CF6),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: prov.complaints.length,
        itemBuilder: (context, i) {
          final d = prov.complaints[i];
          final data = d.data() as Map<String, dynamic>;
          return _ComplaintCard(
            data: data,
            onReply: () => _reply(context, prov, d.id, data['text']?.toString() ?? ''),
            onResolve: () => prov.resolve(d.id),
            onDelete: () => prov.delete(d.id));
        },
      ),
    );
  }

  Future<void> _reply(BuildContext context, ComplaintsProvider prov, String id, String title) async {
    final reply = TextEditingController();
    await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0B1730),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reply to Complaint',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Column(mainAxisSize: MainAxisSize.min, crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, maxLines: 2, overflow: TextOverflow.ellipsis,
            style: TextStyle(color: Colors.white.withOpacity(0.70), fontSize: 12.5)),
          const SizedBox(height: 12),
          TextField(controller: reply, maxLines: 3,
            style: const TextStyle(color: Colors.white),
            cursorColor: const Color(0xFF8B5CF6),
            decoration: InputDecoration(
              hintText: 'Type your reply...', hintStyle: TextStyle(color: Colors.white.withOpacity(0.40), fontSize: 13),
              enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.white.withOpacity(0.25), width: 1.2)),
              focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: Color(0xFF8B5CF6), width: 1.4)))),
        ]),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () async {
            if (reply.text.trim().isEmpty) return;
            await prov.reply(id, reply.text.trim());
            if (context.mounted) Navigator.pop(context);
          }, style: TextButton.styleFrom(foregroundColor: const Color(0xFF8B5CF6)),
            child: const Text('Send')),
        ],
      ),
    );
  }

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
            radius: 1.5,
            colors: const [Color(0xFF1E0E3A), Color(0xFF0D061A), Color(0xFF04060F)],
            stops: const [0.0, 0.55, 1.0])),
      );

  Widget _orbs(Size size) => Stack(children: [
        Positioned(left: -size.width * 0.15 + _parallax.dx * -14,
          top: -size.height * 0.18 + _parallax.dy * -10,
          child: _orb(380, const Color(0xFF8B5CF6), 0.30)),
        Positioned(right: -size.width * 0.12 + _parallax.dx * 14,
          bottom: -size.height * 0.15 + _parallax.dy * 10,
          child: _orb(420, const Color(0xFFA855F7), 0.24)),
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

class _ComplaintCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onReply;
  final VoidCallback onResolve;
  final VoidCallback onDelete;
  const _ComplaintCard({required this.data, required this.onReply, required this.onResolve, required this.onDelete});

  @override
  Widget build(BuildContext context) {
    final status = (data['status'] ?? 'Pending').toString();
    final resolved = status == 'Resolved';
    final statusColor = resolved ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
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
                statusColor.withOpacity(0.10)]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2)),
            child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
              Row(children: [
                Container(padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: statusColor.withOpacity(0.18),
                    border: Border.all(color: statusColor.withOpacity(0.55), width: 1.2),
                    boxShadow: [BoxShadow(color: statusColor.withOpacity(0.35), blurRadius: 12)]),
                  child: Icon(resolved ? Icons.check_circle_rounded : Icons.pending_rounded,
                    color: statusColor, size: 20)),
                const SizedBox(width: 14),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text(data['text'] ?? 'Untitled',
                    style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700, height: 1.4)),
                  const SizedBox(height: 4),
                  Row(children: [
                    Text(status, style: TextStyle(color: statusColor, fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                    if (dateStr.isNotEmpty)
                      Text('  •  $dateStr',
                        style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
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
              if ((data['adminReply'] ?? '').toString().isNotEmpty) ...[
                const SizedBox(height: 12),
                Container(padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFF10B981).withOpacity(0.10),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: const Color(0xFF10B981).withOpacity(0.35), width: 1)),
                  child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    const Icon(Icons.reply_rounded, size: 14, color: Color(0xFF10B981)),
                    const SizedBox(width: 8),
                    Expanded(child: Text(data['adminReply'],
                      style: const TextStyle(color: Color(0xFF6EE7B7), fontSize: 12, height: 1.4))),
                  ])),
              ],
              const SizedBox(height: 12),
              Row(children: [
                if (!resolved)
                  Expanded(child: OutlinedButton.icon(
                    icon: const Icon(Icons.check_rounded, size: 16),
                    label: const Text('Resolve'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF10B981),
                      side: const BorderSide(color: Color(0xFF10B981), width: 1.3),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12)),
                    onPressed: onResolve)),
                if (!resolved) const SizedBox(width: 10),
                Expanded(child: ElevatedButton.icon(
                  icon: const Icon(Icons.reply_rounded, size: 16),
                  label: const Text('Reply'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF8B5CF6),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0),
                  onPressed: onReply)),
              ]),
            ]),
          ),
        ),
      ),
    );
  }
}