import 'dart:ui';
import 'package:flutter/material.dart';
import '../../widgets/glass_scaffold.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  @override
  Widget build(BuildContext context) {
    final faqs = const [
      _F('How do I file a report?',
          'Go to Home → Report Problem. Fill in the details, add a photo, and submit.'),
      _F('How long until my report is fixed?',
          'Most reports are assigned to a field worker within 24 hours. Complex issues may take 3–5 days.'),
      _F('Can I track my report?',
          'Yes. Open Home → My Reports to see live status (Pending, Assigned, In Progress, Completed).'),
      _F('How do I reach emergency services?',
          'Go to Home → Emergency SOS. Dial 112 for all emergencies.'),
      _F('Where can I see traffic alerts?',
          'Home screen shows live alerts at the top. Tap any news card for full details.'),
    ];

    return GlassScaffold(
      title: 'Help Center',
      accent: const Color(0xFF0EA5E9),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
        children: [
          Text(
            'FREQUENTLY ASKED',
            style: TextStyle(
              color: Colors.white.withOpacity(0.55),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.5,
            ),
          ),
          const SizedBox(height: 12),
          ...faqs.map(_card),
          const SizedBox(height: 20),
          // Contact
          ClipRRect(
            borderRadius: BorderRadius.circular(24),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.white.withOpacity(0.10),
                      const Color(0xFF0EA5E9).withOpacity(0.12),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: Colors.white.withOpacity(0.28),
                    width: 1.2,
                  ),
                ),
                child: const Column(
                  children: [
                    Icon(Icons.support_agent_rounded,
                        color: Color(0xFF0EA5E9), size: 40),
                    SizedBox(height: 12),
                    Text(
                      'Still need help?',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'support@roadfix.com  •  1800-XXX-XXXX',
                      style: TextStyle(color: Colors.white70, fontSize: 13),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _card(_F f) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Theme(
            data: ThemeData.dark().copyWith(
              dividerColor: Colors.transparent,
            ),
            child: ExpansionTile(
              collapsedBackgroundColor: Colors.transparent,
              backgroundColor: Colors.transparent,
              tilePadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              childrenPadding:
                  const EdgeInsets.fromLTRB(16, 0, 16, 16),
              iconColor: const Color(0xFF0EA5E9),
              collapsedIconColor: Colors.white70,
              title: Text(
                f.q,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
              children: [
                Text(
                  f.a,
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.80),
                    fontSize: 13.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _F {
  final String q;
  final String a;
  const _F(this.q, this.a);
}


