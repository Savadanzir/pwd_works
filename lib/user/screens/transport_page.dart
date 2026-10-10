import 'dart:async';
import 'dart:ui';
import 'package:flutter/material.dart';

class TransportPage extends StatefulWidget {
  const TransportPage({super.key});
  @override
  State<TransportPage> createState() => _TransportPageState();
}

class _TransportPageState extends State<TransportPage> {
  // Each transport option has a set of live "arrivals"
  final List<_Transport> _transports = [
    _Transport(
      name: 'Metro — Purple Line',
      emoji: '🚇',
      color: const Color(0xFF8B5CF6),
      subtitle: 'Every 5 min',
      routes: [
        _Arrival('KSRTC → Aluva', 'M1', 2, 'Platform 1'),
        _Arrival('KSRTC → Aluva', 'M1', 7, 'Platform 1'),
        _Arrival('KSRTC → Aluva', 'M1', 12, 'Platform 1'),
      ],
      fare: '₹15 – ₹40',
    ),
    _Transport(
      name: 'BMTC Bus 500C',
      emoji: '🚌',
      color: const Color(0xFF22C55E),
      subtitle: 'Every 10 min',
      routes: [
        _Arrival('Central → Airport', '500C', 3, 'Bus Stop 4'),
        _Arrival('Central → Airport', '500C', 13, 'Bus Stop 4'),
        _Arrival('Central → Airport', '500C', 23, 'Bus Stop 4'),
      ],
      fare: '₹20 – ₹65',
    ),
    _Transport(
      name: 'Auto Rickshaw',
      emoji: '🛺',
      color: const Color(0xFFF59E0B),
      subtitle: 'Available',
      routes: [
        _Arrival('Nearest auto', '—', 1, '50m away'),
        _Arrival('Next auto', '—', 3, '200m away'),
      ],
      fare: '₹30 base + ₹15/km',
    ),
    _Transport(
      name: 'Bike Taxi',
      emoji: '🏍️',
      color: const Color(0xFF06B6D4),
      subtitle: '2 min away',
      routes: [
        _Arrival('Rider: Arjun', '—', 2, '1.2 km away'),
        _Arrival('Rider: Vishal', '—', 4, '2.1 km away'),
      ],
      fare: '₹25 base + ₹8/km',
    ),
    _Transport(
      name: 'Cab — Uber / Ola',
      emoji: '🚗',
      color: const Color(0xFF3B82F6),
      subtitle: '3 min away',
      routes: [
        _Arrival('Mini — Swift Dzire', 'KA-01-AB-1234', 3, '850m away'),
        _Arrival('Prime — Honda City', 'KA-05-CD-5678', 5, '1.4 km away'),
        _Arrival('Sedan — Hyundai Aura', 'KA-03-EF-9012', 8, '2.3 km away'),
      ],
      fare: '₹50 base + ₹12/km',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Public Transport',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(-0.4, -0.6),
            radius: 1.5,
            colors: [
              Color(0xFF062A1E),
              Color(0xFF04140F),
              Color(0xFF04060F),
            ],
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: SafeArea(
          bottom: false,
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 40),
            children: [
              Text(
                'NEARBY — TAP FOR LIVE TIMING',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.55),
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              const SizedBox(height: 12),
              ..._transports.map(_card),
            ],
          ),
        ),
      ),
    );
  }

  Widget _card(_Transport t) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => _showLiveSheet(t),
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
                    t.color.withOpacity(0.10),
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
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: t.color.withOpacity(0.20),
                      border: Border.all(
                          color: t.color.withOpacity(0.55), width: 1.2),
                    ),
                    child:
                        Text(t.emoji, style: const TextStyle(fontSize: 22)),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          t.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          t.subtitle,
                          style: TextStyle(
                            color: t.color,
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: Colors.white.withOpacity(0.45),
                    size: 22,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ------------------------------------------------------------
  // 🎯 Live timing sheet
  // ------------------------------------------------------------
  void _showLiveSheet(_Transport t) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (_) => _LiveTimingSheet(transport: t),
    );
  }
}

// ============================================================
// Data models
// ============================================================
class _Transport {
  final String name;
  final String emoji;
  final Color color;
  final String subtitle;
  final List<_Arrival> routes;
  final String fare;
  const _Transport({
    required this.name,
    required this.emoji,
    required this.color,
    required this.subtitle,
    required this.routes,
    required this.fare,
  });
}

class _Arrival {
  final String destination;
  final String vehicleNo; // bus number, metro ID, plate
  final int minutesAway;
  final String platform; // bus stop / platform / rider info
  const _Arrival(
      this.destination, this.vehicleNo, this.minutesAway, this.platform);
}

// ============================================================
// 📋 Live timing bottom sheet
// ============================================================
class _LiveTimingSheet extends StatefulWidget {
  final _Transport transport;
  const _LiveTimingSheet({required this.transport});

  @override
  State<_LiveTimingSheet> createState() => _LiveTimingSheetState();
}

class _LiveTimingSheetState extends State<_LiveTimingSheet> {
  Timer? _timer;
  int _tick = 0; // advances every second

  @override
  void initState() {
    super.initState();
    // Tick every second so countdown updates smoothly
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (mounted) setState(() => _tick++);
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  /// Live countdown — starts at `minutesAway * 60` seconds and decreases.
  /// When it hits 0, it resets to 15 min (so the demo keeps showing).
  int _liveSeconds(_Arrival a, int index) {
    // Stagger each arrival by an offset so they're not all zero together
    final offset = index * 37;
    final initial = a.minutesAway * 60;
    final cycle = 15 * 60; // 15 minutes
    final raw = (initial - _tick - offset);
    final positive = ((raw % cycle) + cycle) % cycle;
    return positive;
  }

  String _formatTime(int seconds) {
    final m = seconds ~/ 60;
    final s = seconds % 60;
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.transport;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Color(0xFF0B1024),
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.white24,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
          const SizedBox(height: 14),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    color: t.color.withOpacity(0.20),
                    border: Border.all(
                        color: t.color.withOpacity(0.55), width: 1.2),
                  ),
                  child: Text(t.emoji,
                      style: const TextStyle(fontSize: 26)),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        t.name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Row(
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: const Color(0xFF22C55E),
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF22C55E)
                                      .withOpacity(0.8),
                                  blurRadius: 8,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Live',
                            style: TextStyle(
                              color: Color(0xFF22C55E),
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '• ${t.subtitle}',
                            style: TextStyle(
                              color: Colors.white.withOpacity(0.6),
                              fontSize: 11.5,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded,
                      color: Colors.white70),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Fare chip
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              decoration: BoxDecoration(
                color: t.color.withOpacity(0.10),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: t.color.withOpacity(0.35),
                  width: 1.1,
                ),
              ),
              child: Row(
                children: [
                  Icon(Icons.currency_rupee_rounded,
                      color: t.color, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    'Fare: ${t.fare}',
                    style: TextStyle(
                      color: t.color,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'Auto-refreshing',
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.55),
                      fontSize: 11,
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Text(
                  'NEXT ARRIVALS',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.55),
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const Spacer(),
                Text(
                  'Updated just now',
                  style: TextStyle(
                    color: Colors.white.withOpacity(0.4),
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 10),

          // Arrivals list
          Flexible(
            child: ListView.builder(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              shrinkWrap: true,
              itemCount: t.routes.length,
              itemBuilder: (context, i) {
                final a = t.routes[i];
                return _arrivalCard(t, a, i);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _arrivalCard(_Transport t, _Arrival a, int index) {
    final seconds = _liveSeconds(a, index);
    final isSoon = seconds < 120; // less than 2 min away

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.white.withOpacity(0.06),
                  t.color.withOpacity(isSoon ? 0.16 : 0.08),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(
                color: isSoon
                    ? t.color.withOpacity(0.65)
                    : Colors.white.withOpacity(0.20),
                width: 1.2,
              ),
              boxShadow: isSoon
                  ? [
                      BoxShadow(
                        color: t.color.withOpacity(0.35),
                        blurRadius: 18,
                        offset: const Offset(0, 6),
                      ),
                    ]
                  : null,
            ),
            child: Row(
              children: [
                // Countdown circle
                SizedBox(
                  width: 62,
                  height: 62,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CircularProgressIndicator(
                        value: 1 - (seconds / (15 * 60)),
                        strokeWidth: 4,
                        backgroundColor: Colors.white.withOpacity(0.10),
                        valueColor:
                            AlwaysStoppedAnimation<Color>(t.color),
                      ),
                      Text(
                        _formatTime(seconds),
                        style: TextStyle(
                          color: isSoon ? t.color : Colors.white,
                          fontSize: 12.5,
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 14),

                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        a.destination,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          if (a.vehicleNo != '—') ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: t.color.withOpacity(0.20),
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(
                                  color: t.color.withOpacity(0.55),
                                  width: 1,
                                ),
                              ),
                              child: Text(
                                a.vehicleNo,
                                style: TextStyle(
                                  color: t.color,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 0.6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Expanded(
                            child: Text(
                              a.platform,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                color: Colors.white.withOpacity(0.65),
                                fontSize: 11.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                // Soon indicator
                if (isSoon)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: t.color.withOpacity(0.20),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: t.color.withOpacity(0.65),
                        width: 1,
                      ),
                    ),
                    child: Text(
                      'ARRIVING',
                      style: TextStyle(
                        color: t.color,
                        fontSize: 9,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1,
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