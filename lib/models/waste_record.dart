import 'package:cloud_firestore/cloud_firestore.dart';

class WasteRecord {
  const WasteRecord({
    this.id,
    required this.product,
    required this.quantity,
    required this.reason,
    required this.createdAt,
  });

  final String? id;
  final String product;
  final int quantity;
  final String reason;
  final DateTime createdAt;

  Map<String, dynamic> toFirestore() => {
        'product': product,
        'quantity': quantity,
        'reason': reason,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  factory WasteRecord.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? <String, dynamic>{};
    return WasteRecord(
      id: doc.id,
      product: (data['product'] ?? '') as String,
      quantity: (data['quantity'] as num? ?? 0).toInt(),
      reason: (data['reason'] ?? '') as String,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}
