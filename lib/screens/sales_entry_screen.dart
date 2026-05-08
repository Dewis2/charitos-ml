import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../models/product_quantity.dart';
import '../models/sale.dart';
import '../services/firestore_service.dart';
import '../widgets/async_error_view.dart';
import '../widgets/product_quantity_fields.dart';

class SalesEntryScreen extends StatefulWidget {
  const SalesEntryScreen({
    super.key,
    required this.firestoreService,
  });

  final FirestoreService firestoreService;

  @override
  State<SalesEntryScreen> createState() => _SalesEntryScreenState();
}

class _SalesEntryScreenState extends State<SalesEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final List<_SaleLineControllers> _lines = [_SaleLineControllers()];
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
      final sale = Sale(
        items: _lines
            .map(
              (line) => ProductQuantity(
                product: line.product.text.trim(),
                quantity: int.parse(line.quantity.text),
              ),
            )
            .toList(),
        totalAmount: _lines.fold<double>(
          0,
          (sum, line) =>
              sum + int.parse(line.quantity.text) * double.parse(line.price.text),
        ),
        createdAt: DateTime.now(),
      );
      await widget.firestoreService.createSale(sale);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Venta guardada.')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar venta: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'es_MX');
    final total = _lines.fold<double>(0, (sum, line) {
      final quantity = int.tryParse(line.quantity.text) ?? 0;
      final price = double.tryParse(line.price.text) ?? 0;
      return sum + quantity * price;
    });

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar venta')),
      body: Form(
        key: _formKey,
        onChanged: () => setState(() {}),
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            ..._lines.asMap().entries.map(
                  (entry) => ProductQuantityFields(
                    productController: entry.value.product,
                    quantityController: entry.value.quantity,
                    priceController: entry.value.price,
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
              onPressed: () => setState(() => _lines.add(_SaleLineControllers())),
              icon: const Icon(Icons.add),
              label: const Text('Agregar producto'),
            ),
            const SizedBox(height: 12),
            Text('Total: ${currency.format(total)}'),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar venta'),
            ),
            const SizedBox(height: 24),
            Text('Ventas recientes', style: Theme.of(context).textTheme.titleLarge),
            StreamBuilder<List<Sale>>(
              stream: widget.firestoreService.watchSales(),
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
                        (sale) => ListTile(
                          title: Text(currency.format(sale.totalAmount)),
                          subtitle: Text(
                            sale.items
                                .map((item) => '${item.product}: ${item.quantity}')
                                .join(', '),
                          ),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              try {
                                await widget.firestoreService.deleteSale(sale.id!);
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

class _SaleLineControllers {
  final product = TextEditingController();
  final quantity = TextEditingController();
  final price = TextEditingController();

  void dispose() {
    product.dispose();
    quantity.dispose();
    price.dispose();
  }
}
