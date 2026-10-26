import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:road_maintenance/employee/providers/employee_provider.dart';



class DailyReport extends StatefulWidget {
  const DailyReport({super.key});

  @override
  State<DailyReport> createState() => _DailyReportState();
}

class _DailyReportState extends State<DailyReport> {
  final _hoursCtrl = TextEditingController();
  final _tasksCtrl = TextEditingController();
  final _blockersCtrl = TextEditingController();

  bool _submitting = false;

  @override
  void dispose() {
    _hoursCtrl.dispose();
    _tasksCtrl.dispose();
    _blockersCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final hours = _hoursCtrl.text.trim();
    final tasks = _tasksCtrl.text.trim();

    if (hours.isEmpty || tasks.isEmpty) {
      _snack('Please fill hours worked and tasks completed', Colors.orangeAccent);
      return;
    }

    setState(() => _submitting = true);

    try {
      final emp =
          Provider.of<EmployeeProvider>(context, listen: false).employee;

      await FirebaseFirestore.instance.collection('daily_reports').add({
        'employeeUid': emp?.uid ?? '',
        'employeeName': emp?.name ?? 'Employee',
        'employeeEmail': emp?.email ?? '',
        'department': emp?.department ?? '',
        'hoursWorked': hours,
        'tasksCompleted': tasks,
        'blockers': _blockersCtrl.text.trim(),
        'status': 'Submitted',
        'createdAt': Timestamp.now(),
      });

      if (!mounted) return;
      _snack('✅ Daily report sent to admin', const Color(0xFF10B981));

      _hoursCtrl.clear();
      _tasksCtrl.clear();
      _blockersCtrl.clear();
      Navigator.pop(context);
    } catch (e) {
      _snack('❌ Failed to submit: $e', Colors.redAccent);
    } finally {
      if (mounted) setState(() => _submitting = false);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Daily Report',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF2A1B0B), Color(0xFF160A04), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _glassCard(
                  child: Column(
                    children: [
                      _glassField(
                        controller: _hoursCtrl,
                        hint: 'Hours Worked',
                        icon: Icons.access_time_rounded,
                        keyboardType: TextInputType.number,
                      ),
                      const SizedBox(height: 14),
                      _glassField(
                        controller: _tasksCtrl,
                        hint: 'Tasks Completed',
                        icon: Icons.check_circle_outline_rounded,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 14),
                      _glassField(
                        controller: _blockersCtrl,
                        hint: 'Blockers / Notes',
                        icon: Icons.notes_rounded,
                        maxLines: 4,
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton.icon(
                          onPressed: _submitting ? null : _submit,
                          icon: _submitting
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                      color: Colors.white, strokeWidth: 2),
                                )
                              : const Icon(Icons.send_rounded, size: 18),
                          label: Text(
                            _submitting ? 'Sending...' : 'Submit Report',
                            style: const TextStyle(
                                fontSize: 15.5, fontWeight: FontWeight.w700),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFF59E0B),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16)),
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

  Widget _glassCard({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.08),
                const Color(0xFFF59E0B).withOpacity(0.08),
              ]),
              borderRadius: BorderRadius.circular(24),
              border:
                  Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
            ),
            child: child,
          ),
        ),
      );

  Widget _glassField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    int maxLines = 1,
    TextInputType? keyboardType,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withOpacity(0.15)),
          ),
          child: TextField(
            controller: controller,
            maxLines: maxLines,
            keyboardType: keyboardType,
            style: const TextStyle(color: Colors.white, fontSize: 15),
            cursorColor: const Color(0xFFF59E0B),
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 14),
              prefixIcon:
                  Icon(icon, color: Colors.white.withOpacity(0.75), size: 20),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 16, horizontal: 4),
            ),
          ),
        ),
      ),
    );
  }
}