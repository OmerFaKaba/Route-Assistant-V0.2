import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../models/notif_item.dart';
import '../../services/notifications_service.dart';
import '../widget/notification_tile.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  final _client = Supabase.instance.client;
  late final NotificationsService _notifService;

  bool _loading = true;
  String? _error;
  List<NotifItem> _items = [];

  @override
  void initState() {
    super.initState();
    _notifService = NotificationsService(_client);
    _load();
  }

  Future<void> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _items = [];
        _error = 'Giriş yapmalısın.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      // Explore'da limit 10'dı; burada 50 göstermek istiyoruz:
      final items = await _notifService.fetchLatest(limit: 50);

      if (!mounted) return;
      setState(() {
        _items = items;
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

  String _timeText(String iso) {
    final dt = DateTime.tryParse(iso);
    if (dt == null) return '';
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'şimdi';
    if (diff.inMinutes < 60) return '${diff.inMinutes} dk';
    if (diff.inHours < 24) return '${diff.inHours} sa';
    return '${diff.inDays} g';
  }

  Future<void> _openNotif(NotifItem n) async {
    await _notifService.markRead(n.id);

    if (!mounted) return;
    if (n.routeId.isNotEmpty) {
      Navigator.pushNamed(context, '/trailDetail', arguments: n.routeId);
    }

    // listeyi güncelle (mavi nokta kalksın)
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Bildirimler')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(child: Text(_error!))
          : RefreshIndicator(
              onRefresh: _load,
              child: ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final n = _items[i];
                  return NotificationTile(
                    item: n,
                    timeText: _timeText(n.createdAt),
                    onTap: () => _openNotif(n),
                  );
                },
              ),
            ),
    );
  }
}
