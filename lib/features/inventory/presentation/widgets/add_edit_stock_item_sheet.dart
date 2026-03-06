import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:tenniscourtcare/domain/entities/stock_item.dart';
import 'package:tenniscourtcare/domain/logic/stock_categorizer.dart';
import 'package:tenniscourtcare/features/inventory/providers/stock_provider.dart';
import './category_selector.dart';
import 'package:tenniscourtcare/shared/widgets/common/quantity_selector.dart';

class AddEditStockItemSheet extends ConsumerStatefulWidget {
  final StockItem? item;

  const AddEditStockItemSheet({super.key, this.item});

  @override
  ConsumerState<AddEditStockItemSheet> createState() =>
      _AddEditStockItemSheetState();
}

class _AddEditStockItemSheetState extends ConsumerState<AddEditStockItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late int _quantity;
  late String _unit;
  String? _comment;
  int? _minThreshold;
  late String _category;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final i = widget.item;
    if (i != null) {
      _name = i.name;
      _quantity = i.quantity;
      _unit = i.unit;
      _comment = i.comment;
      _minThreshold = i.minThreshold;
      _category = i.category ?? StockCategorizer.getCategory(i);
    } else {
      _name = '';
      _quantity = 0;
      _unit = 'pcs';
      _minThreshold = 5;
      _category = StockCategorizer.materiaux;
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isSaving = true);

    try {
      if (widget.item == null) {
        // ✅ CREATE with sync
        final newItem = StockItem(
          name: _name,
          quantity: _quantity,
          unit: _unit,
          comment: _comment,
          isCustom: true,
          minThreshold: _minThreshold,
          updatedAt: DateTime.now(),
          createdAt: DateTime.now(),
          category: _category,
        );

        // Add item to database
        await ref.read(stockNotifierProvider.notifier).addItem(newItem);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Article ajouté'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        // ✅ UPDATE with sync
        final updated = widget.item!.copyWith(
          name: _name,
          quantity: _quantity,
          unit: _unit,
          comment: _comment,
          minThreshold: _minThreshold,
          updatedAt: DateTime.now(),
          category: _category,
        );

        // Update item in database
        await ref.read(stockNotifierProvider.notifier).updateItem(updated);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Article mis à jour'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  // ✅ DELETE ITEM
  Future<void> _deleteItem() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Supprimer l\'article?'),
        content: const Text('Cette action est irréversible.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Supprimer', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    setState(() => _isSaving = true);

    try {
      if (widget.item?.firebaseId != null) {
        // Delete from database
        await ref
            .read(stockNotifierProvider.notifier)
            .deleteItem(widget.item!.firebaseId!);

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Article supprimé'),
              backgroundColor: Colors.green,
            ),
          );
          Navigator.pop(context);
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Impossible de supprimer: firebaseId manquant.'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('❌ Erreur: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final categories = [
      StockCategorizer.materiaux,
      StockCategorizer.produitsEntretien,
      StockCategorizer.fournitureMaintenance,
      StockCategorizer.autres,
    ];

    return DraggableScrollableSheet(
      initialChildSize: 0.9,
      minChildSize: 0.5,
      maxChildSize: 0.95,
      expand: false,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Handle
              Center(
                child: Container(
                  margin: const EdgeInsets.symmetric(vertical: 12),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        widget.item == null
                            ? 'Nouvel Article'
                            : 'Modifier Article',
                        style: Theme.of(context).textTheme.headlineSmall
                            ?.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                    IconButton.filledTonal(
                      onPressed: _isSaving
                          ? null
                          : () => Navigator.of(context).pop(),
                      icon: const Icon(Icons.close),
                    ),
                  ],
                ),
              ),

              const Divider(),

              Expanded(
                child: SingleChildScrollView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(24),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        // Category Selector
                        Text(
                          'Groupe',
                          style: Theme.of(context).textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        CategorySelector(
                          selectedCategory: _category,
                          categories: categories,
                          onSelected: (val) => setState(() => _category = val),
                          enabled: widget.item == null || widget.item!.isCustom,
                        ),

                        const SizedBox(height: 24),

                        // Name
                        TextFormField(
                          initialValue: _name,
                          decoration: InputDecoration(
                            labelText: 'Nom de l\'article',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            filled: true,
                            fillColor: Colors.grey.shade50,
                          ),
                          validator: (v) =>
                              (v == null || v.isEmpty) ? 'Requis' : null,
                          onSaved: (v) => _name = v!.trim(),
                          enabled: !_isSaving,
                        ),

                        const SizedBox(height: 16),

                        // Quantity & Unit
                        Row(
                          children: [
                            Expanded(
                              flex: 2,
                              child: QuantitySelector(
                                label: 'Quantité',
                                value: _quantity,
                                unit: _unit,
                                onChanged: (val) {
                                  if (!_isSaving) {
                                    setState(() => _quantity = val);
                                  }
                                },
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 1,
                              child: TextFormField(
                                initialValue: _unit,
                                decoration: InputDecoration(
                                  labelText: 'Unité',
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                ),
                                onSaved: (v) => _unit = v?.trim() ?? 'pcs',
                                enabled: !_isSaving,
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        // Threshold
                        TextFormField(
                          initialValue: _minThreshold?.toString(),
                          decoration: InputDecoration(
                            labelText: 'Seuil d\'alerte (min)',
                            helperText: 'Alerte si quantité <= seuil',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            suffixIcon: const Icon(
                              Icons.notifications_outlined,
                            ),
                          ),
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onSaved: (v) => _minThreshold = int.tryParse(v ?? ''),
                          enabled: !_isSaving,
                        ),

                        const SizedBox(height: 16),

                        // Comment
                        TextFormField(
                          initialValue: _comment,
                          decoration: InputDecoration(
                            labelText: 'Commentaire (optionnel)',
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          maxLines: 2,
                          onSaved: (v) => _comment = v?.trim(),
                          enabled: !_isSaving,
                        ),

                        const SizedBox(height: 32),

                        // Save Button
                        FilledButton(
                          onPressed: _isSaving ? null : _save,
                          style: FilledButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Text(
                                  'Enregistrer',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),

                        // ✅ DELETE BUTTON
                        if (widget.item != null)
                          Padding(
                            padding: const EdgeInsets.only(top: 12),
                            child: OutlinedButton(
                              onPressed: _isSaving ? null : _deleteItem,
                              style: OutlinedButton.styleFrom(
                                side: const BorderSide(color: Colors.red),
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                ),
                              ),
                              child: const Text(
                                'Supprimer',
                                style: TextStyle(
                                  color: Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ),

                        const SizedBox(height: 24),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
