import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class StorageService {
  static final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();

  static Future<void> write(String key, String value) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(key, value);
    } else {
      await _secureStorage.write(key: key, value: value);
    }
  }

  static Future<String?> read(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(key);
    } else {
      return await _secureStorage.read(key: key);
    }
  }

  static Future<void> delete(String key) async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(key);
    } else {
      await _secureStorage.delete(key: key);
    }
  }

  static Future<void> deleteAll() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
    } else {
      await _secureStorage.deleteAll();
    }
  }
}
