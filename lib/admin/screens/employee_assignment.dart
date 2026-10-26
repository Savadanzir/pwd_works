import 'dart:math' as math;
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:road_maintenance/services/firestore_service.dart';



class EmployeeAssignment extends StatefulWidget {
  const EmployeeAssignment({super.key});

  @override
  State<EmployeeAssignment> createState() => _EmployeeAssignmentState();
}

class _EmployeeAssignmentState extends State<EmployeeAssignment>
    with TickerProviderStateMixin {
  final FirestoreService _fs = FirestoreService();

  // -------- Animated background controllers --------
  late AnimationController _bgCtrl;
  late AnimationController _orbCtrl;
  late AnimationController _dustCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _orbAnim;
  late Animation<double> _dustRise;
  Offset _parallax = Offset.zero;

  // -------- Data state --------
  bool _loading = true;
  List<QueryDocumentSnapshot> _pendingReports = [];
  List<QueryDocumentSnapshot> _employees = [];

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

    _loadData();
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
  // 🔄 DATA LOADING
  // ============================================================
  Future<void> _loadData() async {
    setState(() => _loading = true);
    try {
      // Load all reports and keep only those that are ready to assign
      final allReports = await _fs.getAllReports();
      final pending = allReports.where((d) {
        final s = (d.data() as Map<String, dynamic>)['status'] ?? '';
        return s == 'Approved' || s == 'Pending';
      }).toList();

      // Load all registered employees
      final emps = await _fs.getAllEmployees();

      setState(() {
        _pendingReports = pending;
        _employees = emps;
      });
    } catch (e) {
      if (!mounted) return;
      _showSnack('❌ Failed to load: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showSnack(String msg, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ============================================================
  // 🎯 ASSIGN A REPORT TO AN EMPLOYEE (writes to Firestore)
  // ============================================================
  Future<void> _assign(
      QueryDocumentSnapshot report, QueryDocumentSnapshot employee) async {
    final reportData = report.data() as Map<String, dynamic>;
    final empData = employee.data() as Map<String, dynamic>;

    try {
      // 👇 This write makes the report appear on the employee's Assigned Works screen
      await _fs.updateReport(report.id, {
        'assignedTo': empData['uid'],
        'employeeName': empData['name'],
        'employeePhone': empData['phone'] ?? '',
        'employeeDepartment': empData['department'] ?? '',
        'status': 'Assigned',
        'assignedAt': Timestamp.now(),
      });

      _showSnack(
        '✅ Assigned "${reportData['title']}" to ${empData['name']}',
        const Color(0xFF10B981),
      );

      // Reload list — the report disappears from "pending" since it's now Assigned
      await _loadData();
    } catch (e) {
      _showSnack('❌ Assignment failed: $e', Colors.redAccent);
    }
  }

  // ============================================================
  // 👤 EMPLOYEE PICKER BOTTOM SHEET
  // ============================================================
  void _showEmployeePicker(QueryDocumentSnapshot report) {
    if (_employees.isEmpty) {
      _showSnack('No employees registered yet', Colors.orangeAccent);
      return;
    }

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (ctx) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
            child: Container(
              padding: const EdgeInsets.all(20),
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(ctx).size.height * 0.85,
              ),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF1B2B54).withOpacity(0.95),
                    const Color(0xFF0B1130).withOpacity(0.95),
                  ],
                ),
                border: Border.all(color: Colors.white.withOpacity(0.2)),
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Select Employee',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Choose who will handle this report',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.6),
                      fontSize: 12.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Flexible(
                    child: ListView.builder(
                      shrinkWrap: true,
                      itemCount: _employees.length,
                      itemBuilder: (context, i) {
                        final e =
                            _employees[i].data() as Map<String, dynamic>;
                        return Container(
                          margin: const EdgeInsets.only(bottom: 10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.06),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                                color: Colors.white.withOpacity(0.15)),
                          ),
                          child: ListTile(
                            leading: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: const Color(0xFF3B82F6)
                                    .withOpacity(0.2),
                                border: Border.all(
                                  color: const Color(0xFF3B82F6)
                                      .withOpacity(0.6),
                                ),
                              ),
                              child: const Icon(Icons.engineering,
                                  color: Colors.white, size: 20),
                            ),
                            title: Text(
                              e['name'] ?? 'Unnamed',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            subtitle: Text(
                              '${e['department'] ?? 'N/A'} • ${e['email'] ?? ''}',
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.55),
                                fontSize: 11.5,
                              ),
                            ),
                            trailing: const Icon(
                              Icons.arrow_forward_ios_rounded,
                              color: Colors.white54,
                              size: 14,
                            ),
                            onTap: () {
                              Navigator.pop(ctx);
                              _assign(report, _employees[i]);
                            },
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  // ============================================================
  // 🎨 BUILD — Animated background + body
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
        title: const Text(
          'Assign Work',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
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
                    SafeArea(bottom: false, child: _body()),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _body() {
    if (_loading) {
      return const Center(
        child: CircularProgressIndicator(color: Colors.white),
      );
    }
    if (_pendingReports.isEmpty) {
      return _emptyState();
    }
    return RefreshIndicator(
      onRefresh: _loadData,
      color: const Color(0xFFA855F7),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: _pendingReports.length,
        itemBuilder: (context, i) => _reportCard(_pendingReports[i]),
      ),
    );
  }

  // ============================================================
  // 🌈 ANIMATED BACKGROUND PIECES
  // ============================================================
  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(
              -0.4 + _bgAnim.value * 0.2,
              -0.6 + _bgAnim.value * 0.15,
            ),
            radius: 1.5,
            colors: const [
              Color(0xFF1E0B3A),
              Color(0xFF0A061E),
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
            gradient: RadialGradient(
              colors: [
                color.withOpacity(opacity * (0.85 + _orbAnim.value * 0.3)),
                color.withOpacity(0.0),
              ],
            ),
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
                ),
              ),
            ),
          ),
        ),
      );
    }
    return Stack(children: list);
  }

  // ============================================================
  // 💳 REPORT CARD
  // ============================================================
  Widget _reportCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'No Title';
    final desc = data['description'] ?? '';
    final category = data['category'] ?? 'Other';
    final location = data['location'] ?? 'Unknown';
    final status = data['status'] ?? 'Pending';
    final imageUrl = data['imageUrl'];
    final createdAt = data['createdAt'];
    final dateStr = createdAt != null
        ? DateFormat('dd MMM yyyy • HH:mm')
            .format((createdAt as Timestamp).toDate())
        : '';

    final categoryColor = _categoryColor(category);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
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
                  categoryColor.withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: categoryColor.withOpacity(0.25),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imageUrl != null && imageUrl.toString().isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(22)),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white10,
                          child: const Icon(Icons.broken_image,
                              color: Colors.white54),
                        ),
                      ),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: categoryColor.withOpacity(0.2),
                              border: Border.all(
                                color: categoryColor.withOpacity(0.6),
                                width: 1.2,
                              ),
                            ),
                            child: Icon(_categoryIcon(category),
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          _statusPill(status),
                        ],
                      ),
                      const SizedBox(height: 10),
                      if (desc.toString().isNotEmpty)
                        Text(
                          desc,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 12.5,
                            height: 1.4,
                          ),
                        ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.redAccent, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11.5),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (dateStr.isNotEmpty)
                            Text(
                              dateStr,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.5),
                                fontSize: 10.5,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 44,
                        child: ElevatedButton.icon(
                          onPressed: () => _showEmployeePicker(doc),
                          icon: const Icon(Icons.person_add_alt_1, size: 18),
                          label: const Text(
                            'Assign to Employee',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13.5),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFA855F7),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
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

  Widget _statusPill(String status) {
    final color = status == 'Approved'
        ? const Color(0xFF10B981)
        : status == 'Assigned'
            ? const Color(0xFF3B82F6)
            : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.6), width: 1),
      ),
      child: Text(
        status,
        style: TextStyle(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
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
                color: Colors.white.withOpacity(0.05),
                border:
                    Border.all(color: Colors.white.withOpacity(0.25), width: 1.5),
              ),
              child: const Icon(Icons.assignment_turned_in_outlined,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'No approved reports to assign',
              style: TextStyle(
                color: Colors.white,
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Approve a report from the Applications page first.',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 12.5,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Color _categoryColor(String cat) {
    switch (cat) {
      case 'Road Work':
        return const Color(0xFFF59E0B);
      case 'Metro':
        return const Color(0xFF3B82F6);
      case 'Traffic Block':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFFA855F7);
    }
  }

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'Road Work':
        return Icons.construction_rounded;
      case 'Metro':
        return Icons.subway_rounded;
      case 'Traffic Block':
        return Icons.traffic_rounded;
      default:
        return Icons.report_problem_rounded;
    }
  }
}