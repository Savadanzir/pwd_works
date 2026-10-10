import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/glass_scaffold.dart';

class ComplaintsPage extends StatefulWidget {
  const ComplaintsPage({super.key});
  @override
  State<ComplaintsPage> createState() => _ComplaintsPageState();
}

class _ComplaintsPageState extends State<ComplaintsPage> {
  final _controller = TextEditingController();
  final List<_Complaint> _list = [
    _Complaint('Pothole near my street', 'Pending', '2 days ago'),
    _Complaint('Broken streetlight on 5th cross', 'Resolved', '1 week ago'),
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _add() {
    if (_controller.text.trim().isEmpty) return;
    setState(() {
      _list.insert(
          0, _Complaint(_controller.text.trim(), 'Pending', 'Just now'));
      _controller.clear();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GlassScaffold(
      title: 'Complaints',
      accent: const Color(0xFF8B5CF6),
      body: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        child: Column(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withOpacity(0.10),
                        Colors.white.withOpacity(0.04),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Colors.white.withOpacity(0.28),
                      width: 1.2,
                    ),
                  ),
                  child: TextField(
                    controller: _controller,
                    style:
                        const TextStyle(color: Colors.white, fontSize: 15),
                    cursorColor: const Color(0xFF8B5CF6),
                    decoration: InputDecoration(
                      hintText: 'Type your complaint...',
                      hintStyle: TextStyle(
                        color: Colors.white.withOpacity(0.55),
                        fontSize: 14.5,
                      ),
                      prefixIcon: Icon(Icons.forum_rounded,
                          color: Colors.white.withOpacity(0.85), size: 20),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(
                          vertical: 16, horizontal: 4),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                icon: const Icon(Icons.send_rounded),
                label: const Text('Submit Complaint'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                ),
                onPressed: _add,
              ),
            ),
            const SizedBox(height: 20),
            Expanded(
              child: ListView.separated(
                itemCount: _list.length,
                separatorBuilder: (_, __) => const SizedBox(height: 12),
                itemBuilder: (context, i) => _card(_list[i]),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _card(_Complaint c) {
    final resolved = c.status == 'Resolved';
    final color =
        resolved ? const Color(0xFF10B981) : const Color(0xFFF59E0B);
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.10),
                color.withOpacity(0.10),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: Colors.white.withOpacity(0.25),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: color.withOpacity(0.20),
                  border: Border.all(
                      color: color.withOpacity(0.55), width: 1.2),
                ),
                child: Icon(
                  resolved
                      ? Icons.check_circle_rounded
                      : Icons.pending_rounded,
                  color: color,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      c.text,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.status} • ${c.time}',
                      style: TextStyle(
                        color: color,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Complaint {
  final String text;
  final String status;
  final String time;
  _Complaint(this.text, this.status, this.time);
}