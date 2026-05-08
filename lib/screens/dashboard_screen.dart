import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../services/auth_service.dart';
import '../services/firestore_service.dart';
import '../services/prediction_api_service.dart';
import '../widgets/async_error_view.dart';
import '../widgets/summary_card.dart';
import 'merma_entry_screen.dart';
import 'predictions_screen.dart';
import 'production_entry_screen.dart';
import 'sales_entry_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({
    super.key,
    required this.authService,
    required this.firestoreService,
    required this.predictionApiService,
  });

  final AuthService authService;
  final FirestoreService firestoreService;
  final PredictionApiService predictionApiService;

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late Future<DashboardSummary> _summaryFuture;

  @override
  void initState() {
    super.initState();
    _summaryFuture = widget.firestoreService.fetchDashboardSummary();
  }

  void _refresh() {
    setState(() {
      _summaryFuture = widget.firestoreService.fetchDashboardSummary();
    });
  }

  void _open(Widget screen) {
    Navigator.of(context)
        .push(MaterialPageRoute<void>(builder: (_) => screen))
        .then((_) => _refresh());
  }

  @override
  Widget build(BuildContext context) {
    final currency = NumberFormat.simpleCurrency(locale: 'es_MX');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Charito’s Dashboard'),
        actions: [
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _refresh,
            icon: const Icon(Icons.refresh),
          ),
          IconButton(
            tooltip: 'Cerrar sesión',
            onPressed: widget.authService.signOut,
            icon: const Icon(Icons.logout),
          ),
        ],
      ),
      body: FutureBuilder<DashboardSummary>(
        future: _summaryFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return AsyncErrorView(
              message: 'No se pudo cargar el dashboard: ${snapshot.error}',
              onRetry: _refresh,
            );
          }

          final summary = snapshot.data!;
          return RefreshIndicator(
            onRefresh: () async => _refresh(),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                SummaryCard(
                  title: 'Ventas de hoy',
                  value: currency.format(summary.todaySalesAmount),
                  icon: Icons.point_of_sale,
                  color: Colors.green,
                ),
                SummaryCard(
                  title: 'Merma de hoy',
                  value: '${summary.todayWasteQuantity} piezas',
                  icon: Icons.delete_sweep,
                  color: Colors.orange,
                ),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Recomendaciones recientes',
                          style: Theme.of(context).textTheme.titleMedium,
                        ),
                        const SizedBox(height: 8),
                        if (summary.latestRecommendations.isEmpty)
                          const Text('Aún no hay predicciones guardadas.')
                        else
                          ...summary.latestRecommendations.take(5).map(
                                (recommendation) => ListTile(
                                  dense: true,
                                  contentPadding: EdgeInsets.zero,
                                  title: Text(recommendation.product),
                                  trailing: Text(
                                    '${recommendation.recommendedQuantity} pzas',
                                  ),
                                ),
                              ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                _ActionButton(
                  label: 'Registrar venta',
                  icon: Icons.add_shopping_cart,
                  onTap: () => _open(
                    SalesEntryScreen(firestoreService: widget.firestoreService),
                  ),
                ),
                _ActionButton(
                  label: 'Registrar producción',
                  icon: Icons.inventory_2,
                  onTap: () => _open(
                    ProductionEntryScreen(
                      firestoreService: widget.firestoreService,
                    ),
                  ),
                ),
                _ActionButton(
                  label: 'Registrar merma',
                  icon: Icons.delete_outline,
                  onTap: () => _open(
                    MermaEntryScreen(firestoreService: widget.firestoreService),
                  ),
                ),
                _ActionButton(
                  label: 'Ver predicciones ML',
                  icon: Icons.auto_graph,
                  onTap: () => _open(
                    PredictionsScreen(
                      firestoreService: widget.firestoreService,
                      predictionApiService: widget.predictionApiService,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: FilledButton.icon(
        onPressed: onTap,
        icon: Icon(icon),
        label: Padding(
          padding: const EdgeInsets.symmetric(vertical: 12),
          child: Text(label),
        ),
      ),
    );
  }
}
