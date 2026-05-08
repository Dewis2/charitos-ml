import 'package:cloud_firestore/cloud_firestore.dart';

class PredictionRecommendation {
  const PredictionRecommendation({
    required this.product,
    required this.recommendedQuantity,
    this.confidence,
  });

  final String product;
  final int recommendedQuantity;
  final double? confidence;

  Map<String, dynamic> toMap() => {
        'product': product,
        'recommendedQuantity': recommendedQuantity,
        if (confidence != null) 'confidence': confidence,
      };

  factory PredictionRecommendation.fromMap(Map<String, dynamic> map) {
    final quantity = map['recommendedQuantity'] ?? map['quantity'] ?? 0;
    return PredictionRecommendation(
      product: (map['product'] ?? '') as String,
      recommendedQuantity: (quantity as num).toInt(),
      confidence: (map['confidence'] as num?)?.toDouble(),
    );
  }
}

class PredictionRecord {
  const PredictionRecord({
    this.id,
    required this.recommendations,
    required this.requestedAt,
  });

  final String? id;
  final List<PredictionRecommendation> recommendations;
  final DateTime requestedAt;

  Map<String, dynamic> toFirestore() => {
        'recommendations':
            recommendations.map((recommendation) => recommendation.toMap()).toList(),
        'requestedAt': Timestamp.fromDate(requestedAt),
      };

  factory PredictionRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return PredictionRecord(
      id: doc.id,
      recommendations: ((data['recommendations'] as List<dynamic>?) ?? [])
          .map(
            (item) => PredictionRecommendation.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(),
      requestedAt: (data['requestedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
