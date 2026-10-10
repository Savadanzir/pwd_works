import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';

import '../providers/employee_management_provider.dart';
import 'create_employee.dart';

class ManageEmployees extends StatefulWidget {
  const ManageEmployees({super.key});
  @override
  State<ManageEmployees> createState() => _ManageEmployeesState();
}

class _ManageEmployeesState extends State<ManageEmployees>
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
      Provider.of<EmployeeManagementProvider>(context, listen: false).loadAll();
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
    final prov = Provider.of<EmployeeManagementProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Manage Employees',
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
      floatingActionButton: _glassFab(prov),
    );
  }

  Widget _body(EmployeeManagementProvider prov) {
    if (prov.loading) {
      return const Center(child: CircularProgressIndicator(color: Colors.white));
    }

    if (prov.employees.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            const Icon(Icons.people_outline_rounded, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text('No employees yet',
                style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text('Tap "Create Employee" below to add the first one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
          ]),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: prov.loadAll,
      color: const Color(0xFFA855F7),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: prov.employees.length,
        itemBuilder: (context, i) {
          final data = prov.employees[i].data() as Map<String, dynamic>;
          final uid = prov.employees[i].id;
          return _EmployeeCard(
            uid: uid,
            data: data,
            onEdit: () => _openEdit(context, uid, data),
            onDelete: () => _confirmDelete(context, uid, data['name']?.toString(), prov),
          );
        },
      ),
    );
  }

  Future<void> _openEdit(BuildContext context, String uid, Map<String, dynamic> data) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => CreateEmployee(existing: data, uid: uid)),
    );
  }

  Future<void> _confirmDelete(
      BuildContext context, String uid, String? name, EmployeeManagementProvider prov) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0B1730),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Delete Employee?',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
        content: Text('Remove "${name ?? 'this employee'}" from the employee list?',
            style: const TextStyle(color: Colors.white70)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false),
              child: const Text('Cancel', style: TextStyle(color: Colors.white70))),
          TextButton(onPressed: () => Navigator.pop(context, true),
              style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
              child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true) {
      await prov.deleteEmployee(uid);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Deleted ${name ?? 'employee'}'),
              backgroundColor: const Color(0xFF10B981),
              behavior: SnackBarBehavior.floating));
      }
    }
  }

  Widget _glassFab(EmployeeManagementProvider prov) {
    return Padding(
      padding: const EdgeInsets.only(right: 8, bottom: 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(100),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(100),
              gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF8B5CF6)]),
              border: Border.all(color: Colors.white.withOpacity(0.35), width: 1.3),
              boxShadow: [
                BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.55), blurRadius: 28, offset: const Offset(0, 10)),
                BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 14, offset: const Offset(0, 6)),
              ]),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () async {
                  await Navigator.push(context,
                      MaterialPageRoute(builder: (_) => const CreateEmployee()));
                  prov.loadAll();
                },
                borderRadius: BorderRadius.circular(100),
                child: const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                  child: Row(mainAxisSize: MainAxisSize.min, children: [
                    Icon(Icons.person_add_alt_1_rounded, color: Colors.white, size: 20),
                    SizedBox(width: 10),
                    Text('Create Employee',
                        style: TextStyle(color: Colors.white, fontSize: 14.5, fontWeight: FontWeight.w800, letterSpacing: 0.3)),
                  ]),
                ),
              ),
            ),
          ),
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

class _EmployeeCard extends StatelessWidget {
  final String uid;
  final Map<String, dynamic> data;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _EmployeeCard({
    required this.uid,
    required this.data,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? 'Unknown').toString();
    final email = (data['email'] ?? '—').toString();
    final phone = (data['phone'] ?? '—').toString();
    final dept = (data['department'] ?? '—').toString();
    final initial = name.isNotEmpty ? name[0].toUpperCase() : '?';

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
                const Color(0xFFA855F7).withOpacity(0.10)]),
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
              boxShadow: [BoxShadow(color: Colors.black.withOpacity(0.30), blurRadius: 20, offset: const Offset(0, 8))]),
            child: Row(children: [
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: const LinearGradient(colors: [Color(0xFFA855F7), Color(0xFF8B5CF6)]),
                  boxShadow: [BoxShadow(color: const Color(0xFFA855F7).withOpacity(0.55), blurRadius: 16, spreadRadius: 1)]),
                child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800))),
              const SizedBox(width: 14),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(name, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800, letterSpacing: 0.2)),
                const SizedBox(height: 2),
                Text(email, style: TextStyle(color: Colors.white.withOpacity(0.75), fontSize: 12.5)),
                const SizedBox(height: 3),
                Text('$dept  •  $phone', style: TextStyle(color: Colors.white.withOpacity(0.60), fontSize: 11.5)),
              ])),
              _iconBtn(icon: Icons.edit_rounded, color: const Color(0xFF3B82F6), onTap: onEdit),
              const SizedBox(width: 6),
              _iconBtn(icon: Icons.delete_rounded, color: const Color(0xFFEF4444), onTap: onDelete),
            ]),
          ),
        ),
      ),
    );
  }

  Widget _iconBtn({required IconData icon, required Color color, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: color.withOpacity(0.15),
          border: Border.all(color: color.withOpacity(0.45), width: 1.1)),
        child: Icon(icon, color: color, size: 16)),
    );
  }
}