import 'package:http/http.dart' as http;

/// NOTE:
/// - Default backend base URL used by services: change BASE_URL if needed.
/// - Authentication endpoints in Django are:
///    POST /authentication/login/
///    POST /authentication/logout/
class AuthService {
  static const String BASE_URL = 'http://localhost:8000';
  static String? sessionCookie; // e.g. "sessionid=xxx; csrftoken=yyy"

  /// Login using Django session-based login.
  /// Returns true on HTTP 200 (success). Saves cookie for later use.
  static Future<bool> login(String username, String password) async {
    final url = Uri.parse('http://localhost:8000/authentication/login/');
    final resp = await http.post(url, body: {
      'username': username,
      'password': password,
    });

    if (resp.statusCode == 200) {
      final setCookie = resp.headers['set-cookie'];
      if (setCookie != null) {
        sessionCookie = _extractCookies(setCookie);
      }
      // even if cookie not found, treat 200 as OK (login view returns 200 on success)
      return true;
    } else {
      return false;
    }
  }

  /// Logout (calls Django logout)
  static Future<bool> logout() async {
    final url = Uri.parse('$BASE_URL/authentication/logout/');
    final headers = <String, String>{};
    if (sessionCookie != null) headers['Cookie'] = sessionCookie!;
    final resp = await http.post(url, headers: headers);
    if (resp.statusCode == 200) {
      sessionCookie = null;
      return true;
    }
    return false;
  }

  /// Helper used by other services to set headers including cookie
  static Map<String, String> defaultHeaders({bool withXRequested = false}) {
    final headers = <String, String>{};
    if (sessionCookie != null) headers['Cookie'] = sessionCookie!;
    if (withXRequested) headers['x-requested-with'] = 'XMLHttpRequest';
    return headers;
  }

  // Parse Set-Cookie header into single cookie string "k=v; k2=v2"
  static String _extractCookies(String setCookieHeader) {
    // setCookieHeader may contain multiple cookies separated by comma(s).
    // we extract cookie name=value parts up to semicolons and join them.
    final parts = setCookieHeader.split(',');
    final cookies = <String>[];
    for (var part in parts) {
      final semi = part.indexOf(';');
      final cookiePart = (semi >= 0) ? part.substring(0, semi).trim() : part.trim();
      if (cookiePart.isNotEmpty) cookies.add(cookiePart);
    }
    return cookies.join('; ');
  }
}
