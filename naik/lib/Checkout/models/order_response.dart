class OrderResponse {
  final String status; // "success" or "error"
  final String message;
  final String? orderId;
  final String? total;
  final String? productName;

  OrderResponse({
    required this.status,
    required this.message,
    this.orderId,
    this.total,
    this.productName,
  });

  factory OrderResponse.fromJson(Map<String, dynamic> json) {
    return OrderResponse(
      status: json['status']?.toString() ?? 'error',
      message: json['message']?.toString() ?? '',
      orderId: json['order_id']?.toString(),
      total: json['total']?.toString(),
      productName: json['product_name']?.toString(),
    );
  }

  bool get success => status.toLowerCase() == 'success';
}
