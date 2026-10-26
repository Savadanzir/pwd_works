import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:road_maintenance/user/providers/best_route_provider.dart';

class BestRoute extends StatefulWidget {
  const BestRoute({super.key});
  @override
  State<BestRoute> createState() => _BestRouteState();
}

class _BestRouteState extends State<BestRoute> with TickerProviderStateMixin {
  final _fromPlace = TextEditingController();
  final _toPlace = TextEditingController();
  final _fromFocus = FocusNode();
  final _toFocus = FocusNode();
  final MapController _map = MapController();

  String _fromDistrict = 'Kozhikode';
  String _toDistrict = 'Kozhikode';

  List<String> _fromSuggestions = [];
  List<String> _toSuggestions = [];

  static const List<String> _districts = [
    'Alappuzha', 'Ernakulam', 'Idukki', 'Kannur', 'Kasaragod',
    'Kollam', 'Kottayam', 'Kozhikode', 'Malappuram', 'Palakkad',
    'Pathanamthitta', 'Thiruvananthapuram', 'Thrissur', 'Wayanad',
  ];

  // 📍 Local coordinate database — no geocoding needed
  static const Map<String, Map<String, List<double>>> _placesByDistrict = {
    'Alappuzha': {
      'Alappuzha Beach': [9.4981, 76.3388],
      'Alappuzha Town': [9.4981, 76.3388],
      'Ambalapuzha': [9.3917, 76.3911],
      'Cherthala': [9.6850, 76.3333],
      'Kayamkulam': [9.1725, 76.5000],
      'Kuttanad': [9.4167, 76.4500],
      'Mavelikara': [9.2417, 76.5333],
      'Thakazhi': [9.3833, 76.4000],
    },
    'Ernakulam': {
      'Aluva': [10.1004, 76.3570],
      'Angamaly': [10.2000, 76.4000],
      'Edappally': [10.0264, 76.3086],
      'Fort Kochi': [9.9658, 76.2425],
      'Kakkanad': [10.0159, 76.3419],
      'Kaloor': [9.9975, 76.2910],
      'Kochi': [9.9312, 76.2673],
      'Kothamangalam': [10.0700, 76.6200],
      'Marine Drive': [9.9775, 76.2795],
      'Muvattupuzha': [9.9827, 76.5817],
      'North Paravur': [10.1442, 76.2297],
      'Palarivattom': [10.0039, 76.3079],
      'Perumbavoor': [10.1122, 76.4783],
      'Thevara': [9.9481, 76.2889],
      'Vyttila': [9.9677, 76.3205],
      'Tripunithura': [9.9470, 76.3492],
      'Infopark': [10.0075, 76.3619],
      'Kalady': [10.1748, 76.4424],
      'Cherai Beach': [10.1419, 76.1760],
    },
    'Idukki': {
      'Adimali': [10.0167, 76.9500],
      'Devikulam': [10.0500, 77.1000],
      'Idukki Town': [9.8500, 76.9667],
      'Kattappana': [9.7558, 77.1112],
      'Kumily': [9.6000, 77.1667],
      'Munnar': [10.0889, 77.0595],
      'Peermade': [9.5667, 76.9833],
      'Thekkady': [9.6033, 77.1617],
      'Vagamon': [9.6833, 76.8833],
      'Thodupuzha': [9.8948, 76.7178],
    },
    'Kannur': {
      'Kannur City': [11.8745, 75.3704],
      'Payyanur': [12.1000, 75.2000],
      'Thalassery': [11.7500, 75.4833],
      'Kannur Beach': [11.8600, 75.3600],
      'Mattannur': [11.9333, 75.5833],
      'Panoor': [11.7500, 75.5833],
      'Koothuparamba': [11.8167, 75.5833],
      'Iritty': [11.9833, 75.6667],
      'Taliparamba': [12.0500, 75.3500],
      'Sreekandapuram': [12.0333, 75.4333],
    },
    'Kasaragod': {
      'Kasaragod Town': [12.5000, 74.9833],
      'Kanhangad': [12.3167, 75.0833],
      'Bekal': [12.3833, 75.0333],
      'Cheruvathur': [12.2667, 75.1667],
      'Hosdurg': [12.3167, 75.1000],
      'Kumbla': [12.5833, 74.9500],
      'Manjeshwar': [12.7167, 74.8833],
      'Nileshwar': [12.2667, 75.1333],
      'Uppala': [12.6667, 74.9500],
    },
    'Kollam': {
      'Kollam City': [8.8800, 76.6000],
      'Karunagapally': [9.0500, 76.5333],
      'Kottarakkara': [8.9833, 76.7833],
      'Punalur': [9.0167, 76.9333],
      'Chathannoor': [8.8167, 76.6833],
      'Kundara': [8.9333, 76.6833],
      'Sasthamkotta': [9.0333, 76.6167],
      'Paravur': [8.8167, 76.6667],
      'Chavara': [8.9667, 76.5500],
      'Kilikollur': [8.8833, 76.6167],
    },
    'Kottayam': {
      'Kottayam Town': [9.5916, 76.5222],
      'Changanassery': [9.4500, 76.5500],
      'Ettumanoor': [9.6667, 76.5667],
      'Kanjirappally': [9.5500, 76.7833],
      'Pala': [9.7167, 76.6833],
      'Ponkunnam': [9.5833, 76.7500],
      'Vaikom': [9.7500, 76.4000],
      'Kumarakom': [9.6167, 76.4333],
      'Thiruvalla': [9.3833, 76.5667],
      'Mundakayam': [9.5333, 76.8833],
    },
    'Kozhikode': {
      'Kozhikode Beach': [11.2588, 75.7804],
      'Mavoor Road': [11.2600, 75.8000],
      'Nadakkavu': [11.2750, 75.7833],
      'Feroke': [11.1667, 75.8333],
      'Koyilandy': [11.4333, 75.7000],
      'Mukkom': [11.3833, 75.7500],
      'Ramanattukara': [11.1833, 75.8500],
      'Thamarassery': [11.4167, 75.9333],
      'Vatakara': [11.6000, 75.5833],
      'Medical College': [11.2700, 75.8400],
      'Kallai': [11.2333, 75.7833],
      'Chaliyam': [11.1500, 75.8167],
      'Beypore': [11.1667, 75.8000],
    },
    'Malappuram': {
      'Manjeri': [11.1167, 76.1167],
      'Nilambur': [11.2833, 76.2500],
      'Perinthalmanna': [10.9667, 76.2167],
      'Ponnani': [10.7833, 75.9167],
      'Tirur': [10.9000, 75.9167],
      'Tirurangadi': [11.0333, 75.9333],
      'Kottakkal': [11.0000, 76.0000],
      'Malappuram Town': [11.0500, 76.0833],
      'Kondotty': [11.1500, 75.9667],
      'Kottappuram': [11.0833, 76.0500],
      'Valanchery': [10.8833, 76.0833],
      'Angadipuram': [10.9833, 76.2000],
      'Wandoor': [11.2000, 76.2500],
    },
    'Palakkad': {
      'Palakkad Town': [10.7867, 76.6548],
      'Ottapalam': [10.7667, 76.3833],
      'Chittur': [10.7000, 76.7333],
      'Mannarkkad': [10.9833, 76.4667],
      'Shoranur': [10.7667, 76.2833],
      'Alathur': [10.6500, 76.5500],
      'Pattambi': [10.8000, 76.1833],
      'Kollengode': [10.6167, 76.7000],
      'Nemmara': [10.5833, 76.5833],
      'Silent Valley': [11.1000, 76.4500],
    },
    'Pathanamthitta': {
      'Pathanamthitta Town': [9.2648, 76.7870],
      'Adoor': [9.1500, 76.7333],
      'Kozhencherry': [9.3333, 76.7000],
      'Ranni': [9.3833, 76.7833],
      'Thiruvalla': [9.3833, 76.5667],
      'Mallapally': [9.4500, 76.6667],
      'Pandalam': [9.2167, 76.6833],
      'Konni': [9.2333, 76.8500],
      'Kumbanad': [9.3667, 76.6167],
    },
    'Thiruvananthapuram': {
      'Thiruvananthapuram City': [8.5241, 76.9366],
      'Kovalam': [8.4000, 76.9833],
      'Varkala': [8.7333, 76.7167],
      'Neyyattinkara': [8.4000, 77.0833],
      'Attingal': [8.6833, 76.8167],
      'Kazhakkoottam': [8.5667, 76.8667],
      'Technopark': [8.5567, 76.8794],
      'Shanghumugham': [8.4833, 76.9167],
      'Padmanabhaswamy Temple': [8.4828, 76.9436],
      'Nedumangad': [8.6000, 77.0000],
      'Balaramapuram': [8.4333, 77.0333],
    },
    'Thrissur': {
      'Thrissur City': [10.5276, 76.2144],
      'Chalakudy': [10.3000, 76.3333],
      'Guruvayur': [10.6000, 76.0333],
      'Irinjalakuda': [10.3333, 76.2167],
      'Kodungallur': [10.2333, 76.2000],
      'Kunnamkulam': [10.6500, 76.0667],
      'Wadakkanchery': [10.6333, 76.2333],
      'Athirappilly': [10.2833, 76.5667],
      'Vadakkunnathan Temple': [10.5275, 76.2142],
      'Ollur': [10.4833, 76.2333],
      'Pudukkad': [10.4167, 76.2667],
    },
    'Wayanad': {
      'Kalpetta': [11.6089, 76.0836],
      'Sulthan Bathery': [11.6667, 76.2833],
      'Mananthavady': [11.8000, 76.0000],
      'Vythiri': [11.5500, 76.0500],
      'Meppadi': [11.5333, 76.1333],
      'Lakkidi': [11.5167, 76.0333],
      'Ambalavayal': [11.6167, 76.2167],
      'Thirunelli': [11.8833, 75.9833],
      'Kuruva Island': [11.8167, 76.1333],
    },
  };

  late AnimationController _bgCtrl;
  late AnimationController _orbCtrl;
  late Animation<double> _bgAnim;
  late Animation<double> _orbAnim;
  Offset _parallax = Offset.zero;

  @override
  void initState() {
    super.initState();
    _bgCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 10))
          ..repeat(reverse: true);
    _bgAnim = CurvedAnimation(parent: _bgCtrl, curve: Curves.easeInOut);

    _orbCtrl =
        AnimationController(vsync: this, duration: const Duration(seconds: 14))
          ..repeat(reverse: true);
    _orbAnim = CurvedAnimation(parent: _orbCtrl, curve: Curves.easeInOut);

    _fromPlace.addListener(_updateFromSuggestions);
    _toPlace.addListener(_updateToSuggestions);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      Provider.of<BestRouteProvider>(context, listen: false).initUserLocation();
    });
  }

  @override
  void dispose() {
    _fromPlace.removeListener(_updateFromSuggestions);
    _toPlace.removeListener(_updateToSuggestions);
    _bgCtrl.dispose();
    _orbCtrl.dispose();
    _fromPlace.dispose();
    _toPlace.dispose();
    _fromFocus.dispose();
    _toFocus.dispose();
    super.dispose();
  }

  void _onHover(PointerEvent e, Size size) {
    final dx = (e.localPosition.dx / size.width - 0.5) * 2;
    final dy = (e.localPosition.dy / size.height - 0.5) * 2;
    setState(() => _parallax = Offset(dx, dy));
  }

  // ---------------- Suggestions ----------------
  void _updateFromSuggestions() => _updateSuggestions(
      _fromPlace.text, _fromDistrict,
      (l) => setState(() => _fromSuggestions = l));

  void _updateToSuggestions() => _updateSuggestions(
      _toPlace.text, _toDistrict,
      (l) => setState(() => _toSuggestions = l));

  void _updateSuggestions(
      String query, String district, Function(List<String>) setter) {
    final places = _placesByDistrict[district]?.keys.toList() ?? <String>[];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) {
      setter(places.take(6).toList());
      return;
    }
    setter(places
        .where((p) => p.toLowerCase().contains(q))
        .take(6)
        .toList());
  }

  // ---------------- Fit bounds ----------------
  void _fitBounds(List<LatLng> points) {
    if (points.isEmpty) return;
    double minLat = points.first.latitude, maxLat = points.first.latitude;
    double minLng = points.first.longitude, maxLng = points.first.longitude;
    for (final p in points) {
      minLat = p.latitude < minLat ? p.latitude : minLat;
      maxLat = p.latitude > maxLat ? p.latitude : maxLat;
      minLng = p.longitude < minLng ? p.longitude : minLng;
      maxLng = p.longitude > maxLng ? p.longitude : maxLng;
    }
    _map.fitCamera(
      CameraFit.bounds(
        bounds: LatLngBounds(LatLng(minLat, minLng), LatLng(maxLat, maxLng)),
        padding: const EdgeInsets.all(60),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prov = Provider.of<BestRouteProvider>(context);

    return Scaffold(
      backgroundColor: const Color(0xFF04060F),
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
        title: const Text(
          'Best Route',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, c) {
          final size = Size(c.maxWidth, c.maxHeight);
          return MouseRegion(
            onHover: (e) => _onHover(e, size),
            child: AnimatedBuilder(
              animation: Listenable.merge([_bgAnim, _orbAnim]),
              builder: (context, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    _gradientBase(),
                    _orbs(size),
                    SafeArea(
                      bottom: false,
                      child: Column(
                        children: [
                          _inputSection(prov),
                          Expanded(child: _mapSection(prov)),
                        ],
                      ),
                    ),
                  ],
                );
              },
            ),
          );
        },
      ),
    );
  }

  // ---------------- Input section ----------------
  Widget _inputSection(BestRouteProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  const Color(0xFF1B2B54).withOpacity(0.55),
                  const Color(0xFF0C1730).withOpacity(0.45),
                ],
              ),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: Colors.white.withOpacity(0.25),
                width: 1.2,
              ),
            ),
            child: Column(
              children: [
                _locationBlock(
                  icon: Icons.trip_origin_rounded,
                  accent: const Color(0xFF10B981),
                  label: 'From',
                  district: _fromDistrict,
                  onDistrictChange: (v) {
                    setState(() {
                      _fromDistrict = v;
                      _fromPlace.clear();
                      _fromSuggestions = [];
                    });
                    _updateFromSuggestions();
                  },
                  placeCtrl: _fromPlace,
                  focusNode: _fromFocus,
                  suggestions: _fromSuggestions,
                  onSuggestionTap: (s) {
                    setState(() {
                      _fromPlace.text = s;
                      _fromSuggestions = [];
                    });
                    FocusScope.of(context).unfocus();
                  },
                ),
                const SizedBox(height: 12),
                _locationBlock(
                  icon: Icons.location_on_rounded,
                  accent: const Color(0xFFEF4444),
                  label: 'To',
                  district: _toDistrict,
                  onDistrictChange: (v) {
                    setState(() {
                      _toDistrict = v;
                      _toPlace.clear();
                      _toSuggestions = [];
                    });
                    _updateToSuggestions();
                  },
                  placeCtrl: _toPlace,
                  focusNode: _toFocus,
                  suggestions: _toSuggestions,
                  onSuggestionTap: (s) {
                    setState(() {
                      _toPlace.text = s;
                      _toSuggestions = [];
                    });
                    FocusScope.of(context).unfocus();
                  },
                ),
                const SizedBox(height: 14),
                SizedBox(
                  width: double.infinity,
                  height: 54,
                  child: ElevatedButton.icon(
                    icon: prov.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          )
                        : const Icon(Icons.alt_route_rounded, size: 20),
                    label: Text(
                      prov.loading ? 'Finding route...' : 'Find Best Route',
                      style: const TextStyle(
                          fontSize: 15.5, fontWeight: FontWeight.w700),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF06B6D4),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    onPressed: prov.loading
                        ? null
                        : () async {
                            FocusScope.of(context).unfocus();
                            setState(() {
                              _fromSuggestions = [];
                              _toSuggestions = [];
                            });
                            await prov.findRoute(
                              fromPlace: _fromPlace.text,
                              fromDistrict: _fromDistrict,
                              toPlace: _toPlace.text,
                              toDistrict: _toDistrict,
                            );
                            if (prov.routePoints.isNotEmpty) {
                              _fitBounds(prov.routePoints);
                            }
                          },
                  ),
                ),
                if (prov.error != null) ...[
                  const SizedBox(height: 10),
                  _errorBanner(prov.error!),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Location block ----------------
  Widget _locationBlock({
    required IconData icon,
    required Color accent,
    required String label,
    required String district,
    required ValueChanged<String> onDistrictChange,
    required TextEditingController placeCtrl,
    required FocusNode focusNode,
    required List<String> suggestions,
    required ValueChanged<String> onSuggestionTap,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: accent.withOpacity(0.15),
                border: Border.all(
                  color: accent.withOpacity(0.55),
                  width: 1.2,
                ),
              ),
              child: Icon(icon, color: accent, size: 18),
            ),
            const SizedBox(width: 10),
            Expanded(
              flex: 4,
              child: _glassDropdown(
                value: district,
                items: _districts,
                accent: accent,
                onChanged: onDistrictChange,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              flex: 5,
              child: _glassTextField(
                controller: placeCtrl,
                hint: 'Search place...',
                accent: accent,
                focusNode: focusNode,
              ),
            ),
          ],
        ),
        if (suggestions.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8, left: 52),
            child: _suggestionsBox(
              suggestions: suggestions,
              accent: accent,
              onTap: onSuggestionTap,
            ),
          ),
      ],
    );
  }

  // ---------------- Suggestions box ----------------
  Widget _suggestionsBox({
    required List<String> suggestions,
    required Color accent,
    required ValueChanged<String> onTap,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          decoration: BoxDecoration(
            color: const Color(0xFF0A1024).withOpacity(0.92),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.20),
              width: 1.2,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.45),
                blurRadius: 20,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: suggestions.map((s) {
              return InkWell(
                onTap: () => onTap(s),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 12, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accent.withOpacity(0.18),
                          border: Border.all(
                            color: accent.withOpacity(0.55),
                            width: 1,
                          ),
                        ),
                        child: Icon(Icons.location_on_rounded,
                            size: 12, color: accent),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          s,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      Icon(Icons.north_west_rounded,
                          size: 14,
                          color: Colors.white.withOpacity(0.45)),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ),
    );
  }

  // ---------------- Glass dropdown ----------------
  Widget _glassDropdown({
    required String value,
    required List<String> items,
    required Color accent,
    required ValueChanged<String> onChanged,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.2,
            ),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isExpanded: true,
              dropdownColor: const Color(0xFF1B2B54),
              borderRadius: BorderRadius.circular(14),
              icon: Icon(Icons.keyboard_arrow_down_rounded,
                  color: Colors.white.withOpacity(0.85), size: 18),
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600),
              items: items
                  .map((d) => DropdownMenuItem<String>(
                        value: d,
                        child: Row(
                          children: [
                            Icon(Icons.map_rounded,
                                color: accent, size: 13),
                            const SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                d,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Glass text field ----------------
  Widget _glassTextField({
    required TextEditingController controller,
    required String hint,
    required Color accent,
    FocusNode? focusNode,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: Container(
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.white.withOpacity(0.10),
                Colors.white.withOpacity(0.04),
              ],
            ),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.28),
              width: 1.2,
            ),
          ),
          child: TextField(
            controller: controller,
            focusNode: focusNode,
            style: const TextStyle(color: Colors.white, fontSize: 13.5),
            cursorColor: accent,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: TextStyle(
                color: Colors.white.withOpacity(0.50),
                fontSize: 12.5,
              ),
              prefixIcon: Icon(Icons.search_rounded,
                  color: Colors.white.withOpacity(0.70), size: 16),
              border: InputBorder.none,
              contentPadding:
                  const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
            ),
          ),
        ),
      ),
    );
  }

  // ---------------- Error banner ----------------
  Widget _errorBanner(String msg) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFEF4444).withOpacity(0.10),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFEF4444).withOpacity(0.40),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              color: Color(0xFFEF4444), size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              msg,
              style: const TextStyle(
                color: Color(0xFFFCA5A5),
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ---------------- Map ----------------
  Widget _mapSection(BestRouteProvider prov) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Stack(
          children: [
            FlutterMap(
              mapController: _map,
              options: const MapOptions(
                initialCenter: LatLng(11.2588, 75.7804),
                initialZoom: 9,
                minZoom: 3,
                maxZoom: 18,
              ),
              children: [
                TileLayer(
                  urlTemplate:
                      'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.road_maintenance',
                ),
                if (prov.routePoints.isNotEmpty) ...[
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: prov.routePoints,
                        strokeWidth: 11,
                        color: const Color(0xFF06B6D4).withOpacity(0.25),
                      ),
                    ],
                  ),
                  PolylineLayer(
                    polylines: [
                      Polyline(
                        points: prov.routePoints,
                        strokeWidth: 5.5,
                        color: const Color(0xFF06B6D4),
                      ),
                    ],
                  ),
                ],
                MarkerLayer(
                  markers: [
                    if (prov.userLocation != null)
                      Marker(
                        point: prov.userLocation!,
                        width: 24,
                        height: 24,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF3B82F6),
                            border:
                                Border.all(color: Colors.white, width: 3),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF3B82F6)
                                    .withOpacity(0.7),
                                blurRadius: 14,
                              ),
                            ],
                          ),
                        ),
                      ),
                    if (prov.fromLatLng != null)
                      Marker(
                        point: prov.fromLatLng!,
                        width: 40,
                        height: 40,
                        child: _pin(const Color(0xFF10B981)),
                      ),
                    if (prov.toLatLng != null)
                      Marker(
                        point: prov.toLatLng!,
                        width: 40,
                        height: 40,
                        child: _pin(const Color(0xFFEF4444)),
                      ),
                  ],
                ),
              ],
            ),
            if (prov.routePoints.isNotEmpty)
              Positioned(
                top: 12,
                left: 12,
                right: 12,
                child: _routeInfoPill(prov),
              ),
            Positioned(bottom: 12, left: 12, child: _legend(prov)),
            Positioned(
              bottom: 12,
              right: 12,
              child: _glassIconBtn(
                icon: Icons.center_focus_strong_rounded,
                onTap: () {
                  if (prov.routePoints.isNotEmpty) {
                    _fitBounds(prov.routePoints);
                  } else if (prov.userLocation != null) {
                    _map.move(prov.userLocation!, 14);
                  }
                },
              ),
            ),
            if (prov.loading)
              Container(
                color: Colors.black.withOpacity(0.35),
                child: const Center(
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _pin(Color color) {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: Border.all(color: Colors.white, width: 2.5),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.65),
            blurRadius: 14,
            spreadRadius: 1,
          ),
        ],
      ),
      child: const Icon(Icons.location_on_rounded,
          color: Colors.white, size: 14),
    );
  }

  Widget _routeInfoPill(BestRouteProvider prov) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                const Color(0xFF06B6D4).withOpacity(0.30),
                const Color(0xFF3B82F6).withOpacity(0.20),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: Colors.white.withOpacity(0.35),
              width: 1.2,
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.alt_route_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${_fromPlace.text} → ${_toPlace.text}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      '${prov.distance} • ${prov.duration}',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.80),
                        fontSize: 11.5,
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

  Widget _legend(BestRouteProvider prov) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(14),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF0A1024).withOpacity(0.65),
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: Colors.white.withOpacity(0.20),
              width: 1,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _legendRow(const Color(0xFF10B981), 'Start'),
              const SizedBox(height: 4),
              _legendRow(const Color(0xFFEF4444), 'Destination'),
              if (prov.userLocation != null) ...[
                const SizedBox(height: 4),
                _legendRow(const Color(0xFF3B82F6), 'You'),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _legendRow(Color c, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(shape: BoxShape.circle, color: c),
        ),
        const SizedBox(width: 6),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10.5,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  Widget _glassIconBtn({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 12, sigmaY: 12),
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1024).withOpacity(0.65),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: Colors.white.withOpacity(0.30),
                width: 1.2,
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 20),
          ),
        ),
      ),
    );
  }

  // ---------------- Background ----------------
  Widget _gradientBase() {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment(
            -0.4 + _bgAnim.value * 0.2,
            -0.6 + _bgAnim.value * 0.15,
          ),
          radius: 1.5,
          colors: const [
            Color(0xFF062A33),
            Color(0xFF04161E),
            Color(0xFF04060F),
          ],
          stops: const [0.0, 0.55, 1.0],
        ),
      ),
    );
  }

  Widget _orbs(Size size) {
    return Stack(
      children: [
        Positioned(
          left: -size.width * 0.15 + _parallax.dx * -14,
          top: -size.height * 0.18 + _parallax.dy * -10,
          child: _orb(380, const Color(0xFF06B6D4), 0.28),
        ),
        Positioned(
          right: -size.width * 0.12 + _parallax.dx * 14,
          bottom: -size.height * 0.15 + _parallax.dy * 10,
          child: _orb(420, const Color(0xFF3B82F6), 0.22),
        ),
      ],
    );
  }

  Widget _orb(double size, Color color, double opacity) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              color.withOpacity(opacity * (0.85 + _orbAnim.value * 0.3)),
              color.withOpacity(0.0),
            ],
          ),
        ),
      ),
    );
  }
}