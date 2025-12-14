class CheckoutResponse {
  final String status;
  final String orderId;
  final String total;
  final String productName;

  CheckoutResponse({
    required this.status,
    required this.orderId,
    required this.total,
    required this.productName,
  });

  factory CheckoutResponse.fromJson(Map<String, dynamic> json) {
    return CheckoutResponse(
      status: json['status'],
      orderId: json['order_id'],
      total: json['total'],
      productName: json['product_name'],
    );
  }
}
