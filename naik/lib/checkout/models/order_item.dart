class OrderItem {
  final String productName;
  final int quantity;
  final String price;

  OrderItem({
    required this.productName,
    required this.quantity,
    required this.price,
  });

  factory OrderItem.fromJson(Map<String, dynamic> json) {
    return OrderItem(
      productName: json['product_name'],
      quantity: json['quantity'],
      price: json['price'],
    );
  }
}
