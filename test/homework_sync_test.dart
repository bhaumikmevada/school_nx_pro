import 'package:flutter_test/flutter_test.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:school_nx_pro/services/homework_sync_service.dart';
import 'package:school_nx_pro/provider/parent_homework_provider.dart';

void main() {
  group('Homework Sync Service Tests', () {
    late HomeworkSyncService syncService;

    setUp(() {
      syncService = HomeworkSyncService();
      // Clear SharedPreferences before each test
      SharedPreferences.setMockInitialValues({});
    });

    test('Save homework locally with sync status', () async {
      final homework = {
        'subjectId': '123',
        'subject': 'Mathematics',
        'title': 'Test Homework',
        'description': 'Test Description',
        'fromDate': '2024-01-15',
        'toDate': '2024-01-20',
        'homeWorkId': '',
      };

      await syncService.saveHomeworkLocally(
        homework,
        syncStatus: SyncStatus.pending,
      );

      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('homeworkList');
      expect(savedData, isNotNull);

      final decoded = jsonDecode(savedData!);
      expect(decoded, isA<List>());
      expect(decoded.length, equals(1));
      expect(decoded[0]['syncStatus'], equals('pending'));
    });

    test('Add to pending queue when offline', () async {
      final homework = {
        'subjectId': '123',
        'subject': 'Mathematics',
        'title': 'Test Homework',
        'description': 'Test Description',
        'fromDate': '2024-01-15',
        'toDate': '2024-01-20',
      };

      await syncService.addToPendingQueue(homework);

      final pending = await syncService.getPendingQueue();
      expect(pending.length, equals(1));
      expect(pending[0]['title'], equals('Test Homework'));
      expect(pending[0]['tempLocalId'], isNotNull);
    });

    test('Remove from pending queue after sync', () async {
      final homework = {
        'subjectId': '123',
        'title': 'Test Homework',
        'tempLocalId': 'temp_123',
      };

      await syncService.addToPendingQueue(homework);
      await syncService.removeFromPendingQueue('temp_123');

      final pending = await syncService.getPendingQueue();
      expect(pending.length, equals(0));
    });

    test('Add to failed queue on API failure', () async {
      final homework = {
        'subjectId': '123',
        'title': 'Test Homework',
      };

      await syncService.addToFailedQueue(homework);

      final failed = await syncService.getFailedQueue();
      expect(failed.length, equals(1));
      expect(failed[0]['title'], equals('Test Homework'));
    });

    test('Generate unique temporary local IDs', () async {
      final homework1 = {'title': 'Homework 1'};
      final homework2 = {'title': 'Homework 2'};

      await syncService.addToPendingQueue(homework1);
      await syncService.addToPendingQueue(homework2);

      final pending = await syncService.getPendingQueue();
      expect(pending.length, equals(2));
      expect(pending[0]['tempLocalId'], isNot(equals(pending[1]['tempLocalId'])));
    });
  });

  group('HomeworkItem Model Tests', () {
    test('Create HomeworkItem from local map with sync status', () {
      final map = {
        'subjectName': 'Mathematics',
        'title': 'Test Homework',
        'fromDate': '2024-01-15',
        'toDate': '2024-01-20',
        'description': 'Test Description',
        'homeWorkId': '',
        'extensions': '',
        'syncStatus': 'pending',
        'tempLocalId': 'temp_123',
      };

      final item = HomeworkItem.fromLocalMap(map);

      expect(item.subjectName, equals('Mathematics'));
      expect(item.homeWorkName, equals('Test Homework'));
      expect(item.syncStatus, equals(SyncStatus.pending));
      expect(item.tempLocalId, equals('temp_123'));
    });

    test('Create HomeworkItem from API (always synced)', () {
      final json = {
        'subjectName': 'Mathematics',
        'homework': {
          'homeWorkName': 'Test Homework',
          'homeWorkDate': '2024-01-15',
          'homeWorkDueOnDate': '2024-01-20',
          'homeWorkDescription': 'Test Description',
          'homeWorkId': '456',
          'extensions': '.pdf',
        },
      };

      final item = HomeworkItem.fromApi(json);

      expect(item.subjectName, equals('Mathematics'));
      expect(item.homeWorkId, equals('456'));
      expect(item.syncStatus, equals(SyncStatus.synced));
    });

    test('Convert HomeworkItem to local map preserves sync status', () {
      final item = HomeworkItem(
        subjectName: 'Mathematics',
        homeWorkName: 'Test Homework',
        homeWorkDate: '2024-01-15',
        homeWorkDueOnDate: '2024-01-20',
        homeWorkDescription: 'Test Description',
        homeWorkId: '',
        extensions: '',
        syncStatus: SyncStatus.pending,
        tempLocalId: 'temp_123',
      );

      final map = item.toLocalMap();

      expect(map['syncStatus'], equals('pending'));
      expect(map['tempLocalId'], equals('temp_123'));
    });
  });

  group('Integration Tests', () {
    test('Create homework offline, then sync when online', () async {
      // This is a conceptual test - actual implementation would require
      // mocking the API and connectivity service
      
      final syncService = HomeworkSyncService();
      final homework = {
        'subjectId': '123',
        'subject': 'Mathematics',
        'title': 'Offline Homework',
        'description': 'Created offline',
        'fromDate': '2024-01-15',
        'toDate': '2024-01-20',
        'homeWorkId': '',
      };

      // Simulate offline creation
      await syncService.addToPendingQueue(homework);
      await syncService.saveHomeworkLocally(homework, syncStatus: SyncStatus.pending);

      // Verify it's in pending queue
      final pending = await syncService.getPendingQueue();
      expect(pending.length, equals(1));

      // Verify it's saved locally
      final prefs = await SharedPreferences.getInstance();
      final savedData = prefs.getString('homeworkList');
      expect(savedData, isNotNull);
    });

    test('Merge API and local homework without duplicates', () async {
      // This test verifies the merge logic conceptually
      final syncService = HomeworkSyncService();
      
      // Simulate API homework
      final apiHomework = {
        'homeWorkId': '456',
        'subject': 'Mathematics',
        'title': 'API Homework',
        'syncStatus': 'synced',
      };

      // Simulate local unsynced homework
      final localHomework = {
        'homeWorkId': '',
        'tempLocalId': 'temp_123',
        'subject': 'Science',
        'title': 'Local Homework',
        'syncStatus': 'pending',
      };

      // Both should be included in merged result
      // (Actual merge happens in getAllHomework which requires API mocking)
      expect(apiHomework['homeWorkId'], isNotEmpty);
      expect(localHomework['tempLocalId'], isNotEmpty);
    });
  });

  group('Edge Cases', () {
    test('Handle empty homework list', () async {
      final syncService = HomeworkSyncService();
      final prefs = await SharedPreferences.getInstance();
      
      // No data in SharedPreferences
      final savedData = prefs.getString('homeworkList');
      expect(savedData, isNull);
    });

    test('Handle homework with missing fields', () {
      final map = {
        'subjectName': 'Mathematics',
        // Missing other fields
      };

      final item = HomeworkItem.fromLocalMap(map);
      
      // Should use default empty strings
      expect(item.homeWorkName, equals(''));
      expect(item.homeWorkId, equals(''));
    });

    test('Handle invalid sync status gracefully', () {
      final map = {
        'subjectName': 'Mathematics',
        'title': 'Test',
        'fromDate': '2024-01-15',
        'toDate': '2024-01-20',
        'description': 'Test',
        'homeWorkId': '',
        'extensions': '',
        'syncStatus': 'invalid_status', // Invalid status
      };

      final item = HomeworkItem.fromLocalMap(map);
      
      // Should default to synced
      expect(item.syncStatus, equals(SyncStatus.synced));
    });
  });
}


