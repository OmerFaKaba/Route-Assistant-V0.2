import 'dart:convert';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'package:route_assistant/models/daily_forecast.dart';

class WeatherService {
  Future<List<DailyForecast>> load7DayOpenMeteo(LatLng p) async {
    final uri = Uri.parse(
      'https://api.open-meteo.com/v1/forecast'
      '?latitude=${p.latitude}'
      '&longitude=${p.longitude}'
      '&daily=weathercode,temperature_2m_max,temperature_2m_min'
      '&timezone=auto',
    );

    final res = await http.get(uri);
    if (res.statusCode != 200) {
      throw Exception('Open-Meteo error: ${res.statusCode} ${res.body}');
    }

    final jsonMap = jsonDecode(res.body) as Map<String, dynamic>;
    final daily = (jsonMap['daily'] as Map<String, dynamic>);

    final times = (daily['time'] as List).cast<String>();
    final tmax = (daily['temperature_2m_max'] as List).cast<num>();
    final tmin = (daily['temperature_2m_min'] as List).cast<num>();
    final codes = (daily['weathercode'] as List).cast<num>();

    final n = times.length < 7 ? times.length : 7;
    final out = <DailyForecast>[];

    for (int i = 0; i < n; i++) {
      out.add(
        DailyForecast(
          date: DateTime.parse(times[i]),
          minC: tmin[i].toDouble(),
          maxC: tmax[i].toDouble(),
          description: _weatherCodeToTr(codes[i].toInt()),
        ),
      );
    }
    return out;
  }

  String _weatherCodeToTr(int code) {
    if (code == 0) return 'Açık';
    if (code == 1) return 'Çoğunlukla açık';
    if (code == 2) return 'Parçalı bulutlu';
    if (code == 3) return 'Kapalı';
    if (code == 45 || code == 48) return 'Sis';
    if (code == 51 || code == 53 || code == 55) return 'Çisenti';
    if (code == 56 || code == 57) return 'Donan çisenti';
    if (code == 61 || code == 63 || code == 65) return 'Yağmur';
    if (code == 66 || code == 67) return 'Donan yağmur';
    if (code == 71 || code == 73 || code == 75) return 'Kar';
    if (code == 77) return 'Kar taneleri';
    if (code == 80 || code == 81 || code == 82) return 'Sağanak';
    if (code == 85 || code == 86) return 'Kar sağanağı';
    if (code == 95) return 'Gök gürültülü';
    if (code == 96 || code == 99) return 'Dolu + fırtına';
    return 'Bilinmiyor';
  }
}
