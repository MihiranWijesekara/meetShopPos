import 'dart:convert';
import 'package:http/http.dart' as http;

class AuthService {
//correct ul
 static const String apiUrl =
      'https://script.google.com/macros/s/AKfycbw6amldD40c19Ovo2MN4gdCD4ERvt2WPDBum8iPn0qozr8BQ4wtX0L7huO4aZfScE3a/exec';

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



  // Method to Sign In
  // static Future<bool> signIn(String username, String password) async {
  //   try {
  //     final url = Uri.parse(
  //       "$apiUrl?action=signin&username=$username&password=$password",
  //     );
  //     final response = await http.get(url);

  //     if (response.statusCode == 200) {
  //       final data = jsonDecode(response.body);
  //       return data["status"] == "success";
  //     }
  //     return false;
  //   } catch (e) {
  //     return false;
  //   }
  // }
}
