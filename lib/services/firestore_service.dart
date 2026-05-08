import 'package:cloud_firestore/cloud_firestore.dart';

import '../models/prediction.dart';
import '../models/production_record.dart';
import '../models/sale.dart';
import '../models/waste_record.dart';

class DashboardSummary {
  const DashboardSummary({
    required this.todaySalesAmount,
    required this.todayWasteQuantity,
    required this.latestRecommendations,
  });

  final double todaySalesAmount;
  final int todayWasteQuantity;
  final List<PredictionRecommendation> latestRecommendations;
}

class FirestoreService {
  FirestoreService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _sales =>
      _firestore.collection('ventas');
  CollectionReference<Map<String, dynamic>> get _production =>
      _firestore.collection('produccion');
  CollectionReference<Map<String, dynamic>> get _waste =>
      _firestore.collection('merma');
  CollectionReference<Map<String, dynamic>> get _predictions =>
      _firestore.collection('predicciones');

  Future<String> createSale(Sale sale) async =>
      (await _sales.add(sale.toFirestore())).id;

  Stream<List<Sale>> watchSales({int limit = 25}) => _sales
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(Sale.fromFirestore).toList());

  Future<void> updateSale(Sale sale) {
    if (sale.id == null) {
      throw ArgumentError('Sale id is required for updates.');
    }
    return _sales.doc(sale.id).update(sale.toFirestore());
  }

  Future<void> deleteSale(String id) => _sales.doc(id).delete();

  Future<String> createProductionRecord(ProductionRecord record) async =>
      (await _production.add(record.toFirestore())).id;

  Stream<List<ProductionRecord>> watchProduction({int limit = 25}) => _production
      .orderBy('productionDate', descending: true)
      .limit(limit)
      .snapshots()
      .map(
        (snapshot) => snapshot.docs.map(ProductionRecord.fromFirestore).toList(),
      );

  Future<void> updateProductionRecord(ProductionRecord record) {
    if (record.id == null) {
      throw ArgumentError('Production record id is required for updates.');
    }
    return _production.doc(record.id).update(record.toFirestore());
  }

  Future<void> deleteProductionRecord(String id) => _production.doc(id).delete();

  Future<String> createWasteRecord(WasteRecord record) async =>
      (await _waste.add(record.toFirestore())).id;

  Stream<List<WasteRecord>> watchWaste({int limit = 25}) => _waste
      .orderBy('createdAt', descending: true)
      .limit(limit)
      .snapshots()
      .map((snapshot) => snapshot.docs.map(WasteRecord.fromFirestore).toList());

  Future<void> updateWasteRecord(WasteRecord record) {
    if (record.id == null) {
      throw ArgumentError('Waste record id is required for updates.');
    }
    return _waste.doc(record.id).update(record.toFirestore());
  }

  Future<void> deleteWasteRecord(String id) => _waste.doc(id).delete();

  Future<String> createPredictionRecord(PredictionRecord record) async =>
      (await _predictions.add(record.toFirestore())).id;

  Stream<List<PredictionRecord>> watchPredictions({int limit = 10}) =>
      _predictions
          .orderBy('requestedAt', descending: true)
          .limit(limit)
          .snapshots()
          .map(
            (snapshot) =>
                snapshot.docs.map(PredictionRecord.fromFirestore).toList(),
          );

  Future<DashboardSummary> fetchDashboardSummary() async {
    final now = DateTime.now();
    final startOfDay = DateTime(now.year, now.month, now.day);
    final startTimestamp = Timestamp.fromDate(startOfDay);

    final salesQuery = await _sales
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .get();
    final wasteQuery = await _waste
        .where('createdAt', isGreaterThanOrEqualTo: startTimestamp)
        .get();
    final predictionQuery = await _predictions
        .orderBy('requestedAt', descending: true)
        .limit(1)
        .get();

    final salesAmount = salesQuery.docs
        .map((doc) => Sale.fromFirestore(doc).totalAmount)
        .fold<double>(0, (sum, amount) => sum + amount);
    final wasteQuantity = wasteQuery.docs
        .map((doc) => WasteRecord.fromFirestore(doc).quantity)
        .fold<int>(0, (sum, quantity) => sum + quantity);
    final recommendations = predictionQuery.docs.isEmpty
        ? <PredictionRecommendation>[]
        : PredictionRecord.fromFirestore(
            predictionQuery.docs.first,
          ).recommendations;

    return DashboardSummary(
      todaySalesAmount: salesAmount,
      todayWasteQuantity: wasteQuantity,
      latestRecommendations: recommendations,
    );
  }
}
