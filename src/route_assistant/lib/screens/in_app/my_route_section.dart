import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MyRoutesScreen extends StatefulWidget {
  const MyRoutesScreen({super.key});

  @override
  State<MyRoutesScreen> createState() => _MyRoutesScreenState();
}

class _MyRoutesScreenState extends State<MyRoutesScreen> {
  final _client = Supabase.instance.client;

  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _routes = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final user = _client.auth.currentUser;
    if (user == null) {
      setState(() {
        _loading = false;
        _error = "Giriş yapmalısın.";
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final rows = await _client
          .from('routes')
          .select(
            'id, name, total_distance_m, duration_s, difficulty, photo_urls, inserted_at',
          )
          .eq('owner_id', user.id)
          .order('inserted_at', ascending: false);

      setState(() {
        _routes = List<Map<String, dynamic>>.from(rows);
        _loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  String _formatDistance(num? meters) {
    if (meters == null) return '-';
    final m = meters.toDouble();
    if (m < 1000) return '${m.toStringAsFixed(0)} m';
    return '${(m / 1000).toStringAsFixed(1)} km';
  }

  String _formatDuration(int? seconds) {
    if (seconds == null) return '-';
    final h = seconds ~/ 3600;
    final m = (seconds % 3600) ~/ 60;
    return h > 0 ? '${h}h ${m}m' : '${m} min';
  }

  // ✅ Silme (DB’den gerçek DELETE)
  Future<void> _deleteRoute({
    required String routeId,
    required int index,
    required String routeName,
  }) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Rotayı Sil'),
        content: Text(
          '"$routeName" rotasını silmek istediğine emin misin?\nBu işlem geri alınamaz.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Vazgeç'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (ok != true) return;

    try {
      // ✅ DB’den siler: routes tablosundan id eşleşen satırı DELETE eder
      await _client.from('routes').delete().eq('id', routeId);

      // ✅ UI’dan da kaldır
      if (!mounted) return;
      setState(() {
        _routes.removeAt(index);
      });

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Rota silindi')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Silme hatası: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My Routes'),
        actions: [
          IconButton(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: _loading
            ? const Center(child: CircularProgressIndicator())
            : (_error != null)
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _load,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Tekrar dene'),
                  ),
                ],
              )
            : (_routes.isEmpty)
            ? ListView(
                padding: const EdgeInsets.all(16),
                children: const [Text("Henüz rota oluşturmadın.")],
              )
            : ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: _routes.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, i) {
                  final r = _routes[i];

                  final routeId = r['id'];
                  final name = (r['name'] ?? 'Unnamed route').toString();
                  final distance = _formatDistance(
                    r['total_distance_m'] as num?,
                  );
                  final duration = _formatDuration(r['duration_s'] as int?);
                  final difficulty = (r['difficulty'] ?? '-').toString();

                  final List photos = (r['photo_urls'] ?? []) as List;
                  final coverUrl = photos.isNotEmpty
                      ? photos.first?.toString()
                      : null;

                  return InkWell(
                    borderRadius: BorderRadius.circular(14),

                    // ✅ Detay sayfasına git
                    onTap: () {
                      Navigator.pushNamed(
                        context,
                        '/trailDetail',
                        arguments: routeId.toString(),
                      );
                    },

                    // ✅ Uzun basınca silme
                    onLongPress: () {
                      _deleteRoute(
                        routeId: routeId.toString(),
                        index: i,
                        routeName: name,
                      );
                    },

                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Row(
                        children: [
                          _CoverThumb(url: coverUrl),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  name,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "Mesafe: $distance",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  "Süre: $duration",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  "Zorluk: $difficulty",
                                  style: const TextStyle(fontSize: 12),
                                ),
                                const SizedBox(height: 6),
                                const Text(
                                  "Uzun bas → Sil",
                                  style: TextStyle(fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.chevron_right),
                        ],
                      ),
                    ),
                  );
                },
              ),
      ),
    );
  }
}

class _CoverThumb extends StatelessWidget {
  final String? url;
  const _CoverThumb({this.url});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(10),
      child: Container(
        width: 56,
        height: 56,
        color: Colors.black12,
        child: (url == null || url!.isEmpty)
            ? const Icon(Icons.map_outlined)
            : Image.network(
                url!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.map_outlined),
              ),
      ),
    );
  }
}
