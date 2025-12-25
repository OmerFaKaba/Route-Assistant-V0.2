import 'package:supabase_flutter/supabase_flutter.dart';

class LikesService {
  LikesService(this._client);
  final SupabaseClient _client;

  /// routeIds için:
  /// - likeCounts
  /// - likedByMe set'i
  Future<({Map<String, int> likeCounts, Set<String> likedByMe})> fetchLikes(
    List<String> routeIds,
  ) async {
    final likeCounts = <String, int>{};
    for (final id in routeIds) {
      likeCounts[id] = 0;
    }
    if (routeIds.isEmpty)
      return (likeCounts: likeCounts, likedByMe: <String>{});

    final user = _client.auth.currentUser;

    final res = await _client
        .from('route_likes')
        .select('route_id, user_id')
        .inFilter('route_id', routeIds);

    final rows = (res as List);

    final likedByMe = <String>{};

    for (final r in rows) {
      final rid = r['route_id']?.toString();
      final uid = r['user_id']?.toString();
      if (rid == null) continue;

      likeCounts[rid] = (likeCounts[rid] ?? 0) + 1;

      if (user != null && uid == user.id) {
        likedByMe.add(rid);
      }
    }

    return (likeCounts: likeCounts, likedByMe: likedByMe);
  }

  Future<void> like(String routeId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    await _client.from('route_likes').insert({
      'route_id': routeId,
      'user_id': user.id,
    });
  }

  Future<void> unlike(String routeId) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('Not logged in');
    await _client
        .from('route_likes')
        .delete()
        .eq('route_id', routeId)
        .eq('user_id', user.id);
  }
}
