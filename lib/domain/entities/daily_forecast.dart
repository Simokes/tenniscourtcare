class DailyForecast {
  final DateTime date;
  final double tempMax;
  final double tempMin;
  final double precipitationSum;
  final int weatherCode;
  final double windSpeed; // km/h max du jour

  const DailyForecast({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitationSum,
    required this.weatherCode,
    required this.windSpeed,
  });

  DailyForecast copyWith({
    DateTime? date,
    double? tempMax,
    double? tempMin,
    double? precipitationSum,
    int? weatherCode,
    double? windSpeed,
  }) {
    return DailyForecast(
      date: date ?? this.date,
      tempMax: tempMax ?? this.tempMax,
      tempMin: tempMin ?? this.tempMin,
      precipitationSum: precipitationSum ?? this.precipitationSum,
      weatherCode: weatherCode ?? this.weatherCode,
      windSpeed: windSpeed ?? this.windSpeed,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is DailyForecast &&
        other.date == date &&
        other.tempMax == tempMax &&
        other.tempMin == tempMin &&
        other.precipitationSum == precipitationSum &&
        other.weatherCode == weatherCode &&
        other.windSpeed == windSpeed;
  }

  @override
  int get hashCode {
    return date.hashCode ^
        tempMax.hashCode ^
        tempMin.hashCode ^
        precipitationSum.hashCode ^
        weatherCode.hashCode ^
        windSpeed.hashCode;
  }
}
