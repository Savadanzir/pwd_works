import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class ManageAlerts extends StatefulWidget {
  const ManageAlerts({super.key});

  @override
  State<ManageAlerts> createState() => _ManageAlertsState();
}

class _ManageAlertsState extends State<ManageAlerts> {
  bool _loading = true;
  List<QueryDocumentSnapshot> _alerts = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final snap = await FirebaseFirestore.instance
          .collection('alerts')
          .get();

      final docs = snap.docs.toList();
      docs.sort((a, b) {
        final ta = (a.data())['createdAt'];
        final tb = (b.data())['createdAt'];
        if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
        return 0;
      });

      setState(() => _alerts = docs);
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
  // 🆕 NEW ALERT DIALOG
  // ============================================================
  Future<void> _showNewAlertDialog() async {
    final titleCtrl = TextEditingController();
    final msgCtrl = TextEditingController();
    String severity = 'Info';
    bool submitting = false;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> publish() async {
              if (titleCtrl.text.trim().isEmpty ||
                  msgCtrl.text.trim().isEmpty) {
                _snack('Please fill title & message', Colors.orangeAccent);
                return;
              }

              setDialogState(() => submitting = true);

              try {
                await FirebaseFirestore.instance.collection('alerts').add({
                  'title': titleCtrl.text.trim(),
                  'message': msgCtrl.text.trim(),
                  'severity': severity, // 'Info' | 'Warning' | 'Critical'
                  'district': '',
                  'createdAt': Timestamp.now(),
                  'createdBy': 'admin',
                });

                if (!mounted) return;
                Navigator.pop(ctx);
                _snack('✅ Alert published', const Color(0xFF10B981));
                _load();
              } catch (e) {
                if (!mounted) return;
                setDialogState(() => submitting = false);
                _snack('❌ Publish failed: $e', Colors.redAccent);
              }
            }

            return AlertDialog(
              backgroundColor: const Color(0xFF0B1730),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
              title: const Text('New Alert',
                  style: TextStyle(
                      color: Colors.white, fontWeight: FontWeight.w800)),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _field(titleCtrl, 'Title'),
                    const SizedBox(height: 14),
                    _field(msgCtrl, 'Message', maxLines: 4),
                    const SizedBox(height: 14),
                    Text('Severity',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.65),
                            fontSize: 12.5)),
                    const SizedBox(height: 4),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: severity,
                        isExpanded: true,
                        dropdownColor: const Color(0xFF1B2B54),
                        icon: const Icon(Icons.arrow_drop_down,
                            color: Colors.white70),
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                            fontWeight: FontWeight.w600),
                        items: const [
                          DropdownMenuItem(value: 'Info', child: Text('Info')),
                          DropdownMenuItem(
                              value: 'Warning', child: Text('Warning')),
                          DropdownMenuItem(
                              value: 'Critical', child: Text('Critical')),
                        ],
                        onChanged: (v) =>
                            setDialogState(() => severity = v!),
                      ),
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: submitting ? null : () => Navigator.pop(ctx),
                  child: const Text('Cancel',
                      style: TextStyle(color: Colors.white70)),
                ),
                TextButton(
                  onPressed: submitting ? null : publish,
                  child: submitting
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(
                              color: Color(0xFFEF4444), strokeWidth: 2),
                        )
                      : const Text('Publish',
                          style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w700)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _field(TextEditingController c, String hint, {int maxLines = 1}) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white.withOpacity(0.15)),
        ),
        child: TextField(
          controller: c,
          maxLines: maxLines,
          style: const TextStyle(color: Colors.white, fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle:
                TextStyle(color: Colors.white.withOpacity(0.5), fontSize: 13),
            border: InputBorder.none,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          ),
        ),
      ),
    );
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
        title: const Text('Manage Alerts',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _showNewAlertDialog,
        backgroundColor: const Color(0xFFEF4444),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Alert',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF3A0A18), Color(0xFF16040A), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _alerts.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: const Color(0xFFEF4444),
                      backgroundColor: const Color(0xFF0B1730),
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
                        itemCount: _alerts.length,
                        itemBuilder: (context, i) => _alertCard(_alerts[i]),
                      ),
                    ),
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
                color: const Color(0xFFEF4444).withOpacity(0.15),
                border: Border.all(
                    color: const Color(0xFFEF4444).withOpacity(0.5),
                    width: 1.5),
              ),
              child: const Icon(Icons.notifications_active_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text('No alerts yet',
                style: TextStyle(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text('Tap "New Alert" to publish your first alert.',
                style: TextStyle(
                    color: Colors.white.withOpacity(0.55), fontSize: 12.5),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  Widget _alertCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Alert';
    final message = data['message'] ?? '';
    final severity = data['severity'] ?? 'Info';
    final createdAt = data['createdAt'];
    final dateStr = createdAt is Timestamp
        ? DateFormat('dd MMM yyyy • HH:mm').format(createdAt.toDate())
        : '';

    final color = severity == 'Critical'
        ? const Color(0xFFEF4444)
        : severity == 'Warning'
            ? const Color(0xFFF59E0B)
            : const Color(0xFF3B82F6);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                color.withOpacity(0.08),
              ]),
              borderRadius: BorderRadius.circular(20),
              border:
                  Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: color.withOpacity(0.20),
                        border:
                            Border.all(color: color.withOpacity(0.6), width: 1.2),
                      ),
                      child:
                          const Icon(Icons.notifications, color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title,
                          style: const TextStyle(
                              color: Colors.white,
                              fontSize: 15,
                              fontWeight: FontWeight.w800),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    _pill(severity, color),
                  ],
                ),
                if (message.toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(message,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.8),
                          fontSize: 13,
                          height: 1.5)),
                ],
                if (dateStr.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(dateStr,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.45),
                          fontSize: 11)),
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
        child: Text(text,
            style: TextStyle(
                color: color,
                fontSize: 10.5,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.4)),
      );
}