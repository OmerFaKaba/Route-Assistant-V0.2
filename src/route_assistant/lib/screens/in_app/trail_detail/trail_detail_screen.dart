import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:route_assistant/models/daily_forecast.dart';
import 'package:route_assistant/screens/in_app/trail_detail/widgets/trail_header.dart';
import 'package:route_assistant/screens/in_app/trail_detail/widgets/trail_map_header.dart';
import 'package:route_assistant/screens/in_app/trail_detail/widgets/trail_stats.dart';
import 'package:route_assistant/screens/in_app/trail_detail/widgets/trail_weather_section.dart';
import 'package:route_assistant/screens/widget/comment_section.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:route_assistant/services/trail_detail_service.dart';
import 'package:route_assistant/services/weather_service.dart';

class TrailDetailScreen extends StatefulWidget {
  const TrailDetailScreen({super.key});

  @override
  State<TrailDetailScreen> createState() => _TrailDetailScreenState();
}

class _TrailDetailScreenState extends State<TrailDetailScreen> {
  final _client = Supabase.instance.client;
  late final _trailService = TrailDetailService(_client);
  final _weatherService = WeatherService();

  bool _loading = true;
  String? _error;

  Map<String, dynamic>? _route;
  List<LatLng> _points = [];

  GoogleMapController? _mapCtrl;

  String? _routeId;
  bool _loadedOnce = false;

  // creator info
  String? _ownerId;
  Map<String, dynamic>? _ownerProfile;

  // likes
  int _likeCount = 0;
  bool _likedByMe = false;
  bool _likeBusy = false;

  // weather
  bool _weatherLoading = false;
  String? _weatherError;
  List<DailyForecast> _forecast = [];

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_loadedOnce) return;
    _loadedOnce = true;

    final args = ModalRoute.of(context)?.settings.arguments;

    String? routeId;
    if (args is String) {
      routeId = args;
    } else if (args is Map) {
      routeId = args['routeId']?.toString();
    }

    if (routeId == null || routeId.isEmpty) {
      setState(() {
        _loading = false;
        _error = "Route ID gelmedi. (arguments null/yanlış format)";
      });
      return;
    }

    _routeId = routeId;
    _loadAll(routeId);
  }

  Future<void> _loadAll(String routeId) async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routeData = await _trailService.loadRoute(routeId);
      final pts = await _trailService.loadRoutePoints(routeId);

      final ownerId = routeData['owner_id']?.toString();
      Map<String, dynamic>? ownerProf;
      if (ownerId != null && ownerId.isNotEmpty) {
        ownerProf = await _trailService.loadOwnerProfile(ownerId);
      }

      setState(() {
        _route = routeData;
        _points = pts;
        _ownerId = ownerId;
        _ownerProfile = ownerProf;
      });

      await _loadLikes(routeId);

      if (pts.isNotEmpty) {
        await _loadWeather(pts.first);
      }
    } catch (e) {
      setState(() => _error = '$e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _loadLikes(String routeId) async {
    final user = _client.auth.currentUser;
    try {
      final likes = await _trailService.loadLikes(routeId);
      final total = likes.length;

      bool liked = false;
      if (user != null) {
        liked = likes.any((row) => row['user_id'] == user.id);
      }

      if (!mounted) return;
      setState(() {
        _likeCount = total;
        _likedByMe = liked;
      });
    } catch (_) {}
  }

  Future<void> _toggleLike() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Like atmak için giriş yapmalısın.')),
      );
      return;
    }
    if (_routeId == null) return;
    if (_likeBusy) return;

    setState(() => _likeBusy = true);

    final wasLiked = _likedByMe;
    setState(() {
      _likedByMe = !wasLiked;
      _likeCount += wasLiked ? -1 : 1;
      if (_likeCount < 0) _likeCount = 0;
    });

    try {
      if (!wasLiked) {
        await _trailService.likeRoute(routeId: _routeId!, userId: user.id);
      } else {
        await _trailService.unlikeRoute(routeId: _routeId!, userId: user.id);
      }
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _likedByMe = wasLiked;
        _likeCount += wasLiked ? 1 : -1;
        if (_likeCount < 0) _likeCount = 0;
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Like işlemi başarısız: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _likeBusy = false);
    }
  }

  Future<void> _loadWeather(LatLng p) async {
    setState(() {
      _weatherLoading = true;
      _weatherError = null;
    });

    try {
      final items = await _weatherService.load7DayOpenMeteo(p);
      if (!mounted) return;
      setState(() => _forecast = items);
    } catch (e) {
      if (!mounted) return;
      setState(() => _weatherError = e.toString());
    } finally {
      if (!mounted) return;
      setState(() => _weatherLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final distanceKm =
        ((_route?['total_distance_m'] ?? 0) as num).toDouble() / 1000.0;
    final durationS = (_route?['duration_s'] ?? 0) as int;
    final difficulty = (_route?['difficulty'] ?? '-')?.toString() ?? '-';

    final photoUrls = (_route?['photo_urls'] as List?) ?? [];
    final coverUrl = photoUrls.isNotEmpty ? photoUrls.first as String : null;

    final ownerUsername = _ownerProfile?['username']?.toString();
    final ownerAvatar = _ownerProfile?['avatar_url']?.toString();

    return Scaffold(
      appBar: AppBar(title: Text(_route?['name'] ?? 'Trail Detail')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : Column(
              children: [
                TrailMapHeader(
                  points: _points,
                  onMapCreated: (c) {
                    _mapCtrl = c;
                    if (_points.isNotEmpty) {
                      _mapCtrl!.animateCamera(
                        CameraUpdate.newLatLngBounds(
                          _boundsFromLatLngList(_points),
                          40,
                        ),
                      );
                    }
                  },
                ),
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (coverUrl != null) ...[
                          ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              coverUrl,
                              height: 180,
                              width: double.infinity,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 12),
                        ],

                        TrailHeader(
                          title: _route?['name']?.toString() ?? '',
                          ownerId: _ownerId,
                          ownerUsername: ownerUsername,
                          ownerAvatarUrl: ownerAvatar,
                          likeCount: _likeCount,
                          likedByMe: _likedByMe,
                          likeBusy: _likeBusy,
                          onToggleLike: _toggleLike,
                        ),

                        const SizedBox(height: 8),
                        Text(_route?['description']?.toString() ?? ''),
                        const SizedBox(height: 12),

                        TrailStats(
                          distanceKm: distanceKm,
                          timeText: _formatDuration(durationS),
                          difficulty: difficulty,
                        ),

                        const SizedBox(height: 12),
                        TrailWeatherSection(
                          loading: _weatherLoading,
                          error: _weatherError,
                          forecast: _forecast,
                        ),
                        const SizedBox(height: 12),

                        if (_routeId != null)
                          CommentsSection(routeId: _routeId!),
                      ],
                    ),
                  ),
                ),
              ],
            ),
    );
  }

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    return '$h h $m min';
  }

  LatLngBounds _boundsFromLatLngList(List<LatLng> list) {
    double x0 = list.first.latitude;
    double x1 = list.first.latitude;
    double y0 = list.first.longitude;
    double y1 = list.first.longitude;
    for (final latLng in list) {
      if (latLng.latitude > x1) x1 = latLng.latitude;
      if (latLng.latitude < x0) x0 = latLng.latitude;
      if (latLng.longitude > y1) y1 = latLng.longitude;
      if (latLng.longitude < y0) y0 = latLng.longitude;
    }
    return LatLngBounds(southwest: LatLng(x0, y0), northeast: LatLng(x1, y1));
  }
}
