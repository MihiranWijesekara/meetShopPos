import 'package:shared_preferences/shared_preferences.dart';

class PreferencesHelper {
  static final PreferencesHelper _instance = PreferencesHelper._internal();
  factory PreferencesHelper() => _instance;

  PreferencesHelper._internal();

  // Keys for shared preferences
  static const String _rememberMeKey = 'remember_me';
  static const String _usernameKey = 'saved_username';
  static const String _passwordKey = 'saved_password';
  static const String _isLoggedInKey = 'is_logged_in';

  // Save remember me credentials
  Future<void> saveCredentials(
    String username,
    String password,
    bool rememberMe,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, rememberMe);

    if (rememberMe) {
      await prefs.setString(_usernameKey, username);
      await prefs.setString(_passwordKey, password);
    } else {
      await prefs.remove(_usernameKey);
      await prefs.remove(_passwordKey);
    }
  }

  // Get saved credentials
  Future<Map<String, dynamic>> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;

    if (rememberMe) {
      return {
        'rememberMe': rememberMe,
        'username': prefs.getString(_usernameKey) ?? '',
        'password': prefs.getString(_passwordKey) ?? '',
      };
    }

    return {'rememberMe': false, 'username': '', 'password': ''};
  }

  // Save login state
  Future<void> setLoggedIn(bool isLoggedIn) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_isLoggedInKey, isLoggedIn);
  }

  // Check if user is logged in
  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_isLoggedInKey) ?? false;
  }

  // Clear all saved data (for logout)
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
