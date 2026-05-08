import 'package:flutter/material.dart';

import '../models/prediction.dart';
import '../services/firestore_service.dart';
import '../services/prediction_api_service.dart';
import '../widgets/async_error_view.dart';

class PredictionsScreen extends StatefulWidget {
  const PredictionsScreen({
    super.key,
    required this.firestoreService,
    required this.predictionApiService,
  });

  final FirestoreService firestoreService;
  final PredictionApiService predictionApiService;

  @override
  State<PredictionsScreen> createState() => _PredictionsScreenState();
}

class _PredictionsScreenState extends State<PredictionsScreen> {
  bool _isLoading = false;
  String? _error;

  Future<void> _requestPrediction() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final recommendations = await widget.predictionApiService
          .fetchRecommendations(targetDate: DateTime.now());
      await widget.firestoreService.createPredictionRecord(
        PredictionRecord(
          recommendations: recommendations,
          requestedAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Predicción guardada.')),
        );
      }
    } catch (error) {
      if (mounted) {
        setState(() => _error = 'No se pudo solicitar predicción: $error');
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Predicciones ML')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Recomendación de producción',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Solicita al backend ML una predicción y guarda el resultado en Firestore.',
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 8),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _isLoading ? null : _requestPrediction,
                    icon: _isLoading
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.auto_graph),
                    label: const Text('Solicitar predicción'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          StreamBuilder<List<PredictionRecord>>(
            stream: widget.firestoreService.watchPredictions(),
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
              if (snapshot.data!.isEmpty) {
                return const Center(child: Text('No hay predicciones guardadas.'));
              }
              return Column(
                children: snapshot.data!
                    .map(
                      (record) => Card(
                        child: ExpansionTile(
                          title: Text(
                            'Predicción ${record.requestedAt.toLocal()}',
                          ),
                          children: record.recommendations
                              .map(
                                (recommendation) => ListTile(
                                  title: Text(recommendation.product),
                                  trailing: Text(
                                    '${recommendation.recommendedQuantity} pzas',
                                  ),
                                  subtitle: recommendation.confidence == null
                                      ? null
                                      : Text(
                                          'Confianza: ${(recommendation.confidence! * 100).toStringAsFixed(0)}%',
                                        ),
                                ),
                              )
                              .toList(),
                        ),
                      ),
                    )
                    .toList(),
              );
            },
          ),
        ],
      ),
    );
  }
}
