enum MaintenanceDuration {
  morning,    // Matinée: openingHour → 12h00
  afternoon,  // Après-midi: 12h00 → closingHour
  fullDay,    // Journée: openingHour → closingHour
  oneHour,    // 1 heure (créneau précis)
}

extension MaintenanceDurationX on MaintenanceDuration {
  String get label => switch (this) {
        MaintenanceDuration.morning => 'Matinée',
        MaintenanceDuration.afternoon => 'Après-midi',
        MaintenanceDuration.fullDay => 'Journée entière',
        MaintenanceDuration.oneHour => '1 heure',
      };

  /// Compute startHour given ClubInfo opening hours
  int startHour(int clubOpeningHour) => switch (this) {
        MaintenanceDuration.morning => clubOpeningHour,
        MaintenanceDuration.afternoon => 12,
        MaintenanceDuration.fullDay => clubOpeningHour,
        MaintenanceDuration.oneHour => clubOpeningHour, // overridden by timePicker
      };

  /// Compute durationMinutes given ClubInfo hours
  int durationMinutes(int clubOpeningHour, int clubClosingHour) =>
      switch (this) {
        MaintenanceDuration.morning => (12 - clubOpeningHour) * 60,
        MaintenanceDuration.afternoon => (clubClosingHour - 12) * 60,
        MaintenanceDuration.fullDay => (clubClosingHour - clubOpeningHour) * 60,
        MaintenanceDuration.oneHour => 60,
      };
}
