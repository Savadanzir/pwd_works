import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:road_maintenance/services/firestore_service.dart';

import 'work_model.dart';

class WorkDetails extends StatefulWidget {
  final WorkModel work;
  const WorkDetails({super.key, required this.work, required String reportId, required Map<dynamic, dynamic> data});

  @override
  State<WorkDetails> createState() => _WorkDetailsState();
}

class _WorkDetailsState extends State<WorkDetails>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _dustCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _dustRise;
  Offset _parallax = Offset.zero;

  bool _submitting = false;

  @override
  void initState() {
    super.initState();
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

  // ============================================================
  // ✅ MARK AS COMPLETED
  // ============================================================
  Future<void> _markCompleted() async {
    final noteCtrl = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0B1730),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Mark as Completed?',
            style: TextStyle(color: Colors.white)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'This will move the work to your History.',
              style:
                  TextStyle(color: Colors.white.withOpacity(0.7), fontSize: 13),
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
            onPressed: () => Navigator.pop(context, false),
            child:
                const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton.icon(
            style:
                ElevatedButton.styleFrom(backgroundColor: const Color(0xFF10B981)),
            onPressed: () => Navigator.pop(context, true),
            icon: const Icon(Icons.check_rounded, size: 16),
            label:
                const Text('Confirm', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    setState(() => _submitting = true);
    try {
      await FirestoreService().markCompleted(
        widget.work.id,
        workNote: noteCtrl.text.trim().isEmpty ? null : noteCtrl.text.trim(),
      );

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Work marked as completed'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true); // return true so caller can reload
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('❌ Failed: $e'),
          backgroundColor: Colors.redAccent,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final w = widget.work;

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Work Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
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
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        children: [
                          // ------ Title & status ------
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  w.title,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 22,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.2,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              _pill(w.status, _statusColor(w.status)),
                            ],
                          ),

                          const SizedBox(height: 20),

                          // ------ Progress timeline ------
                          _timeline(w.status),

                          const SizedBox(height: 20),

                          // ------ Image ------
                          if (w.imageUrl != null && w.imageUrl!.isNotEmpty) ...[
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                w.imageUrl!,
                                height: 220,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 220,
                                  color: Colors.white10,
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.white54, size: 40),
                                ),
                              ),
                            ),
                            const SizedBox(height: 18),
                          ],

                          // ------ Description ------
                          _sectionHeader('DESCRIPTION',
                              Icons.description_outlined),
                          const SizedBox(height: 8),
                          _glassBox(
                            child: Text(
                              w.description.isEmpty ? '—' : w.description,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 13.5,
                                height: 1.5,
                              ),
                            ),
                          ),

                          const SizedBox(height: 18),

                          // ------ Location ------
                          _sectionHeader('LOCATION', Icons.location_on_outlined),
                          const SizedBox(height: 8),
                          _glassBox(
                            child: Row(
                              children: [
                                const Icon(Icons.location_on,
                                    color: Colors.redAccent, size: 16),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    w.location.isEmpty ? '—' : w.location,
                                    style: const TextStyle(
                                        color: Colors.white, fontSize: 13.5),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // ------ Work note (if any) ------
                          if (w.workNote != null &&
                              w.workNote!.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _sectionHeader(
                                'WORK NOTE', Icons.sticky_note_2_outlined),
                            const SizedBox(height: 8),
                            _glassBox(
                              child: Text(
                                w.workNote!,
                                style: const TextStyle(
                                    color: Colors.white70,
                                    fontSize: 13,
                                    height: 1.5),
                              ),
                            ),
                          ],

                          // ------ Completion image (if any) ------
                          if (w.completionImage != null &&
                              w.completionImage!.isNotEmpty) ...[
                            const SizedBox(height: 18),
                            _sectionHeader('COMPLETION PHOTO',
                                Icons.check_circle_outline_rounded),
                            const SizedBox(height: 8),
                            ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Image.network(
                                w.completionImage!,
                                height: 200,
                                width: double.infinity,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  height: 200,
                                  color: Colors.white10,
                                  child: const Icon(Icons.broken_image,
                                      color: Colors.white54, size: 40),
                                ),
                              ),
                            ),
                          ],

                          const SizedBox(height: 30),

                          // ------ Action buttons ------
                          if (w.status != 'Completed') ...[
                            SizedBox(
                              width: double.infinity,
                              height: 56,
                              child: ElevatedButton.icon(
                                onPressed:
                                    _submitting ? null : _markCompleted,
                                icon: _submitting
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2),
                                      )
                                    : const Icon(
                                        Icons.check_circle_rounded,
                                        size: 20,
                                      ),
                                label: Text(
                                  _submitting
                                      ? 'Submitting...'
                                      : 'Mark as Completed',
                                  style: const TextStyle(
                                    fontSize: 15.5,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(18),
                                  ),
                                  elevation: 0,
                                ),
                              ),
                            ),
                          ] else ...[
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: const Color(0xFF10B981)
                                    .withOpacity(0.12),
                                borderRadius: BorderRadius.circular(18),
                                border: Border.all(
                                    color: const Color(0xFF10B981)
                                        .withOpacity(0.5),
                                    width: 1.2),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.verified_rounded,
                                      color: Color(0xFF10B981), size: 22),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Text(
                                      'This work has been completed.',
                                      style: TextStyle(
                                        color: Colors.white.withOpacity(0.9),
                                        fontSize: 13.5,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
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

  // ---------------- Progress timeline ----------------
  Widget _timeline(String status) {
    final steps = ['Assigned', 'In Progress', 'Completed'];
    final current = steps.indexOf(status).clamp(0, 2);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withOpacity(0.15), width: 1),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // connector line
            final lineIndex = i ~/ 2;
            final passed = lineIndex < current;
            return Expanded(
              child: Container(
                height: 2,
                color: passed
                    ? const Color(0xFF10B981)
                    : Colors.white.withOpacity(0.15),
              ),
            );
          } else {
            // node
            final nodeIndex = i ~/ 2;
            final reached = nodeIndex <= current;
            final isCurrent = nodeIndex == current;
            return Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: reached
                        ? const Color(0xFF10B981)
                        : Colors.white.withOpacity(0.08),
                    border: Border.all(
                      color: reached
                          ? const Color(0xFF10B981)
                          : Colors.white.withOpacity(0.25),
                      width: 1.5,
                    ),
                    boxShadow: isCurrent
                        ? [
                            BoxShadow(
                              color: const Color(0xFF10B981).withOpacity(0.6),
                              blurRadius: 12,
                            ),
                          ]
                        : null,
                  ),
                  child: Icon(
                    nodeIndex == 0
                        ? Icons.assignment_turned_in_rounded
                        : nodeIndex == 1
                            ? Icons.engineering_rounded
                            : Icons.check_rounded,
                    size: 14,
                    color: reached ? Colors.white : Colors.white54,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  steps[nodeIndex],
                  style: TextStyle(
                    color: reached ? Colors.white : Colors.white54,
                    fontSize: 10.5,
                    fontWeight: reached ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ],
            );
          }
        }),
      ),
    );
  }

  // ---------------- Helpers ----------------
  Widget _sectionHeader(String label, IconData icon) => Row(
        children: [
          Icon(icon, color: const Color(0xFFF59E0B), size: 16),
          const SizedBox(width: 8),
          Text(
            label,
            style: const TextStyle(
              color: Color(0xFFF59E0B),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ],
      );

  Widget _glassBox({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(18),
              border:
                  Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            ),
            child: child,
          ),
        ),
      );

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.65), width: 1.1),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: color,
              fontSize: 11,
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
      default:
        return const Color(0xFFF59E0B);
    }
  }

  // ---------------- Animated background ----------------
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
            child: _orb(380, const Color(0xFFF59E0B), 0.28),
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