import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/providers/core_providers.dart';

// Définition de l'état
class YearlyComparisonState {
  final int yearN;
  final ({int manto, int sottomanto, int silice}) dataN;
  final ({int manto, int sottomanto, int silice}) dataNMinus1;

  const YearlyComparisonState({
    required this.yearN,
    required this.dataN,
    required this.dataNMinus1,
  });

  int get totalN => dataN.manto + dataN.sottomanto + dataN.silice;
  int get totalNMinus1 =>
      dataNMinus1.manto + dataNMinus1.sottomanto + dataNMinus1.silice;

  double get percentageChange {
    if (totalNMinus1 == 0) return totalN > 0 ? 100.0 : 0.0;
    return ((totalN - totalNMinus1) / totalNMinus1) * 100;
  }

  String get message {
    final diff = percentageChange;
    final absDiff = diff.abs().toStringAsFixed(0);
    final comparison = diff >= 0 ? 'plus' : 'moins';

    if (diff == 0) {
      return "Cette saison ($yearN), votre consommation est identique à l'an dernier (${yearN - 1}).";
    }

    return "Cette saison ($yearN), vous avez consommé $absDiff% de sacs en $comparison que l'an dernier (${yearN - 1}).";
  }
}

// Providers intermédiaires pour récupérer les données de l'année N et N-1
final _yearNProvider =
    StreamProvider.autoDispose<({int manto, int sottomanto, int silice})>((
      ref,
    ) {
      final db = ref.watch(databaseProvider);
      final year = DateTime.now().year;
      return db.watchYearlySacksTotal(year);
    });

final _yearNMinus1Provider =
    StreamProvider.autoDispose<({int manto, int sottomanto, int silice})>((
      ref,
    ) {
      final db = ref.watch(databaseProvider);
      final year = DateTime.now().year - 1;
      return db.watchYearlySacksTotal(year);
    });

// Provider principal combiné
final yearlyComparisonProvider =
    Provider.autoDispose<AsyncValue<YearlyComparisonState>>((ref) {
      final dataNAsync = ref.watch(_yearNProvider);
      final dataNMinus1Async = ref.watch(_yearNMinus1Provider);

      // Si l'un des deux charge, on renvoie loading
      if (dataNAsync.isLoading || dataNMinus1Async.isLoading) {
        return const AsyncValue.loading();
      }

      // Si erreur
      if (dataNAsync.hasError) {
        return AsyncValue.error(dataNAsync.error!, dataNAsync.stackTrace!);
      }
      if (dataNMinus1Async.hasError) {
        return AsyncValue.error(
          dataNMinus1Async.error!,
          dataNMinus1Async.stackTrace!,
        );
      }

      // Si données disponibles
      if (dataNAsync.hasValue && dataNMinus1Async.hasValue) {
        return AsyncValue.data(
          YearlyComparisonState(
            yearN: DateTime.now().year,
            dataN: dataNAsync.value!,
            dataNMinus1: dataNMinus1Async.value!,
          ),
        );
      }

      return const AsyncValue.loading();
    });
