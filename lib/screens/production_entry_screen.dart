import 'package:flutter/material.dart';

import '../models/product_quantity.dart';
import '../models/production_record.dart';
import '../services/firestore_service.dart';
import '../widgets/async_error_view.dart';
import '../widgets/product_quantity_fields.dart';

class ProductionEntryScreen extends StatefulWidget {
  const ProductionEntryScreen({
    super.key,
    required this.firestoreService,
  });

  final FirestoreService firestoreService;

  @override
  State<ProductionEntryScreen> createState() => _ProductionEntryScreenState();
}

class _ProductionEntryScreenState extends State<ProductionEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_LineControllers> _lines = [_LineControllers()];
  bool _isSaving = false;

  @override
  void dispose() {
    for (final line in _lines) {
      line.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await widget.firestoreService.createProductionRecord(
        ProductionRecord(
          items: _lines
              .map(
                (line) => ProductQuantity(
                  product: line.product.text.trim(),
                  quantity: int.parse(line.quantity.text),
                ),
              )
              .toList(),
          productionDate: DateTime.now(),
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Producción guardada.')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar producción: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar producción')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._lines.asMap().entries.map(
                  (entry) => ProductQuantityFields(
                    productController: entry.value.product,
                    quantityController: entry.value.quantity,
                    onRemove: _lines.length == 1
                        ? null
                        : () {
                            final removed = _lines.removeAt(entry.key);
                            removed.dispose();
                            setState(() {});
                          },
                  ),
                ),
            TextButton.icon(
              onPressed: () => setState(() => _lines.add(_LineControllers())),
              icon: const Icon(Icons.add),
              label: const Text('Agregar producto'),
            ),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar producción'),
            ),
            const SizedBox(height: 24),
            Text(
              'Producción reciente',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            StreamBuilder<List<ProductionRecord>>(
              stream: widget.firestoreService.watchProduction(),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return AsyncErrorView(message: '${snapshot.error}');
                }
                if (!snapshot.hasData) {
                  return const Padding(
                    padding: EdgeInsets.all(24),
                    child: Center(child: CircularProgressIndicator()),
                  );
                }
                return Column(
                  children: snapshot.data!
                      .map(
                        (record) => ListTile(
                          title: Text(
                            record.items
                                .map((item) => '${item.product}: ${item.quantity}')
                                .join(', '),
                          ),
                          subtitle: Text(record.productionDate.toLocal().toString()),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              try {
                                await widget.firestoreService
                                    .deleteProductionRecord(record.id!);
                              } catch (error) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(content: Text('$error')),
                                  );
                                }
                              }
                            },
                          ),
                        ),
                      )
                      .toList(),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}

class _LineControllers {
  final product = TextEditingController();
  final quantity = TextEditingController();

  void dispose() {
    product.dispose();
    quantity.dispose();
  }
}
