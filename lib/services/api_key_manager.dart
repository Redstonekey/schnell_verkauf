import 'package:shared_preferences/shared_preferences.dart';

class ApiKeyManager {
  static const String _apiKeyKey = 'gemini_api_key';
  static SharedPreferences? _prefs;
  
  static Future<void> initialize() async {
    _prefs ??= await SharedPreferences.getInstance();
  }
  
  static Future<void> saveApiKey(String apiKey) async {
    await initialize();
    await _prefs!.setString(_apiKeyKey, apiKey);
  }
  
  static Future<String?> getApiKey() async {
    await initialize();
    return _prefs!.getString(_apiKeyKey);
  }
  
  static Future<bool> hasApiKey() async {
    final apiKey = await getApiKey();
    return apiKey != null && apiKey.isNotEmpty;
  }
  
  static Future<void> clearApiKey() async {
    await initialize();
    await _prefs!.remove(_apiKeyKey);
  }
}
