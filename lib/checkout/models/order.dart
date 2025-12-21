import 'order_item.dart';

class Order {
  final String id;
  final String totalPrice;
  final String paymentMethod;
  final String shippingType;
  final bool insurance;
  final String status;
  final String createdAt;
  final List<OrderItem> items;

  Order({
    required this.id,
    required this.totalPrice,
    required this.paymentMethod,
    required this.shippingType,
    required this.insurance,
    required this.status,
    required this.createdAt,
    required this.items,
  });

  factory Order.fromJson(Map<String, dynamic> json) {
    return Order(
      id: json['id'],
      totalPrice: json['total_price'],
      paymentMethod: json['payment_method'],
      shippingType: json['shipping_type'],
      insurance: json['insurance'],
      status: json['status'],
      createdAt: json['created_at'],
      items: (json['items'] as List)
          .map((e) => OrderItem.fromJson(e))
          .toList(),
    );
  }
}
