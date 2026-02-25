import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';
import 'package:school_nx_pro/utils/http_client_manager.dart';

/// Safe logout that preserves homework data and event images
/// Data keys that should be preserved across logout/login
class SafeLogout {
  static const List<String> _homeworkKeysToPreserve = [
    'homeworkList',
    'homework_pending_sync',
    'homework_failed_sync',
  ];

  // Keys to preserve that contain permanent user data
  static const List<String> _permanentDataKeys = [
    'local_event_images', // Event images (both local and server URLs)
  ];

  /// Logout while preserving homework data and event images
  static Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save homework data temporarily
    final Map<String, dynamic> dataToPreserve = {};
    for (final key in _homeworkKeysToPreserve) {
      final value = prefs.getString(key);
      if (value != null) {
        dataToPreserve[key] = value;
      }
    }
    
    // Save permanent data (event images, etc.)
    for (final key in _permanentDataKeys) {
      final value = prefs.getString(key);
      if (value != null) {
        dataToPreserve[key] = value;
      }
    }
    
    // Also preserve all parent_homework_cache_* keys
    final allKeys = prefs.getKeys();
    for (final key in allKeys) {
      if (key.startsWith('parent_homework_cache_')) {
        final value = prefs.getString(key);
        if (value != null) {
          dataToPreserve[key] = value;
        }
      }
    }
    
    // Clear all preferences
    await prefs.clear();
    
    // Restore preserved data
    for (final entry in dataToPreserve.entries) {
      await prefs.setString(entry.key, entry.value as String);
    }
    
    // Also clear auth-related data explicitly (in case clear() didn't work as expected)
    // This is redundant but ensures auth data is cleared
    await MySharedPreferences.instance.removeValue("token");
    await MySharedPreferences.instance.removeValue("refresh_token");
    await MySharedPreferences.instance.removeValue("userType");
    await MySharedPreferences.instance.removeValue("studentId");
    await MySharedPreferences.instance.removeValue("instituteId");
    await MySharedPreferences.instance.removeValue("allottedTeacherId");
    await MySharedPreferences.instance.removeValue("createdByInstituteUserId");
    await MySharedPreferences.instance.removeValue("loginRequestData");
    
    // 🔥 CRITICAL: Reset HTTP clients to clear stale connections
    // This prevents timeout errors after logout/login
    await HttpClientManager.instance.reset();
  }
}

