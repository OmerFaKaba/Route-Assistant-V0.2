import 'package:flutter/material.dart';
import '../nearby_state.dart';

class RouteBottomSheet extends StatelessWidget {
  final NearbyState state;
  final VoidCallback onDetail;
  final VoidCallback onDirections;

  const RouteBottomSheet({
    super.key,
    required this.state,
    required this.onDetail,
    required this.onDirections,
  });

  @override
  Widget build(BuildContext context) {
    final route = state.selectedRoute;
    final name = route?.name ?? 'Rota';
    final distKm = route?.distanceM == null
        ? null
        : (route!.distanceM! / 1000).toStringAsFixed(1);

    return DraggableScrollableSheet(
      initialChildSize: 0.28,
      minChildSize: 0.22,
      maxChildSize: 0.72,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(22)),
            boxShadow: [BoxShadow(blurRadius: 20, color: Colors.black26)],
          ),
          child: ListView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 16),
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.black26,
                    borderRadius: BorderRadius.circular(99),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  const Icon(Icons.route),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              if (distKm != null)
                Text(
                  "$distKm km uzaklıkta",
                  style: const TextStyle(color: Colors.black54),
                ),
              const SizedBox(height: 14),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDetail,
                      icon: const Icon(Icons.info_outline),
                      label: const Text("Detay"),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: onDirections,
                      icon: const Icon(Icons.directions_walk),
                      label: const Text("Yol Tarifi"),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              const Divider(height: 1),
              const SizedBox(height: 12),
              _buildDetail(),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetail() {
    if (state.sheetLoading) {
      return const Padding(
        padding: EdgeInsets.symmetric(vertical: 22),
        child: Center(child: CircularProgressIndicator()),
      );
    }

    if (state.sheetError != null) {
      return Text(
        "Bilgi alınamadı: ${state.sheetError}",
        style: const TextStyle(color: Colors.red),
      );
    }

    final desc = (state.sheetDescription ?? '').trim();
    final photos = state.sheetPhotos;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (desc.isNotEmpty) ...[
          const Text("Açıklama", style: TextStyle(fontWeight: FontWeight.w800)),
          const SizedBox(height: 6),
          Text(desc),
          const SizedBox(height: 14),
        ],
        if (photos.isNotEmpty) ...[
          const Text(
            "Fotoğraflar",
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 110,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: photos.length,
              separatorBuilder: (_, __) => const SizedBox(width: 10),
              itemBuilder: (context, i) {
                final url = photos[i];
                return ClipRRect(
                  borderRadius: BorderRadius.circular(14),
                  child: AspectRatio(
                    aspectRatio: 16 / 10,
                    child: Image.network(
                      url,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => Container(
                        color: Colors.black12,
                        alignment: Alignment.center,
                        child: const Icon(Icons.broken_image),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
        if (desc.isEmpty && photos.isEmpty)
          const Text(
            "Bu rotada henüz açıklama veya fotoğraf yok.",
            style: TextStyle(color: Colors.black54),
          ),
      ],
    );
  }
}
