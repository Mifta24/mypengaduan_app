import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Service untuk caching data dengan TTL (Time To Live)
class CacheService {
  static const String _prefix = 'cache_';
  static const Duration _defaultTTL = Duration(minutes: 5);

  /// Save data to cache with TTL
  static Future<void> set(
    String key,
    dynamic data, {
    Duration? ttl,
  }) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final expiry = DateTime.now().add(ttl ?? _defaultTTL);
      
      final cacheData = {
        'data': data,
        'expiry': expiry.toIso8601String(),
      };
      
      await prefs.setString('$_prefix$key', jsonEncode(cacheData));
    } catch (e) {
      print('Cache set error: $e');
    }
  }

  /// Get data from cache if not expired
  static Future<dynamic> get(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('$_prefix$key');
      
      if (cached == null) return null;
      
      final cacheData = jsonDecode(cached);
      final expiry = DateTime.parse(cacheData['expiry']);
      
      // Check if expired
      if (DateTime.now().isAfter(expiry)) {
        await remove(key);
        return null;
      }
      
      return cacheData['data'];
    } catch (e) {
      print('Cache get error: $e');
      return null;
    }
  }

  /// Remove specific cache
  static Future<void> remove(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('$_prefix$key');
    } catch (e) {
      print('Cache remove error: $e');
    }
  }

  /// Clear all cache
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.startsWith(_prefix));
      for (var key in keys) {
        await prefs.remove(key);
      }
    } catch (e) {
      print('Cache clear error: $e');
    }
  }

  /// Check if cache exists and not expired
  static Future<bool> has(String key) async {
    final data = await get(key);
    return data != null;
  }
}
