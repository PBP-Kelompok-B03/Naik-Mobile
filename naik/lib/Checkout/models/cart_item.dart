class CartItem {
  final String id; // product id (string or int as string)
  final String title;
  final double price;
  int quantity;

  CartItem({
    required this.id,
    required this.title,
    required this.price,
    this.quantity = 1,
  });

  double get subtotal => price * quantity;

  Map<String, dynamic> toJson() => {
    'product_id': id,
    'quantity': quantity,
  };
}
