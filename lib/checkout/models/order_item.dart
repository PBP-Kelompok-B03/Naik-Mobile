import '/reviews/comment_entry.dart';

class OrderItem {
  final String orderItemId;
  final String productName;
  final String productId;
  final int quantity;
  final String price;
  List<Comment>? comments;

  OrderItem({
    required this.orderItemId,
    required this.productName,
    required this.productId,
    required this.quantity,
    required this.price,
    this.comments,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      orderItemId: json['order_item_id'],
      productName: json['product_name'],
      productId: json['product_id'],
      quantity: json['quantity'],
      price: json['price'],
      comments: json['comments'] != null
          ? List<Comment>.from(json['comments'].map((x) => Comment.fromJson(x)))
          : [],
    );
  }
}