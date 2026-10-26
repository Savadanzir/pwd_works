import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/firestore_service.dart';

class AdminTrafficBlocks extends StatefulWidget {
  const AdminTrafficBlocks({super.key});

  @override
  State<AdminTrafficBlocks> createState() => _AdminTrafficBlocksState();
}

class _AdminTrafficBlocksState extends State<AdminTrafficBlocks> {
  bool _loading = true;
  List<QueryDocumentSnapshot> _blocks = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final all = await FirestoreService().getAllReports();
      final blocks = all.where((d) {
        final data = d.data() as Map<String, dynamic>;
        final cat = (data['category'] ?? '').toString();
        return cat == 'Traffic Block';
      }).toList();

      blocks.sort((a, b) {
        final ta = (a.data() as Map)['createdAt'];
        final tb = (b.data() as Map)['createdAt'];
        if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
        return 0;
      });

      setState(() => _blocks = blocks);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Traffic Blocks',
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
            colors: [Color(0xFF3A0A18), Color(0xFF16040A), Color(0xFF04060F)],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          child: _loading
              ? const Center(
                  child: CircularProgressIndicator(color: Colors.white))
              : _blocks.isEmpty
                  ? _emptyState()
                  : RefreshIndicator(
                      color: const Color(0xFFEF4444),
                      backgroundColor: const Color(0xFF0B1730),
                      onRefresh: _load,
                      child: ListView.builder(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
                        itemCount: _blocks.length,
                        itemBuilder: (context, i) => _blockCard(_blocks[i]),
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
              child: const Icon(Icons.traffic_rounded,
                  color: Colors.white, size: 40),
            ),
            const SizedBox(height: 18),
            const Text(
              'No traffic blocks reported',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 15,
                  fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 6),
            Text(
              'Traffic blocks from users and employees will appear here.',
              style: TextStyle(
                  color: Colors.white.withOpacity(0.55), fontSize: 12.5),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _blockCard(QueryDocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    final title = data['title'] ?? 'Traffic Block';
    final desc = data['description'] ?? '';
    final location = data['location'] ?? '—';
    final status = data['status'] ?? 'Approved';
    final reporter = data['userName'] ?? 'User';
    final isEmployee = (data['reportedBy'] ?? '') == 'employee';
    final district = data['district'] ?? '';
    final imageUrl = data['imageUrl'];
    final createdAt = data['createdAt'];
    final dateStr = createdAt is Timestamp
        ? DateFormat('dd MMM yyyy • HH:mm').format(createdAt.toDate())
        : '';

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(22),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(0.10),
                const Color(0xFFEF4444).withOpacity(0.08),
              ]),
              borderRadius: BorderRadius.circular(22),
              border:
                  Border.all(color: Colors.white.withOpacity(0.22), width: 1.2),
              boxShadow: [
                BoxShadow(
                    color: const Color(0xFFEF4444).withOpacity(0.25),
                    blurRadius: 20,
                    offset: const Offset(0, 8)),
              ],
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
                        color: const Color(0xFFEF4444).withOpacity(0.20),
                        border: Border.all(
                            color: const Color(0xFFEF4444).withOpacity(0.6),
                            width: 1.2),
                      ),
                      child: const Icon(Icons.traffic_rounded,
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
                    _pill(status),
                  ],
                ),
                if (desc.toString().isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Text(
                    desc,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12.5,
                        height: 1.4),
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
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      isEmployee
                          ? Icons.engineering_rounded
                          : Icons.person_rounded,
                      color: isEmployee
                          ? const Color(0xFFF59E0B)
                          : const Color(0xFF3B82F6),
                      size: 14,
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        'Reported by $reporter${isEmployee ? " (Employee)" : ""}${district.isNotEmpty ? " • $district" : ""}',
                        style: TextStyle(
                            color: Colors.white.withOpacity(0.7),
                            fontSize: 11.5),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                if (imageUrl != null && imageUrl.toString().isNotEmpty) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(14),
                    child: AspectRatio(
                      aspectRatio: 16 / 10,
                      child: Image.network(
                        imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => Container(
                          color: Colors.white10,
                          child: const Icon(Icons.broken_image,
                              color: Colors.white54, size: 32),
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _pill(String status) {
    final color = status == 'Rejected'
        ? const Color(0xFFEF4444)
        : status == 'Completed' || status == 'Verified'
            ? const Color(0xFF10B981)
            : const Color(0xFFF59E0B);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.18),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.65), width: 1),
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
  }
}