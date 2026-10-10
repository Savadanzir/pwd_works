import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class EmergencyPage extends StatelessWidget {
  const EmergencyPage({super.key});

  /// Opens the phone dialer with the number pre-filled.
  Future<void> _call(BuildContext context, String rawNumber) async {
    // Clean up the number — keep only digits and leading +
    final cleaned = rawNumber.replaceAll(RegExp(r'[^\d+]'), '');

    if (cleaned.isEmpty) {
      _snack(context, 'Invalid number', error: true);
      return;
    }

    final uri = Uri(scheme: 'tel', path: cleaned);
    try {
      final launched = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );
      if (!launched && context.mounted) {
        _snack(context, 'Could not open dialer for $rawNumber',
            error: true);
      }
    } catch (e) {
      if (context.mounted) {
        _snack(context, 'Call error: $e', error: true);
      }
    }
  }

  void _snack(BuildContext context, String msg, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor:
            error ? const Color(0xFFB91C1C) : const Color(0xFF10B981),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final contacts = const [
      _EC('Police', '100', '🚓', Color(0xFF3B82F6)),
      _EC('Ambulance', '108', '🚑', Color(0xFFEF4444)),
      _EC('Fire Brigade', '101', '🚒', Color(0xFFF59E0B)),
      _EC('Road Accident Helpline', '1073', '🚗', Color(0xFFA855F7)),
      _EC('Women Helpline', '1091', '👩', Color(0xFFEC4899)),
      _EC('Emergency (All)', '112', '🚨', Color(0xFFDC2626)),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      appBar: AppBar(
        title: const Text('Emergency SOS'),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [
              Color(0xFF3A0B0B),
              Color(0xFF10060A),
              Color(0xFF04060F),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
          children: [
            // ------- Big SOS button -------
            GestureDetector(
              onTap: () => _call(context, '112'),
              child: Container(
                height: 120,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(28),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFDC2626).withOpacity(0.65),
                      blurRadius: 40,
                      offset: const Offset(0, 16),
                    ),
                  ],
                ),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.sos_rounded,
                          color: Colors.white, size: 42),
                      SizedBox(height: 8),
                      Text(
                        'SOS — Tap to Call 112',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 1.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            const SizedBox(height: 22),

            // ------- Section label -------
            Text(
              'QUICK DIAL',
              style: TextStyle(
                color: Colors.white.withOpacity(0.55),
                fontSize: 11,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 12),

            // ------- Emergency cards -------
            ...contacts.map((c) => _card(context, c)),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, _EC c) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 14, sigmaY: 14),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Colors.white.withOpacity(0.10),
                  c.color.withOpacity(0.10),
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
                // Emoji badge
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: c.color.withOpacity(0.20),
                    border: Border.all(
                      color: c.color.withOpacity(0.55),
                      width: 1.2,
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: c.color.withOpacity(0.45),
                        blurRadius: 14,
                      ),
                    ],
                  ),
                  child: Text(c.emoji,
                      style: const TextStyle(fontSize: 20)),
                ),
                const SizedBox(width: 14),

                // Name + number
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        c.number,
                        style: TextStyle(
                          color: c.color,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),

                // ------- Tap-to-call button -------
                GestureDetector(
                  onTap: () => _call(context, c.number),
                  child: MouseRegion(
                    cursor: SystemMouseCursors.click,
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [c.color, c.color.withOpacity(0.65)],
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: c.color.withOpacity(0.55),
                            blurRadius: 14,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.call_rounded,
                          color: Colors.white, size: 18),
                    ),
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

class _EC {
  final String name;
  final String number;
  final String emoji;
  final Color color;
  const _EC(this.name, this.number, this.emoji, this.color);
}