import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/notifications_provider.dart';

class NotificationsPage extends StatelessWidget {
  const NotificationsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<NotificationsProvider>(context);
    final notes = prov.notes;

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text('Notifications',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
              center: Alignment(-0.4, -0.6),
              radius: 1.5,
              colors: [Color(0xFF1E0E3A), Color(0xFF0D061A), Color(0xFF04060F)],
              stops: [0.0, 0.55, 1.0]),
        ),
        child: SafeArea(
          child: ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            itemCount: notes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _card(notes[i]),
          ),
        ),
      ),
    );
  }

  Widget _card(NotificationItem n) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(20),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
              gradient: LinearGradient(colors: [
                Colors.white.withOpacity(n.unread ? 0.12 : 0.06),
                n.color.withOpacity(n.unread ? 0.14 : 0.06)
              ]),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                  color: Colors.white.withOpacity(n.unread ? 0.35 : 0.18),
                  width: 1.2),
              boxShadow: n.unread
                  ? [
                      BoxShadow(
                          color: n.color.withOpacity(0.35),
                          blurRadius: 22,
                          offset: const Offset(0, 8))
                    ]
                  : null),
          child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: n.color.withOpacity(0.20),
                    border: Border.all(
                        color: n.color.withOpacity(0.55), width: 1.2)),
                child: Text(n.emoji, style: const TextStyle(fontSize: 18))),
            const SizedBox(width: 14),
            Expanded(
                child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                  Row(children: [
                    Expanded(
                        child: Text(n.title,
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 14,
                                fontWeight: n.unread
                                    ? FontWeight.w800
                                    : FontWeight.w600))),
                    if (n.unread)
                      Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: n.color,
                              boxShadow: [
                                BoxShadow(
                                    color: n.color.withOpacity(0.9),
                                    blurRadius: 10)
                              ])),
                  ]),
                  const SizedBox(height: 4),
                  Text(n.body,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.75),
                          fontSize: 12.5,
                          height: 1.4)),
                  const SizedBox(height: 6),
                  Text(n.time,
                      style: TextStyle(
                          color: Colors.white.withOpacity(0.5), fontSize: 11)),
                ])),
          ]),
        ),
      ),
    );
  }
}
