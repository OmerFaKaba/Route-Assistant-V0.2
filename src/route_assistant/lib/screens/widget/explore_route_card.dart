import 'package:flutter/material.dart';

class ExploreRouteCard extends StatelessWidget {
  final dynamic route;

  final int likeCount;
  final bool liked;
  final bool busy;

  final void Function(String routeId) onOpenDetail;
  final void Function(String routeId) onToggleLike;

  const ExploreRouteCard({
    super.key,
    required this.route,
    required this.likeCount,
    required this.liked,
    required this.busy,
    required this.onOpenDetail,
    required this.onToggleLike,
  });

  String _formatDuration(int seconds) {
    final d = Duration(seconds: seconds);
    String two(int n) => n.toString().padLeft(2, '0');
    final h = two(d.inHours);
    final m = two(d.inMinutes.remainder(60));
    return '$h h $m min';
  }

  @override
  Widget build(BuildContext context) {
    final rid = route['id'].toString();

    final distanceKm = (route['total_distance_m'] ?? 0) / 1000.0;
    final durationS = route['duration_s'] ?? 0;

    final photoUrls = (route['photo_urls'] as List?) ?? [];
    final coverUrl = photoUrls.isNotEmpty ? photoUrls.first as String : null;

    return GestureDetector(
      onTap: () => onOpenDetail(rid),
      child: Card(
        margin: const EdgeInsets.only(bottom: 12),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: coverUrl != null
                    ? Image.network(
                        coverUrl,
                        width: 80,
                        height: 80,
                        fit: BoxFit.cover,
                      )
                    : Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[300],
                        child: const Icon(Icons.landscape),
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      route['name'] ?? 'Untitled trail',
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text('Mesafe: ${distanceKm.toStringAsFixed(1)} km'),
                    Text('Süre: ${_formatDuration(durationS)}'),
                    Text(
                      'Zorluk: ${route['difficulty'] ?? '-'}',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        IconButton(
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          onPressed: busy ? null : () => onToggleLike(rid),
                          icon: Icon(
                            liked ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          '$likeCount',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
