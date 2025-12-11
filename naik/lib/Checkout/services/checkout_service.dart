import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/order_request.dart';
import '../models/order_response.dart';
import 'auth_service.dart';

class CheckoutService {
  // NOTE: change BASE_URL if your backend hosted elsewhere
  static const String BASE_URL = AuthService.BASE_URL; // reuse same base as auth
  static const String CHECKOUT_ENDPOINT = '/checkout/';

  /// Submit an order (form-encoded POST), matching your Django view expectations.
  /// Adds header 'x-requested-with': 'XMLHttpRequest' and Cookie header if logged in.
  static Future<OrderResponse> submitOrder(OrderRequest req) async {
    final uri = Uri.parse('$BASE_URL$CHECKOUT_ENDPOINT');

    final headers = AuthService.defaultHeaders(withXRequested: true);

    final resp = await http.post(uri, headers: headers, body: req.toFormData());

    try {
      final body = utf8.decode(resp.bodyBytes);
      final json = jsonDecode(body);
      return OrderResponse.fromJson(json);
    } catch (e) {
      // If parsing fails, return error-wrapped response
      return OrderResponse(
        status: 'error',
        message: 'HTTP ${resp.statusCode}: ${resp.body}',
      );
    }
  }

  /// Fetch order list page (currently your Django returns HTML).
  /// Best is to implement a JSON endpoint in Django; this returns raw HTML as string.
  static Future<String> fetchOrdersHtml() async {
    final uri = Uri.parse('http://localhost:8000/checkout/orders/');
    final headers = AuthService.defaultHeaders(withXRequested: false);
    final resp = await http.get(uri, headers: headers);
    if (resp.statusCode == 200) {
      return resp.body;
    } else {
      return 'Failed to fetch orders. HTTP ${resp.statusCode}';
    }
  }
}
