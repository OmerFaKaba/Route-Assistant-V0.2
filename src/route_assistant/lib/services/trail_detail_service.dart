import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrailDetailService {
  final SupabaseClient client;
  TrailDetailService(this.client);

  Future<Map<String, dynamic>> loadRoute(String routeId) {
    return client
        .from('routes')
        .select(
          'id, owner_id, name, description, total_distance_m, duration_s, difficulty, photo_urls',
        )
        .eq('id', routeId)
        .single();
  }

  Future<List<LatLng>> loadRoutePoints(String routeId) async {
    final pointsData = await client
        .from('route_points')
        .select('geom')
        .eq('route_id', routeId)
        .order('seq');

    final pts = <LatLng>[];
    for (final p in pointsData as List) {
      final geom = p['geom'];
      final coords = (geom['coordinates'] as List);
      pts.add(LatLng(coords[1] as double, coords[0] as double));
    }
    return pts;
  }

  Future<Map<String, dynamic>?> loadOwnerProfile(String ownerId) {
    return client
        .from('profiles')
        .select('id, username, avatar_url')
        .eq('id', ownerId)
        .maybeSingle();
  }

  Future<List<dynamic>> loadLikes(String routeId) {
    return client.from('route_likes').select('user_id').eq('route_id', routeId);
  }

  Future<void> likeRoute({required String routeId, required String userId}) {
    return client.from('route_likes').insert({
      'route_id': routeId,
      'user_id': userId,
    });
  }

  Future<void> unlikeRoute({required String routeId, required String userId}) {
    return client
        .from('route_likes')
        .delete()
        .eq('route_id', routeId)
        .eq('user_id', userId);
  }
}
