import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_nx_pro/services/homework_sync_service.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

class HomeworkItem {
  final String subjectName;
  final String homeWorkName;
  final String homeWorkDate;
  final String homeWorkDueOnDate;
  final String homeWorkDescription;
  final String homeWorkId;
  final String extensions;
  final String? attachmentPath;
  final SyncStatus syncStatus;
  final String? tempLocalId;

  HomeworkItem({
    required this.subjectName,
    required this.homeWorkName,
    required this.homeWorkDate,
    required this.homeWorkDueOnDate,
    required this.homeWorkDescription,
    required this.homeWorkId,
    required this.extensions,
    this.attachmentPath,
    this.syncStatus = SyncStatus.synced,
    this.tempLocalId,
  });

  factory HomeworkItem.fromApi(Map<String, dynamic> json) {
    final hw = json['homework'] ?? <String, dynamic>{};
    return HomeworkItem(
      subjectName: json['subjectName'] ?? '',
      homeWorkName: hw['homeWorkName'] ?? '',
      homeWorkDate: hw['homeWorkDate'] ?? '',
      homeWorkDueOnDate: hw['homeWorkDueOnDate'] ?? '',
      homeWorkDescription: hw['homeWorkDescription'] ?? '',
      homeWorkId: (hw['homeWorkId'] ?? '').toString(),
      extensions: hw['extensions'] ?? '',
      attachmentPath: hw['attachment'] as String?,
      syncStatus: SyncStatus.synced,
    );
  }

  factory HomeworkItem.fromLocalMap(Map<String, dynamic> map) {
    final syncStatusStr = map['syncStatus']?.toString() ?? SyncStatus.synced.name;
    SyncStatus status = SyncStatus.synced;
    try {
      status = SyncStatus.values.firstWhere(
        (e) => e.name == syncStatusStr,
        orElse: () => SyncStatus.synced,
      );
    } catch (_) {}

    return HomeworkItem(
      subjectName: map['subjectName'] ?? map['subject'] ?? '',
      homeWorkName: map['homeWorkName'] ?? map['title'] ?? '',
      homeWorkDate: map['homeWorkDate'] ?? map['fromDate'] ?? '',
      homeWorkDueOnDate: map['homeWorkDueOnDate'] ?? map['toDate'] ?? '',
      homeWorkDescription: map['homeWorkDescription'] ?? map['description'] ?? '',
      homeWorkId: (map['homeWorkId'] ?? map['id'] ?? '').toString(),
      extensions: map['extensions'] ?? map['extension'] ?? '',
      attachmentPath: map['attachment'] as String?,
      syncStatus: status,
      tempLocalId: map['tempLocalId'] as String?,
    );
  }

  Map<String, dynamic> toLocalMap() {
    return {
      'subjectName': subjectName,
      'homeWorkName': homeWorkName,
      'homeWorkDate': homeWorkDate,
      'homeWorkDueOnDate': homeWorkDueOnDate,
      'homeWorkDescription': homeWorkDescription,
      'homeWorkId': homeWorkId,
      'extensions': extensions,
      'attachment': attachmentPath,
      'syncStatus': syncStatus.name,
      if (tempLocalId != null) 'tempLocalId': tempLocalId,
    };
  }

  DateTime? get assignedDate => DateTime.tryParse(homeWorkDate);
  DateTime? get dueDate => DateTime.tryParse(homeWorkDueOnDate);

  String get formattedAssignedDate => _formatDate(homeWorkDate);
  String get formattedDueDate => _formatDate(homeWorkDueOnDate);

  static String _formatDate(String source) {
    if (source.isEmpty) return '-';
    final date = DateTime.tryParse(source);
    if (date == null) return source;
    return DateFormat('dd/MM/yyyy').format(date);
  }

  String? get attachmentUrl {
    if (extensions.isEmpty || homeWorkId.isEmpty) return null;
    return "https://schoolnx.com/SchoolWebsiteImages/Institute10085/HomeWork/Attachment_${homeWorkId}$extensions";
  }
}

class HomeworkProviders extends ChangeNotifier {
  static const _storageKeyPrefix = 'parent_homework_cache_';
  final HomeworkSyncService _syncService = HomeworkSyncService();

  final List<HomeworkItem> _homeworkList = [];
  bool _isLoading = false;

  bool get isLoading => _isLoading;

  List<HomeworkItem> get homeworkList => List.unmodifiable(_homeworkList);

  HomeworkItem? get homework => _homeworkList.isEmpty ? null : _homeworkList.first;

  Future<void> fetchHomework(
    String studentId, {
    bool forceRefresh = false,
  }) async {
    debugPrint("fetch homework studentId : $studentId");
    if (studentId.isEmpty) return;

    // Load local cache first (after reinstall this is empty)
    await _loadFromLocal(studentId);
    final cacheWasEmpty = _homeworkList.isEmpty;
    if (_homeworkList.isNotEmpty && !forceRefresh) {
      _sortHomework();
      notifyListeners();
    }
    // After reinstall cache is empty – always fetch from API so data shows
    if (cacheWasEmpty) forceRefresh = true;

    _isLoading = true;
    notifyListeners();

    try {
      final instituteId = await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";
      
      // Call both APIs in parallel
      final results = await Future.wait([
        // Original API call (direct HTTP with instituteId)
        _fetchHomeworkFromOriginalAPI(studentId, instituteId),
        // Sync service API call (via repo) - includes local unsynced items
        _syncService.getAllHomework(
          studentId: studentId,
          instituteId: instituteId,
        ),
      ]);

      final originalApiHomework = results[0] as List<HomeworkItem>;
      final syncServiceHomework = results[1] as List<Map<String, dynamic>>;

      // Convert sync service results to HomeworkItem
      final syncServiceItems = syncServiceHomework
          .map((hw) => HomeworkItem.fromLocalMap(hw))
          .toList();

      // Also load local homework from SharedPreferences (homeworkList key)
      // This includes homework added through HomeworkScreen
      final prefs = await SharedPreferences.getInstance();
      final localSavedData = prefs.getString("homeworkList");
      List<HomeworkItem> localSavedItems = [];
      
      if (localSavedData != null) {
        try {
          final List<dynamic> decoded = json.decode(localSavedData);
          localSavedItems = decoded
              .map((item) => HomeworkItem.fromLocalMap(
                    Map<String, dynamic>.from(item as Map<String, dynamic>),
                  ))
              .toList();
        } catch (e) {
          debugPrint("Error decoding local homework: $e");
        }
      }

      // Merge all sources: API results are authoritative, local items supplement
      final Map<String, HomeworkItem> merged = {};

      // Priority 1: Original API results (most authoritative - server data)
      for (final item in originalApiHomework) {
        if (item.homeWorkId.isNotEmpty) {
          merged[item.homeWorkId] = item;
        }
      }

      // Priority 2: Sync service API results (only if not already present from original API)
      for (final item in syncServiceItems) {
        if (item.homeWorkId.isNotEmpty) {
          // Only add if not already in merged (original API takes precedence)
          if (!merged.containsKey(item.homeWorkId)) {
            merged[item.homeWorkId] = item;
          }
        } else if (item.tempLocalId != null && item.syncStatus != SyncStatus.synced) {
          // Include unsynced local items (pending/failed sync)
          merged[item.tempLocalId!] = item;
        }
      }

      // Priority 3: Locally saved items (from HomeworkScreen's homeworkList)
      // Only add if they're not already in API results
      for (final item in localSavedItems) {
        if (item.homeWorkId.isNotEmpty) {
          // If it has a server ID, check if it's already in API results
          // If not in API, it might be newly added - include it
          if (!merged.containsKey(item.homeWorkId)) {
            merged[item.homeWorkId] = item;
          }
        } else if (item.tempLocalId != null) {
          // Unsynced items - add if not already present
          if (!merged.containsKey(item.tempLocalId!)) {
            merged[item.tempLocalId!] = item;
          }
        }
      }

      // Priority 4: Items from current _homeworkList (fallback)
      // Only add if they're not already merged
      for (final item in _homeworkList) {
        if (item.homeWorkId.isNotEmpty && !merged.containsKey(item.homeWorkId)) {
          merged[item.homeWorkId] = item;
        } else if (item.homeWorkId.isEmpty && item.tempLocalId != null) {
          if (!merged.containsKey(item.tempLocalId!)) {
            merged[item.tempLocalId!] = item;
          }
        }
      }

      _homeworkList.clear();
      _homeworkList.addAll(merged.values);
      _sortHomework();
      await _saveToLocal(studentId);

      // Process pending queue in background
      _syncService.processPendingQueue();
    } catch (e) {
      debugPrint("Homework fetch error: $e");
      // On error, still show local data
      if (_homeworkList.isEmpty) {
        await _loadFromLocal(studentId);
      }
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Original API call logic (from HomeworkScreen)
  Future<List<HomeworkItem>> _fetchHomeworkFromOriginalAPI(
    String studentId,
    String instituteId,
  ) async {
    try {
      final uri = Uri.parse(
        "https://api.schoolnxpro.com/api/Homework/Id?admissionId=$studentId&instituteId=$instituteId",
      );
      final response = await http.get(uri);

      debugPrint("fetch homework : https://api.schoolnxpro.com/api/Homework/Id?admissionId=$studentId&instituteId=$instituteId");
      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final apiData = jsonData['data'];
        
        if (apiData is List) {
          return apiData
              .map((item) => HomeworkItem.fromApi(
                    Map<String, dynamic>.from(item as Map<String, dynamic>),
                  ))
              .toList();
        } else if (apiData is Map<String, dynamic>) {
          return [
            HomeworkItem.fromApi(Map<String, dynamic>.from(apiData))
          ];
        }
      }
      return [];
    } catch (e) {
      debugPrint("Original API fetch error: $e");
      return [];
    }
  }

  Future<void> addLocalHomework(String studentId, HomeworkItem homework) async {
    _homeworkList.removeWhere(
      (item) =>
          (item.homeWorkId.isNotEmpty && item.homeWorkId == homework.homeWorkId) ||
          (item.homeWorkId.isEmpty &&
              item.subjectName == homework.subjectName &&
              item.homeWorkName == homework.homeWorkName &&
              item.homeWorkDate == homework.homeWorkDate),
    );
    _homeworkList.insert(0, homework);
    _sortHomework();
    await _saveToLocal(studentId);
    notifyListeners();
  }

  Future<void> _loadFromLocal(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey(studentId));
    _homeworkList.clear();
    if (raw == null) return;
    try {
      final List<dynamic> decoded = json.decode(raw);
      _homeworkList.addAll(
        decoded
            .map(
              (item) => HomeworkItem.fromLocalMap(
                Map<String, dynamic>.from(item as Map<String, dynamic>),
              ),
            )
            .toList(),
      );
    } catch (e) {
      debugPrint("Homework local decode error: $e");
    }
  }

  Future<void> _saveToLocal(String studentId) async {
    final prefs = await SharedPreferences.getInstance();
    final encoded =
        json.encode(_homeworkList.map((e) => e.toLocalMap()).toList(growable: false));
    await prefs.setString(_storageKey(studentId), encoded);
  }

  static String _storageKey(String studentId) =>
      '$_storageKeyPrefix$studentId';

  void _sortHomework() {
    _homeworkList.sort((a, b) {
      final aDate = DateTime.tryParse(a.homeWorkDate);
      final bDate = DateTime.tryParse(b.homeWorkDate);
      if (aDate != null && bDate != null) {
        return bDate.compareTo(aDate);
      }
      return b.homeWorkDate.compareTo(a.homeWorkDate);
    });
  }
}

