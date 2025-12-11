class OrderRequest {
  final String productId;
  final int quantity;
  final String address;
  final String paymentMethod; // e.g. "EWALLET","COD","TRANSFER","CREDIT"
  final String shippingType; // e.g. "BIASA","CEPAT","SAME_DAY"
  final bool insurance;
  final String note;

  OrderRequest({
    required this.productId,
    required this.quantity,
    required this.address,
    required this.paymentMethod,
    required this.shippingType,
    required this.insurance,
    required this.note,
  });

  /// Convert to form-data map expected by your Django view
  Map<String, String> toFormData() {
    return {
      'product_id': productId,
      'quantity': quantity.toString(),
      'address': address,
      'payment_method': paymentMethod,
      'shipping_type': shippingType,
      'insurance': insurance ? 'on' : 'off',
      'note': note,
    };
  }
}
