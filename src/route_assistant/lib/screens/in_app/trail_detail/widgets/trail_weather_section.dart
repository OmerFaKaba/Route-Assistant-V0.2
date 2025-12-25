import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:route_assistant/models/daily_forecast.dart';

class TrailWeatherSection extends StatelessWidget {
  final bool loading;
  final String? error;
  final List<DailyForecast> forecast;

  const TrailWeatherSection({
    super.key,
    required this.loading,
    required this.error,
    required this.forecast,
  });

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return const Row(
        children: [
          SizedBox(
            width: 18,
            height: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
          SizedBox(width: 10),
          Expanded(child: Text("7 günlük hava tahmini yükleniyor...")),
        ],
      );
    }

    if (error != null) {
      return Text(
        "Hava tahmini alınamadı: $error",
        style: const TextStyle(color: Colors.red),
      );
    }

    if (forecast.isEmpty) return const SizedBox.shrink();

    final df = DateFormat('EEE, d MMM');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "7 Günlük Hava Tahmini",
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),

        // ✅ Burada overflow fix var: cardWidth ekrana göre hesaplanıyor
        LayoutBuilder(
          builder: (context, c) {
            final w = c.maxWidth;

            // 1 kartın ideal genişliği:
            // küçük ekranda ~0.55 * width, büyük ekranda max 160
            final cardWidth = math.min(160.0, math.max(120.0, w * 0.55));

            return SizedBox(
              height: 92,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                itemCount: forecast.length,
                separatorBuilder: (_, __) => const SizedBox(width: 10),
                itemBuilder: (context, i) {
                  final d = forecast[i];

                  return SizedBox(
                    width: cardWidth,
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: Colors.black12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            df.format(d.date),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            d.description,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 12),
                          ),
                          const Spacer(),
                          FittedBox(
                            fit: BoxFit.scaleDown,
                            alignment: Alignment.centerLeft,
                            child: Text(
                              "${d.minC.toStringAsFixed(0)}° / ${d.maxC.toStringAsFixed(0)}°",
                              style: const TextStyle(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ],
    );
  }
}
