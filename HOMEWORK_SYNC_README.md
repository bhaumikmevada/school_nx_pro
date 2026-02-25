# Homework Sync Implementation

## Overview

This document describes the homework synchronization system that enables offline-first functionality for homework management. The system ensures that homework created by teachers/employees is saved both to the server API and locally, with automatic sync when network connectivity is restored.

## Architecture

### Components

1. **HomeworkSyncService** (`lib/services/homework_sync_service.dart`)
   - Manages offline queue and sync logic
   - Handles network connectivity detection
   - Processes pending and failed syncs
   - Merges API and local data

2. **HomeworkItem Model** (`lib/provider/parent_homework_provider.dart`)
   - Extended with `syncStatus` and `tempLocalId` fields
   - Tracks sync state: `synced`, `syncing`, `pending`, `failed`

3. **HomeworkScreen** (`lib/screens/common_screens/homework_screen.dart`)
   - Teacher/Employee interface for creating homework
   - Integrates with sync service for offline support

4. **ParentHomeworkScreen** (`lib/screens/parent/screens/parent_homework_screen.dart`)
   - Parent interface for viewing homework
   - Displays merged API + local data
   - Shows sync status indicators and retry buttons

## Sync Workflow

### Creating Homework (Online)

1. User fills homework form in `HomeworkScreen`
2. System checks network connectivity
3. If online:
   - Attempts immediate API save via `HomeworkProvider.addHomework()`
   - On success: Saves locally with `SyncStatus.synced`
   - On failure: Saves locally with `SyncStatus.failed` and adds to failed queue
4. Homework appears immediately in both screens

### Creating Homework (Offline)

1. User fills homework form
2. System detects offline state
3. Saves locally with `SyncStatus.pending`
4. Adds to pending queue
5. When network returns (detected via `connectivity_plus`):
   - `HomeworkSyncService.processPendingQueue()` runs automatically
   - Each pending item is synced to server
   - On success: Updates local record with server ID and `SyncStatus.synced`
   - On failure: Moves to failed queue

### Viewing Homework (ParentHomeworkScreen)

1. On screen load or pull-to-refresh:
   - Fetches fresh data from API (if online)
   - Loads local data from SharedPreferences
   - Merges both sources using `homeWorkId` as deduplication key
   - Server data takes precedence for synced items
   - Local unsynced items are included in the list

## Local Storage

### Storage Mechanism

- **Technology**: SharedPreferences (key-value storage)
- **Location**: Device local storage (persists across app restarts and logout)
- **Removal**: Data is cleared only on app uninstall

### Storage Keys

1. `homeworkList` - Main homework list with sync status
2. `homework_pending_sync` - Queue of items waiting to sync
3. `homework_failed_sync` - Queue of items that failed to sync
4. `parent_homework_cache_{studentId}` - Per-student cached homework for parents

### Data Structure

Each homework item stored locally includes:
```json
{
  "subjectId": "123",
  "subject": "Mathematics",
  "title": "Algebra Homework",
  "description": "Complete exercises 1-10",
  "fromDate": "2024-01-15",
  "toDate": "2024-01-20",
  "attachment": "/path/to/file.pdf",
  "extensions": ".pdf",
  "homeWorkId": "456",  // Server ID (empty if not synced)
  "tempLocalId": "temp_1234567890",  // Temporary ID for unsynced items
  "syncStatus": "synced",  // synced | syncing | pending | failed
  "lastSyncAttempt": "2024-01-15T10:30:00Z"
}
```

## Sync Status Indicators

### UI Feedback

- **✓ Synced** (Green checkmark): Successfully saved to server
- **🔁 Syncing** (Blue spinner): Currently being synced
- **⏳ Pending** (Orange clock): Waiting for network to sync
- **⚠ Failed** (Red error): Sync failed, manual retry available

### Retry Mechanism

- Failed syncs can be retried manually via "Retry" button
- Automatic retry occurs when network connectivity is restored
- Retry uses the same API endpoint as initial creation

## API Integration

### Endpoints Used

1. **GET** `https://api.schoolnxpro.com/api/Homework/Id?admissionId={studentId}&instituteId={instituteId}`
   - Fetches homework for a specific student
   - Used in `ParentHomeworkScreen` and sync service

2. **POST** `https://api.schoolnxpro.com/api/HomeworkUpload1/add`
   - Creates new homework
   - Multipart form data with optional file attachment
   - Returns homework with server-assigned `homeWorkId`

### Error Handling

- Network failures are caught and handled gracefully
- Failed API calls don't crash the app
- Local data is always preserved
- User receives feedback via SnackBars

## Edge Cases Handled

### 1. Duplicate Prevention
- Uses `homeWorkId` as primary deduplication key
- For unsynced items, uses `tempLocalId`
- Server data takes precedence over local when IDs match

### 2. Network Failures
- API calls wrapped in try-catch
- Failed requests queue for retry
- Local data remains accessible

### 3. App Restart & Logout
- Local cache persists across restarts
- Data survives logout/login cycles
- Only cleared on app uninstall

### 4. Conflict Resolution
- Server version is authoritative for synced items
- Local unsynced items are preserved until synced
- No data loss during conflicts

### 5. Multiple Students
- Each student's homework cached separately
- Uses `studentId` in cache key
- No cross-contamination between students

## Testing

### Test Scenarios

See `test/homework_sync_test.dart` for comprehensive test cases covering:
- Creating homework while online
- Creating homework while offline
- Automatic sync on network restore
- App restart persistence
- Logout/login persistence
- ParentHomeworkScreen merge logic
- Retry functionality

### Running Tests

```bash
flutter test test/homework_sync_test.dart
```

## Dependencies

- `connectivity_plus: ^6.1.0` - Network connectivity detection
- `shared_preferences: ^2.5.3` - Local storage
- `http: ^1.4.0` - API calls
- `provider: ^6.1.5` - State management

## Future Enhancements

1. **Background Sync**: Use WorkManager for background sync processing
2. **Batch Sync**: Sync multiple items in a single API call
3. **Edit/Delete Support**: Extend sync to handle updates and deletions
4. **Sync History**: Track sync attempts and failures for debugging
5. **Data Compression**: Compress local storage for large datasets

## Troubleshooting

### Homework not syncing

1. Check network connectivity
2. Verify API endpoint is accessible
3. Check pending/failed queues in SharedPreferences
4. Review logs for error messages

### Duplicate homework items

1. Ensure `homeWorkId` is being used correctly
2. Check merge logic in `getAllHomework()`
3. Verify tempLocalId generation is unique

### Local data not persisting

1. Verify SharedPreferences permissions
2. Check storage space on device
3. Review error logs for storage failures

