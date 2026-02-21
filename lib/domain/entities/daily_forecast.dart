class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitationSum;
  final int weatherCode;

  const DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationSum,
    required this.weatherCode,
  });
}
