import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:chicken_dilivery/database/database_helper.dart';

class AuthService {
  //correct ul
  static const String apiUrl =
      'https://script.google.com/macros/s/AKfycbxWkvsXB7z1dj1p8nreqbBJRvbHYoraXwnFRmfStmaI0GcbIXyuwxq-gkDeaA1lRS5c/exec';

  //correct sign in method
  static Future<bool> signIn(String username, String password) async {
    try {
      final url = Uri.parse(
        "$apiUrl?action=login&userName=$username&password=$password",
      );

      final response = await http.get(url);

      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data["status"] == "success";
      }
      return false;
    } catch (e) {
      print("Connection Error: $e");
      return false;
    }
  }

  /// Call the server login endpoint and return structured result.
  static Future<Map<String, dynamic>> loginOnline(
    String username,
    String password,
  ) async {
    try {
      final url = Uri.parse(
        "$apiUrl?action=login&userName=${Uri.encodeComponent(username)}&password=${Uri.encodeComponent(password)}",
      );

      final response = await http.get(url);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        // The Apps Script should ideally return the account status in the response
        // (e.g. { status: 'success', accountStatus: 'Temporary' })
        final accountStatus =
            responseData['accountStatus'] ??
            responseData['userStatus'] ??
            responseData['statusDetail'] ??
            '';
        final success =
            (responseData['status'] == 'success' ||
            responseData['result'] == 'success');
        return {
          'success': success,
          'message': responseData['message'] ?? '',
          'accountStatus': accountStatus,
          'data': responseData,
        };
      }

      return {'success': false, 'message': 'HTTP ${response.statusCode}'};
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Try to login using online check when [internetAvailable] is true; otherwise fallback to local DB.
  /// - If online and login succeeds, saves credentials locally with the returned status (or 'Temporary' if unknown).
  /// - If offline, only allow login when local saved status is 'active'.
  static Future<Map<String, dynamic>> loginWithOfflineSupport(
    String username,
    String password, {
    required bool internetAvailable,
  }) async {
    final db = DatabaseHelper.instance;

    if (internetAvailable) {
      final result = await loginOnline(username, password);

      final message = (result['message'] ?? '').toString();
      final isNetworkError =
          message.contains('SocketException') ||
          message.contains('Failed host lookup') ||
          message.contains('No address associated with hostname');

      if (isNetworkError) {
        // Treat as offline when connectivity exists but internet is unreachable.
        internetAvailable = false;
      }

      if (result['success'] == true) {
        String status = (result['accountStatus'] as String?) ?? '';
        if (status.isEmpty) {
          // If server didn't return explicit account status, default to 'active'.
          // Prefer updating your Apps Script to include the real status in the response.
          status = 'active';
        }

        // Save locally so future offline login works for active users
        await db.saveUserCredentials(username, password, status);

        return {'loggedIn': true, 'source': 'online', 'status': status};
      }

      if (internetAvailable) {
        return {
          'loggedIn': false,
          'source': 'online',
          'message': result['message'],
        };
      }

      // Fall through to offline flow when network is unreachable.
    }

    // Offline login flow
    final local = await db.getLocalUser(username);
    if (local == null)
      return {
        'loggedIn': false,
        'source': 'offline',
        'message': 'No local credentials',
      };

    final savedPass = local['password'] as String? ?? '';
    final savedStatus = (local['status'] as String?)?.toLowerCase() ?? '';

    if (savedPass != password)
      return {
        'loggedIn': false,
        'source': 'offline',
        'message': 'Invalid credentials (offline)',
      };

    // Only active users can login while offline
    if (savedStatus == 'active') {
      return {'loggedIn': true, 'source': 'offline', 'status': 'active'};
    }

    return {
      'loggedIn': false,
      'source': 'offline',
      'message': 'Offline login requires active status',
    };
  }

  static Future<Map<String, dynamic>> signUp({
    required String userName,
    required String firstName,
    required String lastName,
    required String shopName,
    required String phoneNumber,
    required String password,
  }) async {
    try {
      final url = Uri.parse(
        "$apiUrl?action=register&userName=${Uri.encodeComponent(userName)}&firstName=${Uri.encodeComponent(firstName)}&lastName=${Uri.encodeComponent(lastName)}&shopName=${Uri.encodeComponent(shopName)}&phoneNumber=${Uri.encodeComponent(phoneNumber)}&password=${Uri.encodeComponent(password)}",
      );

      final response = await http.get(url);

      if (response.statusCode == 200 ||
          response.statusCode == 201 ||
          response.statusCode == 302) {
        try {
          final responseData = jsonDecode(response.body);
          return {
            'success':
                responseData['status'] == 'success' ||
                responseData['result'] == 'success',
            'message': responseData['message'] ?? "Register successful",
            'data': responseData,
          };
        } catch (e) {
          return {
            'success': true,
            'message': 'Register successful',
            'data': {},
          };
        }
        ;
      } else {
        return {
          'success': false,
          'message': "Registration Failed (Status: ${response.statusCode})",
          'data': {},
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': "Error: ${e.toString()}",
        'data': {},
      };
    }
  }
}
