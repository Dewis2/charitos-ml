import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_quantity.dart';

class ProductionRecord {
  const ProductionRecord({
    this.id,
    required this.items,
    required this.productionDate,
    required this.createdAt,
  });

  final String? id;
  final List<ProductQuantity> items;
  final DateTime productionDate;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
        'items': items.map((item) => item.toMap()).toList(),
        'productionDate': Timestamp.fromDate(productionDate),
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory ProductionRecord.fromFirestore(
    DocumentSnapshot<Map<String, dynamic>> doc,
  ) {
    final data = doc.data() ?? <String, dynamic>{};
    return ProductionRecord(
      id: doc.id,
      items: ((data['items'] as List<dynamic>?) ?? [])
          .map((item) => ProductQuantity.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      productionDate:
          (data['productionDate'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
