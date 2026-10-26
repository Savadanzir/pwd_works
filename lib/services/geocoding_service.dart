import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

class GeocodingService {
  static const _ua = 'road_maintenance_app/1.0 (contact@example.com)';

  /// Converts a place name + district into coordinates.
  /// Uses OpenStreetMap's free Nominatim API — no key required.
  static Future<LatLng?> geocode(String query, {String? district}) async {
    final full = district == null || district.isEmpty
        ? query
        : '$query, $district, Kerala, India';
    final uri = Uri.https('nominatim.openstreetmap.org', '/search', {
      'q': full,
      'format': 'json',
      'limit': '1',
      'countrycodes': 'in',
    });

    final res = await http.get(uri, headers: {'User-Agent': _ua});
    if (res.statusCode != 200) return null;

    final data = jsonDecode(res.body);
    if (data is! List || data.isEmpty) return null;

    final first = data.first;
    final lat = double.tryParse(first['lat'].toString());
    final lon = double.tryParse(first['lon'].toString());
    if (lat == null || lon == null) return null;

    return LatLng(lat, lon);
  }
}