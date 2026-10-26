import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class LiveNewsFeed extends StatefulWidget {
  const LiveNewsFeed({super.key});

  @override
  State<LiveNewsFeed> createState() => _LiveNewsFeedState();
}

class _LiveNewsFeedState extends State<LiveNewsFeed> {
  bool _loading = true;
  List<Map<String, dynamic>> _feed = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      // 1. Fetch reports (accidents, traffic blocks, road works)
      final reportsSnap =
          await FirebaseFirestore.instance.collection('reports').get();
      // 2. Fetch alerts (emergencies, warnings)
      final alertsSnap =
          await FirebaseFirestore.instance.collection('alerts').get();

      final List<Map<String, dynamic>> allItems = [];

      // Convert reports into news items
      for (var doc in reportsSnap.docs) {
        final data = doc.data();
        final cat = data['category']?.toString().toLowerCase() ?? '';

        String emoji = '📰';
        String tag = 'NEWS';

        if (cat.contains('accident')) {
          emoji = '🚗';
          tag = 'ACCIDENT';
        } else if (cat.contains('traffic')) {
          emoji = '🚦';
          tag = 'TRAFFIC';
        } else if (cat.contains('road')) {
          emoji = '🚧';
          tag = 'ROAD WORK';
        }

        allItems.add({
          'title': data['title'] ?? 'Incident Reported',
          'message': data['description'] ?? data['location'] ?? '',
          'emoji': emoji,
          'tag': tag,
          'createdAt': data['createdAt'],
        });
      }

      // Convert alerts into news items
      for (var doc in alertsSnap.docs) {
        final data = doc.data();
        final severity = data['severity']?.toString().toLowerCase() ?? 'info';

        String emoji = '📢';
        if (severity == 'critical') emoji = '🚨';

        allItems.add({
          'title': data['title'] ?? 'Alert',
          'message': data['message'] ?? '',
          'emoji': emoji,
          'tag': severity.toUpperCase(),
          'createdAt': data['createdAt'],
        });
      }

      // Sort newest first
      allItems.sort((a, b) {
        final ta = a['createdAt'];
        final tb = b['createdAt'];
        if (ta is Timestamp && tb is Timestamp) return tb.compareTo(ta);
        return 0;
      });

      setState(() => _feed = allItems);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('❌ Failed to load live news: $e')),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(
          child: CircularProgressIndicator(color: Colors.white));
    }

    if (_feed.isEmpty) {
      return const Center(
        child: Text('No live news at the moment.',
            style: TextStyle(color: Colors.white54)),
      );
    }

    return RefreshIndicator(
      onRefresh: _load,
      color: const Color(0xFF06B6D4),
      backgroundColor: const Color(0xFF0B1730),
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: _feed.length,
        itemBuilder: (context, index) {
          final item = _feed[index];
          final createdAt = item['createdAt'];
          final dateStr = createdAt is Timestamp
              ? DateFormat('dd MMM yyyy • HH:mm')
                  .format(createdAt.toDate())
              : '';

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
                      const Color(0xFF06B6D4).withOpacity(0.08),
                    ]),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                        color: Colors.white.withOpacity(0.22), width: 1.2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(item['emoji'],
                              style: const TextStyle(fontSize: 26)),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(item['title'],
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFF06B6D4)
                                  .withOpacity(0.18),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFF06B6D4)
                                      .withOpacity(0.65),
                                  width: 1),
                            ),
                            child: Text(
                              item['tag'],
                              style: const TextStyle(
                                  color: Color(0xFF06B6D4),
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.4),
                            ),
                          ),
                        ],
                      ),
                      if (item['message'].toString().isNotEmpty) ...[
                        const SizedBox(height: 10),
                        Text(item['message'],
                            style: TextStyle(
                                color: Colors.white.withOpacity(0.8),
                                fontSize: 13,
                                height: 1.5),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
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
        },
      ),
    );
  }
}