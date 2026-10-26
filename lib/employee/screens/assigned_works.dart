import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:road_maintenance/employee/providers/employee_provider.dart';
import 'package:road_maintenance/services/firestore_service.dart';


import 'work_details.dart';
import 'work_model.dart';

class AssignedWorks extends StatefulWidget {
  const AssignedWorks({super.key});

  @override
  State<AssignedWorks> createState() => _AssignedWorksState();
}

class _AssignedWorksState extends State<AssignedWorks>
    with TickerProviderStateMixin {
  late TabController _tabCtrl;

  // Animated background
  late AnimationController _bgCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _dustCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _dustRise;
  Offset _parallax = Offset.zero;

  bool _loading = true;
  List<QueryDocumentSnapshot> _active = [];
  List<QueryDocumentSnapshot> _history = [];

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);

    _bgCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 10))
      ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _orbCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 14))
      ..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _dustCtrl = AnimationController(
        vsync: this, duration: const Duration(seconds: 6))
      ..repeat();
    _dustRise = CurvedAnimation(parent: _dustCtrl, curve: Curves.linear);

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
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

  // ============================================================
  // 🔄 LOAD
  // ============================================================
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid =
          Provider.of<EmployeeProvider>(context, listen: false).employee?.uid ??
              '';
      if (uid.isEmpty) return;

      final all = await FirestoreService().getEmployeeWorks(uid);

      final active = <QueryDocumentSnapshot>[];
      final history = <QueryDocumentSnapshot>[];

      for (final d in all) {
        final status = (d.data() as Map<String, dynamic>)['status'] ?? '';
        if (status == 'Completed') {
          history.add(d);
        } else if (status == 'Assigned' || status == 'In Progress') {
          active.add(d);
        }
      }

      int cmp(QueryDocumentSnapshot a, QueryDocumentSnapshot b) {
        final ta = (a.data() as Map)['createdAt'];
        final tb = (b.data() as Map)['createdAt'];
        if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
        return 0;
      }

      active.sort(cmp);
      history.sort(cmp);

      setState(() {
        _active = active;
        _history = history;
      });
    } catch (e) {
      _snack('❌ Failed to load: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _snack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: color,
      behavior: SnackBarBehavior.floating,
    ));
  }

  // ============================================================
  // ✅ MARK AS COMPLETED (quick action from card)
  // ============================================================
  Future<void> _markCompleted(QueryDocumentSnapshot doc, {String? note}) async {
    try {
      await FirestoreService().markCompleted(doc.id, workNote: note);
      _snack('✅ Work marked as completed', const Color(0xFF10B981));
      await _load();
      _tabCtrl.animateTo(1); // auto-switch to History
    } catch (e) {
      _snack('❌ Failed to complete: $e', Colors.redAccent);
    }
  }

  void _confirmComplete(QueryDocumentSnapshot doc) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0B1730),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title:
            const Text('Mark as Completed?', style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will move the work to your History.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.7), fontSize: 13),
            ),
            const SizedBox(height: 14),
            TextField(
              controller: noteCtrl,
              maxLines: 3,
              style: const TextStyle(color: Colors.white),
              decoration: InputDecoration(
                hintText: 'Add a completion note (optional)',
                hintStyle: const TextStyle(color: Colors.white38),
                filled: true,
                fillColor: Colors.white.withOpacity(0.05),
                border:
                    OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF10B981)),
            onPressed: () {
              Navigator.pop(context);
              _markCompleted(doc, note: noteCtrl.text.trim());
            },
            icon: const Icon(Icons.check_rounded, size: 16),
            label:
                const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // 🏗️ BUILD
  // ============================================================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Assigned Works',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: const Color(0xFFF59E0B),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white54,
          labelStyle:
              const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
          tabs: const [
            Tab(text: 'Active'),
            Tab(text: 'History'),
          ],
        ),
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
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white))
                          : TabBarView(
                              controller: _tabCtrl,
                              children: [
                                _listView(_active, isHistory: false),
                                _listView(_history, isHistory: true),
                              ],
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

  Widget _listView(List<QueryDocumentSnapshot> items,
      {required bool isHistory}) {
    if (items.isEmpty) return _emptyState(isHistory);
    return RefreshIndicator(
      color: const Color(0xFFF59E0B),
      backgroundColor: const Color(0xFF0B1730),
      onRefresh: _load,
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: items.length,
        itemBuilder: (context, i) => _workCard(items[i], isHistory: isHistory),
      ),
    );
  }

  Widget _emptyState(bool isHistory) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF59E0B).withOpacity(0.15),
                border: Border.all(
                    color: const Color(0xFFF59E0B).withOpacity(0.5),
                    width: 1.5),
              ),
              child: Icon(
                isHistory ? Icons.history_rounded : Icons.assignment_outlined,
                color: Colors.white,
                size: 40,
              ),
            ),
            const SizedBox(height: 18),
            Text(
              isHistory ? 'No completed work yet' : 'No active assignments',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              isHistory
                  ? 'Completed works will appear here.'
                  : 'Once the admin assigns you work, it will appear here.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // 🃏 CARD
  // ============================================================
  Widget _workCard(QueryDocumentSnapshot doc, {required bool isHistory}) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Work';
    final desc = data['description'] ?? '';
    final location = data['location'] ?? '—';
    final status = data['status'] ?? 'Assigned';
    final createdAt = data['createdAt'];
    final dateStr = createdAt is Timestamp
        ? DateFormat('dd MMM yyyy • HH:mm').format(createdAt.toDate())
        : '';
    final workNote = data['workNote'];

    final statusColor = _statusColor(status);
    final accent =
        isHistory ? const Color(0xFF10B981) : const Color(0xFFF59E0B);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: InkWell(
        onTap: () async {
          // Build the model from the Firestore doc + open details page
          final workModel = WorkModel.fromMap(doc.id, data);

          await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => WorkDetails(work: workModel, reportId: '', data: {},), // ✅ correct call
            ),
          );

          // Reload on return (in case the work was completed inside details)
          if (mounted) _load();
        },
        borderRadius: BorderRadius.circular(22),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(22),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withOpacity(0.10),
                    accent.withOpacity(0.10),
                  ],
                ),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25), width: 1.2),
                boxShadow: [
                  BoxShadow(
                    color: accent.withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Title + status
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                      _pill(status, statusColor),
                    ],
                  ),

                  if (desc.toString().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Text(
                      desc,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12.5,
                          height: 1.4),
                    ),
                  ],

                  const SizedBox(height: 10),

                  // Location + date
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.redAccent, size: 14),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          location,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 11.5),
                        ),
                      ),
                      if (dateStr.isNotEmpty)
                        Text(dateStr,
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10.5)),
                    ],
                  ),

                  // Hint
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Icon(Icons.touch_app_rounded,
                          size: 14, color: Colors.white.withOpacity(0.5)),
                      const SizedBox(width: 6),
                      Text(
                        'Tap to view details & update',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.5),
                            fontSize: 11.5),
                      ),
                    ],
                  ),

                  // Work note (only in history)
                  if (isHistory &&
                      workNote != null &&
                      workNote.toString().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.05),
                        borderRadius: BorderRadius.circular(12),
                        border:
                            Border.all(color: Colors.white.withOpacity(0.12)),
                      ),
                      child: Text(
                        'Note: $workNote',
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 11.5),
                      ),
                    ),
                  ],

                  // Mark as Completed button (only for Active)
                  if (!isHistory) ...[
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      height: 44,
                      child: ElevatedButton.icon(
                        onPressed: () => _confirmComplete(doc),
                        icon: const Icon(Icons.check_circle_rounded, size: 18),
                        label: const Text(
                          'Mark as Completed',
                          style: TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 13.5),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF10B981),
                          foregroundColor: Colors.white,
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.65), width: 1),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: color,
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 0.5),
        ),
      );

  Color _statusColor(String status) {
    switch (status) {
      case 'Assigned':
        return const Color(0xFF3B82F6);
      case 'In Progress':
        return const Color(0xFFA855F7);
      case 'Completed':
        return const Color(0xFF10B981);
      case 'Pending':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFFF59E0B);
    }
  }

  // ---------- Animated background ----------

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
                -0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
            radius: 1.5,
            colors: const [
              Color(0xFF2A1B0B),
              Color(0xFF160A04),
              Color(0xFF04060F),
            ],
            stops: const [0.0, 0.55, 1.0],
          ),
        ),
      );

  Widget _orbs(Size size) => Stack(
        children: [
          Positioned(
            left: -size.width * 0.15 + _parallax.dx * -14,
            top: -size.height * 0.18 + _parallax.dy * -10,
            child: _orb(380, const Color(0xFFF59E0B), 0.30),
          ),
          Positioned(
            right: -size.width * 0.12 + _parallax.dx * 14,
            bottom: -size.height * 0.15 + _parallax.dy * 10,
            child: _orb(420, const Color(0xFFEF4444), 0.20),
          ),
        ],
      );

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
                        color: Colors.white.withOpacity(0.30), blurRadius: 6)
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
}