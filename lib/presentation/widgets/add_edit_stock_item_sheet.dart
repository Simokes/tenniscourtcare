import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/stock_item.dart';
import '../providers/stock_provider.dart';

class AddEditStockItemSheet extends StatefulWidget {
  final StockItem? item;

  const AddEditStockItemSheet({super.key, this.item});

  @override
  State<AddEditStockItemSheet> createState() => _AddEditStockItemSheetState();
}

class _AddEditStockItemSheetState extends State<AddEditStockItemSheet> {
  final _formKey = GlobalKey<FormState>();
  late String _name;
  late int _quantity;
  late String _unit;
  String? _comment;
  int? _minThreshold;

  @override
  void initState() {
    super.initState();
    _name = widget.item?.name ?? '';
    _quantity = widget.item?.quantity ?? 0;
    _unit = widget.item?.unit ?? 'pcs';
    _comment = widget.item?.comment;
    _minThreshold = widget.item?.minThreshold;
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.item != null;
    final isCustom = widget.item?.isCustom ?? true;

    return Consumer(
      builder: (context, ref, child) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            left: 16,
            right: 16,
            top: 16,
          ),
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    isEditing ? 'Modifier l\'article' : 'Nouvel article personnalisé',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _name,
                    enabled: isCustom,
                    decoration: const InputDecoration(labelText: 'Nom *', border: OutlineInputBorder()),
                    validator: (v) => (v == null || v.isEmpty) ? 'Requis' : null,
                    onSaved: (v) => _name = v!,
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          initialValue: _quantity.toString(),
                          decoration: const InputDecoration(labelText: 'Quantité *', border: OutlineInputBorder()),
                          keyboardType: TextInputType.number,
                          onSaved: (v) => _quantity = int.tryParse(v ?? '') ?? 0,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: TextFormField(
                          initialValue: _unit,
                          enabled: isCustom,
                          decoration: const InputDecoration(labelText: 'Unité *', border: OutlineInputBorder()),
                          onSaved: (v) => _unit = v ?? 'pcs',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _minThreshold?.toString(),
                    decoration: const InputDecoration(labelText: 'Seuil d\'alerte (optionnel)', border: OutlineInputBorder(), hintText: 'Alerte si quantité ≤ seuil'),
                    keyboardType: TextInputType.number,
                    onSaved: (v) => _minThreshold = int.tryParse(v ?? ''),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    initialValue: _comment,
                    decoration: const InputDecoration(labelText: 'Commentaire', border: OutlineInputBorder()),
                    maxLines: 2,
                    onSaved: (v) => _comment = v,
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => _save(ref),
                    child: Text(isEditing ? 'Mettre à jour' : 'Ajouter'),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  void _save(WidgetRef ref) {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    final now = DateTime.now();
    if (widget.item != null) {
      final updated = widget.item!.copyWith(
        name: _name,
        quantity: _quantity,
        unit: _unit,
        comment: _comment,
        minThreshold: _minThreshold,
        updatedAt: now,
      );
      ref.read(stockNotifierProvider.notifier).updateItem(updated);
    } else {
      final newItem = StockItem(
        name: _name,
        quantity: _quantity,
        unit: _unit,
        comment: _comment,
        isCustom: true,
        minThreshold: _minThreshold,
        updatedAt: now,
      );
      ref.read(stockNotifierProvider.notifier).addItem(newItem);
    }
    Navigator.pop(context);
  }
}
