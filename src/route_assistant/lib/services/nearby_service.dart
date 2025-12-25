import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:route_assistant/screens/in_app/nearby/nearby_models.dart';

class NearbyService {
  final SupabaseClient client;
  NearbyService(this.client);

  Future<List<NearbyRoute>> getNearbyRoutes({
    required double lat,
    required double lng,
    required int radiusM,
  }) async {
    final res = await client.rpc(
      'get_nearby_routes',
      params: {'lat': lat, 'lng': lng, 'radius_m': radiusM},
    );

    final list = (res as List).cast<dynamic>();
    final routes = <NearbyRoute>[];

    for (final item in list) {
      if (item is Map) {
        routes.add(NearbyRoute.fromRpcRow(item.cast<String, dynamic>()));
      }
    }
    return routes;
  }

  Future<RouteDetail> getRouteDetail(String routeId) async {
    final row = await client
        .from('routes')
        .select('description, photo_urls')
        .eq('id', routeId)
        .maybeSingle()
        .timeout(const Duration(seconds: 10));

    final desc = row?['description']?.toString();

    final raw = row?['photo_urls'];
    final photos = <String>[];

    if (raw is List) {
      for (final e in raw) {
        final s = e.toString().trim();
        if (s.isNotEmpty) photos.add(s);
      }
    } else if (raw is String) {
      for (final p in raw.split(',')) {
        final s = p.trim();
        if (s.isNotEmpty) photos.add(s);
      }
    }

    return RouteDetail(description: desc, photos: photos);
  }
}
