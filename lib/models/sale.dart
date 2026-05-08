import 'package:cloud_firestore/cloud_firestore.dart';

import 'product_quantity.dart';

class Sale {
  const Sale({
    this.id,
    required this.items,
    required this.totalAmount,
    required this.createdAt,
  });

  final String? id;
  final List<ProductQuantity> items;
  final double totalAmount;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
        'items': items.map((item) => item.toMap()).toList(),
        'totalAmount': totalAmount,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory Sale.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return Sale(
      id: doc.id,
      items: ((data['items'] as List<dynamic>?) ?? [])
          .map((item) => ProductQuantity.fromMap(Map<String, dynamic>.from(item)))
          .toList(),
      totalAmount: (data['totalAmount'] as num? ?? 0).toDouble(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
