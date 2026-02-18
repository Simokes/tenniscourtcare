/// Utilitaires pour les dates avec timestamps epoch ms
class DateUtils {
  /// Retourne le début de la journée (00:00:00) en epoch ms
  static int startOfDay(DateTime date) {
    final d = DateTime(date.year, date.month, date.day);
    return d.millisecondsSinceEpoch;
  }

  /// Retourne la fin de la journée (23:59:59.999) en epoch ms
  static int endOfDay(DateTime date) {
    final d = DateTime(date.year, date.month, date.day, 23, 59, 59, 999);
    return d.millisecondsSinceEpoch;
  }

  /// Retourne le début de la semaine (lundi 00:00:00) en epoch ms
  static int startOfWeek(DateTime date) {
    final weekday = date.weekday; // 1 = lundi, 7 = dimanche
    final daysFromMonday = weekday == 7 ? 0 : weekday - 1;
    final monday = date.subtract(Duration(days: daysFromMonday));
    return startOfDay(monday);
  }

  /// Retourne la fin de la semaine (dimanche 23:59:59.999) en epoch ms
  static int endOfWeek(DateTime date) {
    final weekday = date.weekday;
    final daysToSunday = weekday == 7 ? 0 : 7 - weekday;
    final sunday = date.add(Duration(days: daysToSunday));
    return endOfDay(sunday);
  }

  /// Retourne le début du mois (1er jour 00:00:00) en epoch ms
  static int startOfMonth(DateTime date) {
    final d = DateTime(date.year, date.month, 1);
    return d.millisecondsSinceEpoch;
  }

  /// Retourne la fin du mois (dernier jour 23:59:59.999) en epoch ms
  static int endOfMonth(DateTime date) {
    final lastDay = DateTime(date.year, date.month + 1, 0);
    return endOfDay(lastDay);
  }
}
