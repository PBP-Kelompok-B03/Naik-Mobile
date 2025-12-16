import 'package:pbp_django_auth/pbp_django_auth.dart';
import '../models/order.dart';

class OrderService {
  static Future<List<Order>> fetchOrders(CookieRequest request) async {
    final response = await request.get(
      "http://127.0.0.1:8000/checkout/api/orders/",
    );

    return (response as List)
        .map((json) => Order.fromJson(json))
        .toList();
  }
}
