import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

/// Centralized HTTP Client Manager
/// Manages HTTP clients with proper timeout and connection settings
/// Can be reset on logout to clear stale connections
class HttpClientManager {
  static HttpClientManager? _instance;
  http.Client? _client;
  HttpClient? _httpClient;

  HttpClientManager._();

  static HttpClientManager get instance {
    _instance ??= HttpClientManager._();
    return _instance!;
  }

  /// Get or create HTTP client with proper configuration
  http.Client getClient() {
    if (_client == null) {
      _httpClient = HttpClient()
        ..connectionTimeout = const Duration(seconds: 30)
        ..idleTimeout = const Duration(seconds: 30)
        ..maxConnectionsPerHost = 5;

      if (kDebugMode) {
        _httpClient!.badCertificateCallback =
            (X509Certificate cert, String host, int port) => true;
      }

      _client = IOClient(_httpClient);
    }
    return _client!;
  }

  /// Reset and close existing client, create a new one
  /// Call this on logout to clear stale connections
  Future<void> reset() async {
    try {
      _client?.close();
      _client = null;
    } catch (e) {
      debugPrint("Error closing HTTP client: $e");
    }

    try {
      _httpClient?.close(force: true);
      _httpClient = null;
    } catch (e) {
      debugPrint("Error closing HttpClient: $e");
    }

    // Create fresh client
    getClient();
  }

  /// Close all connections (for cleanup)
  Future<void> close() async {
    await reset();
  }
}

