import 'package:shared_preferences/shared_preferences.dart';

class SessionStore {
  static const _tokenKey = 'access_token';
  static const _companyKey = 'company_name';

  Future<void> save({required String token, required String companyName}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_companyKey, companyName);
  }

  Future<String?> token() async => (await SharedPreferences.getInstance()).getString(_tokenKey);
  Future<String?> companyName() async => (await SharedPreferences.getInstance()).getString(_companyKey);

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
    await prefs.remove(_companyKey);
  }
}
