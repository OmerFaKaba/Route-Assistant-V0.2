import 'package:supabase_flutter/supabase_flutter.dart';

class MessageService {
  static final _client = Supabase.instance.client;

  /// İki kullanıcı arasında conversation var mı? Yoksa oluştur. id döner.
  static Future<int> getOrCreateConversation({
    required String otherUserId,
  }) async {
    final me = _client.auth.currentUser;
    if (me == null) throw Exception('Not authenticated');

    // önce var mı bak
    final existing = await _client
        .from('conversations')
        .select('id, user_a, user_b')
        .or('user_a.eq.${me.id},user_b.eq.${me.id}') // hızlı filtre
        .limit(200);

    for (final row in (existing as List)) {
      final a = row['user_a'].toString();
      final b = row['user_b'].toString();
      if ((a == me.id && b == otherUserId) ||
          (a == otherUserId && b == me.id)) {
        return row['id'] as int;
      }
    }

    // yoksa insert (unique index A-B koruyor)
    final inserted = await _client
        .from('conversations')
        .insert({'user_a': me.id, 'user_b': otherUserId})
        .select('id')
        .single();

    return inserted['id'] as int;
  }

  static Future<void> sendMessage({
    required int conversationId,
    required String content,
  }) async {
    final me = _client.auth.currentUser;
    if (me == null) throw Exception('Not authenticated');

    final text = content.trim();
    if (text.isEmpty) return;

    await _client.from('messages').insert({
      'conversation_id': conversationId,
      'sender_id': me.id,
      'content': text,
    });
  }

  static Future<List<Map<String, dynamic>>> fetchMessages({
    required int conversationId,
    int limit = 100,
  }) async {
    final res = await _client
        .from('messages')
        .select('id, sender_id, content, created_at, read_at')
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: true)
        .limit(limit);

    return (res as List).cast<Map<String, dynamic>>();
  }

  /// Inbox: conversation list + other user profile + last message
  static Future<List<Map<String, dynamic>>> fetchInbox({int limit = 50}) async {
    final me = _client.auth.currentUser;
    if (me == null) throw Exception('Not authenticated');

    final convos = await _client
        .from('conversations')
        .select('id, user_a, user_b, created_at')
        .order('created_at', ascending: false)
        .limit(200);

    final convoList = (convos as List).cast<Map<String, dynamic>>();

    // Son mesajları tek tek çekmek basit ama maliyetli; şimdilik yeterli (50 convo)
    final result = <Map<String, dynamic>>[];
    for (final c in convoList.take(limit)) {
      final a = c['user_a'].toString();
      final b = c['user_b'].toString();
      final otherId = (a == me.id) ? b : a;

      final otherProfile = await _client
          .from('profiles')
          .select('id, username, avatar_url')
          .eq('id', otherId)
          .maybeSingle();

      final lastMsg = await _client
          .from('messages')
          .select('content, created_at, sender_id')
          .eq('conversation_id', c['id'])
          .order('created_at', ascending: false)
          .limit(1);

      result.add({
        'conversation': c,
        'other': otherProfile,
        'last': (lastMsg as List).isNotEmpty ? lastMsg.first : null,
      });
    }

    return result;
  }
}
