// lib/services/trail_service.dart
import 'dart:io';

import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class TrailService {
  static final _client = Supabase.instance.client;

  /// Fotoğrafları Supabase Storage'a yükler ve public URL listesini döner.
  static Future<List<String>> uploadPhotos(List<XFile> images) async {
    if (images.isEmpty) return [];

    final user = _client.auth.currentUser;
    if (user == null) {
      throw Exception('User not authenticated');
    }

    final storage = _client.storage.from('trail-photos');
    final List<String> urls = [];

    for (final img in images) {
      final file = File(img.path);

      final fileName = file.path.split('/').last;
      final path =
          '${user.id}/${DateTime.now().millisecondsSinceEpoch}_$fileName';

      await storage.upload(path, file);

      final publicUrl = storage.getPublicUrl(path);
      urls.add(publicUrl);
    }

    return urls;
  }

  /// Trail + noktalar + meta bilgileri DB'ye yazar
  static Future<String> insertTrailWithPoints({
    required String name,
    required String description,
    required String difficulty, // easy / medium / hard
    required bool isPublic,
    required double totalDistanceMeters,
    required Duration duration,
    required DateTime startedAt,
    required DateTime endedAt,
    required List<LatLng> points,
    required List<String> photoUrls,
  }) async {
    final pointsJson = points
        .map((p) => {'lat': p.latitude, 'lng': p.longitude})
        .toList();

    final result = await _client.rpc(
      'insert_trail_with_points',
      params: {
        'p_name': name,
        'p_description': description,
        'p_difficulty': difficulty,
        'p_is_public': isPublic,
        'p_total_distance_m': totalDistanceMeters,
        'p_duration_s': duration.inSeconds,
        'p_started_at': startedAt.toIso8601String(),
        'p_ended_at': endedAt.toIso8601String(),
        'p_points': pointsJson,
        'p_photo_urls': photoUrls,
      },
    );

    return result as String;
  }

  // ============================================================
  // COMMENTS (YORUMLAR)
  // ============================================================

  /// ✅ Bir route'un yorumlarını çeker + profile (username, avatar_url) ile birlikte
  static Future<List<Map<String, dynamic>>> fetchComments({
    required String routeId,
    int limit = 50,
  }) async {
    final res = await _client
        .from('route_comments')
        .select(
          'id, route_id, user_id, content, created_at, '
          'profile:profiles!route_comments_user_profile_fk(username, avatar_url)',
        )
        .eq('route_id', routeId)
        .order('created_at', ascending: false)
        .limit(limit);

    return (res as List).cast<Map<String, dynamic>>();
  }

  /// Route'a yorum ekler.
  static Future<void> addComment({
    required String routeId,
    required String content,
  }) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    final text = content.trim();
    if (text.isEmpty) return;

    await _client.from('route_comments').insert({
      'route_id': routeId,
      'user_id': user.id,
      'content': text,
    });
  }

  /// (Opsiyonel) Kullanıcı kendi yorumunu silebilsin diye.
  static Future<void> deleteComment({required int commentId}) async {
    final user = _client.auth.currentUser;
    if (user == null) throw Exception('User not authenticated');

    await _client.from('route_comments').delete().eq('id', commentId);
  }
}
