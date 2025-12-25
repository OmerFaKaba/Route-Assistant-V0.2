class DailyForecast {
  final DateTime date;
  final double minC;
  final double maxC;
  final String description;

  const DailyForecast({
    required this.date,
    required this.minC,
    required this.maxC,
    required this.description,
  });
}
