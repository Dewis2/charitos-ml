import 'package:flutter/material.dart';

class ProductQuantityFields extends StatelessWidget {
  const ProductQuantityFields({
    super.key,
    required this.productController,
    required this.quantityController,
    this.priceController,
    this.onRemove,
  });

  final TextEditingController productController;
  final TextEditingController quantityController;
  final TextEditingController? priceController;
  final VoidCallback? onRemove;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            TextFormField(
              controller: productController,
              decoration: const InputDecoration(labelText: 'Producto'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa un producto'
                  : null,
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: quantityController,
                    decoration: const InputDecoration(labelText: 'Cantidad'),
                    keyboardType: TextInputType.number,
                    validator: _positiveIntegerValidator,
                  ),
                ),
                if (priceController != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: priceController,
                      decoration: const InputDecoration(labelText: 'Precio unit.'),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: _positiveDecimalValidator,
                    ),
                  ),
                ],
                if (onRemove != null) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    tooltip: 'Quitar producto',
                    onPressed: onRemove,
                    icon: const Icon(Icons.delete_outline),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  static String? _positiveIntegerValidator(String? value) {
    final parsed = int.tryParse(value ?? '');
    if (parsed == null || parsed <= 0) {
      return 'Cantidad inválida';
    }
    return null;
  }

  static String? _positiveDecimalValidator(String? value) {
    final parsed = double.tryParse(value ?? '');
    if (parsed == null || parsed < 0) {
      return 'Precio inválido';
    }
    return null;
  }
}
