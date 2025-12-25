import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/notif_item.dart';

class NotificationsService {
  NotificationsService(this._client);
  final SupabaseClient _client;

  String? get myUserId => _client.auth.currentUser?.id;

  Future<int> fetchUnreadCount() async {
    final uid = myUserId;
    if (uid == null) return 0;

    final unreadRes = await _client
        .from('notifications')
        .select('id')
        .eq('recipient_id', uid)
        .isFilter('read_at', null);

    return (unreadRes as List).length;
  }

  Future<List<NotifItem>> fetchLatest({int limit = 10}) async {
    final uid = myUserId;
    if (uid == null) return [];

    final latestRes = await _client
        .from('notifications')
        .select('id, type, created_at, read_at, route_id, actor_id')
        .eq('recipient_id', uid)
        .order('created_at', ascending: false)
        .limit(limit);

    final notifsRaw = (latestRes as List)
        .map((e) => (e as Map).cast<String, dynamic>())
        .toList();

    final actorIds = notifsRaw
        .map((n) => n['actor_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    final routeIds = notifsRaw
        .map((n) => n['route_id']?.toString())
        .whereType<String>()
        .toSet()
        .toList();

    Map<String, Map<String, dynamic>> profilesById = {};
    Map<String, Map<String, dynamic>> routesById = {};

    if (actorIds.isNotEmpty) {
      final profRes = await _client
          .from('profiles')
          .select('id, username, avatar_url')
          .inFilter('id', actorIds);

      final profList = (profRes as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();

      profilesById = {for (final p in profList) p['id'].toString(): p};
    }

    if (routeIds.isNotEmpty) {
      final rRes = await _client
          .from('routes')
          .select('id, name')
          .inFilter('id', routeIds);

      final rList = (rRes as List)
          .map((e) => (e as Map).cast<String, dynamic>())
          .toList();

      routesById = {for (final r in rList) r['id'].toString(): r};
    }

    return notifsRaw.map((n) {
      final actorId = n['actor_id']?.toString() ?? '';
      final routeId = n['route_id']?.toString() ?? '';
      final prof = profilesById[actorId];
      final rt = routesById[routeId];

      return NotifItem(
        id: n['id'] as int,
        type: (n['type'] ?? '').toString(),
        createdAt: (n['created_at'] ?? '').toString(),
        readAt: n['read_at'],
        routeId: routeId,
        actorUsername: (prof?['username'] ?? 'user').toString(),
        actorAvatarUrl: (prof?['avatar_url'] ?? '').toString(),
        routeName: (rt?['name'] ?? 'rota').toString(),
      );
    }).toList();
  }

  Future<void> markRead(int notifId) async {
    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('id', notifId);
  }

  Future<void> markAllRead() async {
    final uid = myUserId;
    if (uid == null) return;

    await _client
        .from('notifications')
        .update({'read_at': DateTime.now().toIso8601String()})
        .eq('recipient_id', uid)
        .isFilter('read_at', null);
  }

  RealtimeChannel? subscribeToMyNotifications({
    required void Function() onNewNotification,
  }) {
    final uid = myUserId;
    if (uid == null) return null;

    final channel = _client.channel('notif_$uid');

    channel
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'recipient_id',
            value: uid,
          ),
          callback: (_) => onNewNotification(),
        )
        .subscribe();

    return channel;
  }
}
