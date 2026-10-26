import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:road_maintenance/employee/providers/employee_provider.dart';



class LeaveRequests extends StatefulWidget {
  const LeaveRequests({super.key});

  @override
  State<LeaveRequests> createState() => _LeaveRequestsState();
}

class _LeaveRequestsState extends State<LeaveRequests>
    with TickerProviderStateMixin {
  late AnimationController _bgCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _dustCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _dustRise;
  Offset _parallax = Offset.zero;

  bool _loading = true;
  List<QueryDocumentSnapshot> _leaves = [];

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

    WidgetsBinding.instance.addPostFrameCallback((_) => _load());
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
  // 🔄 LOAD — no orderBy → no composite index needed
  // ============================================================
  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final uid =
          Provider.of<EmployeeProvider>(context, listen: false).employee?.uid ??
              '';
      if (uid.isEmpty) {
        setState(() => _leaves = []);
        return;
      }

      // 👇 Only `where` — no orderBy
      final snap = await FirebaseFirestore.instance
          .collection('leaves')
          .where('employeeUid', isEqualTo: uid)
          .get();

      // Sort client-side by createdAt desc
      final docs = snap.docs.toList();
      docs.sort((a, b) {
        final ta = (a.data())['createdAt'];
        final tb = (b.data())['createdAt'];
        if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
        return 0;
      });

      setState(() => _leaves = docs);
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
  // 📝 APPLY LEAVE SHEET
  // ============================================================
  void _showApplySheet() {
    final reasonCtrl = TextEditingController();
    String leaveType = 'Sick Leave';
    DateTime? fromDate;
    DateTime? toDate;
    bool submitting = false;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            Future<void> pickDate(bool isFrom) async {
              final now = DateTime.now();
              final picked = await showDatePicker(
                context: ctx,
                initialDate: isFrom
                    ? (fromDate ?? now)
                    : (toDate ?? fromDate ?? now),
                firstDate: now.subtract(const Duration(days: 30)),
                lastDate: now.add(const Duration(days: 365)),
                builder: (context, child) => Theme(
                  data: ThemeData.dark().copyWith(
                    colorScheme: const ColorScheme.dark(
                      primary: Color(0xFFA855F7),
                      onPrimary: Colors.white,
                      surface: Color(0xFF0B1730),
                      onSurface: Colors.white,
                    ),
                  ),
                  child: child!,
                ),
              );
              if (picked != null) {
                setSheetState(() {
                  if (isFrom) {
                    fromDate = picked;
                    if (toDate != null && toDate!.isBefore(picked)) {
                      toDate = picked;
                    }
                  } else {
                    toDate = picked;
                  }
                });
              }
            }

            Future<void> submit() async {
              if (fromDate == null || toDate == null) {
                _snack('Please pick both dates', Colors.orangeAccent);
                return;
              }
              if (reasonCtrl.text.trim().isEmpty) {
                _snack('Please describe the reason', Colors.orangeAccent);
                return;
              }

              setSheetState(() => submitting = true);

              try {
                final emp =
                    Provider.of<EmployeeProvider>(context, listen: false)
                        .employee;

                await FirebaseFirestore.instance.collection('leaves').add({
                  'employeeUid': emp?.uid ?? '',
                  'employeeName': emp?.name ?? '',
                  'employeeEmail': emp?.email ?? '',
                  'department': emp?.department ?? '',
                  'leaveType': leaveType,
                  'fromDate': Timestamp.fromDate(fromDate!),
                  'toDate': Timestamp.fromDate(toDate!),
                  'reason': reasonCtrl.text.trim(),
                  'status': 'Pending',
                  'createdAt': Timestamp.now(),
                });

                if (!mounted) return;
                Navigator.pop(ctx);
                _snack('✅ Leave request sent to admin',
                    const Color(0xFF10B981));
                _load();
              } catch (e) {
                _snack('❌ Submission failed: $e', Colors.redAccent);
              } finally {
                setSheetState(() => submitting = false);
              }
            }

            return ClipRRect(
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(28)),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: Container(
                  padding: EdgeInsets.only(
                    left: 20,
                    right: 20,
                    top: 20,
                    bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        const Color(0xFF2A1B4A).withOpacity(0.98),
                        const Color(0xFF0B1130).withOpacity(0.98),
                      ],
                    ),
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(28)),
                    border:
                        Border.all(color: Colors.white.withOpacity(0.2)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Center(
                        child: Container(
                          width: 40,
                          height: 4,
                          decoration: BoxDecoration(
                            color: Colors.white24,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Apply for Leave',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 20),

                      _glassInput(
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: leaveType,
                            isExpanded: true,
                            dropdownColor: const Color(0xFF1B2B54),
                            icon: const Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: Colors.white),
                            style: const TextStyle(
                                color: Colors.white, fontSize: 15),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Sick Leave',
                                  child: Text('Sick Leave')),
                              DropdownMenuItem(
                                  value: 'Casual Leave',
                                  child: Text('Casual Leave')),
                              DropdownMenuItem(
                                  value: 'Emergency Leave',
                                  child: Text('Emergency Leave')),
                              DropdownMenuItem(
                                  value: 'Other', child: Text('Other')),
                            ],
                            onChanged: (v) =>
                                setSheetState(() => leaveType = v!),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      Row(
                        children: [
                          Expanded(
                            child: _dateTile(
                              label: 'From',
                              date: fromDate,
                              onTap: () => pickDate(true),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _dateTile(
                              label: 'To',
                              date: toDate,
                              onTap: () => pickDate(false),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),

                      _glassInput(
                        child: TextField(
                          controller: reasonCtrl,
                          maxLines: 3,
                          style: const TextStyle(color: Colors.white),
                          decoration: const InputDecoration(
                            hintText: 'Reason for leave',
                            hintStyle: TextStyle(color: Colors.white38),
                            border: InputBorder.none,
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),

                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: submitting ? null : submit,
                          icon: submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            submitting ? 'Sending...' : 'Send to Admin',
                            style: const TextStyle(
                                fontSize: 15, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA855F7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _glassInput({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white.withOpacity(0.18)),
            ),
            child: child,
          ),
        ),
      );

  Widget _dateTile({
    required String label,
    required DateTime? date,
    required VoidCallback onTap,
  }) {
    final value =
        date == null ? 'Pick date' : DateFormat('dd MMM yyyy').format(date);
    return GestureDetector(
      onTap: onTap,
      child: _glassInput(
        child: Row(
          children: [
            const Icon(Icons.calendar_today_rounded,
                color: Colors.white70, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11)),
                  const SizedBox(height: 2),
                  Text(value,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13.5)),
                ],
              ),
            ),
          ],
        ),
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
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showApplySheet,
        backgroundColor: const Color(0xFFA855F7),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Apply Leave',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Leave Requests',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
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
                      child: _loading
                          ? const Center(
                              child: CircularProgressIndicator(
                                  color: Colors.white))
                          : _leaves.isEmpty
                              ? _emptyState()
                              : RefreshIndicator(
                                  color: const Color(0xFFA855F7),
                                  backgroundColor: const Color(0xFF0B1730),
                                  onRefresh: _load,
                                  child: ListView.builder(
                                    padding: const EdgeInsets.fromLTRB(
                                        16, 16, 16, 100),
                                    itemCount: _leaves.length,
                                    itemBuilder: (context, i) =>
                                        _leaveCard(_leaves[i]),
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

  Widget _emptyState() {
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
                color: const Color(0xFFA855F7).withOpacity(0.15),
                border: Border.all(
                    color: const Color(0xFFA855F7).withOpacity(0.5),
                    width: 1.5),
              ),
              child: const Icon(Icons.event_note_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'No leave requests yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Tap "Apply Leave" to submit your first request.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _leaveCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final type = data['leaveType'] ?? 'Leave';
    final reason = data['reason'] ?? '';
    final status = data['status'] ?? 'Pending';
    final from = data['fromDate'];
    final to = data['toDate'];
    final adminReply = data['adminReply'];

    final fromStr = from is Timestamp
        ? DateFormat('yyyy-MM-dd').format(from.toDate())
        : '';
    final toStr =
        to is Timestamp ? DateFormat('yyyy-MM-dd').format(to.toDate()) : '';

    final statusColor = _statusColor(status);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.08),
                const Color(0xFFA855F7).withOpacity(0.06),
              ]),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.22), width: 1.1),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        type,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                            fontWeight: FontWeight.w800),
                      ),
                    ),
                    _pill(status, statusColor),
                  ],
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    const Icon(Icons.date_range_rounded,
                        color: Colors.white70, size: 14),
                    const SizedBox(width: 6),
                    Text(
                      '$fromStr  →  $toStr',
                      style: const TextStyle(
                          color: Colors.white70, fontSize: 12.5),
                    ),
                  ],
                ),
                if (reason.toString().isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    reason,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12.5,
                        height: 1.4),
                  ),
                ],
                if (adminReply != null &&
                    adminReply.toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                          color: statusColor.withOpacity(0.4), width: 1),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.reply_rounded,
                            color: statusColor, size: 16),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Admin: $adminReply',
                            style: TextStyle(
                                color: statusColor,
                                fontSize: 12,
                                fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ],
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
      case 'Approved':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFFEF4444);
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
              Color(0xFF2A1B4A),
              Color(0xFF10061E),
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
            child: _orb(380, const Color(0xFFA855F7), 0.30),
          ),
          Positioned(
            right: -size.width * 0.12 + _parallax.dx * 14,
            bottom: -size.height * 0.15 + _parallax.dy * 10,
            child: _orb(420, const Color(0xFF8B5CF6), 0.24),
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