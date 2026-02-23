import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/stock_item.dart';
import '../../domain/entities/refill_recommendation.dart';
import '../providers/stock_provider.dart';
import 'premium/premium_card.dart';

class RefillRecommendationCard extends ConsumerWidget {
  final RefillRecommendation recommendation;

  const RefillRecommendationCard({
    super.key,
    required this.recommendation,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // Watch stock items
    final stockItemsAsync = ref.watch(stockItemsProvider);

    // Calculate stock status
    int? availableManto;
    bool isInsufficient = false;

    // We try to find Manto if data is available
    if (stockItemsAsync.hasValue) {
      final items = stockItemsAsync.value!;
      // Recherche insensible à la casse
      final mantoItem = items.cast<StockItem?>().firstWhere(
        (item) => item!.name.toLowerCase().contains('manto'),
        orElse: () => null,
      );

      if (mantoItem != null) {
        availableManto = mantoItem.quantity;
        isInsufficient = availableManto < recommendation.recommendedBags;
      }
    }

    // Couleur dynamique : Critique (selon l'algo) OU Stock Insuffisant
    // Si stock insuffisant, on force le rouge (alerte).
    final showRedAlert = recommendation.isCritical || isInsufficient;

    final accentColor = showRedAlert
        ? Colors.red.shade700
        : Colors.blueGrey.shade700;

    final backgroundColor = showRedAlert
        ? Colors.red.shade50
        : Colors.blueGrey.shade50;

    return PremiumCard(
      color: backgroundColor,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.lightbulb_outline, color: accentColor),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Recommandation Smart Refill',
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: accentColor,
                  ),
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Bloc nombre de sacs
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: accentColor.withValues(alpha: 0.3)),
                ),
                child: Column(
                  children: [
                    Text(
                      '${recommendation.recommendedBags}',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: accentColor,
                      ),
                    ),
                    Text(
                      'Sacs',
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: Colors.grey.shade700,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              // Bloc explication
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recommendation.reason,
                      style: theme.textTheme.bodyMedium?.copyWith(height: 1.4),
                    ),
                    const SizedBox(height: 12),

                    // Alerte Stock Insuffisant
                    if (isInsufficient && availableManto != null)
                       Padding(
                         padding: const EdgeInsets.only(bottom: 12.0),
                         child: Row(
                           children: [
                             const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 20),
                             const SizedBox(width: 8),
                             Expanded(
                               child: Text(
                                 '⚠️ Stock insuffisant pour la recharge conseillée (Dispo: $availableManto)',
                                 style: const TextStyle(
                                   color: Colors.red,
                                   fontWeight: FontWeight.bold,
                                   fontSize: 13, // Slightly larger for readability
                                 ),
                               ),
                             ),
                           ],
                         ),
                       ),

                    InkWell(
                      onTap: () => _checkStock(context, ref, recommendation.recommendedBags),
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: accentColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: accentColor.withValues(alpha: 0.5)),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.inventory_2_outlined, size: 16, color: accentColor),
                            const SizedBox(width: 6),
                            Text(
                              'Vérifier le stock',
                              style: theme.textTheme.labelSmall?.copyWith(
                                color: accentColor,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _checkStock(BuildContext context, WidgetRef ref, int requiredBags) {
    // Lire la liste des items de stock de manière asynchrone sans watch
    ref.read(stockItemsProvider.future).then((items) {
      if (!context.mounted) return;

      // Recherche insensible à la casse
      final mantoItem = items.cast<StockItem?>().firstWhere(
        (item) => item!.name.toLowerCase().contains('manto'),
        orElse: () => null,
      );

      if (mantoItem == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Article 'Manto' introuvable dans le stock."),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }

      final available = mantoItem.quantity;
      final missing = requiredBags - available;

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(missing > 0 ? 'Stock Insuffisant' : 'Stock Suffisant'),
          icon: Icon(
            missing > 0 ? Icons.warning_amber : Icons.check_circle_outline,
            color: missing > 0 ? Colors.red : Colors.green,
            size: 48,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _row('Recommandé :', '$requiredBags sacs'),
              _row('En stock :', '$available sacs'),
              const Divider(),
              if (missing > 0)
                Text(
                  'Il manque $missing sacs pour suivre la recommandation.',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                )
              else
                const Text(
                  'Le stock couvre la quantité recommandée.',
                  style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('OK'),
            ),
          ],
        ),
      );
    });
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
