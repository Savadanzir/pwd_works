import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/performance_provider.dart';
import '../providers/employee_provider.dart';

class PerformancePage extends StatefulWidget {
  const PerformancePage({super.key});
  @override
  State<PerformancePage> createState() => _PerformancePageState();
}

class _PerformancePageState extends State<PerformancePage> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final uid =
          Provider.of<EmployeeProvider>(context, listen: false).employee?.uid;
      if (uid != null) {
        Provider.of<PerformanceProvider>(context, listen: false).loadStats(uid);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<PerformanceProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('My Performance',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
              center: Alignment(-0.4, -0.6),
              radius: 1.5,
              colors: [Color(0xFF062A1E), Color(0xFF04140F), Color(0xFF04060F)],
              stops: [0.0, 0.55, 1.0]),
        ),
        child: SafeArea(
          child: prov.loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                  child: Column(children: [
                    // Big score card
                    ClipRRect(
                      borderRadius: BorderRadius.circular(28),
                      child: BackdropFilter(
                        filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                        child: Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                              gradient: LinearGradient(colors: [
                                Colors.white.withOpacity(0.10),
                                const Color(0xFF10B981).withOpacity(0.14)
                              ]),
                              borderRadius: BorderRadius.circular(28),
                              border: Border.all(
                                  color: Colors.white.withOpacity(0.28),
                                  width: 1.2)),
                          child: Column(children: [
                            const Icon(Icons.emoji_events_rounded,
                                color: Color(0xFFFBBF24), size: 54),
                            const SizedBox(height: 12),
                            Text('${prov.completionRate.toStringAsFixed(0)}%',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 46,
                                    fontWeight: FontWeight.w900,
                                    letterSpacing: 1)),
                            const Text('Overall Performance',
                                style: TextStyle(
                                    color: Colors.white70, fontSize: 14)),
                          ]),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    _stat('Total Assigned', '${prov.total}',
                        Icons.assignment_rounded, const Color(0xFF3B82F6)),
                    const SizedBox(height: 12),
                    _stat('Completed', '${prov.completed}',
                        Icons.check_circle_rounded, const Color(0xFF10B981)),
                    const SizedBox(height: 12),
                    _stat('In Progress', '${prov.inProgress}',
                        Icons.pending_rounded, const Color(0xFFF59E0B)),
                    const SizedBox(height: 12),
                    _stat(
                        'Completion Rate',
                        '${prov.completionRate.toStringAsFixed(1)}%',
                        Icons.speed_rounded,
                        const Color(0xFF8B5CF6)),
                  ]),
                ),
        ),
      ),
    );
  }

  Widget _stat(String label, String value, IconData icon, Color color) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                color.withOpacity(0.10)
              ]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(0.25), width: 1.2)),
          child: Row(children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: color.withOpacity(0.20),
                    border:
                        Border.all(color: color.withOpacity(0.55), width: 1.2)),
                child: Icon(icon, color: color, size: 20)),
            const SizedBox(width: 14),
            Expanded(
                child: Text(label,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75), fontSize: 13))),
            Text(value,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800)),
          ]),
        ),
      ),
    );
  }
}
