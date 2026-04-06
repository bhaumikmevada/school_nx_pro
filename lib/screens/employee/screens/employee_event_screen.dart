import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:datepicker_dropdown/datepicker_dropdown.dart';
import 'package:datepicker_dropdown/order_format.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/utils/CustomButton.dart';
import 'package:school_nx_pro/utils/CustomText.dart';
import 'package:school_nx_pro/utils/api_urls.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/http_client_manager.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';
import 'package:school_nx_pro/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../components/app_dropdown.dart';
import '../../../models/course_model.dart';
import '../../../models/event_list_model.dart';
import '../../../models/medium_model.dart';
import '../../../models/section_model.dart';
import '../../../models/stream_model.dart';
import '../../../models/sub_stream_model.dart';
import '../../../provider/employee_attendance_provider.dart';

class LocalImageStorage {
  static const String key = "local_event_images";

  /// Save image path or URL against eventId
  /// Can save both local file paths and server URLs
  static Future<void> saveImage(int eventId, String pathOrUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> map =
        jsonDecode(prefs.getString(key) ?? "{}");

    List<String> images = List<String>.from(map[eventId.toString()] ?? []);

    // Avoid duplicates
    if (!images.contains(pathOrUrl)) {
      images.add(pathOrUrl);
      map[eventId.toString()] = images;
      await prefs.setString(key, jsonEncode(map));
    }
  }

  /// Save server URL from API response
  /// This ensures the uploaded image URL is stored permanently
  static Future<void> saveServerUrl(int eventId, String serverUrl) async {
    await saveImage(eventId, serverUrl);
  }

  /// Get images for one event
  static Future<List<String>> getImages(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> map =
        jsonDecode(prefs.getString(key) ?? "{}");

    return List<String>.from(map[eventId.toString()] ?? []);
  }

  /// Get all images for all events
  static Future<Map<String, List<String>>> getAllImages() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> map =
        jsonDecode(prefs.getString(key) ?? "{}");

    return map.map((k, v) => MapEntry(k, List<String>.from(v)));
  }

  /// Remove a specific image (local or server URL)
  static Future<void> removeImage(int eventId, String pathOrUrl) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> map =
        jsonDecode(prefs.getString(key) ?? "{}");

    List<String> images = List<String>.from(map[eventId.toString()] ?? []);
    images.remove(pathOrUrl);

    map[eventId.toString()] = images;
    await prefs.setString(key, jsonEncode(map));
  }
}

class LocalEventStorage {
  static const String key = "local_events";

  /// Save event data locally
  static Future<void> saveEvent({
    required int eventId,
    required String eventName,
    required DateTime eventDate,
    required int sectionId,
    required int employeeId,
    String? imageUrl,
    String? filename,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> eventsMap =
        jsonDecode(prefs.getString(key) ?? "{}");

    final eventData = {
      'eventId': eventId,
      'eventName': eventName,
      'eventDate': eventDate.toIso8601String(),
      'sectionId': sectionId,
      'employeeId': employeeId,
      'imageUrl': imageUrl,
      'filename': filename,
      'createdAt': DateTime.now().toIso8601String(),
    };

    eventsMap[eventId.toString()] = eventData;
    debugPrint("Local Event Stored : ${eventsMap.toString()}");

    await prefs.setString(key, jsonEncode(eventsMap));
  }

  /// Get all local events
  static Future<List<Map<String, dynamic>>> getAllEvents() async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> eventsMap =
        jsonDecode(prefs.getString(key) ?? "{}");

    return eventsMap.values
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  }

  /// Remove a local event
  static Future<void> removeEvent(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> eventsMap =
        jsonDecode(prefs.getString(key) ?? "{}");

    eventsMap.remove(eventId.toString());
    await prefs.setString(key, jsonEncode(eventsMap));
  }

  /// Mark event as synced to API
  static Future<void> markEventSynced(int eventId) async {
    final prefs = await SharedPreferences.getInstance();
    final Map<String, dynamic> eventsMap =
        jsonDecode(prefs.getString(key) ?? "{}");

    if (eventsMap.containsKey(eventId.toString())) {
      final eventData = Map<String, dynamic>.from(eventsMap[eventId.toString()]);
      eventData['syncedToAPI'] = true;
      eventData['syncedAt'] = DateTime.now().toIso8601String();
      eventsMap[eventId.toString()] = eventData;
      await prefs.setString(key, jsonEncode(eventsMap));
    }
  }

  /// Get unsynced events
  static Future<List<Map<String, dynamic>>> getUnsyncedEvents() async {
    final allEvents = await getAllEvents();
    return allEvents.where((e) => e['syncedToAPI'] != true).toList();
  }
}

class EventModel {
  final int eventId;
  final String eventName;
  final DateTime eventDate;
  final int courseId;
  final String courseName;
  List<String> images = [];

  EventModel({
    required this.eventId,
    required this.eventName,
    required this.eventDate,
    required this.courseId,
    required this.courseName,
    required this.images,
  });

  // Create a copy with updated images
  EventModel copyWith({
    int? eventId,
    String? eventName,
    DateTime? eventDate,
    int? courseId,
    String? courseName,
    List<String>? images,
  }) {
    return EventModel(
      eventId: eventId ?? this.eventId,
      eventName: eventName ?? this.eventName,
      eventDate: eventDate ?? this.eventDate,
      courseId: courseId ?? this.courseId,
      courseName: courseName ?? this.courseName,
      images: images ?? List<String>.from(this.images),
    );
  }

  factory EventModel.fromJson(Map<String, dynamic> json) {
    return EventModel(
      eventId: json['eventId'],
      eventName: json['eventName'],
      eventDate: json['eventDate'],
      courseId: json['courseId'],
      courseName: json['courseName'],
      images: List<String>.from(json['images'] ?? []),
    );
  }
}

class EventService {
  // static Future<List<EventModel>> fetchEvents() async {
  //   final response = await http.get(
  //     Uri.parse(
  //         "https://api.schoolnxpro.com/api/EventWithImages?instituteId=10085"),
  //   );

  //   if (response.statusCode == 200) {
  //     final data = json.decode(response.body);
  //     List events = data['data'];
  //     return events.map((e) => EventModel.fromJson(e)).toList();
  //   } else {
  //     throw Exception("Failed to load events");
  //   }
  // }

  static Future<List<EventModel>> fetchEvents() async {
    final client = HttpClientManager.instance.getClient();

    // Get instituteId dynamically
    String? instituteId;
    try {
      instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
    } catch (e) {
      print("⚠️ Could not get instituteId: $e");
    }

    if (instituteId == null || instituteId.isEmpty) {
      instituteId = "10085"; // Fallback
    }

    final response = await client.get(
      // Uri.parse("${ApiUrls.baseUrl}/EventWithImages?instituteId=$instituteId"),
      Uri.parse("${ApiUrls.baseUrl}/EventWithImages?instituteId=$instituteId"),
      headers: {'Content-Type': 'application/json'},
    );

    List<EventModel> eventList = [];

    debugPrint("Fetch Event url  : ${ Uri.parse("${ApiUrls.baseUrl}EventWithImages?instituteId=$instituteId")}");
    debugPrint("Fetch Event response : ${response.body.toString()}");

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      List events = data['data'] ?? [];

      // server events
      eventList = events.map((e) => EventModel.fromJson(e)).toList();

      // for(var i=0; i<eventList.length; i++){
      //
      //   debugPrint("Event Id : ${eventList[i].eventId} | Name : ${eventList[i].eventName} | Date : ${eventList[i].eventDate}");
      // }
    }

    // 🔹 Get local events (events created locally but not yet synced to API)
    final localEvents = await LocalEventStorage.getAllEvents();
    final localEventIds = <int>{};

    for (var localEvent in localEvents) {
      final eventId = localEvent['eventId'] as int;
      localEventIds.add(eventId);

      // Check if this event already exists in server events
      final existsInServer = eventList.any((e) => e.eventId == eventId);

      if (!existsInServer) {
        // Add local event to list
        eventList.add(EventModel(
          eventId: eventId,
          eventName: localEvent['eventName'] as String,
          eventDate: localEvent['eventDate'],
          courseId: localEvent['courseId'],
          courseName: localEvent['courseName'],
          images: localEvent['imageUrl'] != null
              ? [localEvent['imageUrl'] as String]
              : [],
        ));
      }
    }

    // 🔹 local images fetch karo
    final localImagesMap = await LocalImageStorage.getAllImages();

    // 🔹 merge karo - create new EventModel instances with merged images
    eventList = eventList.map((event) {
      if (localImagesMap.containsKey(event.eventId.toString())) {
        final localImages = localImagesMap[event.eventId.toString()]!;
        final mergedImages = List<String>.from(event.images)..addAll(localImages);
        return event.copyWith(images: mergedImages);
      }
      return event;
    }).toList();

    // Sort by date (newest first)
    eventList.sort((a, b) => b.eventDate.compareTo(a.eventDate));

    return eventList;
  }

  /// Verify that uploaded image appears in EventWithImages API
  /// Returns true if image is found in the API response, false otherwise
  static Future<bool> verifyImageInEvent(int eventId, String? serverUrl, String? filename) async {
    try {
      // Get instituteId dynamically instead of hardcoding
      String? instituteId;
      try {
        instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
        print("🔍 Verification: Using instituteId: $instituteId");
      } catch (e) {
        print("⚠️ Could not get instituteId for verification: $e");
        instituteId = "10085"; // Fallback to default
      }

      if (instituteId == null || instituteId.isEmpty) {
        instituteId = "10085"; // Fallback to default
      }

      // Wait longer for backend to process and link the image to the event
      // Backend may need time to process the upload and update the database
      print("🔍 Starting verification after 5 second delay...");
      await Future.delayed(const Duration(seconds: 5));

      final client = HttpClientManager.instance.getClient();
      final verificationUrl = "https://api.schoolnxpro.com/api/EventWithImages?instituteId=$instituteId";
      print("🔍 Verification: Fetching from $verificationUrl");
      final response = await client.get(
        Uri.parse(verificationUrl),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final events = data['data'] as List;

        // Find our event
        final event = events.firstWhere(
          (e) => e['eventId'] == eventId,
          orElse: () => null,
        );

        if (event != null) {
          final images = List<String>.from(event['images'] ?? []);
          print("🔍 Verification: Event $eventId has ${images.length} images in API");
          print("🔍 Verification: Images in API: $images");

          if (serverUrl != null && serverUrl.isNotEmpty) {
            // Check if server URL matches any image in the API
            final found = images.any((img) =>
              img.contains(serverUrl) ||
              serverUrl.contains(img) ||
              img.endsWith(serverUrl.split('/').last) ||
              serverUrl.endsWith(img.split('/').last) ||
              (filename != null && img.contains(filename))
            );

            if (found) {
              print("✅ VERIFIED: Server URL found in EventWithImages API");
              print("✅ Server URL: $serverUrl");
              return true;
            } else {
              print("⚠️ WARNING: Server URL not found in EventWithImages API");
              print("⚠️ Server URL: $serverUrl");
              print("⚠️ Filename: $filename");
              print("⚠️ API Images: $images");

              // Try multiple retries after additional delays
              print("🔄 Retrying verification after additional delay...");
              for (int retryAttempt = 1; retryAttempt <= 3; retryAttempt++) {
                await Future.delayed(Duration(seconds: 3 * retryAttempt)); // Progressive delay: 3s, 6s, 9s
                print("🔄 Retry attempt $retryAttempt/3...");

                // Re-fetch to check again
                final retryResponse = await client.get(
                  Uri.parse("https://api.schoolnxpro.com/api/EventWithImages?instituteId=$instituteId"),
                  headers: {'Content-Type': 'application/json'},
                );

                if (retryResponse.statusCode == 200) {
                  final retryData = json.decode(retryResponse.body);
                  final retryEvents = retryData['data'] as List;
                  final retryEvent = retryEvents.firstWhere(
                    (e) => e['eventId'] == eventId,
                    orElse: () => null,
                  );

                  if (retryEvent != null) {
                    final retryImages = List<String>.from(retryEvent['images'] ?? []);
                    print("🔍 Retry: Event $eventId now has ${retryImages.length} images");
                    print("🔍 Retry: Images: $retryImages");

                    final retryFound = retryImages.any((img) =>
                      img.contains(serverUrl) ||
                      serverUrl.contains(img) ||
                      img.endsWith(serverUrl.split('/').last) ||
                      serverUrl.endsWith(img.split('/').last) ||
                      (filename != null && img.contains(filename))
                    );

                    if (retryFound) {
                      print("✅ VERIFIED on retry $retryAttempt: Server URL found in EventWithImages API");
                      return true;
                    }
                  }
                }
              }

              return false;
            }
          } else if (filename != null) {
            // Check if filename appears in any image URL (more flexible matching)
            print("🔍 Checking for filename: $filename");
            final found = images.any((img) {
              // Try multiple matching strategies:
              // 1. Exact filename match
              final exactMatch = img.contains(filename);
              // 2. Filename appears at end of URL
              final endsWithMatch = img.endsWith(filename);
              // 3. Extract filename from URL and compare
              final urlFilename = img.split('/').last;
              final urlMatches = urlFilename == filename || urlFilename.contains(filename) || filename.contains(urlFilename);

              if (exactMatch || endsWithMatch || urlMatches) {
                print("✅ Filename match found: $img (matches $filename)");
              }
              return exactMatch || endsWithMatch || urlMatches;
            });

            if (found) {
              print("✅ VERIFIED: Filename found in EventWithImages API");
              return true;
            }

            print("⚠️ Filename not found in API images");
            print("⚠️ Searched filename: $filename");
            print("⚠️ API images: $images");

            // Retry with filename search too
            for (int retryAttempt = 1; retryAttempt <= 3; retryAttempt++) {
              await Future.delayed(Duration(seconds: 3 * retryAttempt));
              print("🔄 Retrying filename verification (attempt $retryAttempt/3)...");

              final retryResponse = await client.get(
                Uri.parse("https://api.schoolnxpro.com/api/EventWithImages?instituteId=$instituteId"),
                headers: {'Content-Type': 'application/json'},
              );

              if (retryResponse.statusCode == 200) {
                final retryData = json.decode(retryResponse.body);
                final retryEvents = retryData['data'] as List;
                final retryEvent = retryEvents.firstWhere(
                  (e) => e['eventId'] == eventId,
                  orElse: () => null,
                );

                if (retryEvent != null) {
                  final retryImages = List<String>.from(retryEvent['images'] ?? []);
                  print("🔍 Retry $retryAttempt: Event $eventId now has ${retryImages.length} images");

                  final retryFound = retryImages.any((img) {
                    return img.contains(filename) ||
                           img.endsWith(filename) ||
                           img.split('/').last == filename ||
                           img.split('/').last.contains(filename);
                  });

                  if (retryFound) {
                    print("✅ VERIFIED on retry $retryAttempt: Filename found in EventWithImages API");
                    return true;
                  }
                }
              }
            }

            return false;
          } else {
            // If no server URL or filename, check if event has any images
            print("⚠️ No server URL or filename provided, checking if event has images");
            print("⚠️ Event has ${images.length} images in API");
            return images.isNotEmpty;
          }
        } else {
          print("❌ Verification failed: Event $eventId not found in API response");
          return false;
        }
      } else {
        print("❌ Verification failed: API returned status ${response.statusCode}");
        return false;
      }
    } catch (e) {
      print("❌ Verification error: $e");
      return false;
    }
  }

  /// Fetch sections from API
  static Future<List<Map<String, dynamic>>> fetchSections() async {
    try {
      String? instituteId;
      try {
        instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
      } catch (e) {
        print("⚠️ Could not get instituteId: $e");
      }

      if (instituteId == null || instituteId.isEmpty) {
        instituteId = "10085"; // Fallback
      }

      final client = HttpClientManager.instance.getClient();
      final url = Uri.parse("https://api.schoolnxpro.com/api/Section?instituteId=$instituteId");
      final response = await client.get(
        url,
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        List<Map<String, dynamic>> sections = [];

        // Handle different response formats
        if (data is List) {
          sections = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] != null) {
          sections = List<Map<String, dynamic>>.from(data['data']);
        }

        // Build full allotment name for display if not present
        for (var section in sections) {
          if (!section.containsKey('fullAllotmentName') ||
              section['fullAllotmentName'] == null) {
            // Try to build from available fields
            final sectionId = section['sectionId'] ?? '';
            final sectionName = section['sectionName'] ?? '';
            final courseName = section['courseName'] ?? '';
            final mediumName = section['mediumName'] ?? '';
            final streamName = section['streamName'] ?? '';
            final subStreamName = section['subStreamName'] ?? '';

            // Build full name like "01/A/English/Common/Common"
            final parts = [
              sectionId.toString(),
              sectionName,
              courseName.isNotEmpty ? courseName : 'Common',
              mediumName.isNotEmpty ? mediumName : 'Common',
              streamName.isNotEmpty ? streamName : 'Common',
              subStreamName.isNotEmpty ? subStreamName : '',
            ].where((p) => p.isNotEmpty).toList();

            section['fullAllotmentName'] = parts.join('/');
          }
        }

        return sections;
      }
      return [];
    } catch (e) {
      print("❌ Error fetching sections: $e");
      return [];
    }
  }

  /// Upload Image to Gallery API Call
  /// Uses the gallery upload API (same endpoint but without eventId)
  /// Images uploaded via this method will appear in both gallery and event list
  static Future<Map<String, dynamic>> uploadGalleryImage(
      File file, String description, int employeeId, int sectionId,
      {String? eventName, String? eventDate}) async {
    try {
      // Get authentication token if available
      String? accessToken;
      try {
        accessToken = await MySharedPreferences.instance.getStringValue("token");
        print("🔑 Auth token available: ${accessToken != null}");
      } catch (e) {
        print("⚠️ Could not get auth token: $e");
      }

      // Get instituteId for URL construction
      String? instituteId;
      try {
        instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
      } catch (e) {
        print("⚠️ Could not get instituteId: $e");
      }

      // Try to get studentId if available (may help backend link image to student)
      String? studentId;
      try {
        studentId = await MySharedPreferences.instance.getStringValue("studentId");
        if (studentId != null && studentId.isNotEmpty) {
          print("👤 Found studentId: $studentId - will include in upload");
        }
      } catch (e) {
        print("⚠️ Could not get studentId: $e (this is optional for employee uploads)");
      }

      // Generate unique description by adding timestamp and random number to avoid duplicate upload issues
      // Format: "event_name_timestamp_random" (e.g., "Annual Day_170709521386859663_12345")
      // This ensures each upload has a completely unique description
      // IMPORTANT: Description must be unique each time, otherwise image upload may fail
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final random = Random().nextInt(99999); // Random number between 0-99999
      final uniqueDescription = "${description}_${timestamp}_$random";

      // API requires query parameters (form fields don't work - returns "description field is required")
      final encodedDescription = Uri.encodeComponent(uniqueDescription);

      // Build URL with gallery upload parameters (NO eventId - this is the key difference)
      String uploadUrl = "https://api.schoolnxpro.com/api/FileUploadDownload1/UploadPhoto"
          "?description=$encodedDescription&employeeId=$employeeId&sectionId=$sectionId";

      // Add instituteId to query params if available
      if (instituteId != null && instituteId.isNotEmpty) {
        uploadUrl += "&instituteId=$instituteId";
      }

      // Add studentId to query params if available (may help backend link image to student's ID)
      if (studentId != null && studentId.isNotEmpty) {
        uploadUrl += "&studentId=$studentId";
        print("✅ Including studentId in upload URL: $studentId");
      }

      // Add eventName and eventDate if provided (helps backend create event automatically)
      if (eventName != null && eventName.isNotEmpty) {
        uploadUrl += "&eventName=${Uri.encodeComponent(eventName)}";
        print("✅ Including eventName in upload URL: $eventName");
      }
      if (eventDate != null && eventDate.isNotEmpty) {
        uploadUrl += "&eventDate=${Uri.encodeComponent(eventDate)}";
        print("✅ Including eventDate in upload URL: $eventDate");
      }

      final url = Uri.parse(uploadUrl);

      var request = http.MultipartRequest("POST", url);

      // Verify file exists and is readable
      if (!await file.exists()) {
        throw Exception("File does not exist: ${file.path}");
      }

      // Get file extension and determine content type
      final fileExtension = file.path.split('.').last.toLowerCase();
      String contentType = 'image/jpeg'; // default
      if (fileExtension == 'png') {
        contentType = 'image/png';
      } else if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (fileExtension == 'gif') {
        contentType = 'image/gif';
      } else if (fileExtension == 'webp') {
        contentType = 'image/webp';
      }

      // Get filename from path
      final filename = file.path.split('/').last;

      // Read file bytes to create MultipartFile with explicit content type
      final fileBytes = await file.readAsBytes();

      // Create multipart file with explicit content type and filename
      final multipartFile = http.MultipartFile.fromBytes(
        "file", // Field name - API expects "file"
        fileBytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      );

      // Add the file to the request body
      request.files.add(multipartFile);

      // Add headers - DO NOT set Content-Type manually for multipart requests
      request.headers.addAll({
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      });

      print("📤 Uploading image to gallery: ${url.toString()}");
      print("📁 File path: ${file.path}");
      print("📎 File name: $filename");
      print("📝 Original Description: $description");
      print("📝 Unique Description: $uniqueDescription");
      print("👤 Employee ID: $employeeId");
      print("📚 Section ID: $sectionId");
      print("🏫 Institute ID: $instituteId");
      if (studentId != null && studentId.isNotEmpty) {
        print("👨‍🎓 Student ID: $studentId");
      }
      print("🔑 Using auth token: ${accessToken != null}");

      // Use managed HTTP client for consistent connection handling
      final client = HttpClientManager.instance.getClient();
      var streamedResponse = await client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      // Log full response for debugging
      if (response.statusCode != 200 && response.statusCode != 201) {
        print("❌ Upload failed with status ${response.statusCode}");
        print("❌ Full error response: ${response.body}");
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = json.decode(response.body);

          // Extract server URL from response if available
          String? serverUrl;
          if (jsonResponse is Map) {
            serverUrl = jsonResponse['url'] ??
                       jsonResponse['imageUrl'] ??
                       jsonResponse['fileUrl'] ??
                       jsonResponse['image'] ??
                       (jsonResponse['data'] is Map ? jsonResponse['data']['url'] : null);

            // If no URL but we have filename, try to construct a server URL
            // Note: Without eventId, we can't construct the exact EventWithImages URL
            // The backend should return the proper URL or we'll use the filename
            if (serverUrl == null && jsonResponse['filename'] != null) {
              final responseFilename = jsonResponse['filename'] as String;
              // Try to construct a generic gallery URL if possible
              // The actual URL format may vary based on backend implementation
              print("📋 Filename from response: $responseFilename");
              print("ℹ️ Server URL will be determined by backend or EventWithImages API");
            }
          }

          print("✅ Gallery upload successful! Server URL: ${serverUrl ?? 'Will be available in EventWithImages API'}");
          print("📋 Full response: $jsonResponse");

          return {
            'success': true,
            'data': jsonResponse,
            'message': jsonResponse['message'] ?? 'Image uploaded successfully to gallery',
            'serverUrl': serverUrl, // Server URL if API returns it
            'filename': jsonResponse['filename'], // Store filename for reference
          };
        } catch (e) {
          // Response might not be JSON
          return {
            'success': true,
            'data': response.body,
            'message': 'Image uploaded successfully to gallery',
            'serverUrl': null,
          };
        }
      } else {
        // Parse error response
        String errorMessage = 'Failed to upload image to gallery';
        try {
          final errorJson = json.decode(response.body);
          errorMessage = errorJson['message'] ??
                        errorJson['error'] ??
                        errorJson['Message'] ??
                        errorJson['Error'] ??
                        response.body;
        } catch (e) {
          errorMessage = response.body.isNotEmpty
              ? response.body
              : 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        }

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print("❌ Gallery upload error: $e");
      return {
        'success': false,
        'error': 'Exception: ${e.toString()}',
      };
    }
  }

  /// Upload Image API Call (DEPRECATED - Use uploadGalleryImage instead)
  /// NOTE: API requires query parameters, not form fields (based on successful uploads)
  @Deprecated('Use uploadGalleryImage instead - gallery upload API is now used for all image uploads')
  static Future<Map<String, dynamic>> uploadEventImage(
      File file, String description, int employeeId, int sectionId, int eventId) async {
    try {
      // Get authentication token if available
      String? accessToken;
      try {
        accessToken = await MySharedPreferences.instance.getStringValue("token");
        print("🔑 Auth token available: ${accessToken != null}");
      } catch (e) {
        print("⚠️ Could not get auth token: $e");
      }

      // Get instituteId for URL construction
      String? instituteId;
      try {
        instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
      } catch (e) {
        print("⚠️ Could not get instituteId: $e");
      }

      // API requires query parameters (form fields don't work - returns "description field is required")
      final encodedDescription = Uri.encodeComponent(description);

      // Build URL with all required parameters, including instituteId if available
      String uploadUrl = "https://api.schoolnxpro.com/api/FileUploadDownload1/UploadPhoto"
          "?description=$encodedDescription&employeeId=$employeeId&sectionId=$sectionId&eventId=$eventId";

      // Add instituteId to query params if available (may help backend link image to event properly)
      if (instituteId != null && instituteId.isNotEmpty) {
        uploadUrl += "&instituteId=$instituteId";
      }

      final url = Uri.parse(uploadUrl);

      var request = http.MultipartRequest("POST", url);

      // Verify file exists and is readable
      if (!await file.exists()) {
        throw Exception("File does not exist: ${file.path}");
      }

      // Get file extension and determine content type
      final fileExtension = file.path.split('.').last.toLowerCase();
      String contentType = 'image/jpeg'; // default
      if (fileExtension == 'png') {
        contentType = 'image/png';
      } else if (fileExtension == 'jpg' || fileExtension == 'jpeg') {
        contentType = 'image/jpeg';
      } else if (fileExtension == 'gif') {
        contentType = 'image/gif';
      } else if (fileExtension == 'webp') {
        contentType = 'image/webp';
      }

      // Get filename from path
      final filename = file.path.split('/').last;

      // Read file bytes to create MultipartFile with explicit content type
      // This ensures the file is properly included in the request body as multipart/form-data
      final fileBytes = await file.readAsBytes();

      // Create multipart file with explicit content type and filename
      // This matches Postman's multipart/form-data behavior
      final multipartFile = http.MultipartFile.fromBytes(
        "file", // Field name - API expects "file"
        fileBytes,
        filename: filename,
        contentType: MediaType.parse(contentType),
      );

      // Add the file to the request body
      request.files.add(multipartFile);

      print("📎 File details: path=${file.path}, filename=$filename, contentType=$contentType, size=${fileBytes.length} bytes");
      print("📎 Multipart file field name: ${multipartFile.field}");
      print("📎 Multipart file filename: ${multipartFile.filename}");
      print("📎 Multipart file content type: ${multipartFile.contentType}");

      // Add headers - DO NOT set Content-Type manually for multipart requests
      // The http package will set it automatically with boundary
      request.headers.addAll({
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      });

      print("📤 Uploading image to: ${url.toString()}");
      print("📁 File path: ${file.path}");
      print("📎 File name: $filename");
      print("📝 Description: $description");
      print("👤 Employee ID: $employeeId");
      print("📚 Section ID: $sectionId");
      print("🎯 Event ID: $eventId");
      print("🏫 Institute ID: $instituteId");
      print("🔑 Using auth token: ${accessToken != null}");
      print("📎 Multipart files count: ${request.files.length}");
      print("📎 Multipart request body: File is included in multipart/form-data");

      // Use managed HTTP client for consistent connection handling
      final client = HttpClientManager.instance.getClient();
      var streamedResponse = await client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Headers: ${response.headers}");
      print("📥 Response Body: ${response.body}");
      print("📥 Response Body Length: ${response.body.length}");

      // Log full response for debugging
      if (response.statusCode != 200 && response.statusCode != 201) {
        print("❌ Upload failed with status ${response.statusCode}");
        print("❌ Full error response: ${response.body}");
      }

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = json.decode(response.body);

          // Extract server URL from response if available
          // API might return URL in various formats: url, imageUrl, fileUrl, data.url, etc.
          String? serverUrl;
          if (jsonResponse is Map) {
            serverUrl = jsonResponse['url'] ??
                       jsonResponse['imageUrl'] ??
                       jsonResponse['fileUrl'] ??
                       jsonResponse['image'] ??
                       (jsonResponse['data'] is Map ? jsonResponse['data']['url'] : null);

            // If no URL but we have filename, construct the server URL
            // Based on the response: {"status":"success","message":"Photo uploaded successfully.","filename":"70091_40130_639021784774251121.jpg","description":"do"}
            if (serverUrl == null && jsonResponse['filename'] != null) {
              final responseFilename = jsonResponse['filename'] as String;
              // Construct URL based on the pattern seen in EventWithImages API
              // Example: https://api.schoolnxpro.com/api/EventWithImages/download/10085/100044/Catalogue.jpg
              if (instituteId != null && instituteId.isNotEmpty) {
                serverUrl = "https://api.schoolnxpro.com/api/EventWithImages/download/$instituteId/$eventId/$responseFilename";
                print("🔗 Constructed server URL from filename: $serverUrl");
                print("🔗 Using instituteId: $instituteId, eventId: $eventId, filename: $responseFilename");
              } else {
                print("⚠️ Cannot construct server URL: instituteId is null or empty");
                print("⚠️ instituteId: $instituteId, eventId: $eventId, filename: $responseFilename");
              }
            }
          }

          print("✅ Upload successful! Server URL: ${serverUrl ?? 'Not provided in response'}");
          print("📋 Full response: $jsonResponse");

          return {
            'success': true,
            'data': jsonResponse,
            'message': jsonResponse['message'] ?? 'Image uploaded successfully',
            'serverUrl': serverUrl, // Server URL if API returns it or constructed from filename
            'filename': jsonResponse['filename'], // Store filename for reference
          };
        } catch (e) {
          // Response might not be JSON
          return {
            'success': true,
            'data': response.body,
            'message': 'Image uploaded successfully',
            'serverUrl': null,
          };
        }
      } else {
        // Parse error response
        String errorMessage = 'Failed to upload image';
        try {
          final errorJson = json.decode(response.body);
          errorMessage = errorJson['message'] ??
                        errorJson['error'] ??
                        errorJson['Message'] ??
                        errorJson['Error'] ??
                        response.body;
        } catch (e) {
          errorMessage = response.body.isNotEmpty
              ? response.body
              : 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        }

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
        };
      }
    } catch (e) {
      print("❌ Upload error: $e");
      return {
        'success': false,
        'error': 'Exception: ${e.toString()}',
      };
    }
  }

  /// Upload method that tries a specific field name
  /// Use this to test different field names if "file" doesn't work
  static Future<Map<String, dynamic>> uploadEventImageWithFieldName(
      File file, String description, int employeeId, int sectionId, int eventId,
      {String fieldName = 'file'}) async {
    try {
      // Get authentication token if available
      String? accessToken;
      try {
        accessToken = await MySharedPreferences.instance.getStringValue("token");
      } catch (e) {
        print("⚠️ Could not get auth token: $e");
      }

      // Build the URL (without query parameters - we'll use form fields)
      final url = Uri.parse(
        "https://api.schoolnxpro.com/api/FileUploadDownload1/UploadPhoto",
      );

      var request = http.MultipartRequest("POST", url);

      // Add form fields
      request.fields['description'] = description;
      request.fields['employeeId'] = employeeId.toString();
      request.fields['sectionId'] = sectionId.toString();
      request.fields['eventId'] = eventId.toString();

      // Try to get additional fields
      try {
        String? instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
        if (instituteId != null && instituteId.isNotEmpty) {
          request.fields['instituteId'] = instituteId;
        }
      } catch (e) {
        // Ignore
      }

      // Verify file exists
      if (!await file.exists()) {
        throw Exception("File does not exist: ${file.path}");
      }

      // Get filename from path
      final filename = file.path.split('/').last;

      // Add the file with the specified field name
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName, // Try different field name
          file.path,
          filename: filename,
        ),
      );

      // Add headers
      request.headers.addAll({
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      });

      print("📤 Uploading with field name '$fieldName' to: ${url.toString()}");
      print("📎 File name: $filename");
      print("📎 File size: ${await file.length()} bytes");
      print("📎 Multipart files count: ${request.files.length}");

      // Use managed HTTP client
      final client = HttpClientManager.instance.getClient();
      var streamedResponse = await client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = json.decode(response.body);

          String? serverUrl;
          String? instituteId;
          try {
            instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
          } catch (e) {
            // Ignore
          }

          if (jsonResponse is Map) {
            serverUrl = jsonResponse['url'] ??
                       jsonResponse['imageUrl'] ??
                       jsonResponse['fileUrl'] ??
                       jsonResponse['image'] ??
                       (jsonResponse['data'] is Map ? jsonResponse['data']['url'] : null);

            // If no URL but we have filename, construct the server URL
            if (serverUrl == null && jsonResponse['filename'] != null && instituteId != null) {
              final filename = jsonResponse['filename'] as String;
              serverUrl = "https://api.schoolnxpro.com/api/EventWithImages/download/$instituteId/$eventId/$filename";
              print("🔗 Constructed server URL from filename: $serverUrl");
            }
          }

          return {
            'success': true,
            'data': jsonResponse,
            'message': jsonResponse['message'] ?? 'Image uploaded successfully',
            'fieldName': fieldName,
            'serverUrl': serverUrl,
            'filename': jsonResponse['filename'],
          };
        } catch (e) {
          return {
            'success': true,
            'data': response.body,
            'message': 'Image uploaded successfully',
            'fieldName': fieldName,
            'serverUrl': null,
          };
        }
      } else {
        String errorMessage = 'Failed to upload image';
        try {
          final errorJson = json.decode(response.body);
          errorMessage = errorJson['message'] ??
                        errorJson['error'] ??
                        errorJson['Message'] ??
                        errorJson['Error'] ??
                        response.body;
        } catch (e) {
          errorMessage = response.body.isNotEmpty
              ? response.body
              : 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        }

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
          'fieldName': fieldName,
        };
      }
    } catch (e) {
      print("❌ Upload error with field name '$fieldName': $e");
      return {
        'success': false,
        'error': 'Exception: ${e.toString()}',
        'fieldName': fieldName,
      };
    }
  }

  /// Alternative upload method that tries query parameters instead of form fields
  /// Use this if the default uploadEventImage (with form fields) doesn't work
  static Future<Map<String, dynamic>> uploadEventImageWithQueryParams(
      File file, String description, int employeeId, int sectionId, int eventId,
      {String fieldName = 'file'}) async {
    try {
      // Get authentication token if available
      String? accessToken;
      try {
        accessToken = await MySharedPreferences.instance.getStringValue("token");
      } catch (e) {
        print("⚠️ Could not get auth token: $e");
      }

      final encodedDescription = Uri.encodeComponent(description);

      final url = Uri.parse(
        "https://api.schoolnxpro.com/api/FileUploadDownload1/UploadPhoto"
        "?description=$encodedDescription&employeeId=$employeeId&sectionId=$sectionId&eventId=$eventId", // ✅ ADD eventId
      );

      // Verify file exists
      if (!await file.exists()) {
        throw Exception("File does not exist: ${file.path}");
      }

      // Get filename from path
      final filename = file.path.split('/').last;

      var request = http.MultipartRequest("POST", url);

      // Add the file with explicit filename
      request.files.add(
        await http.MultipartFile.fromPath(
          fieldName,
          file.path,
          filename: filename, // Explicit filename
        ),
      );

      // Add headers - DO NOT set Content-Type manually for multipart requests
      request.headers.addAll({
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      });

      print("📤 Uploading with query params and field name '$fieldName' to: ${url.toString()}");
      print("📎 File name: $filename");
      print("📎 File size: ${await file.length()} bytes");
      print("📎 Multipart files count: ${request.files.length}");

      // Use managed HTTP client for consistent connection handling
      final client = HttpClientManager.instance.getClient();
      var streamedResponse = await client.send(request);
      var response = await http.Response.fromStream(streamedResponse);

      print("📥 Response Status: ${response.statusCode}");
      print("📥 Response Body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = json.decode(response.body);

          // Extract server URL from response if available
          String? serverUrl;
          String? instituteId;
          try {
            instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
          } catch (e) {
            // Ignore
          }

          if (jsonResponse is Map) {
            serverUrl = jsonResponse['url'] ??
                       jsonResponse['imageUrl'] ??
                       jsonResponse['fileUrl'] ??
                       jsonResponse['image'] ??
                       (jsonResponse['data'] is Map ? jsonResponse['data']['url'] : null);

            // If no URL but we have filename, construct the server URL
            if (serverUrl == null && jsonResponse['filename'] != null && instituteId != null) {
              final responseFilename = jsonResponse['filename'] as String;
              serverUrl = "https://api.schoolnxpro.com/api/EventWithImages/download/$instituteId/$eventId/$responseFilename";
              print("🔗 Constructed server URL from filename: $serverUrl");
            }
          }

          return {
            'success': true,
            'data': jsonResponse,
            'message': jsonResponse['message'] ?? 'Image uploaded successfully',
            'fieldName': fieldName, // Return which field name worked
            'serverUrl': serverUrl,
            'filename': jsonResponse['filename'],
          };
        } catch (e) {
          return {
            'success': true,
            'data': response.body,
            'message': 'Image uploaded successfully',
            'fieldName': fieldName,
            'serverUrl': null,
          };
        }
      } else {
        String errorMessage = 'Failed to upload image';
        try {
          final errorJson = json.decode(response.body);
          errorMessage = errorJson['message'] ??
                        errorJson['error'] ??
                        errorJson['Message'] ??
                        errorJson['Error'] ??
                        response.body;
        } catch (e) {
          errorMessage = response.body.isNotEmpty
              ? response.body
              : 'HTTP ${response.statusCode}: ${response.reasonPhrase}';
        }

        return {
          'success': false,
          'error': errorMessage,
          'statusCode': response.statusCode,
          'fieldName': fieldName,
        };
      }
    } catch (e) {
      print("❌ Upload error with field name '$fieldName': $e");
      return {
        'success': false,
        'error': 'Exception: ${e.toString()}',
        'fieldName': fieldName,
      };
    }
  }

  /// Create a new event with image upload

  static Future<Map<String, dynamic>> createEvent({
    required DateTime eventDate,
    required String eventName,
    required String sectionId,     // String because Postman sends as text
    required String courseId,      // String because Postman sends as text
    required int employeeId,
    required File imageFile,       // now required (as per your UI)
    String? instituteId,           // optional, will fallback
  }) async {
    try {
      // ── Get token ───────────────────────────────────────────────────────
      String? token = await MySharedPreferences.instance.getStringValue("token");

      // ── Get / fallback instituteId ─────────────────────────────────────
      instituteId ??= await MySharedPreferences.instance.getStringValue("instituteId");
      instituteId ??= "10085";

      // ── Format date ─────────────────────────────────────────────────────
      final formattedDate = DateFormat('yyyy-MM-dd').format(eventDate);

      // ── Build multipart request ────────────────────────────────────────
      final uri = Uri.parse("${ApiUrls.baseUrl}Event/CreateEvent");

      var request = http.MultipartRequest('POST', uri);

      // Headers
      request.headers.addAll({
        'Accept': 'application/json',
        if (token != null && token.isNotEmpty) 'Authorization': 'Bearer $token',
      });

      // ── Text fields (exact keys from Postman) ──────────────────────────
      request.fields.addAll({
        'EventName': eventName.trim(),
        'EventDate': formattedDate,
        'SectionId': sectionId,           // string
        'CourseId': courseId,             // string
        'EmployeeId': employeeId.toString(),
        'InstituteId': instituteId,
      });

      // ── Add image file (key = "File") ──────────────────────────────────
      if (!await imageFile.exists()) {
        return {
          'success': false,
          'error': 'Image file does not exist',
        };
      }

      final fileName = imageFile.path.split(Platform.pathSeparator).last;
      final extension = fileName.split('.').last.toLowerCase();

      String mimeType = 'image/jpeg';
      if (extension == 'png') mimeType = 'image/png';
      if (extension == 'webp') mimeType = 'image/webp';

      final multipartFile = await http.MultipartFile.fromPath(
        'File',               // ← VERY IMPORTANT: exact key from Postman
        imageFile.path,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      // ── Send request ───────────────────────────────────────────────────
      print("📤 Sending multipart request to: $uri");
      print("📋 Fields: ${request.fields}");
      print("📎 File: $fileName (${(await imageFile.length() / 1024).toStringAsFixed(1)} KB)");

      final streamedResponse = await request.send().timeout(
        const Duration(seconds: 60),
      );

      final response = await http.Response.fromStream(streamedResponse);

      print("📥 Status: ${response.statusCode}");
      print("📥 Body: ${response.body}");

      // ── Parse response ─────────────────────────────────────────────────
      if (response.statusCode == 200 || response.statusCode == 201) {
        Map<String, dynamic> jsonData = {};

        try {
          jsonData = jsonDecode(response.body);
        } catch (e) {
          print("⚠️ Response is not valid JSON: ${response.body}");
        }

        final success = jsonData['success'] == true;
        final message = jsonData['message']?.toString() ?? 'Event created';
        final eventId = jsonData['eventId']?.toString() ?? 'unknown';

        return {
          'success': success,
          'message': message,
          'eventId': eventId,
          'rawResponse': jsonData,
          'statusCode': response.statusCode,
        };
      } else {
        String errorMsg = 'Failed to create event (HTTP ${response.statusCode})';

        try {
          final err = jsonDecode(response.body);
          errorMsg = err['message'] ?? err['error'] ?? response.body;
        } catch (_) {
          errorMsg = response.body.isNotEmpty ? response.body : errorMsg;
        }

        return {
          'success': false,
          'error': errorMsg,
          'statusCode': response.statusCode,
        };
      }
    } catch (e, stack) {
      print("❌ createEvent exception: $e");
      print(stack);

      return {
        'success': false,
        'error': e.toString().contains('Timeout')
            ? 'Request timeout. Please check your internet.'
            : 'Failed to create event: $e',
      };
    }
  }

  static Future<Map<String, dynamic>> createEvent11({
    required DateTime eventDate,
    required String eventName,
    required String sectionId,
    required File? imageFile,
    required int employeeId,
    required String courseId,
  }) async {
    try {
      // Get authentication token if available
      String? accessToken;
      try {
        accessToken = await MySharedPreferences.instance.getStringValue("token");
      } catch (e) {
        print("⚠️ Could not get auth token: $e");
      }

      // Get instituteId
      String? instituteId;
      try {
        instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
      } catch (e) {
        print("⚠️ Could not get instituteId: $e");
      }

      if (instituteId == null || instituteId.isEmpty) {
        instituteId = "10085"; // Fallback
      }

      // Format event date as required by API (assuming format: yyyy-MM-dd)
      final formattedDate = DateFormat('yyyy-MM-dd').format(eventDate);

      // Generate unique eventId for local storage (using timestamp)
      // This will be used if API doesn't return an eventId
      final localEventId = DateTime.now().millisecondsSinceEpoch;

      // Step 1: Upload image if provided
      // IMPORTANT: Include event name and date in description so backend can create event
      String? imageUrl;
      String? filename;
      if (imageFile != null) {
        // Generate unique description for image upload
        // Format: "eventName|eventDate|timestamp|random"
        // Backend can parse this to create the event automatically
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        final random = Random().nextInt(99999);
        // Include event name and date in description - backend can parse this
        final uniqueDescription = "${eventName}|${formattedDate}|${timestamp}|$random";

        print("📤 Uploading image with description: $uniqueDescription");
        print("📝 Event Name: $eventName");
        print("📅 Event Date: $formattedDate");
        print("📚 Section ID: $sectionId");
        print("👤 Employee ID: $employeeId");

        final uploadResult = await uploadGalleryImage(
          imageFile,
          uniqueDescription, // Includes event name and date
          employeeId,
          int.parse(sectionId),
          eventName: eventName, // Pass event name as separate parameter
          eventDate: formattedDate, // Pass event date as separate parameter
        );

        if (uploadResult['success'] == true) {
          imageUrl = uploadResult['serverUrl'] as String?;
          filename = uploadResult['filename'] as String?;
          print("✅ Image uploaded successfully for event creation");
          print("📋 Image URL: $imageUrl");
          print("📋 Filename: $filename");
        } else {
          final errorMsg = uploadResult['error'] ?? 'Unknown error';
          print("❌ Image upload failed: $errorMsg");
          // Return error if image upload fails (it's required)
          return {
            'success': false,
            'error': 'Failed to upload image: $errorMsg',
          };
        }
      } else {
        // Image is required
        return {
          'success': false,
          'error': 'Image is required for event creation',
        };
      }

      // Step 2: Create event via API using multipart/form-data (similar to homework upload)
      final client = HttpClientManager.instance.getClient();
      bool eventCreatedViaAPI = false;
      int? apiEventId;

      // Try multiple approaches: JSON POST, Multipart POST, and query params
      List<Map<String, dynamic>> attempts = [
        // {
        //   'method': 'json',
        //   'endpoint': 'https://api.schoolnxpro.com/api/Holiday',
        // },
        // {
        //   'method': 'multipart',
        //   'endpoint': 'https://api.schoolnxpro.com/api/Event/CreateEvent',
        // },
        // {
        //   'method': 'json',
        //   'endpoint': 'https://api.schoolnxpro.com/api/Holiday',
        // },
        {
          'method': 'multipart',
          'endpoint': 'https://api.schoolnxpro.com/api/Event/CreateEvent',

        },
      ];

      for (var attempt in attempts) {
        final endpoint = attempt['endpoint'] as String;
        final method = attempt['method'] as String;

        debugPrint("Create Event Method : $method , endPoint : $endpoint");
        try {
          if (method == 'json') {
            // Try JSON POST
            final eventData = {
              'eventName': eventName,
              'eventDate': formattedDate,
              'sectionId': sectionId,
              'employeeId': employeeId,
              'reason': Utils.generateRandomCode(),
              'instituteId': int.tryParse(instituteId) ?? 10085,
              if (imageUrl != null) 'imageUrl': imageUrl,
              if (filename != null) 'filename': filename,
            };

            final response = await client.post(
              Uri.parse(endpoint),
              headers: {
                'Content-Type': 'application/json',
                if (accessToken != null) 'Authorization': 'Bearer $accessToken',
              },
              body: json.encode(eventData),
            ).timeout(const Duration(seconds: 10));

            print("📥 Create Event url : ${Uri.parse(endpoint)}");
            print("📥 Create Event (JSON) Response Status ($endpoint): ${response.statusCode}");
            print("📥 Create Event Response Body: ${response.body}");

            if (response.statusCode == 200 || response.statusCode == 201) {
              try {
                final responseData = json.decode(response.body);
                if (responseData is Map) {
                  apiEventId = responseData['eventId'] ??
                             responseData['data']?['eventId'] ??
                             responseData['id'];
                }
              } catch (e) {
                print("⚠️ Could not parse event creation response: $e");
              }
              eventCreatedViaAPI = true;
              break;
            }
          } else if (method == 'multipart') {
            // Try Multipart POST (like homework upload)
            final uri = Uri.parse(endpoint);
            var request = http.MultipartRequest('POST', uri);

            // Add form fields
            request.fields['eventName'] = eventName;
            request.fields['EventDate'] = formattedDate;
            request.fields['sectionId'] = sectionId.toString();
            request.fields['employeeId'] = employeeId.toString();
            request.fields['instituteId'] = instituteId;
            request.fields['CourseId'] = courseId.toString();
            if (imageUrl != null) request.fields['File'] = imageUrl;
            if (filename != null) request.fields['filename'] = filename;

            // Add headers
            request.headers.addAll({
              'Accept': 'application/json',
              if (accessToken != null) 'Authorization': 'Bearer $accessToken',
            });

            print("📤 Creating event via multipart: $endpoint");
            print("📋 Event Data: ${request.fields}");

            var streamedResponse = await client.send(request);
            var response = await http.Response.fromStream(streamedResponse);

            print("📥 Create Event (Multipart) Response Status ($endpoint): ${response.statusCode}");
            print("📥 Create Event Response Body: ${response.body}");

            if (response.statusCode == 200 || response.statusCode == 201) {
              try {
                final responseData = json.decode(response.body);
                if (responseData is Map) {
                  apiEventId = responseData['eventId'] ??
                             responseData['data']?['eventId'] ??
                             responseData['id'];
                }
              } catch (e) {
                print("⚠️ Could not parse event creation response: $e");
              }
              eventCreatedViaAPI = true;
              break;
            }
          }
        } catch (e) {
          print("⚠️ Failed to create event at $endpoint ($method): $e");
          continue;
        }
      }

      // If JSON/Multipart didn't work, try with query parameters
      if (!eventCreatedViaAPI) {
        try {
          final queryParams = {
            'eventName': eventName,
            'eventDate': formattedDate,
            'sectionId': sectionId.toString(),
            'employeeId': employeeId.toString(),
            'instituteId': instituteId,
            if (imageUrl != null) 'imageUrl': imageUrl,
            if (filename != null) 'filename': filename,
          };

          // final uri = Uri.parse('https://api.schoolnxpro.com/api/Event/CreateEvent').replace(
          //   queryParameters: queryParams,
          // );
          final uri = Uri.parse('https://api.schoolnxpro.com/api/Event/CreateEvent');
          final response = await client.post(
            uri,
            headers: {
              'Content-Type': 'application/json',
              if (accessToken != null) 'Authorization': 'Bearer $accessToken',
            },
          ).timeout(const Duration(seconds: 10));

          print("📥 Create Event URL : https://api.schoolnxpro.com/api/Event/CreateEvent");
          print("📥 Create Event (Query Params) Response Status: ${response.statusCode}");
          print("📥 Create Event Response Body: ${response.body}");

          if (response.statusCode == 200 || response.statusCode == 201) {
            try {
              final responseData = json.decode(response.body);
              if (responseData is Map) {
                apiEventId = responseData['eventId'] ??
                           responseData['data']?['eventId'] ??
                           responseData['id'];
              }
            } catch (e) {
              print("⚠️ Could not parse event creation response: $e");
            }
            eventCreatedViaAPI = true;
          }
        } catch (e) {
          print("⚠️ Failed to create event with query params: $e");
        }
      }

      // Step 3: Save event locally (always save, even if API fails)
      // Use API eventId if available, otherwise use local generated ID
      final finalEventId = apiEventId ?? localEventId;

      await LocalEventStorage.saveEvent(
        eventId: finalEventId,
        eventName: eventName,
        eventDate: eventDate,
        sectionId: int.parse(sectionId),
        employeeId: employeeId,
        imageUrl: imageUrl,
        filename: filename,
      );

      // Mark as synced if API creation succeeded
      if (eventCreatedViaAPI) {
        await LocalEventStorage.markEventSynced(finalEventId);
        print("✅ Event created in API and saved locally with ID: $finalEventId");
      } else {
        print("✅ Event saved locally with ID: $finalEventId (will sync to API later)");
      }

      // Step 4: Save image URL to local storage for this event
      if (imageUrl != null) {
        await LocalImageStorage.saveServerUrl(finalEventId, imageUrl);
      }

      // Step 5: If API creation failed, try one more time with PUT request to EventWithImages
      if (!eventCreatedViaAPI) {
        try {
          print("🔄 Attempting PUT request to EventWithImages endpoint...");
          final putResponse = await client.put(
            Uri.parse("https://api.schoolnxpro.com/api/EventWithImages"),
            headers: {
              'Content-Type': 'application/json',
              if (accessToken != null) 'Authorization': 'Bearer $accessToken',
            },
            body: json.encode({
              'eventId': finalEventId,
              'eventName': eventName,
              'eventDate': formattedDate,
              'sectionId': sectionId,
              'employeeId': employeeId,
              'instituteId': int.tryParse(instituteId) ?? 10085,
              'images': imageUrl != null ? [imageUrl] : [],
            }),
          ).timeout(const Duration(seconds: 10));

          print("📥 Create Event (PUT EventWithImages) Response Status: ${putResponse.statusCode}");
          print("📥 Create Event Response Body: ${putResponse.body}");

          if (putResponse.statusCode == 200 || putResponse.statusCode == 201) {
            await LocalEventStorage.markEventSynced(finalEventId);
            eventCreatedViaAPI = true;
            print("✅ Event created successfully via PUT request");
          }
        } catch (e) {
          print("⚠️ PUT request also failed: $e");
        }
      }

      // Return success - image uploaded and event saved locally
      return {
        'success': true,
        'data': {
          'eventId': finalEventId,
          'eventName': eventName,
          'eventDate': formattedDate,
          'imageUrl': imageUrl,
          'filename': filename,
        },
        'message': eventCreatedViaAPI
            ? 'Event created successfully ✅\nImage uploaded and event saved to API'
            : 'Event saved successfully ✅\nImage uploaded to API. Backend will process and create event automatically.',
        'imageUrl': imageUrl,
        'filename': filename,
        'eventId': finalEventId,
        'eventCreatedViaAPI': eventCreatedViaAPI,
      };
    } catch (e) {
      print("❌ Create event error: $e");
      return {
        'success': false,
        'error': 'Exception: ${e.toString()}',
      };
    }
  }

  /// Sync unsynced local events to API
  static Future<void> syncUnsyncedEvents() async {
    try {
      final unsyncedEvents = await LocalEventStorage.getUnsyncedEvents();
      if (unsyncedEvents.isEmpty) {
        print("✅ No unsynced events to sync");
        return;
      }

      print("🔄 Syncing ${unsyncedEvents.length} unsynced events to API...");

      final client = HttpClientManager.instance.getClient();
      String? accessToken;
      try {
        accessToken = await MySharedPreferences.instance.getStringValue("token");
      } catch (e) {
        print("⚠️ Could not get auth token: $e");
      }

      String? instituteId;
      try {
        instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
      } catch (e) {
        print("⚠️ Could not get instituteId: $e");
      }

      if (instituteId == null || instituteId.isEmpty) {
        instituteId = "10085";
      }

      for (var event in unsyncedEvents) {
        try {
          final eventId = event['eventId'] as int;
          final eventName = event['eventName'] as String;
          final eventDate = event['eventDate'] as String;
          final sectionId = event['sectionId'] as int;
          final employeeId = event['employeeId'] as int;
          final imageUrl = event['imageUrl'] as String?;

          // Try to create event via API
          final eventData = {
            'eventId': eventId,
            'eventName': eventName,
            'eventDate': eventDate.split('T')[0], // Extract date part
            'sectionId': sectionId,
            'employeeId': employeeId,
            'instituteId': int.tryParse(instituteId) ?? 10085,
            if (imageUrl != null) 'imageUrl': imageUrl,
            if (event['filename'] != null) 'filename': event['filename'],
          };

          // Try POST to Event endpoint
          final response = await client.post(
            Uri.parse("https://api.schoolnxpro.com/api/Event"),
            headers: {
              'Content-Type': 'application/json',
              if (accessToken != null) 'Authorization': 'Bearer $accessToken',
            },
            body: json.encode(eventData),
          ).timeout(const Duration(seconds: 10));

          debugPrint("Api Event url : https://api.schoolnxpro.com/api/Event");
          debugPrint("Api Event response : ${response.body.toString()}");

          if (response.statusCode == 200 || response.statusCode == 201) {
            await LocalEventStorage.markEventSynced(eventId);
            print("✅ Synced event $eventId to API");
          } else {
            print("⚠️ Failed to sync event $eventId: ${response.statusCode}");
          }
        } catch (e) {
          print("⚠️ Error syncing event ${event['eventId']}: $e");
        }
      }
    } catch (e) {
      print("❌ Error syncing unsynced events: $e");
    }
  }
}

class EmployeeEventScreen extends StatefulWidget {
  final UserType userType;

  const EmployeeEventScreen({super.key, required this.userType});

  @override
  State<EmployeeEventScreen> createState() => _EmployeeEventScreenState();
}

class _EmployeeEventScreenState extends State<EmployeeEventScreen> {
  late Future<List<EventModel>> futureEvents;
  final ImagePicker picker = ImagePicker();
  List<Map<String, dynamic>> sections = [];
  bool isLoadingSections = false;
  String _selectedFilterYear = "";
  String _selectedFilterMonth = "";

  bool isUploading = false;

  @override
  void initState() {
    super.initState();

    final DateTime _currentDate = DateTime.now();

    _selectedFilterYear = DateFormat('yyyy').format(_currentDate);
    _selectedFilterMonth = DateTime.now().month.toString();
    debugPrint("selectedFilterDate : $_selectedFilterMonth,$_selectedFilterYear");
    futureEvents = fetchEventsByMonth(
      year: int.parse(_selectedFilterYear),
      month: int.parse(_selectedFilterMonth),
    );

    // futureEvents = EventService.fetchEvents();
    // _loadSections();
    // Sync unsynced events in background
    EventService.syncUnsyncedEvents();
  }

  Future<void> _loadSections() async {
    setState(() => isLoadingSections = true);
    try {
      final fetchedSections = await EventService.fetchSections();
      setState(() {
        sections = fetchedSections;
        isLoadingSections = false;
      });
    } catch (e) {
      print("❌ Error loading sections: $e");
      setState(() => isLoadingSections = false);
    }
  }

  // Future<void> _pickAndUploadImage(EventModel event) async {
  //   final XFile? pickedFile =
  //       await picker.pickImage(source: ImageSource.gallery);

  //   if (pickedFile != null) {
  //     File file = File(pickedFile.path);

  //     // 🔹 Locally add kariye jethi image immediately show thay
  //     setState(() {
  //       event.images.add(file.path);
  //     });
  //     print("📸 Image picked & added locally: ${file.path}");

  //     // 🔥 API upload call
  //     bool success = await EventService.uploadEventImage(
  //       file,
  //       event.eventName,
  //       70095, // employeeId (replace with actual userId)
  //       40130, // sectionId (replace with actual sectionId)
  //     );

  //     if (success) {
  //       print("✅ Image uploaded successfully to server: ${file.path}");
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Image uploaded successfully ✅")),
  //       );
  //     } else {
  //       print("❌ Failed to upload image to server: ${file.path}");
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         const SnackBar(content: Text("Failed to upload image ❌")),
  //       );
  //     }
  //   } else {
  //     print("⚠️ No image selected!");
  //   }
  // }

  Future<File> _saveToLocalDir(File file) async {
    final directory = await getApplicationDocumentsDirectory();
    final newPath = "${directory.path}/${DateTime.now().millisecondsSinceEpoch}.jpg";
    final newFile = await file.copy(newPath);
    return newFile;
  }

  static Future<Map<String, dynamic>> editEventAddImage({
    required int eventId,
    required File newImageFile,
    required int employeeId,
    required String courseId,
  }) async {
    try {
      String? accessToken = await MySharedPreferences.instance.getStringValue("token");
      String? instituteId = await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";

      final uri = Uri.parse("${ApiUrls.baseUrl}Event/EditEvent");

      var request = http.MultipartRequest('PUT', uri);

      request.headers.addAll({
        'Accept': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken',
      });

      // Required Fields
      request.fields['EventId'] = eventId.toString();
      request.fields['EmployeeId'] = employeeId.toString();
      request.fields['CourseId'] = courseId;

      // New Image - Field name MUST be "NewImages"
      final fileName = newImageFile.path.split(Platform.pathSeparator).last;
      final extension = fileName.split('.').last.toLowerCase();

      String mimeType = 'image/jpeg';
      if (extension == 'png') mimeType = 'image/png';
      if (extension == 'webp') mimeType = 'image/webp';

      final multipartFile = await http.MultipartFile.fromPath(
        'NewImages',                    // ← Critical: Must match API param
        newImageFile.path,
        filename: fileName,
        contentType: MediaType.parse(mimeType),
      );

      request.files.add(multipartFile);

      print("📤 Calling EditEvent API - Adding new image");
      print("🎯 EventId: $eventId | EmployeeId: $employeeId | CourseId: $courseId");

      final streamedResponse = await request.send().timeout(const Duration(seconds: 60));
      final response = await http.Response.fromStream(streamedResponse);

      print("📥 EditEvent Status: ${response.statusCode}");
      print("📥 Response: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        try {
          final jsonResponse = jsonDecode(response.body);
          return {
            'success': true,
            'message': jsonResponse['message'] ?? 'Image added successfully to event',
            'data': jsonResponse,
          };
        } catch (e) {
          return {'success': true, 'message': 'Image added successfully'};
        }
      } else {
        String errorMsg = 'Failed to add image';
        try {
          final err = jsonDecode(response.body);
          errorMsg = err['message'] ?? err['error'] ?? response.body;
        } catch (_) {}
        return {'success': false, 'error': errorMsg, 'statusCode': response.statusCode};
      }
    } catch (e) {
      print("❌ editEventAddImage Error: $e");
      return {'success': false, 'error': e.toString()};
    }
  }

  Future<void> _pickAndUploadImage(EventModel event) async {
    final XFile? pickedFile =
        await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      File file = File(pickedFile.path);

      // Save to permanent local directory (persists across logout)
      file = await _saveToLocalDir(file);

      // 🔹 Show image immediately in UI (local path)
      setState(() {
        event.images.add(file.path);
        isUploading = true;
      });

      // 🔹 Save local path in SharedPreferences (will be preserved on logout)
      await LocalImageStorage.saveImage(event.eventId!, file.path);

      // Get employeeId from SharedPreferences
      String? employeeIdStr;
      int? employeeId;
      try {
        employeeIdStr = await MySharedPreferences.instance.getStringValue("employeeID");
        if (employeeIdStr != null && employeeIdStr.isNotEmpty) {
          employeeId = int.tryParse(employeeIdStr);
        }
      } catch (e) {
        print("⚠️ Could not get employeeID: $e");
      }

      if (employeeId == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Employee ID not found. Please login again."),
              backgroundColor: Colors.red,
            ),
          );
        }
        return;
      }

      // Get sectionId from API or use default
      int? sectionId;
      try {
        final sections = await EventService.fetchSections();
        if (sections.isNotEmpty) {
          // Use first section as default, or you can implement section selection logic
          sectionId = sections.first['sectionId'] as int?;
          print("📚 Using sectionId from API: $sectionId");
        }
      } catch (e) {
        print("⚠️ Could not fetch sections: $e");
      }

      // Fallback to default sectionId if API call failed
      if (sectionId == null) {
        sectionId = 40130; // Default fallback
        print("⚠️ Using default sectionId: $sectionId");
      }

      // var result = await EventService.uploadGalleryImage(
      //   file,
      //   event.eventName, // This will be made unique with timestamp in uploadGalleryImage
      //   employeeId,
      //   sectionId,
      //   // Note: No eventId parameter - this is the gallery upload API
      // );

      debugPrint("eventId : ${event.eventId}");
      debugPrint("eventCourseId : ${event.courseId}");

      final result = await editEventAddImage(
        eventId: event.eventId!,
        newImageFile: file,
        employeeId: employeeId,
        courseId: event.courseId.toString(),
      );

      setState(() => isUploading = false);

      if (result['success'] == true) {
        // ✅ Gallery upload successful
        final serverUrl = result['serverUrl'] as String?;
        final filename = result['filename'] as String?;

        print("✅ Image uploaded to gallery successfully!");
        print("📋 Server URL: $serverUrl");
        print("📋 Filename: $filename");
        print("ℹ️ Image will appear in both gallery and event list via EventWithImages API");

        // Refresh the events list to get the updated images from the API
        // The backend should link the uploaded image to the appropriate event(s)
        setState(() {
          // futureEvents = EventService.fetchEvents();
          futureEvents = fetchEventsByMonth(
            year: int.parse(_selectedFilterYear),
            month: int.parse(_selectedFilterMonth),
          );
        });

        // If API returned server URL, save it
        if (serverUrl != null && serverUrl.isNotEmpty) {
          // Remove local path and use server URL
          await LocalImageStorage.removeImage(event.eventId!, file.path);
          await LocalImageStorage.saveServerUrl(event.eventId!, serverUrl);

          // Update UI to show server URL
          setState(() {
            final index = event.images.indexOf(file.path);
            if (index != -1) {
              event.images[index] = serverUrl;
            }
          });

          print("✅ Server URL saved: $serverUrl");
        } else {
          // No server URL in response - image will be available via EventWithImages API
          // Keep local path temporarily until we refresh from API
          print("ℹ️ Server URL not in response - will be available via EventWithImages API");
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text("Image uploaded successfully ✅\nVisible in gallery and event list"),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      } else {
        // Upload failed - but local image is still saved
        final errorMsg = result['error'] ?? 'Failed to upload image to gallery';
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Upload failed: $errorMsg ❌\nLocal image saved.",),
              backgroundColor: Colors.orange,
              duration: const Duration(seconds: 4),
            ),
          );
        }
        print("❌ Gallery upload failed: $errorMsg");
      }
    }
  }

  /// Show dialog to create a new event
  Future<void> _showCreateEventDialog() async {
    DateTime? selectedDate = DateTime.now();
    final TextEditingController eventNameController = TextEditingController();
    Map<String, dynamic>? selectedSection;
    File? selectedImage;
    CourseModel? selectedCourse;
    SectionModel? selectedSections;
    MediumModel? selectedMedium;

    final provider = Provider.of<EmployeeAttendanceProvider>(
      context,
      listen: false,
    );

    if (provider.courseList.isEmpty) {
      await provider.getCourse();
      await provider.getSection();
      await provider.getMedium();
      await provider.getStream();
      await provider.getSubStream();
    }

    await showDialog(
      context: context,
      builder: (BuildContext dialogContext) {
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
              child: SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            "Event Entry",
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 20,
                            ),
                          ),
                          IconButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            icon: const Icon(Icons.close),
                            color: Colors.black54,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),

                      // Event Date
                      GestureDetector(
                        onTap: () async {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: selectedDate,
                            firstDate: DateTime(2020),
                            lastDate: DateTime(2100),
                          );
                          if (picked != null) {
                            setStateDialog(() => selectedDate = picked);
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                selectedDate != null
                                    ? DateFormat('MM/dd/yyyy').format(selectedDate!)
                                    : "Select Event Date",
                                style: TextStyle(
                                  color: selectedDate != null
                                      ? Colors.black
                                      : Colors.grey,
                                ),
                              ),
                              const Icon(Icons.calendar_today, size: 20),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Event Name
                      TextField(
                        controller: eventNameController,
                        decoration: const InputDecoration(
                          labelText: "Event Name *",
                          border: OutlineInputBorder(),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Full Allotment Name (Section Dropdown)
                      // DropdownButtonFormField<Map<String, dynamic>>(
                      //   decoration: const InputDecoration(
                      //     labelText: "Full Allotment Name *",
                      //     border: OutlineInputBorder(),
                      //   ),
                      //   value: selectedSection,
                      //   hint: const Text("Select Section"),
                      //   items: sections.map((section) {
                      //     // Use fullAllotmentName if available, otherwise build from fields
                      //     final displayName = section['fullAllotmentName'] ??
                      //                      section['fullName'] ??
                      //                      section['sectionName'] ??
                      //                      'Section ${section['sectionId']}';
                      //     return DropdownMenuItem<Map<String, dynamic>>(
                      //       value: section,
                      //       child: CustomText.TextRegular(displayName,maxLine: 2),
                      //     );
                      //   }).toList(),
                      //   onChanged: (value) {
                      //     setStateDialog(() => selectedSection = value);
                      //   },
                      // ),

                      AppDropDown(
                        labelText: "Select Course *",
                        value: selectedCourse != null
                            ? "${selectedCourse!.courseName} (${selectedCourse!.courseId})"
                            : null,
                        items: provider.courseList
                            .map((c) => "${c.courseName} (${c.courseId})")
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue == null) return;
                          setStateDialog(() {
                            selectedCourse = provider.courseList.firstWhere(
                                  (c) => "${c.courseName} (${c.courseId})" == newValue,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      AppDropDown(
                        labelText: "Select Section *",
                        value: selectedSections != null
                            ? "${selectedSections!.sectionName} (${selectedSections!.sectionId})"
                            : null,
                        items: provider.sectionList
                            .map((s) => "${s.sectionName} (${s.sectionId})")
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue == null) return;
                          setStateDialog(() {
                            selectedSections = provider.sectionList.firstWhere(
                                  (s) => "${s.sectionName} (${s.sectionId})" == newValue,
                            );
                          });
                        },
                      ),
                      const SizedBox(height: 12),

                      AppDropDown(
                        labelText: "Select Medium *",
                        value: selectedMedium != null
                            ? "${selectedMedium!.mediumName} (${selectedMedium!.mediumId})"
                            : null,
                        items: provider.mediumList
                            .map((m) => "${m.mediumName} (${m.mediumId})")
                            .toList(),
                        onChanged: (String? newValue) {
                          if (newValue == null) return;
                          setStateDialog(() {
                            selectedMedium = provider.mediumList.firstWhere(
                                  (m) => "${m.mediumName} (${m.mediumId})" == newValue,
                            );
                          });
                        },
                      ),

                      const SizedBox(height: 16),

                      // Catalogue Image
                      const Text(
                        "Catalogue Image *",
                        style: TextStyle(
                          fontWeight: FontWeight.w500,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: () async {
                          final XFile? pickedFile =
                              await picker.pickImage(source: ImageSource.gallery);
                          if (pickedFile != null) {
                            setStateDialog(() {
                              selectedImage = File(pickedFile.path);
                            });
                          }
                        },
                        child: Container(
                          height: 150,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey),
                            borderRadius: BorderRadius.circular(8),
                            color: Colors.grey[100],
                          ),
                          child: selectedImage != null
                              ? ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: Image.file(
                                    selectedImage!,
                                    fit: BoxFit.cover,
                                  ),
                                )
                              : const Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(Icons.image, size: 48, color: Colors.grey),
                                      SizedBox(height: 8),
                                      Text(
                                        "No Photo Available",
                                        style: TextStyle(color: Colors.grey),
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Buttons
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(dialogContext),
                            child: const Text("Cancel"),
                          ),
                          const SizedBox(width: 8),
                          ElevatedButton(
                            onPressed: () async {
                              // Validate inputs
                              if (selectedDate == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please select event date"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (eventNameController.text.trim().isEmpty) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please enter event name"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }
                              if (selectedCourse == null) {
                                Utils.toastMessage("Please select Course");
                                return;
                              }
                              if (selectedSections == null) {
                                Utils.toastMessage("Please select Section");
                                return;
                              }
                              if (selectedMedium == null) {
                                Utils.toastMessage("Please select Medium");
                                return;
                              }
                              if (selectedImage == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text("Please select an image"),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Get employeeId
                              String? employeeIdStr;
                              int? employeeId;
                              try {
                                employeeIdStr = await MySharedPreferences.instance
                                    .getStringValue("employeeID");
                                if (employeeIdStr != null &&
                                    employeeIdStr.isNotEmpty) {
                                  employeeId = int.tryParse(employeeIdStr);
                                }
                              } catch (e) {
                                print("⚠️ Could not get employeeID: $e");
                              }

                              if (employeeId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text(
                                        "Employee ID not found. Please login again."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                                return;
                              }

                              // Close dialog first
                              Navigator.pop(dialogContext);

                              // Show loading using rootNavigator to avoid context issues
                              if (!mounted) return;

                              showDialog(
                                context: this.context,
                                barrierDismissible: false,
                                builder: (_) => const Center(
                                  child: CircularProgressIndicator(),
                                ),
                              );

                              // Create event
                              // final sectionId = selectedSection!['sectionId'] as int;
                              final result = await EventService.createEvent(
                                eventDate: selectedDate!,
                                eventName: eventNameController.text.trim(),
                                sectionId: "${selectedSections?.sectionId.toString()}",
                                imageFile: selectedImage!,
                                employeeId: employeeId,
                                courseId:"${selectedCourse?.courseId.toString()}",
                              );

                              // Hide loading - check if mounted and can pop before trying
                              if (mounted) {
                                try {
                                  final navigator = Navigator.of(this.context, rootNavigator: true);
                                  if (navigator.canPop()) {
                                    navigator.pop();
                                  }
                                } catch (e) {
                                  print("⚠️ Error closing loading dialog: $e");
                                  // Silently fail - dialog might already be closed
                                }
                              }

                              if (result['success'] == true) {
                                // Refresh events list
                                if (mounted) {
                                  setState(() {
                                    // futureEvents = EventService.fetchEvents();
                                    futureEvents = fetchEventsByMonth(
                                      year: int.parse(_selectedFilterYear),
                                      month: int.parse(_selectedFilterMonth),
                                    );
                                  });
                                }

                                if (mounted) {
                                  final message = result['eventCreatedViaAPI'] == true
                                      ? "Event created successfully ✅\nImage uploaded and event saved to API"
                                      : "Event saved successfully ✅\nImage uploaded to API. Event will appear in list after backend processing.";

                                  // ScaffoldMessenger.of(this.context).showSnackBar(
                                  //   SnackBar(
                                  //     content: Text(message),
                                  //     backgroundColor: Colors.green,
                                  //     duration: const Duration(seconds: 5),
                                  //   ),
                                  // );
                                  Utils.toastMessage(message);
                                }
                              } else {
                                final errorMsg =
                                    result['error'] ?? 'Failed to create event';
                                if (mounted) {
                                  ScaffoldMessenger.of(this.context).showSnackBar(
                                    SnackBar(
                                      content: Text("Error: $errorMsg ❌"),
                                      backgroundColor: Colors.red,
                                      duration: const Duration(seconds: 4),
                                    ),
                                  );
                                }
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.blue,
                              foregroundColor: Colors.white,
                            ),
                            child: const Text("Save"),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// Fetch events by Year and Month using GetEventCalendar API
  /// Fetch events using GetEventCalendar API and convert to flat list for UI
  static Future<List<EventModel>> fetchEventsByMonth({
    required int year,
    required int month,
  }) async {
    try {
      final client = HttpClientManager.instance.getClient();

      String? instituteId = await MySharedPreferences.instance.getStringValue("instituteId");
      instituteId ??= "10085";

      final url = Uri.parse(
        "${ApiUrls.baseUrl}Event/GetEventCalendar?instituteId=$instituteId&year=$year&month=$month",
      );

      debugPrint("📡 Calling GetEventCalendar: $url");

      final response = await client.get(url);

      if (response.statusCode == 200) {
        final eventListModel = eventListModelFromJson(response.body);

        if (!eventListModel.success) {
          print("API returned success: false");
          return [];
        }

        // Convert nested structure (Day → Events) into flat EventModel list
        List<EventModel> eventModels = [];

        for (var day in eventListModel.days) {
          for (var event in day.events) {
            eventModels.add(
              EventModel(
                eventId: event.eventId, // API doesn't return eventId, so we use 0 or generate one
                eventName: event.eventName,
                eventDate: day.date,
                courseId: event.courseId,
                courseName: event.courseName,
                images: event.images,
              ),
            );
          }
        }

        // Sort by date (newest first)
        eventModels.sort((a, b) => b.eventDate.compareTo(a.eventDate));

        debugPrint("✅ Loaded ${eventModels.length} events for $month/$year");
        return eventModels;
      } else {
        print("❌ API Error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ fetchEventsByMonth Error: $e");
      return [];
    }
  }

// Filter method
  Future<void> _applyFilter() async {
    setState(() {
      futureEvents = fetchEventsByMonth(
        year: int.parse(_selectedFilterYear),
        month: int.parse(_selectedFilterMonth),
      );
    });
  }


  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(title: const Text("Events")),
      floatingActionButton: FloatingActionButton(
        onPressed: _showCreateEventDialog,
        child: const Icon(Icons.add),
        tooltip: "Add Event",
      ),
      body: Stack(
        children: [

          Column(

            children: [

              Padding(
                padding: EdgeInsets.fromLTRB(10, 10, 10, 8),
                child: Row(
                  children: [

                    Expanded(
                      child: Container(
                        height: 45,
                        alignment: Alignment.center,
                        child: DropdownDatePicker(
                          dateformatorder: OrderFormat.ydm, // default is myd
                          inputDecoration: InputDecoration(
                              fillColor: AppColors.whiteColor,
                              contentPadding: EdgeInsets.only(left: 20,right: 20),
                              enabledBorder:  OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: AppColors.blue, width: 1.0),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: AppColors.blue, width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: AppColors.blue, width: 1.0),
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          isDropdownHideUnderline: true,
                          isFormValidator: true,
                          startYear: 1900,
                          endYear: 2030,
                          width: 2,
                          textStyle: TextStyle(fontFamily: CustomText.fontPoppins,fontSize: 12.0),
                          hintTextStyle: TextStyle(fontFamily: CustomText.fontPoppins,fontSize: 12.0),
                          showDay: false,
                          showMonth: false,
                          showYear: true,
                          selectedYear: int.parse(_selectedFilterYear),
                          onChangedDay: (value) => print('onChangedDay: $value'),
                          onChangedMonth: (value) => print('onChangedMonth: $value'),
                          onChangedYear: (value) {
                            print('onChangedYear: $value');
                            _selectedFilterYear = value.toString();
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 2),

                    // Month Box - Shows Full Month Name
                    Expanded(
                      child: Container(
                        height: 45,
                        alignment: Alignment.center,
                        child: DropdownDatePicker(
                          dateformatorder: OrderFormat.ydm, // default is myd
                          inputDecoration: InputDecoration(
                              fillColor: AppColors.whiteColor,
                              contentPadding: EdgeInsets.only(left: 10,right: 10),
                              enabledBorder:  OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: AppColors.blue, width: 1.0),
                              ),
                              disabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: AppColors.blue, width: 1.0),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(10),
                                borderSide: BorderSide(color: AppColors.blue, width: 1.0),
                              ),
                              border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(10))),
                          isDropdownHideUnderline: true,
                          isFormValidator: true,
                          width: 2,
                          textStyle: TextStyle(fontFamily: CustomText.fontPoppins,fontSize: 12.0),
                          hintTextStyle: TextStyle(fontFamily: CustomText.fontPoppins,fontSize: 12.0),
                          showDay: false,
                          showMonth: true,
                          showYear: false,
                          selectedMonth: int.parse(_selectedFilterMonth),
                          onChangedDay: (value) => print('onChangedDay: $value'),
                          onChangedMonth: (value) {
                            _selectedFilterMonth = value.toString();
                          },
                          onChangedYear: (value) {
                          },
                        ),
                      ),
                    ),

                    const SizedBox(width: 5),

                    Container(
                      height: 45,
                      child: CustomButton(
                        text: "Filter",
                        callback: _applyFilter,
                        radius: 10,
                      ),
                    )
                  ],
                ),
              ),

              Expanded(
                child: FutureBuilder<List<EventModel>>(
                  future: futureEvents,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    } else if (snapshot.hasError) {
                      return Center(child: Text("Error: ${snapshot.error}"));
                    } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                      return const Center(child: Text("No Events Found"));
                    } else {
                      final events = snapshot.data!;
                      return ListView.builder(
                        itemCount: events.length,
                        itemBuilder: (context, index) {
                          final event = events[index];
                          return Card(
                            margin: const EdgeInsets.all(10),
                            child: ExpansionTile(
                              title: Text(event.eventName),
                              subtitle: Text(event.eventDate.toString().split(" ")[0]),
                              children: [
                                if (event.images.isNotEmpty)
                                  SizedBox(
                                    height: 150,
                                    child: ListView.builder(
                                      scrollDirection: Axis.horizontal,
                                      itemCount: event.images.length,
                                      itemBuilder: (context, imgIndex) {
                                        final img = event.images[imgIndex];
                                        return Padding(
                                          padding: const EdgeInsets.all(5),
                                          child: Image.network(
                                            img,
                                            errorBuilder: (context,stackTrace,error){
                                              return Container();
                                            },
                                          ),
                                        );
                                      },
                                    ),
                                  )
                                else
                                  const Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: Text("No Images Available"),
                                  ),

                                // ➕ Add Image Button
                                TextButton.icon(
                                  onPressed: () => _pickAndUploadImage(event),
                                  icon: const Icon(Icons.add_a_photo),
                                  label: const Text("Add Image"),
                                ),
                              ],
                            ),
                          );
                        },
                      );
                    }
                  },
                ),
              ),

            ],
          ),

          if (isUploading)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(
                      color: Colors.white,
                      strokeWidth: 5,
                    ),
                    const SizedBox(height: 30),
                    const Text(
                      "Uploading Image...",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

        ],
      ),
    );
  }
}



// class EmployeeEventScreen extends StatefulWidget {
//   final UserType userType;

//   const EmployeeEventScreen({super.key, required this.userType});

//   @override
//   State<EmployeeEventScreen> createState() => _EmployeeEventScreenState();
// }

// class _EmployeeEventScreenState extends State<EmployeeEventScreen> {
//   final String baseUrl = "https://api.schoolnxpro.com/api/Holiday";
//   final int instituteId = 10085;

//   List<dynamic> holidays = [];
//   bool isLoading = true;

//   @override
//   void initState() {
//     super.initState();
//     fetchHolidays();
//   }

//   /// 🔹 GET Holidays
//   Future<void> fetchHolidays() async {
//     setState(() => isLoading = true);

//     final url = Uri.parse("$baseUrl?instituteId=$instituteId");
//     final response = await http.get(url);

//     if (response.statusCode == 200) {
//       final body = jsonDecode(response.body);
//       setState(() {
//         holidays = body["data"] ?? [];
//         isLoading = false;
//       });
//     } else {
//       setState(() => isLoading = false);
//       debugPrint("Error: ${response.body}");
//     }
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text("Events"),
//       ),
//       body: isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : holidays.isEmpty
//               ? const Center(child: Text("No events found"))
//               : ListView.builder(
//                   itemCount: holidays.length,
//                   itemBuilder: (ctx, i) {
//                     final h = holidays[i];
//                     final reason = h["reason"] ?? "";
//                     final rawDate = h["holiday_On"]; // ✅ API field
//                     DateTime? parsedDate;

//                     try {
//                       parsedDate = DateFormat("dd-MM-yyyy").parse(rawDate);
//                     } catch (_) {}

//                     return Card(
//                       child: ListTile(
//                         leading: const Icon(Icons.event),
//                         title: Text(reason),
//                         subtitle: Text(
//                           parsedDate != null
//                               ? DateFormat("dd MMM yyyy").format(parsedDate)
//                               : rawDate,
//                         ),
//                       ),
//                     );
//                   },
//                 ),
//     );
//   }
// }
