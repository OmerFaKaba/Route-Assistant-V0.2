import 'package:google_maps_flutter/google_maps_flutter.dart';

class NearbyRoute {
  final String id;
  final String name;
  final LatLng start;
  final double? distanceM;

  const NearbyRoute({
    required this.id,
    required this.name,
    required this.start,
    required this.distanceM,
  });

  factory NearbyRoute.fromRpcRow(Map<String, dynamic> row) {
    final id = row['id'].toString();
    final name = (row['name'] ?? 'Rota').toString();
    final lat = (row['start_lat'] as num).toDouble();
    final lng = (row['start_lng'] as num).toDouble();
    final distM = (row['distance_m'] as num?)?.toDouble();

    return NearbyRoute(
      id: id,
      name: name,
      start: LatLng(lat, lng),
      distanceM: distM,
    );
  }
}

class RouteDetail {
  final String? description;
  final List<String> photos;

  const RouteDetail({required this.description, required this.photos});
}
