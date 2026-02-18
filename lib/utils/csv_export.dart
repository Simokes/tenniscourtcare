import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

// Imports conditionnels
import 'dart:io' if (dart.library.html) 'dart:html' as platform;
import 'csv_export_stub.dart' if (dart.library.html) 'csv_export_web.dart' as web_helper;

class CsvExport {
  /// Exporte les séries de sacs en CSV
  static Future<void> exportSacksSeries({
    required List<({int date, int manto, int sottomanto, int silice})> data,
    required String filename,
    required BuildContext context,
  }) async {
    final csv = _generateSacksSeriesCsv(data);
    await _saveFile(csv, 'export_$filename.csv', context);
  }

  /// Exporte les totaux en CSV
  static Future<void> exportTotals({
    required ({int manto, int sottomanto, int silice}) totals,
    required String filename,
    required BuildContext context,
  }) async {
    final csv = _generateTotalsCsv(totals);
    await _saveFile(csv, 'export_$filename.csv', context);
  }

  /// Méthode privée pour sauvegarder le fichier selon la plateforme
  static Future<void> _saveFile(
    String csv,
    String filename,
    BuildContext context,
  ) async {
    final bytes = Uint8List.fromList(utf8.encode(csv));
    
    if (kIsWeb) {
      // Sur web, utiliser la fonction helper
      web_helper.downloadOnWeb(bytes, filename);
    } else {
      // Sur mobile/desktop, sauvegarder dans le répertoire de documents
      final directory = await getApplicationDocumentsDirectory();
      final file = platform.File('${directory.path}/$filename');
      await file.writeAsBytes(bytes);
    }

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Export CSV réussi')),
      );
    }
  }

  static String _generateSacksSeriesCsv(
    List<({int date, int manto, int sottomanto, int silice})> data,
  ) {
    final buffer = StringBuffer();
    
    // En-têtes
    buffer.writeln('Date,Manto,Sottomanto,Silice,Total');

    // Données
    for (final item in data) {
      final date = DateTime.fromMillisecondsSinceEpoch(item.date);
      final dateStr = '${date.day}/${date.month}/${date.year}';
      final total = item.manto + item.sottomanto + item.silice;
      
      buffer.writeln('$dateStr,${item.manto},${item.sottomanto},${item.silice},$total');
    }

    return buffer.toString();
  }

  static String _generateTotalsCsv(
    ({int manto, int sottomanto, int silice}) totals,
  ) {
    final buffer = StringBuffer();
    
    buffer.writeln('Type,Quantité');
    buffer.writeln('Manto,${totals.manto}');
    buffer.writeln('Sottomanto,${totals.sottomanto}');
    buffer.writeln('Silice,${totals.silice}');
    buffer.writeln('Total,${totals.manto + totals.sottomanto + totals.silice}');

    return buffer.toString();
  }
}
