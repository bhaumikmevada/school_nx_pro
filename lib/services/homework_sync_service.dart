import 'dart:convert';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_nx_pro/repository/homework_repo.dart';
import 'package:intl/intl.dart';

/// Sync status for homework items
enum SyncStatus {
  synced,      // ✓ Successfully synced to server
  syncing,     // 🔁 Currently syncing
  pending,     // ⏳ Waiting to sync (offline)
  failed,      // ⚠ Failed to sync (needs retry)
}

/// Homework sync service that handles offline queue and automatic sync
class HomeworkSyncService {
  static const String _pendingQueueKey = 'homework_pending_sync';
  static const String _failedQueueKey = 'homework_failed_sync';
  static final HomeworkSyncService _instance = HomeworkSyncService._internal();
  final HomeworkRepo _repo = HomeworkRepo();
  final Connectivity _connectivity = Connectivity();

  factory HomeworkSyncService() => _instance;
  HomeworkSyncService._internal();

  /// Check if device is online
  /// Works on both Android and iOS
  Future<bool> isOnline() async {
    try {
      // Check connectivity status using connectivity_plus
      final result = await _connectivity.checkConnectivity();
      
      // If no connectivity at all, return false immediately
      if (result.contains(ConnectivityResult.none)) {
        return false;
      }
      
      // Additional verification: try to reach a known server
      // This helps catch cases where device is connected to WiFi but has no internet
      try {
        final lookupResult = await InternetAddress.lookup('google.com')
            .timeout(const Duration(seconds: 3));
        return lookupResult.isNotEmpty && lookupResult[0].rawAddress.isNotEmpty;
      } catch (_) {
        // If lookup fails, we still have connectivity (WiFi/Mobile) but no internet
        // Return true anyway since connectivity_plus detected a connection
        // The actual API call will fail if there's no real internet
        return true;
      }
    } catch (e) {
      debugPrint('Connectivity check error: $e');
      // On error, assume offline to be safe
      return false;
    }
  }

  /// Save homework locally with sync status
  Future<void> saveHomeworkLocally(
    Map<String, dynamic> homework, {
    SyncStatus syncStatus = SyncStatus.pending,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString("homeworkList");
    List<Map<String, dynamic>> homeworkList = [];

    if (savedData != null) {
      homeworkList = List<Map<String, dynamic>>.from(jsonDecode(savedData));
    }

    // Add sync status to homework
    final homeworkWithStatus = {
      ...homework,
      'syncStatus': syncStatus.name,
      'lastSyncAttempt': DateTime.now().toIso8601String(),
    };

    // Remove duplicate by homeWorkId if it exists
    homeworkList.removeWhere((hw) =>
        hw['homeWorkId'] != null &&
        hw['homeWorkId'].toString() == homework['homeWorkId'].toString() &&
        homework['homeWorkId'].toString().isNotEmpty);

    // If no server ID, also check by temporary local ID
    if (homework['homeWorkId'] == null || homework['homeWorkId'].toString().isEmpty) {
      final tempId = homework['tempLocalId'] ?? _generateTempId();
      homeworkWithStatus['tempLocalId'] = tempId;
      homeworkList.removeWhere((hw) => hw['tempLocalId'] == tempId);
    }

    homeworkList.insert(0, homeworkWithStatus);
    await prefs.setString("homeworkList", jsonEncode(homeworkList));
  }

  String _generateTempId() {
    return 'temp_${DateTime.now().millisecondsSinceEpoch}';
  }

  /// Add homework to pending sync queue
  Future<void> addToPendingQueue(Map<String, dynamic> homework) async {
    final prefs = await SharedPreferences.getInstance();
    final queueData = prefs.getString(_pendingQueueKey);
    List<Map<String, dynamic>> queue = [];

    if (queueData != null) {
      queue = List<Map<String, dynamic>>.from(jsonDecode(queueData));
    }

    // Check if already in queue
    final tempId = homework['tempLocalId'] ?? _generateTempId();
    homework['tempLocalId'] = tempId;
    queue.removeWhere((item) => item['tempLocalId'] == tempId);
    queue.add(homework);

    await prefs.setString(_pendingQueueKey, jsonEncode(queue));
  }

  /// Add homework to failed sync queue
  Future<void> addToFailedQueue(Map<String, dynamic> homework) async {
    final prefs = await SharedPreferences.getInstance();
    final queueData = prefs.getString(_failedQueueKey);
    List<Map<String, dynamic>> queue = [];

    if (queueData != null) {
      queue = List<Map<String, dynamic>>.from(jsonDecode(queueData));
    }

    final tempId = homework['tempLocalId'] ?? _generateTempId();
    homework['tempLocalId'] = tempId;
    queue.removeWhere((item) => item['tempLocalId'] == tempId);
    queue.add(homework);

    await prefs.setString(_failedQueueKey, jsonEncode(queue));
  }

  /// Remove from pending queue
  Future<void> removeFromPendingQueue(String tempLocalId) async {
    final prefs = await SharedPreferences.getInstance();
    final queueData = prefs.getString(_pendingQueueKey);
    if (queueData == null) return;

    List<Map<String, dynamic>> queue =
        List<Map<String, dynamic>>.from(jsonDecode(queueData));
    queue.removeWhere((item) => item['tempLocalId'] == tempLocalId);
    await prefs.setString(_pendingQueueKey, jsonEncode(queue));
  }

  /// Remove from failed queue
  Future<void> removeFromFailedQueue(String tempLocalId) async {
    final prefs = await SharedPreferences.getInstance();
    final queueData = prefs.getString(_failedQueueKey);
    if (queueData == null) return;

    List<Map<String, dynamic>> queue =
        List<Map<String, dynamic>>.from(jsonDecode(queueData));
    queue.removeWhere((item) => item['tempLocalId'] == tempLocalId);
    await prefs.setString(_failedQueueKey, jsonEncode(queue));
  }

  /// Get pending queue
  Future<List<Map<String, dynamic>>> getPendingQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueData = prefs.getString(_pendingQueueKey);
    if (queueData == null) return [];

    return List<Map<String, dynamic>>.from(jsonDecode(queueData));
  }

  /// Get failed queue
  Future<List<Map<String, dynamic>>> getFailedQueue() async {
    final prefs = await SharedPreferences.getInstance();
    final queueData = prefs.getString(_failedQueueKey);
    if (queueData == null) return [];

    return List<Map<String, dynamic>>.from(jsonDecode(queueData));
  }

  /// Sync a single homework item to server
  Future<Map<String, dynamic>?> syncHomeworkToServer(
    Map<String, dynamic> homework,
  ) async {
    try {
      final subjectId = homework['subjectId']?.toString() ?? '';
      final homeWorkDate = homework['fromDate']?.toString() ?? '';
      final homeWorkDueOnDate = homework['toDate']?.toString() ?? '';
      final homeWorkName = homework['title']?.toString() ?? '';
      final homeWorkDescription = homework['description']?.toString() ?? '';
      final attachmentPath = homework['attachment'] as String?;

      // Convert date format if needed
      String formattedDate = homeWorkDate;
      String formattedDueDate = homeWorkDueOnDate;

      if (homeWorkDate.contains('-') && !homeWorkDate.contains('T')) {
        try {
          final date = DateTime.parse(homeWorkDate);
          formattedDate = DateFormat('dd-MM-yyyy').format(date);
        } catch (_) {}
      }

      if (homeWorkDueOnDate.contains('-') && !homeWorkDueOnDate.contains('T')) {
        try {
          final date = DateTime.parse(homeWorkDueOnDate);
          formattedDueDate = DateFormat('dd-MM-yyyy').format(date);
        } catch (_) {}
      }

      final response = await _repo.addHomeworkAPI(
        subjectId: subjectId,
        homeWorkDate: formattedDate,
        homeWorkDueOnDate: formattedDueDate,
        homeWorkName: homeWorkName,
        homeWorkDescription: homeWorkDescription,
        filePath: attachmentPath,
      );

      if (response != null && response['statusCode'] == 200) {
        return response['data'] as Map<String, dynamic>?;
      }

      return null;
    } catch (e) {
      debugPrint('Sync error: $e');
      return null;
    }
  }

  /// Process pending queue (called when network is available)
  Future<void> processPendingQueue() async {
    if (!await isOnline()) {
      debugPrint('Device is offline, skipping sync');
      return;
    }

    final pending = await getPendingQueue();
    if (pending.isEmpty) return;

    debugPrint('Processing ${pending.length} pending homework items...');

    for (final homework in pending) {
      try {
        final tempId = homework['tempLocalId']?.toString() ?? '';
        final response = await syncHomeworkToServer(homework);

        if (response != null) {
          // Success: Update local storage with server ID
          final serverId = response['homeWorkId']?.toString() ?? '';
          final updatedHomework = {
            ...homework,
            'homeWorkId': serverId,
            'attachment': response['attachment'] ?? homework['attachment'],
            'extensions': response['extensions'] ?? homework['extensions'],
            'syncStatus': SyncStatus.synced.name,
          };

          await saveHomeworkLocally(updatedHomework, syncStatus: SyncStatus.synced);
          await removeFromPendingQueue(tempId);
          debugPrint('Successfully synced homework: $serverId');
        } else {
          // Failed: Move to failed queue
          await addToFailedQueue(homework);
          await removeFromPendingQueue(tempId);
          await saveHomeworkLocally(homework, syncStatus: SyncStatus.failed);
          debugPrint('Failed to sync homework: $tempId');
        }
      } catch (e) {
        debugPrint('Error processing homework: $e');
        await addToFailedQueue(homework);
        await removeFromPendingQueue(homework['tempLocalId']?.toString() ?? '');
      }
    }
  }

  /// Retry failed syncs
  Future<bool> retryFailedSync(String tempLocalId) async {
    if (!await isOnline()) {
      return false;
    }

    final failed = await getFailedQueue();
    final homework = failed.firstWhere(
      (item) => item['tempLocalId'] == tempLocalId,
      orElse: () => <String, dynamic>{},
    );

    if (homework.isEmpty) return false;

    try {
      final response = await syncHomeworkToServer(homework);

      if (response != null) {
        final serverId = response['homeWorkId']?.toString() ?? '';
        final updatedHomework = {
          ...homework,
          'homeWorkId': serverId,
          'attachment': response['attachment'] ?? homework['attachment'],
          'extensions': response['extensions'] ?? homework['extensions'],
          'syncStatus': SyncStatus.synced.name,
        };

        await saveHomeworkLocally(updatedHomework, syncStatus: SyncStatus.synced);
        await removeFromFailedQueue(tempLocalId);
        return true;
      }

      return false;
    } catch (e) {
      debugPrint('Retry error: $e');
      return false;
    }
  }

  /// Get all homework (local + API merged)
  Future<List<Map<String, dynamic>>> getAllHomework({
    String? studentId,
    String? instituteId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString("homeworkList");
    List<Map<String, dynamic>> localHomework = [];

    if (savedData != null) {
      localHomework = List<Map<String, dynamic>>.from(jsonDecode(savedData));
    }

    // Fetch from API if online
    List<Map<String, dynamic>> apiHomework = [];
    if (await isOnline() && studentId != null && studentId.isNotEmpty) {
      try {
        final response = await _repo.getHomeworkApi(studentId);
        if (response['statusCode'] == 200) {
          final data = response['data'];
          if (data is List) {
            apiHomework = data.map<Map<String, dynamic>>((item) {
              final map = Map<String, dynamic>.from(item as Map);
              final hw = Map<String, dynamic>.from(
                (map['homework'] ?? <String, dynamic>{}) as Map,
              );
              return _mapApiHomework(map, hw);
            }).toList();
          } else if (data is Map<String, dynamic>) {
            final hw = Map<String, dynamic>.from(
              (data['homework'] ?? <String, dynamic>{}) as Map<String, dynamic>,
            );
            apiHomework = [_mapApiHomework(data, hw)];
          }
        }
      } catch (e) {
        debugPrint('API fetch error: $e');
      }
    }

    // Merge: Use homeWorkId as dedup key
    final Map<String, Map<String, dynamic>> merged = {};

    // First add API items (server is source of truth)
    for (final hw in apiHomework) {
      final id = hw['homeWorkId']?.toString() ?? '';
      if (id.isNotEmpty) {
        merged[id] = {...hw, 'syncStatus': SyncStatus.synced.name};
      }
    }

    // Then add local items (only if not already in merged, or if unsynced)
    for (final hw in localHomework) {
      final id = hw['homeWorkId']?.toString() ?? '';
      final tempId = hw['tempLocalId']?.toString() ?? '';
      final syncStatus = hw['syncStatus']?.toString() ?? SyncStatus.pending.name;

      if (id.isNotEmpty && merged.containsKey(id)) {
        // Already synced, skip (server version is authoritative)
        continue;
      } else if (tempId.isNotEmpty || syncStatus != SyncStatus.synced.name) {
        // Unsynced or pending item, add it
        final key = id.isNotEmpty ? id : tempId;
        if (!merged.containsKey(key)) {
          merged[key] = hw;
        }
      }
    }

    return merged.values.toList();
  }

  Map<String, dynamic> _mapApiHomework(
    Map<String, dynamic> container,
    Map<String, dynamic> hw,
  ) {
    final attachmentPath = hw['attachment'];
    final extensions = hw['extensions']?.toString() ?? '';
    final homeWorkId = hw['homeWorkId']?.toString() ?? '';
    final resolvedAttachment = attachmentPath ??
        (homeWorkId.isNotEmpty && extensions.isNotEmpty
            ? "https://schoolnx.com/SchoolWebsiteImages/Institute10085/HomeWork/Attachment_${homeWorkId}$extensions"
            : null);

    return {
      "subject": container['subjectName'] ?? '',
      "subjectName": container['subjectName'] ?? '',
      "title": hw['homeWorkName'] ?? '',
      "homeWorkName": hw['homeWorkName'] ?? '',
      "description": hw['homeWorkDescription'] ?? '',
      "homeWorkDescription": hw['homeWorkDescription'] ?? '',
      "fromDate": hw['homeWorkDate'] ?? '',
      "homeWorkDate": hw['homeWorkDate'] ?? '',
      "toDate": hw['homeWorkDueOnDate'] ?? '',
      "homeWorkDueOnDate": hw['homeWorkDueOnDate'] ?? '',
      "attachment": resolvedAttachment,
      "extensions": extensions,
      "homeWorkId": homeWorkId,
      "subjectId": hw['subjectId']?.toString() ?? '',
      "syncStatus": SyncStatus.synced.name,
    };
  }

  /// Initialize: Start listening for connectivity changes and auto-sync
  void initialize() {
    _connectivity.onConnectivityChanged.listen((result) {
      if (!result.contains(ConnectivityResult.none)) {
        // Network is back, process pending queue
        processPendingQueue();
      }
    });
  }
}

