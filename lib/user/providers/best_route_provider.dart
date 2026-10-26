import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class BestRouteProvider extends ChangeNotifier {
  bool loading = false;
  String? error;

  LatLng? fromLatLng;
  LatLng? toLatLng;
  LatLng? userLocation;

  List<LatLng> routePoints = [];
  String distance = '';
  String duration = '';

  // ============================================================
  // 📍 Same local coordinate DB you already have
  // ============================================================
  static const Map<String, Map<String, List<double>>> placesByDistrict = {
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

  // ============================================================
  // 🌍 USER LOCATION
  // ============================================================
  Future<void> initUserLocation() async {
    try {
      final perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        await Geolocator.requestPermission();
      }
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.medium,
      );
      userLocation = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (_) {}
  }

  // ============================================================
  // 🔍 Fuzzy place lookup
  // ============================================================
  LatLng? _lookup(String district, String place) {
    final districtMap = placesByDistrict[district];
    if (districtMap == null) return null;

    final query = place.trim().toLowerCase();
    if (query.isEmpty) return null;

    // 1. Exact (case-insensitive) match
    for (final entry in districtMap.entries) {
      if (entry.key.toLowerCase() == query) {
        return LatLng(entry.value[0], entry.value[1]);
      }
    }

    // 2. Contains match ("beach" matches "Kozhikode Beach")
    for (final entry in districtMap.entries) {
      if (entry.key.toLowerCase().contains(query) ||
          query.contains(entry.key.toLowerCase())) {
        return LatLng(entry.value[0], entry.value[1]);
      }
    }

    // 3. Fallback: match against the district center
    //    (so the user still gets a route to the district itself)
    final districtCenter = _districtCenters[district];
    if (districtCenter != null) {
      return LatLng(districtCenter[0], districtCenter[1]);
    }

    return null;
  }

  static const Map<String, List<double>> _districtCenters = {
    'Alappuzha': [9.4981, 76.3388],
    'Ernakulam': [9.9312, 76.2673],
    'Idukki': [9.8500, 76.9667],
    'Kannur': [11.8745, 75.3704],
    'Kasaragod': [12.5000, 74.9833],
    'Kollam': [8.8800, 76.6000],
    'Kottayam': [9.5916, 76.5222],
    'Kozhikode': [11.2588, 75.7804],
    'Malappuram': [11.0500, 76.0833],
    'Palakkad': [10.7867, 76.6548],
    'Pathanamthitta': [9.2648, 76.7870],
    'Thiruvananthapuram': [8.5241, 76.9366],
    'Thrissur': [10.5276, 76.2144],
    'Wayanad': [11.6089, 76.0836],
  };

  // ============================================================
  // 🚀 FIND ROUTE
  // ============================================================
  Future<void> findRoute({
    required String fromPlace,
    required String fromDistrict,
    required String toPlace,
    required String toDistrict,
  }) async {
    loading = true;
    error = null;
    routePoints = [];
    fromLatLng = null;
    toLatLng = null;
    distance = '';
    duration = '';
    notifyListeners();

    try {
      final fromPt = _lookup(fromDistrict, fromPlace);
      final toPt = _lookup(toDistrict, toPlace);

      if (fromPt == null) {
        loading = false;
        error = 'Could not find "$fromPlace" in $fromDistrict';
        notifyListeners();
        return;
      }
      if (toPt == null) {
        loading = false;
        error = 'Could not find "$toPlace" in $toDistrict';
        notifyListeners();
        return;
      }

      fromLatLng = fromPt;
      toLatLng = toPt;

      final route = await _fetchRoute(fromPt, toPt);
      if (route.isEmpty) {
        loading = false;
        error = 'No route found between the selected places';
        notifyListeners();
        return;
      }

      routePoints = route;
      loading = false;
      notifyListeners();
    } catch (e) {
      loading = false;
      error = 'Route error: $e';
      notifyListeners();
    }
  }

  // ============================================================
  // 🌐 OSRM route fetch
  // ============================================================
  Future<List<LatLng>> _fetchRoute(LatLng from, LatLng to) async {
    final url = Uri.parse(
      'https://router.project-osrm.org/route/v1/driving/'
      '${from.longitude},${from.latitude};'
      '${to.longitude},${to.latitude}'
      '?overview=full&geometries=geojson',
    );

    final res = await http.get(url);
    if (res.statusCode != 200) return [];

    final data = jsonDecode(res.body);
    if (data['routes'] == null || (data['routes'] as List).isEmpty) return [];

    final route = data['routes'][0];
    final meters = (route['distance'] as num).toDouble();
    final seconds = (route['duration'] as num).toDouble();

    distance = meters >= 1000
        ? '${(meters / 1000).toStringAsFixed(1)} km'
        : '${meters.toStringAsFixed(0)} m';
    duration = seconds >= 60
        ? '${(seconds / 60).toStringAsFixed(0)} min'
        : '${seconds.toStringAsFixed(0)} s';

    final coords = route['geometry']['coordinates'] as List;
    return coords
        .map((c) => LatLng(
              (c[1] as num).toDouble(),
              (c[0] as num).toDouble(),
            ))
        .toList();
  }
}