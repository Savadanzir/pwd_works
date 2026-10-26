import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:road_maintenance/services/firestore_service.dart';



class AdminMetroUpdates extends StatefulWidget {
  const AdminMetroUpdates({super.key});

  @override
  State<AdminMetroUpdates> createState() => _AdminMetroUpdatesState();
}

class _AdminMetroUpdatesState extends State<AdminMetroUpdates> {
  final FirestoreService _fs = FirestoreService();

  bool _loading = true;
  List<QueryDocumentSnapshot> _metroReports = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await _fs.getAllReports();
      final metro = all.where((d) {
        final data = d.data() as Map<String, dynamic>;
        return (data['category'] ?? '') == 'Metro';
      }).toList();

      setState(() => _metroReports = metro);
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

  Future<void> _approve(String id) async {
    try {
      await _fs.approveReport(id, adminName: 'Admin');
      _snack('✅ Metro update approved', const Color(0xFF10B981));
      _load();
    } catch (e) {
      _snack('❌ $e', Colors.redAccent);
    }
  }

  Future<void> _reject(String id) async {
    final controller = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        backgroundColor: const Color(0xFF0B1730),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Reject Update', style: TextStyle(color: Colors.white)),
        content: TextField(
          controller: controller,
          maxLines: 3,
          style: const TextStyle(color: Colors.white),
          decoration: InputDecoration(
            hintText: 'Reason for rejection',
            hintStyle: const TextStyle(color: Colors.white38),
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel', style: TextStyle(color: Colors.white70)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.redAccent),
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Reject', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (reason == null || reason.isEmpty) return;
    try {
      await _fs.rejectReport(id, reason: reason, adminName: 'Admin');
      _snack('Metro update rejected', Colors.orangeAccent);
      _load();
    } catch (e) {
      _snack('❌ $e', Colors.redAccent);
    }
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
        title: const Text('Metro Updates',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _load,
          ),
        ],
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF0B2A3A), Color(0xFF06141E), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _metroReports.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: const Color(0xFF06B6D4),
                      backgroundColor: const Color(0xFF0B1730),
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        itemCount: _metroReports.length,
                        itemBuilder: (context, i) =>
                            _metroCard(_metroReports[i]),
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
                color: const Color(0xFF06B6D4).withOpacity(0.15),
                border: Border.all(
                    color: const Color(0xFF06B6D4).withOpacity(0.5),
                    width: 1.5),
              ),
              child: const Icon(Icons.subway_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'No metro updates yet',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Updates shared by users will appear here.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _metroCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Metro Update';
    final desc = data['description'] ?? '';
    final user = data['userName'] ?? 'User';
    final location = data['location'] ?? '—';
    final status = data['status'] ?? 'Pending';
    final imageUrl = data['imageUrl'];
    final createdAt = data['createdAt'];
    final dateStr = createdAt is Timestamp
        ? DateFormat('dd MMM yyyy • HH:mm').format(createdAt.toDate())
        : '';

    final statusColor = _statusColor(status);

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
                  const Color(0xFF06B6D4).withOpacity(0.10),
                ],
              ),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.25), width: 1.2),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF06B6D4).withOpacity(0.25),
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
                      child: Image.network(imageUrl,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                                color: Colors.white10,
                                child: const Icon(Icons.broken_image,
                                    color: Colors.white54),
                              )),
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
                              color: const Color(0xFF06B6D4).withOpacity(0.2),
                              border: Border.all(
                                  color:
                                      const Color(0xFF06B6D4).withOpacity(0.6),
                                  width: 1.2),
                            ),
                            child: const Icon(Icons.subway_rounded,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700),
                            ),
                          ),
                          _statusPill(status, statusColor),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'From: $user',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.6),
                            fontSize: 11.5),
                      ),
                      if (desc.toString().isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          desc,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                              color: Colors.white.withOpacity(0.85),
                              fontSize: 12.5,
                              height: 1.45),
                        ),
                      ],
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          const Icon(Icons.location_on,
                              color: Colors.redAccent, size: 14),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              location,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                  color: Colors.white70, fontSize: 11.5),
                            ),
                          ),
                          if (dateStr.isNotEmpty)
                            Text(dateStr,
                                style: TextStyle(
                                    color: Colors.white.withOpacity(0.5),
                                    fontSize: 10.5)),
                        ],
                      ),

                      // 👇 NEW: View Full Detail button
                      const SizedBox(height: 14),
                      SizedBox(
                        width: double.infinity,
                        height: 42,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => MetroUpdateDetailPage(
                                  docId: doc.id,
                                  data: data,
                                  onActionDone: _load,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.visibility_rounded, size: 18),
                          label: const Text(
                            'View Full Detail',
                            style: TextStyle(
                                fontWeight: FontWeight.w700, fontSize: 13),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.white,
                            side: BorderSide(
                                color: const Color(0xFF06B6D4)
                                    .withOpacity(0.65),
                                width: 1.3),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            backgroundColor:
                                const Color(0xFF06B6D4).withOpacity(0.08),
                          ),
                        ),
                      ),

                      if (status == 'Pending') ...[
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () => _reject(doc.id),
                                icon: const Icon(Icons.close_rounded, size: 16),
                                label: const Text('Reject'),
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.redAccent,
                                  side: const BorderSide(
                                      color: Colors.redAccent, width: 1.2),
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: ElevatedButton.icon(
                                onPressed: () => _approve(doc.id),
                                icon: const Icon(Icons.check_rounded, size: 16),
                                label: const Text('Approve'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: const Color(0xFF10B981),
                                  foregroundColor: Colors.white,
                                  padding:
                                      const EdgeInsets.symmetric(vertical: 12),
                                  shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(12)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
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

  Widget _statusPill(String status, Color color) => Container(
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
              letterSpacing: 0.5),
        ),
      );

  Color _statusColor(String status) {
    switch (status) {
      case 'Approved':
        return const Color(0xFF10B981);
      case 'Rejected':
        return const Color(0xFFEF4444);
      case 'Assigned':
        return const Color(0xFF3B82F6);
      case 'Completed':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}

// ============================================================
// 🆕 FULL DETAIL PAGE
// ============================================================
class MetroUpdateDetailPage extends StatelessWidget {
  final String docId;
  final Map<String, dynamic> data;
  final VoidCallback onActionDone;

  const MetroUpdateDetailPage({
    super.key,
    required this.docId,
    required this.data,
    required this.onActionDone,
  });

  @override
  Widget build(BuildContext context) {
    final title = data['title'] ?? 'Metro Update';
    final desc = data['description'] ?? '—';
    final user = data['userName'] ?? 'User';
    final userPhone = data['userPhone'] ?? '';
    final location = data['location'] ?? '—';
    final latitude = data['latitude'];
    final longitude = data['longitude'];
    final status = data['status'] ?? 'Pending';
    final imageUrl = data['imageUrl'];
    final adminReply = data['adminReply'];
    final createdAt = data['createdAt'];
    final dateStr = createdAt is Timestamp
        ? DateFormat('dd MMM yyyy • HH:mm').format(createdAt.toDate())
        : '';

    final statusColor = _statusColor(status);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Update Details',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [Color(0xFF0B2A3A), Color(0xFF06141E), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              // Image
              if (imageUrl != null && imageUrl.toString().isNotEmpty)
                ClipRRect(
                  borderRadius: BorderRadius.circular(22),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.white10,
                        child: const Icon(Icons.broken_image,
                            color: Colors.white54, size: 40),
                      ),
                    ),
                  ),
                ),

              const SizedBox(height: 20),

              // Title + Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  _pill(status, statusColor),
                ],
              ),

              const SizedBox(height: 6),

              // Category
              Row(
                children: [
                  const Icon(Icons.subway_rounded,
                      color: Color(0xFF06B6D4), size: 16),
                  const SizedBox(width: 6),
                  Text(
                    'Category: Metro',
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.7), fontSize: 12.5),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Description section
              _sectionHeader('Description', Icons.description_rounded),
              const SizedBox(height: 8),
              _glassBox(
                child: Text(
                  desc,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Reporter section
              _sectionHeader('Reporter', Icons.person_rounded),
              const SizedBox(height: 8),
              _glassBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    if (userPhone.toString().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        userPhone,
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.6),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Location section
              _sectionHeader('Location', Icons.location_on_rounded),
              const SizedBox(height: 8),
              _glassBox(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      location,
                      style: const TextStyle(
                          color: Colors.white, fontSize: 13.5),
                    ),
                    if (latitude != null && longitude != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Lat: $latitude   Lng: $longitude',
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.55),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Date section
              _sectionHeader('Submitted At', Icons.schedule_rounded),
              const SizedBox(height: 8),
              _glassBox(
                child: Text(
                  dateStr.isEmpty ? '—' : dateStr,
                  style: const TextStyle(color: Colors.white, fontSize: 13.5),
                ),
              ),

              // Admin reply (if any)
              if (adminReply != null && adminReply.toString().isNotEmpty) ...[
                const SizedBox(height: 16),
                _sectionHeader('Admin Reply', Icons.reply_rounded),
                const SizedBox(height: 8),
                _glassBox(
                  child: Text(
                    adminReply,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 13, height: 1.5),
                  ),
                ),
              ],

              const SizedBox(height: 28),

              // Approve / Reject buttons (only when pending)
              if (status == 'Pending')
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: OutlinedButton.icon(
                          onPressed: () async {
                            final fs = FirestoreService();
                            await fs.rejectReport(docId,
                                reason: 'Rejected by admin',
                                adminName: 'Admin');
                            onActionDone();
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.close_rounded, size: 18),
                          label: const Text('Reject'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.redAccent,
                            side: const BorderSide(
                                color: Colors.redAccent, width: 1.3),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 52,
                        child: ElevatedButton.icon(
                          onPressed: () async {
                            final fs = FirestoreService();
                            await fs.approveReport(docId, adminName: 'Admin');
                            onActionDone();
                            if (context.mounted) Navigator.pop(context);
                          },
                          icon: const Icon(Icons.check_rounded, size: 18),
                          label: const Text('Approve'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF10B981),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14)),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionHeader(String label, IconData icon) => Row(
        children: [
          Icon(icon, color: const Color(0xFF06B6D4), size: 16),
          const SizedBox(width: 8),
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: Color(0xFF06B6D4),
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.4,
            ),
          ),
        ],
      );

  Widget _glassBox({required Widget child}) => ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.06),
              borderRadius: BorderRadius.circular(16),
              border:
                  Border.all(color: Colors.white.withOpacity(0.15), width: 1),
            ),
            child: child,
          ),
        ),
      );

  Widget _pill(String text, Color color) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: color.withOpacity(0.18),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withOpacity(0.65), width: 1.1),
        ),
        child: Text(
          text,
          style: TextStyle(
              color: color,
              fontSize: 11,
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
      case 'Assigned':
        return const Color(0xFF3B82F6);
      case 'Completed':
        return const Color(0xFF22C55E);
      default:
        return const Color(0xFFF59E0B);
    }
  }
}