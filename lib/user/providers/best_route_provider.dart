import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class BestRouteProvider extends ChangeNotifier {
  LatLng? _userLocation;
  LatLng? _fromLatLng;
  LatLng? _toLatLng;
  List<LatLng> _routePoints = [];
  String _distance = '';
  String _duration = '';
  bool _loading = false;
  String? _error;

  LatLng? get userLocation => _userLocation;
  LatLng? get fromLatLng => _fromLatLng;
  LatLng? get toLatLng => _toLatLng;
  List<LatLng> get routePoints => _routePoints;
  String get distance => _distance;
  String get duration => _duration;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> initUserLocation() async {
    try {
      final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );
      _userLocation = LatLng(pos.latitude, pos.longitude);
      notifyListeners();
    } catch (_) {}
  }

  Future<LatLng?> _geocode(String place, String district) async {
    final query = place.trim().isEmpty
        ? '$district, Kerala, India'
        : '${place.trim()}, $district, Kerala, India';
    try {
      final results = await locationFromAddress(query);
      if (results.isNotEmpty) {
        final r = results.first;
        return LatLng(r.latitude, r.longitude);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> findRoute({
    required String fromPlace,
    required String fromDistrict,
    required String toPlace,
    required String toDistrict,
  }) async {
    _loading = true;
    _error = null;
    _routePoints = [];
    notifyListeners();

    try {
      final from = await _geocode(fromPlace, fromDistrict);
      final to = await _geocode(toPlace, toDistrict);

      if (from == null) {
        throw Exception('Could not find "$fromPlace" in $fromDistrict');
      }
      if (to == null) {
        throw Exception('Could not find "$toPlace" in $toDistrict');
      }

      final url = Uri.parse(
        'https://router.project-osrm.org/route/v1/driving/'
        '${from.longitude},${from.latitude};'
        '${to.longitude},${to.latitude}'
        '?overview=full&geometries=geojson',
      );
      final resp = await http.get(url);
      if (resp.statusCode != 200) {
        throw Exception('Routing failed (${resp.statusCode})');
      }

      final json = jsonDecode(resp.body) as Map<String, dynamic>;
      if (json['routes'] == null || (json['routes'] as List).isEmpty) {
        throw Exception('No route found');
      }

      final route = (json['routes'] as List).first as Map<String, dynamic>;
      final geometry = route['geometry'] as Map<String, dynamic>;
      final coords = geometry['coordinates'] as List;

      final meters = (route['distance'] ?? 0).toDouble();
      final seconds = (route['duration'] ?? 0).toDouble();
      _distance = '${(meters / 1000).toStringAsFixed(1)} km';
      _duration = '${(seconds / 60).toStringAsFixed(0)} min';

      _fromLatLng = from;
      _toLatLng = to;
      _routePoints = coords
          .map((c) => LatLng((c[1] as num).toDouble(),
              (c[0] as num).toDouble()))
          .toList();
    } catch (e) {
      _error = e.toString().replaceAll('Exception: ', '');
    } finally {
      _loading = false;
      notifyListeners();
    }
  }
}