import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/entities/period_report.dart';

class ShareReportService {
  static Future<void> share(PeriodReport report) async {
    final text = _generateText(report);
    // ignore: deprecated_member_use
    await Share.share(text);
  }

  static String _generateText(PeriodReport report) {
    // Format dates
    // On suppose que l'initialisation de 'fr_FR' a été faite dans main.dart
    final monthFormat = DateFormat.yMMMM('fr_FR');
    final fullFormat = DateFormat.yMMMMd('fr_FR');

    String title;

    // Si la période couvre un mois complet (simplification : même mois/année et > 27 jours d'écart)
    // Ou simplement on affiche le mois si start et end sont dans le même mois
    if (report.start.month == report.end.month && report.start.year == report.end.year) {
       title = 'Rapport - ${monthFormat.format(report.start)}';
       // On capitalize la première lettre du mois (ex: février -> Février)
       title = title.replaceRange(10, 11, title[10].toUpperCase());
    } else {
       title = 'Rapport - ${fullFormat.format(report.start)} au ${fullFormat.format(report.end)}';
    }

    final buffer = StringBuffer();
    buffer.writeln('🎾 $title');
    buffer.writeln('');
    buffer.writeln('🛠 ${report.totalInterventions} interventions effectuées.');
    buffer.writeln('');

    if (report.totalInterventions > 0) {
      buffer.writeln('📦 Consommation :');
      final consumption = <String>[];
      if (report.totalSacksManto > 0) consumption.add('${report.totalSacksManto} sacs de Manto');
      if (report.totalSacksSottomanto > 0) consumption.add('${report.totalSacksSottomanto} sacs de Sottomanto');
      if (report.totalSacksSilice > 0) consumption.add('${report.totalSacksSilice} sacs de Silice');

      if (consumption.isEmpty) {
        buffer.writeln('Aucune consommation de sacs.');
      } else {
        buffer.writeln("${consumption.join(", ")}.");
      }
      buffer.writeln('');

      if (report.mostMaintainedTerrainName != null) {
        buffer.writeln('🏟 Terrain le plus entretenu :');
        buffer.writeln('${report.mostMaintainedTerrainName} (${report.mostMaintainedTerrainCount} fois).');
        buffer.writeln('');
      }
    }

    buffer.writeln('Généré par Court Care');

    return buffer.toString();
  }
}
