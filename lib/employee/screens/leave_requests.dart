import 'dart:math' as math;
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

import '../providers/leave_request_provider.dart';
import '../providers/employee_provider.dart';
import '../models/leave_request_model.dart';

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

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid =
          Provider.of<EmployeeProvider>(context, listen: false).employee?.uid;
      if (uid != null) {
        Provider.of<LeaveRequestProvider>(context, listen: false)
            .loadForEmployee(uid);
      }
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
    final prov = Provider.of<LeaveRequestProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Leave Requests',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: () {
                final uid =
                    Provider.of<EmployeeProvider>(context, listen: false)
                        .employee
                        ?.uid;
                if (uid != null) prov.loadForEmployee(uid);
              }),
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

  Widget _body(LeaveRequestProvider prov) {
    if (prov.loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }
    if (prov.requests.isEmpty) {
      return Center(
          child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                const Icon(Icons.event_busy_rounded,
                    size: 64, color: Colors.grey),
                const SizedBox(height: 16),
                Text('No leave requests yet',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 15,
                        fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                Text('Tap "Apply Leave" below to submit your first request.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.5), fontSize: 12.5)),
              ])));
    }

    return RefreshIndicator(
      onRefresh: () {
        final uid =
            Provider.of<EmployeeProvider>(context, listen: false).employee?.uid;
        return prov.loadForEmployee(uid ?? '');
      },
      color: const Color(0xFFA855F7),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
        itemCount: prov.requests.length,
        itemBuilder: (context, i) => _LeaveCard(request: prov.requests[i]),
      ),
    );
  }

  Widget _glassFab(BuildContext context, LeaveRequestProvider prov) {
    return Padding(
        padding: const EdgeInsets.only(right: 8, bottom: 8),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(100),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
            child: Container(
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(100),
                    gradient: const LinearGradient(
                        colors: [Color(0xFFA855F7), Color(0xFF8B5CF6)]),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.35), width: 1.3),
                    boxShadow: [
                      BoxShadow(
                          color: const Color(0xFFA855F7).withOpacity(0.55),
                          blurRadius: 28,
                          offset: const Offset(0, 10)),
                      BoxShadow(
                          color: Colors.black.withOpacity(0.30),
                          blurRadius: 14,
                          offset: const Offset(0, 6))
                    ]),
                child: Material(
                    color: Colors.transparent,
                    child: InkWell(
                        onTap: () => _openForm(context, prov),
                        borderRadius: BorderRadius.circular(100),
                        child: const Padding(
                          padding: EdgeInsets.symmetric(
                              horizontal: 20, vertical: 16),
                          child: Row(mainAxisSize: MainAxisSize.min, children: [
                            Icon(Icons.add_rounded,
                                color: Colors.white, size: 20),
                            SizedBox(width: 8),
                            Text('Apply Leave',
                                style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 0.3)),
                          ]),
                        )))),
          ),
        ));
  }

  Future<void> _openForm(
      BuildContext context, LeaveRequestProvider prov) async {
    String type = 'Sick Leave';
    DateTime from = DateTime.now();
    DateTime to = DateTime.now().add(const Duration(days: 1));
    final reason = TextEditingController();

    await showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          backgroundColor: const Color(0xFF0B1730),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Apply Leave',
              style:
                  TextStyle(color: Colors.white, fontWeight: FontWeight.w800)),
          content: SingleChildScrollView(
              child: Column(mainAxisSize: MainAxisSize.min, children: [
            DropdownButtonFormField<String>(
                value: type,
                dropdownColor: const Color(0xFF1B2B54),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                    labelText: 'Type',
                    labelStyle:
                        TextStyle(color: Colors.white.withOpacity(0.70)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.25),
                            width: 1.2))),
                items: const [
                  DropdownMenuItem(
                      value: 'Sick Leave',
                      child: Text('🤒 Sick Leave',
                          style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(
                      value: 'Vacation',
                      child: Text('🏖️ Vacation',
                          style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(
                      value: 'Emergency',
                      child: Text('🚨 Emergency',
                          style: TextStyle(color: Colors.white))),
                  DropdownMenuItem(
                      value: 'Personal',
                      child: Text('👤 Personal',
                          style: TextStyle(color: Colors.white))),
                ],
                onChanged: (v) => setSt(() => type = v!)),
            const SizedBox(height: 14),
            _dateTile('From', from, () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: from,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (picked != null) setSt(() => from = picked);
            }),
            const SizedBox(height: 10),
            _dateTile('To', to, () async {
              final picked = await showDatePicker(
                  context: context,
                  initialDate: to,
                  firstDate: DateTime.now().subtract(const Duration(days: 30)),
                  lastDate: DateTime.now().add(const Duration(days: 365)));
              if (picked != null) setSt(() => to = picked);
            }),
            const SizedBox(height: 14),
            TextField(
                controller: reason,
                maxLines: 3,
                style: const TextStyle(color: Colors.white),
                cursorColor: const Color(0xFFA855F7),
                decoration: InputDecoration(
                    labelText: 'Reason',
                    labelStyle:
                        TextStyle(color: Colors.white.withOpacity(0.70)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.25), width: 1.2)),
                    focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(
                            color: Color(0xFFA855F7), width: 1.4)))),
          ])),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel',
                    style: TextStyle(color: Colors.white70))),
            TextButton(
                onPressed: () async {
                  final emp =
                      Provider.of<EmployeeProvider>(context, listen: false)
                          .employee;
                  if (emp == null) return;
                  await prov.submitRequest(
                      employeeId: emp.uid,
                      employeeName: emp.name,
                      department: emp.department,
                      type: type,
                      from: from,
                      to: to,
                      reason: reason.text.trim());
                  if (context.mounted) Navigator.pop(context);
                },
                style: TextButton.styleFrom(
                    foregroundColor: const Color(0xFFA855F7)),
                child: const Text('Submit')),
          ],
        ),
      ),
    );
  }

  Widget _dateTile(String label, DateTime date, VoidCallback onTap) =>
      GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                  color: Colors.white.withOpacity(0.25), width: 1.2)),
          child: Row(children: [
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Text(label,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.55), fontSize: 12)),
                  const SizedBox(height: 4),
                  Text(DateFormat('dd MMM yyyy').format(date),
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700)),
                ])),
            const Icon(Icons.calendar_today_rounded,
                color: Colors.white70, size: 18),
          ]),
        ),
      );

  Widget _gradientBase() => Container(
        decoration: BoxDecoration(
            gradient: RadialGradient(
                center: Alignment(
                    -0.4 + _bgAnim.value * 0.2, -0.6 + _bgAnim.value * 0.15),
                radius: 1.5,
                colors: const [
              Color(0xFF1E0E3A),
              Color(0xFF0D061A),
              Color(0xFF04060F)
            ],
                stops: const [
              0.0,
              0.55,
              1.0
            ])),
      );

  Widget _orbs(Size size) => Stack(children: [
        Positioned(
            left: -size.width * 0.15 + _parallax.dx * -14,
            top: -size.height * 0.18 + _parallax.dy * -10,
            child: _orb(380, const Color(0xFFA855F7), 0.30)),
        Positioned(
            right: -size.width * 0.12 + _parallax.dx * 14,
            bottom: -size.height * 0.15 + _parallax.dy * 10,
            child: _orb(420, const Color(0xFF8B5CF6), 0.22)),
      ]);

  Widget _orb(double size, Color color, double opacity) => IgnorePointer(
        child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(colors: [
                  color.withOpacity(opacity * (0.85 + _orbAnim.value * 0.3)),
                  color.withOpacity(0.0)
                ]))),
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
}

class _LeaveCard extends StatelessWidget {
  final LeaveRequestModel request;
  const _LeaveCard({required this.request});

  @override
  Widget build(BuildContext context) {
    final status = request.status;
    final color = status == 'Approved'
        ? const Color(0xFF10B981)
        : status == 'Rejected'
            ? const Color(0xFFEF4444)
            : const Color(0xFFF59E0B);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
                gradient: LinearGradient(colors: [
                  Colors.white.withOpacity(0.10),
                  color.withOpacity(0.10)
                ]),
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                    color: Colors.white.withOpacity(0.25), width: 1.2)),
            child:
                Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                Expanded(
                    child: Text(request.type,
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.w800))),
                Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                        color: color.withOpacity(0.20),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                            color: color.withOpacity(0.60), width: 1)),
                    child: Text(status,
                        style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w800))),
              ]),
              const SizedBox(height: 8),
              Text('${request.fromDate}  →  ${request.toDate}',
                  style: TextStyle(
                      color: Colors.white.withOpacity(0.75), fontSize: 13)),
              if (request.reason.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(request.reason,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.65), fontSize: 12.5)),
              ],
            ]),
          ),
        ),
      ),
    );
  }
}
