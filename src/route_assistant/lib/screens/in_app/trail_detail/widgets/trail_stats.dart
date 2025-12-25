import 'package:flutter/material.dart';

class TrailStats extends StatelessWidget {
  final double distanceKm;
  final String timeText;
  final String difficulty;

  const TrailStats({
    super.key,
    required this.distanceKm,
    required this.timeText,
    required this.difficulty,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Mesafe: ${distanceKm.toStringAsFixed(2)} km'),
        Text('Süre: $timeText'),
        Text('Zorluk: $difficulty'),
      ],
    );
  }
}
