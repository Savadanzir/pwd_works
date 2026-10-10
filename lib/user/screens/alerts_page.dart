import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/glass_scaffold.dart';

class AlertsPage extends StatelessWidget {
  const AlertsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final alerts = const [
      _Alert('Traffic block near Silk Board',
          'Signal failure. Expect 15 min delay.', '🚨',
          Color(0xFFEF4444), '2 min ago', true),
      _Alert('Road closed — MG Road',
          'Emergency repair. Use Brigade Road.', '⛔',
          Color(0xFFEF4444), '18 min ago', true),
      _Alert('Your report was assigned',
          'A field worker is on the way.', '✅',
          Color(0xFF10B981), '25 min ago', true),
      _Alert('Metro Line 3 resumed',
          'Normal service after maintenance.', '🚇',
          Color(0xFF3B82F6), '1 hour ago', false),
      _Alert('Heavy rain warning',
          'Avoid ORR tonight. Helpline: 1077.', '🌧️',
          Color(0xFF06B6D4), '2 days ago', false),
    ];

    return GlassScaffold(
      title: 'Alerts',
      accent: const Color(0xFFE11D48),
      body: ListView.separated(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        itemCount: alerts.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, i) => _card(alerts[i]),
      ),
    );
  }

  Widget _card(_Alert a) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(a.unread ? 0.10 : 0.06),
                a.color.withOpacity(a.unread ? 0.14 : 0.06),
              ],
            ),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: Colors.white.withOpacity(a.unread ? 0.35 : 0.18),
              width: 1.2,
            ),
            boxShadow: a.unread
                ? [
                    BoxShadow(
                      color: a.color.withOpacity(0.35),
                      blurRadius: 22,
                      offset: const Offset(0, 8),
                    ),
                  ]
                : null,
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: a.color.withOpacity(0.20),
                  border: Border.all(
                      color: a.color.withOpacity(0.55), width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: a.color.withOpacity(0.45),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Text(a.emoji, style: const TextStyle(fontSize: 20)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            a.title,
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 14.5,
                              fontWeight: a.unread
                                  ? FontWeight.w700
                                  : FontWeight.w600,
                            ),
                          ),
                        ),
                        if (a.unread)
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: a.color,
                              boxShadow: [
                                BoxShadow(
                                  color: a.color.withOpacity(0.9),
                                  blurRadius: 10,
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      a.body,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.75),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      a.time,
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 11,
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

class _Alert {
  final String title;
  final String body;
  final String emoji;
  final Color color;
  final String time;
  final bool unread;
  const _Alert(this.title, this.body, this.emoji, this.color, this.time,
      this.unread);
}