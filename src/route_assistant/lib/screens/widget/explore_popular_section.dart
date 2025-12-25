import 'package:flutter/material.dart';

class ExplorePopularSection extends StatelessWidget {
  final List<dynamic> popularRoutes;
  final Map<String, int> likeCounts;
  final Map<String, bool> likedByMe;
  final Set<String> busyIds;

  final void Function(String routeId) onOpenDetail;
  final void Function(String routeId) onToggleLike;

  const ExplorePopularSection({
    super.key,
    required this.popularRoutes,
    required this.likeCounts,
    required this.likedByMe,
    required this.busyIds,
    required this.onOpenDetail,
    required this.onToggleLike,
  });

  @override
  Widget build(BuildContext context) {
    if (popularRoutes.isEmpty) return const SizedBox.shrink();

    final count = popularRoutes.length > 5 ? 5 : popularRoutes.length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          '🔥 Popüler Rotalar',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 140,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: count,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (context, index) {
              final r = popularRoutes[index];
              final rid = r['id'].toString();

              final photoUrls = (r['photo_urls'] as List?) ?? [];
              final coverUrl = photoUrls.isNotEmpty
                  ? photoUrls.first as String
                  : null;

              final likeCount = likeCounts[rid] ?? 0;
              final liked = likedByMe[rid] ?? false;
              final busy = busyIds.contains(rid);

              return InkWell(
                onTap: () => onOpenDetail(rid),
                borderRadius: BorderRadius.circular(14),
                child: Container(
                  width: 190,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: Colors.black12),
                  ),
                  child: Row(
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: coverUrl != null
                            ? Image.network(
                                coverUrl,
                                width: 60,
                                height: 80,
                                fit: BoxFit.cover,
                              )
                            : Container(
                                width: 60,
                                height: 80,
                                color: Colors.grey[300],
                                child: const Icon(Icons.landscape),
                              ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              r['name'] ?? 'Untitled',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                IconButton(
                                  padding: EdgeInsets.zero,
                                  constraints: const BoxConstraints(),
                                  onPressed: busy
                                      ? null
                                      : () => onToggleLike(rid),
                                  icon: Icon(
                                    liked
                                        ? Icons.favorite
                                        : Icons.favorite_border,
                                    size: 18,
                                  ),
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  '$likeCount',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w600,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
