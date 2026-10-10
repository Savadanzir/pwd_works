import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/assignment_provider.dart';
import '../providers/admin_provider.dart';
import '../models/report_model.dart';

class EmployeeAssignment extends StatefulWidget {
  const EmployeeAssignment({super.key});
  @override
  State<EmployeeAssignment> createState() => _EmployeeAssignmentState();
}

class _EmployeeAssignmentState extends State<EmployeeAssignment>
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
      Provider.of<AssignmentProvider>(context, listen: false).loadApproved();
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
    final prov = Provider.of<AssignmentProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Assign Work',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: () => prov.loadApproved()),
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
                      child: _body(prov),
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

  Widget _body(AssignmentProvider prov) {
    if (prov.loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }
    if (prov.approvedReports.isEmpty) {
      return Center(child: Padding(padding: const EdgeInsets.all(32),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.assignment_turned_in_outlined, size: 64, color: Colors.grey),
          const SizedBox(height: 16),
          Text('No approved reports to assign',
            style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 15, fontWeight: FontWeight.w700)),
          const SizedBox(height: 8),
          Text('Approve a report from the Applications page first.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
        ])));
    }

    return RefreshIndicator(
      onRefresh: prov.loadApproved,
      color: const Color(0xFFA855F7),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: prov.approvedReports.length,
        itemBuilder: (context, i) => _ApprovedCard(
          report: prov.approvedReports[i],
          onAssigned: prov.loadApproved,
        ),
      ),
    );
  }

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
            radius: 1.5,
            colors: const [Color(0xFF1E0B3A), Color(0xFF0A061E), Color(0xFF04060F)],
            stops: const [0.0, 0.55, 1.0]),
        ),
      );

  Widget _orbs(Size size) => Stack(children: [
        Positioned(
          left: -size.width * 0.15 + _parallax.dx * -14,
          top: -size.height * 0.18 + _parallax.dy * -10,
          child: _orb(380, const Color(0xFFA855F7), 0.30)),
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

class _ApprovedCard extends StatelessWidget {
  final ReportModel report;
  final VoidCallback onAssigned;
  const _ApprovedCard({required this.report, required this.onAssigned});

  @override
  Widget build(BuildContext context) {
    final dateStr = report.createdAt != null
        ? DateFormat('dd MMM yyyy • HH:mm').format(report.createdAt!.toDate())
        : '';

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                const Color(0xFF3B82F6).withOpacity(0.10)]),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2)),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (report.imageUrl != null && report.imageUrl!.isNotEmpty)
                  ClipRRect(
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
                    child: AspectRatio(aspectRatio: 16 / 10,
                      child: Image.network(report.imageUrl!, fit: BoxFit.cover))),
                Padding(padding: const EdgeInsets.all(16),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Row(children: [
                      Expanded(child: Text(report.title,
                        style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0xFF3B82F6).withOpacity(0.20),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFF3B82F6).withOpacity(0.65), width: 1)),
                        child: Text(report.category,
                          style: const TextStyle(color: Color(0xFF60A5FA), fontSize: 10.5, fontWeight: FontWeight.w800))),
                    ]),
                    const SizedBox(height: 8),
                    if (report.description.isNotEmpty)
                      Text(report.description, maxLines: 2, overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.85), fontSize: 13, height: 1.5)),
                    const SizedBox(height: 10),
                    Row(children: [
                      const Icon(Icons.location_on_rounded, color: Color(0xFFEF4444), size: 14),
                      const SizedBox(width: 4),
                      Expanded(child: Text(report.location,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12))),
                      if (dateStr.isNotEmpty)
                        Text(dateStr, style: TextStyle(color: Colors.white.withOpacity(0.55), fontSize: 11)),
                    ]),
                    const SizedBox(height: 14),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        icon: const Icon(Icons.person_add_alt_1_rounded, size: 18),
                        label: const Text('Assign Employee',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.w700)),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFFA855F7),
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                          elevation: 0),
                        onPressed: () => _showAssignSheet(context))),
                  ])),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showAssignSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _EmployeePickerSheet(
        reportId: report.id,
        reportCategory: report.category,
        reportTitle: report.title,
        onAssigned: () {
          Navigator.pop(context);
          onAssigned();
        },
      ),
    );
  }
}

class _EmployeePickerSheet extends StatefulWidget {
  final String reportId;
  final String reportCategory;
  final String reportTitle;
  final VoidCallback onAssigned;
  const _EmployeePickerSheet({
    required this.reportId,
    required this.reportCategory,
    required this.reportTitle,
    required this.onAssigned,
  });

  @override
  State<_EmployeePickerSheet> createState() => _EmployeePickerSheetState();
}

class _EmployeePickerSheetState extends State<_EmployeePickerSheet> {
  static const Map<String, String> _categoryToDept = {
    'Road Work': 'Engineer',
    'Metro': 'Engineer',
    'Traffic Block': 'Traffic Controller',
    'Other': 'Supervisor',
  };

  late String _targetDept;
  bool _showAll = false;
  bool _loading = true;
  List<QueryDocumentSnapshot> _employees = [];

  @override
  void initState() {
    super.initState();
    _targetDept = _categoryToDept[widget.reportCategory] ?? 'Staff';
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final prov = Provider.of<AssignmentProvider>(context, listen: false);
    try {
      _employees = _showAll
          ? await prov.allEmployees()
          : await prov.employeesByDepartment(_targetDept);
    } catch (_) {
      _employees = [];
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1024),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(margin: const EdgeInsets.only(top: 12),
          width: 40, height: 4,
          decoration: BoxDecoration(color: Colors.white24, borderRadius: BorderRadius.circular(4))),
        const SizedBox(height: 14),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Row(children: [
            Container(padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                color: const Color(0xFFA855F7).withOpacity(0.20),
                border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.55), width: 1.2)),
              child: const Icon(Icons.person_add_alt_1_rounded, color: Color(0xFFA855F7), size: 22)),
            const SizedBox(width: 14),
            Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('Assign Employee',
                style: TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(widget.reportTitle, maxLines: 1, overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12.5)),
            ])),
            IconButton(icon: const Icon(Icons.close_rounded, color: Colors.white70),
              onPressed: () => Navigator.pop(context)),
          ])),
        const SizedBox(height: 12),
        Padding(padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFA855F7).withOpacity(0.10),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFA855F7).withOpacity(0.35), width: 1)),
            child: Row(children: [
              const Icon(Icons.filter_list_rounded, size: 16, color: Color(0xFFA855F7)),
              const SizedBox(width: 8),
              Expanded(child: Text(
                _showAll ? 'Showing all departments' : 'Filtered: $_targetDept',
                style: const TextStyle(fontSize: 12, color: Color(0xFFA855F7), fontWeight: FontWeight.w600))),
              TextButton(
                onPressed: () { setState(() => _showAll = !_showAll); _load(); },
                style: TextButton.styleFrom(foregroundColor: const Color(0xFFA855F7),
                  padding: EdgeInsets.zero, minimumSize: const Size(0, 30)),
                child: Text(_showAll ? 'Filter' : 'Show all',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700))),
            ]),
          )),
        const SizedBox(height: 12),
        Flexible(child: _loading
          ? const Center(child: Padding(padding: EdgeInsets.all(40),
              child: CircularProgressIndicator(color: Color(0xFFA855F7))))
          : _employees.isEmpty
            ? Padding(padding: const EdgeInsets.all(32),
                child: Column(mainAxisSize: MainAxisSize.min, children: [
                  const Icon(Icons.person_off_outlined, size: 56, color: Colors.grey),
                  const SizedBox(height: 12),
                  Text('No employees in $_targetDept',
                    style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 14, fontWeight: FontWeight.w600)),
                ]))
            : ListView.builder(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                shrinkWrap: true,
                itemCount: _employees.length,
                itemBuilder: (context, i) {
                  final e = _employees[i].data() as Map<String, dynamic>;
                  return _employeeTile(e, _employees[i].id);
                })),
      ]),
    );
  }

  Widget _employeeTile(Map<String, dynamic> e, String uid) {
    final name = (e['name'] ?? 'Unknown').toString();
    final dept = (e['department'] ?? '—').toString();
    final phone = (e['phone'] ?? '—').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: () async {
                final prov = Provider.of<AssignmentProvider>(context, listen: false);
                final admin = Provider.of<AdminProvider>(context, listen: false).admin;
                await prov.assign(
                  reportId: widget.reportId,
                  employeeUid: uid,
                  employeeName: name,
                  employeeDepartment: dept,
                  adminName: admin?.name ?? 'admin',
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Assigned to $name ($dept)'),
                      backgroundColor: const Color(0xFF10B981),
                      behavior: SnackBarBehavior.floating));
                }
                widget.onAssigned();
              },
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: [
                    Colors.white.withOpacity(0.08),
                    const Color(0xFFA855F7).withOpacity(0.08)]),
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(color: Colors.white.withOpacity(0.20), width: 1.1)),
                child: Row(children: [
                  Container(padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(shape: BoxShape.circle,
                      gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF8B5CF6)]),
                      boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.55), blurRadius: 14)]),
                    child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.w800))),
                  const SizedBox(width: 14),
                  Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text(name, style: const TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 2),
                    Text('$dept  •  $phone',
                      style: TextStyle(color: Colors.white.withOpacity(0.65), fontSize: 12)),
                  ])),
                  Icon(Icons.chevron_right_rounded, color: Colors.white.withOpacity(0.5), size: 22),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}