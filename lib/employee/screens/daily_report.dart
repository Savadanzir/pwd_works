import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/daily_report_provider.dart';
import '../providers/employee_provider.dart';

class DailyReport extends StatefulWidget {
  const DailyReport({super.key});
  @override
  State<DailyReport> createState() => _DailyReportState();
}

class _DailyReportState extends State<DailyReport> {
  final _hours = TextEditingController();
  final _tasksDone = TextEditingController();
  final _blockers = TextEditingController();

  @override
  void dispose() {
    _hours.dispose();
    _tasksDone.dispose();
    _blockers.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_hours.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Enter hours worked'),
          backgroundColor: Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating));
      return;
    }

    final emp = Provider.of<EmployeeProvider>(context, listen: false).employee;
    if (emp == null) return;

    final prov = Provider.of<DailyReportProvider>(context, listen: false);
    final err = await prov.submitReport(
      employeeId: emp.uid,
      employeeName: emp.name,
      department: emp.department,
      hoursWorked: double.tryParse(_hours.text.trim()) ?? 0,
      tasksCompleted: int.tryParse(_tasksDone.text.trim()) ?? 0,
      blockers: _blockers.text.trim(),
    );

    if (err == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Daily report submitted'),
          backgroundColor: Color(0xFF10B981),
          behavior: SnackBarBehavior.floating));
      Navigator.pop(context);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text('Error: $err'),
          backgroundColor: const Color(0xFFB91C1C),
          behavior: SnackBarBehavior.floating));
    }
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<DailyReportProvider>(context);

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
              colors: [Color(0xFF2E1E06), Color(0xFF140D02), Color(0xFF04060F)],
              stops: [0.0, 0.55, 1.0]),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                child: Container(
                  padding: const EdgeInsets.all(18),
                  decoration: BoxDecoration(
                      gradient: LinearGradient(colors: [
                        Colors.white.withOpacity(0.10),
                        const Color(0xFFF59E0B).withOpacity(0.10)
                      ]),
                      borderRadius: BorderRadius.circular(24),
                      border: Border.all(
                          color: Colors.white.withOpacity(0.25), width: 1.2)),
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _field(_hours, 'Hours Worked', Icons.schedule_rounded,
                            keyboard: TextInputType.number),
                        const SizedBox(height: 14),
                        _field(_tasksDone, 'Tasks Completed',
                            Icons.check_circle_rounded,
                            keyboard: TextInputType.number),
                        const SizedBox(height: 14),
                        _field(
                            _blockers, 'Blockers / Notes', Icons.notes_rounded,
                            maxLines: 4),
                        const SizedBox(height: 24),
                        SizedBox(
                            height: 54,
                            child: ElevatedButton.icon(
                                icon: prov.loading
                                    ? const SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2))
                                    : const Icon(Icons.send_rounded),
                                label: const Text('Submit Report',
                                    style: TextStyle(
                                        fontSize: 15.5,
                                        fontWeight: FontWeight.w700)),
                                style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFFF59E0B),
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(
                                        borderRadius:
                                            BorderRadius.circular(16)),
                                    elevation: 0),
                                onPressed: prov.loading ? null : _submit)),
                      ]),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _field(TextEditingController c, String label, IconData icon,
      {int maxLines = 1, TextInputType? keyboard}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                  color: Colors.white.withOpacity(0.28), width: 1.2)),
          child: TextField(
              controller: c,
              maxLines: maxLines,
              keyboardType: keyboard,
              style: const TextStyle(color: Colors.white, fontSize: 14.5),
              cursorColor: const Color(0xFFF59E0B),
              decoration: InputDecoration(
                  labelText: label,
                  labelStyle: TextStyle(
                      color: Colors.white.withOpacity(0.60), fontSize: 13.5),
                  floatingLabelStyle: const TextStyle(
                      color: Color(0xFFF59E0B),
                      fontSize: 13,
                      fontWeight: FontWeight.w600),
                  prefixIcon: Icon(icon,
                      color: Colors.white.withOpacity(0.70), size: 20),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 16, horizontal: 4))),
        ),
      ),
    );
  }
}
