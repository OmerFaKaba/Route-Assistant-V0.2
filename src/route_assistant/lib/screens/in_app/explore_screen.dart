import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/notif_item.dart';
import '../../services/explore_service.dart';
import '../../services/like_service.dart';
import '../../services/notifications_service.dart';

import '../widget/explore_popular_section.dart';
import '../widget/explore_route_card.dart';
import '../widget/notif_popup.dart';

class ExploreScreen extends StatefulWidget {
  const ExploreScreen({super.key});

  @override
  State<ExploreScreen> createState() => _ExploreScreenState();
}

class _ExploreScreenState extends State<ExploreScreen> {
  final _client = Supabase.instance.client;

  late final ExploreService _exploreService;
  late final LikesService _likesService;
  late final NotificationsService _notifService;

  bool _loading = true;
  String? _error;

  List<dynamic> _routes = [];
  List<dynamic> _popularRoutes = [];

  final Map<String, int> _likeCounts = {};
  final Map<String, bool> _likedByMe = {};
  final Set<String> _busyRouteIds = {};

  int _unreadNotifCount = 0;
  List<NotifItem> _latestNotifs = [];

  RealtimeChannel? _notifChannel;
  OverlayEntry? _notifOverlay;

  @override
  void initState() {
    super.initState();
    _exploreService = ExploreService(_client);
    _likesService = LikesService(_client);
    _notifService = NotificationsService(_client);

    _loadAll();
    _subscribeNotifications();
  }

  @override
  void dispose() {
    _hideNotifOverlay();
    if (_notifChannel != null) _client.removeChannel(_notifChannel!);
    super.dispose();
  }

  Future<void> _loadAll() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final routes = await _exploreService.fetchExploreRoutes();
      final popular = await _exploreService.fetchPopularRoutes(limit: 5);

      final ids = <String>{
        ...routes.map((r) => r['id'].toString()),
        ...popular.map((r) => r['id'].toString()),
      }.toList();

      final likesPack = await _likesService.fetchLikes(ids);

      _likeCounts
        ..clear()
        ..addAll(likesPack.likeCounts);

      _likedByMe
        ..clear()
        ..addEntries(
          ids.map((id) => MapEntry(id, likesPack.likedByMe.contains(id))),
        );

      await _refreshNotifPanelData(showPopup: false);

      if (!mounted) return;
      setState(() {
        _routes = routes;
        _popularRoutes = popular;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = '$e';
        _loading = false;
      });
    }
  }

  Future<void> _subscribeNotifications() async {
    final user = _client.auth.currentUser;
    if (user == null) return;

    await _refreshNotifPanelData(showPopup: false);

    _notifChannel = _notifService.subscribeToMyNotifications(
      onNewNotification: () async {
        await _refreshNotifPanelData(showPopup: true);
      },
    );
  }

  Future<void> _refreshNotifPanelData({required bool showPopup}) async {
    final unread = await _notifService.fetchUnreadCount();
    final latest = await _notifService.fetchLatest(limit: 10);

    if (!mounted) return;
    setState(() {
      _unreadNotifCount = unread;
      _latestNotifs = latest;
    });

    if (showPopup) _showNotifOverlay();
  }

  Future<void> _toggleLike(String routeId) async {
    final user = _client.auth.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Like atmak için giriş yapmalısın.')),
      );
      return;
    }
    if (_busyRouteIds.contains(routeId)) return;

    setState(() => _busyRouteIds.add(routeId));

    final wasLiked = _likedByMe[routeId] ?? false;

    setState(() {
      _likedByMe[routeId] = !wasLiked;
      _likeCounts[routeId] = (_likeCounts[routeId] ?? 0) + (wasLiked ? -1 : 1);
      if ((_likeCounts[routeId] ?? 0) < 0) _likeCounts[routeId] = 0;
    });

    try {
      if (!wasLiked) {
        await _likesService.like(routeId);
      } else {
        await _likesService.unlike(routeId);
      }
    } catch (e) {
      setState(() {
        _likedByMe[routeId] = wasLiked;
        _likeCounts[routeId] =
            (_likeCounts[routeId] ?? 0) + (wasLiked ? 1 : -1);
        if ((_likeCounts[routeId] ?? 0) < 0) _likeCounts[routeId] = 0;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Like işlemi başarısız: $e')));
    } finally {
      if (!mounted) return;
      setState(() => _busyRouteIds.remove(routeId));
    }
  }

  Future<void> _markNotifRead(int notifId) async {
    await _notifService.markRead(notifId);
    await _refreshNotifPanelData(showPopup: false);
  }

  Future<void> _markAllNotifsRead() async {
    await _notifService.markAllRead();
    await _refreshNotifPanelData(showPopup: false);
  }

  void _openDetail(String routeId) {
    Navigator.pushNamed(context, '/trailDetail', arguments: routeId);
  }

  void _showNotifOverlay() {
    _hideNotifOverlay();

    final overlay = Overlay.of(context);
    if (overlay == null) return;

    _notifOverlay = OverlayEntry(
      builder: (_) => Positioned(
        top: 90,
        right: 16,
        child: Material(
          color: Colors.transparent,
          child: NotifPopup(
            unreadCount: _unreadNotifCount,
            items: _latestNotifs,
            onTapHeader: () async {
              await _markAllNotifsRead();
              _hideNotifOverlay();
            },
            onTapItem: (notifId, routeId) async {
              await _markNotifRead(notifId);
              _hideNotifOverlay();
              if (routeId.isNotEmpty) _openDetail(routeId);
            },
            onClose: _hideNotifOverlay,
          ),
        ),
      ),
    );

    overlay.insert(_notifOverlay!);

    Future.delayed(const Duration(seconds: 6), () {
      if (mounted) _hideNotifOverlay();
    });
  }

  void _hideNotifOverlay() {
    _notifOverlay?.remove();
    _notifOverlay = null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Keşfet'),
        actions: [
          IconButton(
            onPressed: () async {
              await Navigator.pushNamed(context, '/notifications');
              await _refreshNotifPanelData(showPopup: false);
            },
            icon: Stack(
              clipBehavior: Clip.none,
              children: [
                const Icon(Icons.notifications_none),
                if (_unreadNotifCount > 0)
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 5,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      constraints: const BoxConstraints(minWidth: 18),
                      child: Text(
                        _unreadNotifCount > 99 ? '99+' : '$_unreadNotifCount',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _loadAll,
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _routes.length + 1,
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return ExplorePopularSection(
                      popularRoutes: _popularRoutes,
                      likeCounts: _likeCounts,
                      likedByMe: _likedByMe,
                      busyIds: _busyRouteIds,
                      onOpenDetail: _openDetail,
                      onToggleLike: _toggleLike,
                    );
                  }

                  final r = _routes[index - 1];
                  final rid = r['id'].toString();

                  return ExploreRouteCard(
                    route: r,
                    likeCount: _likeCounts[rid] ?? 0,
                    liked: _likedByMe[rid] ?? false,
                    busy: _busyRouteIds.contains(rid),
                    onOpenDetail: _openDetail,
                    onToggleLike: _toggleLike,
                  );
                },
              ),
            ),
    );
  }
}
