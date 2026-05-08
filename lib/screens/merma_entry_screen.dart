import 'package:flutter/material.dart';

import '../models/waste_record.dart';
import '../services/firestore_service.dart';
import '../widgets/async_error_view.dart';

class MermaEntryScreen extends StatefulWidget {
  const MermaEntryScreen({
    super.key,
    required this.firestoreService,
  });

  final FirestoreService firestoreService;

  @override
  State<MermaEntryScreen> createState() => _MermaEntryScreenState();
}

class _MermaEntryScreenState extends State<MermaEntryScreen> {
  final _formKey = GlobalKey<FormState>();
  final _productController = TextEditingController();
  final _quantityController = TextEditingController();
  final _reasonController = TextEditingController();
  bool _isSaving = false;

  @override
  void dispose() {
    _productController.dispose();
    _quantityController.dispose();
    _reasonController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);

    try {
      await widget.firestoreService.createWasteRecord(
        WasteRecord(
          product: _productController.text.trim(),
          quantity: int.parse(_quantityController.text),
          reason: _reasonController.text.trim(),
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Merma guardada.')),
        );
        Navigator.pop(context);
      }
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error al guardar merma: $error')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar merma')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _productController,
              decoration: const InputDecoration(labelText: 'Producto'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa un producto'
                  : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _quantityController,
              decoration: const InputDecoration(labelText: 'Cantidad'),
              keyboardType: TextInputType.number,
              validator: (value) {
                final parsed = int.tryParse(value ?? '');
                return parsed == null || parsed <= 0 ? 'Cantidad inválida' : null;
              },
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _reasonController,
              decoration: const InputDecoration(labelText: 'Motivo'),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Ingresa el motivo'
                  : null,
            ),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: _isSaving ? null : _save,
              icon: const Icon(Icons.save),
              label: const Text('Guardar merma'),
            ),
            const SizedBox(height: 24),
            Text('Merma reciente', style: Theme.of(context).textTheme.titleLarge),
            StreamBuilder<List<WasteRecord>>(
              stream: widget.firestoreService.watchWaste(),
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
                          title: Text('${record.product}: ${record.quantity} pzas'),
                          subtitle: Text(record.reason),
                          trailing: IconButton(
                            icon: const Icon(Icons.delete_outline),
                            onPressed: () async {
                              try {
                                await widget.firestoreService
                                    .deleteWasteRecord(record.id!);
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
