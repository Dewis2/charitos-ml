class ProductQuantity {
  const ProductQuantity({
    required this.product,
    required this.quantity,
  });

  final String product;
  final int quantity;

  Map<String, dynamic> toMap() => {
        'product': product,
        'quantity': quantity,
      };

  factory ProductQuantity.fromMap(Map<String, dynamic> map) => ProductQuantity(
        product: (map['product'] ?? '') as String,
        quantity: (map['quantity'] as num? ?? 0).toInt(),
      );
}
