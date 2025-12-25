import 'package:supabase_flutter/supabase_flutter.dart';

class ExploreService {
  ExploreService(this._client);
  final SupabaseClient _client;

  Future<List<Map<String, dynamic>>> fetchExploreRoutes() async {
    final data = await _client
        .from('routes')
        .select(
          'id, name, total_distance_m, duration_s, difficulty, photo_urls',
        )
        .eq('is_public', true)
        .order('inserted_at', ascending: false);

    return (data as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();
  }

  Future<List<Map<String, dynamic>>> fetchPopularRoutes({int limit = 5}) async {
    final countsRes = await _client
        .from('route_like_counts')
        .select('route_id, like_count')
        .order('like_count', ascending: false)
        .limit(limit);

    final countsList = (countsRes as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    final ids = countsList.map((e) => e['route_id'].toString()).toList();
    if (ids.isEmpty) return [];

    final routesRes = await _client
        .from('routes')
        .select(
          'id, name, total_distance_m, duration_s, difficulty, photo_urls',
        )
        .inFilter('id', ids)
        .eq('is_public', true);

    final routesList = (routesRes as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    // ids sırasına göre sırala
    final byId = {for (final r in routesList) r['id'].toString(): r};
    return ids.where(byId.containsKey).map((id) => byId[id]!).toList();
  }
}
