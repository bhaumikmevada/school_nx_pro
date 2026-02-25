import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/provider/holiday_provider.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

class EmployeeHolidayScreen extends StatefulWidget {
  final UserType userType;

  const EmployeeHolidayScreen({super.key, required this.userType});

  @override
  State<EmployeeHolidayScreen> createState() => _EmployeeHolidayScreenState();
}

class _EmployeeHolidayScreenState extends State<EmployeeHolidayScreen> {
  final String baseUrl = "https://api.schoolnxpro.com/api/Holiday";
  List<Map<String, dynamic>> holidays = [];
  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  /// 🔹 Load holidays: try HolidayProvider first (same as rest of app), then direct API with saved instituteId
  Future<void> _loadHolidays() async {
    if (!mounted) return;
    setState(() => isLoading = true);

    try {
      // Use HolidayProvider (same API as attendance/parent) so data shows consistently
      final provider = Provider.of<HolidayProvider>(context, listen: false);
      final count = await provider.getHoliday();
      if (count > 0 && mounted) {
        final list = provider.getHolidayList;
        setState(() {
          holidays = list.map((m) => {
            "holiday_ID": m.holidayID,
            "holidayId": m.holidayID,
            "reason": m.eventName,
            "holidayName": m.eventName,
            "holiday_On": m.holidayOn,
            "holidayOn": m.holidayOn,
            "holidayForMonthDate": m.holidayForMonthDate,
          }).toList();
          isLoading = false;
        });
        return;
      }
    } catch (e) {
      debugPrint("HolidayProvider load error: $e");
    }

    // Fallback: direct API with instituteId from preferences
    final instituteId = await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";
    await fetchHolidaysFromApi(instituteId);
  }

  /// 🔹 GET Holidays from API (direct) – supports flat list or nested HolidayDetails
  Future<void> fetchHolidaysFromApi(String instituteId) async {
    if (!mounted) return;

    final url = Uri.parse("$baseUrl?instituteId=$instituteId");
    final response = await http.get(url);

    if (!mounted) return;
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      dynamic data = body["data"];
      if (data == null && body["success"] == true) data = body["data"];
      if (data == null) data = [];

      List<Map<String, dynamic>> flatList = [];
      if (data is List) {
        for (var item in data) {
          final map = Map<String, dynamic>.from(item as Map);
          final details = map["holidayDetails"] ?? map["HolidayDetails"];
          if (details is List && details.isNotEmpty) {
            for (var d in details) {
              final detail = Map<String, dynamic>.from(d as Map);
              flatList.add({
                ...map,
                "reason": detail["reason"] ?? map["reason"] ?? map["holidayName"] ?? "",
                "holiday_On": detail["holiday_On"] ?? detail["holidayOn"] ?? map["holiday_On"] ?? map["holidayOn"] ?? "",
                "holidayDetailId": detail["holidayDetailId"] ?? detail["holidayDetail_ID"],
              });
            }
          } else {
            flatList.add(map);
          }
        }
      }
      if (mounted) {
        setState(() {
          holidays = flatList;
          isLoading = false;
        });
      }
    } else {
      if (mounted) setState(() => isLoading = false);
      debugPrint("Holiday API Error: ${response.body}");
    }
  }

  Future<void> fetchHolidays() async {
    final instituteId = await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";
    await fetchHolidaysFromApi(instituteId);
  }

  int _getHolidayId(Map<String, dynamic> holiday) {
    dynamic id = holiday["holiday_ID"] ?? holiday["holidayID"] ?? holiday["holidayId"] ??
        holiday["id"] ?? holiday["Id"] ?? holiday["holiday_id"] ?? holiday["Holiday_ID"] ?? holiday["HolidayID"];
    if (id == null) {
      for (var key in holiday.keys) {
        if (key.toString().toLowerCase().contains('id')) {
          final value = holiday[key];
          if (value is int && value > 0) return value;
          if (value is String) {
            final parsed = int.tryParse(value);
            if (parsed != null && parsed > 0) return parsed;
          }
        }
      }
      return 0;
    }
    if (id is int) return id;
    if (id is String) return int.tryParse(id) ?? 0;
    return int.tryParse(id.toString()) ?? 0;
  }

  /// 🔹 POST Add Holiday — returns true on success so caller can close dialog
  Future<bool> addHoliday(DateTime date, String reason) async {
    final trimmedReason = reason.trim();
    if (trimmedReason.isEmpty) return false;

    final instituteId = int.tryParse(
      await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085",
    ) ?? 10085;
    final url = Uri.parse(baseUrl);

    final body = {
      "holidayForMonthDate":
          DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(date),
      "instituteId": instituteId,
      "holidayDetails": [
        {
          "holidayOn":
              DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(date),
          "reason": trimmedReason,
        }
      ]
    };

    final response = await http.post(
      url,
      headers: {"Content-Type": "application/json"},
      body: jsonEncode(body),
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      await fetchHolidays();
      return true;
    }
    debugPrint("Failed: ${response.body}");
    return false;
  }

  /// 🔹 POST Update Holiday - Change Reason
  /// Pass full holiday map so we can send HolidayDetails (API requires it).
  /// Returns true on success so caller can close dialog.
  Future<bool> updateHoliday(Map<String, dynamic> holiday, String changeReason) async {
    if (!mounted) return false;
    setState(() => isUpdating = true);

    final trimmedReason = changeReason.trim();
    if (trimmedReason.isEmpty) {
      setState(() => isUpdating = false);
      return false;
    }

    final url = Uri.parse(baseUrl);

    final int holidayId = _getHolidayId(holiday);
    final int holidayDetailId = holiday["holidayDetailId"] as int? ?? 0;
    final String rawDate = holiday["holiday_On"]?.toString() ?? "";
    // API may expect date in ISO format for HolidayDetails
    String holidayOnFormatted = rawDate;
    try {
      final parsed = DateFormat("dd-MM-yyyy").parse(rawDate);
      holidayOnFormatted = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(parsed);
    } catch (_) {}

    // API requires HolidayDetails array; include holidayDetailId, reason, date
    final body = {
      "holiday_ID": holidayId,
      "changeReason": trimmedReason,
      "HolidayDetails": [
        {
          "holidayDetailId": holidayDetailId,
          "holidayId": holidayId,
          "holidayOn": holidayOnFormatted,
          "holiday_On": holidayOnFormatted,
          "reason": trimmedReason,
        }
      ]
    };

    debugPrint("Updating holiday - ID: $holidayId, Reason: $trimmedReason");
    debugPrint("Request body: ${jsonEncode(body)}");

    try {
      final response = await http.post(
        url,
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      debugPrint("Update response status: ${response.statusCode}");
      debugPrint("Update response body: ${response.body}");

      if (response.statusCode == 200 || response.statusCode == 201) {
        await fetchHolidays();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("Holiday updated successfully"),
              backgroundColor: Colors.green,
            ),
          );
        }
        return true;
      } else {
        debugPrint("Failed to update holiday: ${response.body}");
        if (mounted) {
          String errorMessage = "Failed to update holiday";
          try {
            final errorBody = jsonDecode(response.body);
            errorMessage = errorBody["message"] ?? 
                          errorBody["error"] ?? 
                          errorBody["data"] ??
                          "Failed to update holiday";
          } catch (_) {
            errorMessage = response.body.isNotEmpty 
                ? response.body 
                : "Failed to update holiday";
          }
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(errorMessage),
              backgroundColor: Colors.red,
            ),
          );
        }
        return false;
      }
    } catch (e) {
      debugPrint("Error updating holiday: $e");
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    } finally {
      if (mounted) {
        setState(() => isUpdating = false);
      }
    }
  }

  /// 🔹 Show Add Holiday Dialog
  void showAddHolidayDialog() {
    final TextEditingController reasonCtrl = TextEditingController();
    DateTime? selectedDate;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text("Add Holiday"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: reasonCtrl,
                decoration: const InputDecoration(labelText: "Reason"),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDate: DateTime.now(),
                  );
                  if (picked != null) {
                    setStateDialog(() => selectedDate = picked);
                  }
                },
                child: Text(selectedDate == null
                    ? "Pick Date"
                    : DateFormat("dd MMM yyyy").format(selectedDate!)),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: () async {
                final reason = reasonCtrl.text.trim();
                if (selectedDate != null && reason.isNotEmpty) {
                  final ok = await addHoliday(selectedDate!, reason);
                  if (ctx.mounted && ok) {
                    Navigator.pop(ctx);
                  } else if (ctx.mounted && !ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to add holiday"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Please enter reason and pick a date"),
                    ),
                  );
                }
              },
              child: const Text("Save"),
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Show Update Holiday Dialog
  void showUpdateHolidayDialog(Map<String, dynamic> holiday) {
    // Debug: Print full holiday structure
    debugPrint("=== Holiday Data Structure ===");
    debugPrint("Full holiday object: $holiday");
    debugPrint("All keys: ${holiday.keys.toList()}");
    
    // Try multiple possible field names for holiday ID
    dynamic holidayId = holiday["holiday_ID"] ?? 
                        holiday["holidayID"] ?? 
                        holiday["holidayId"] ??
                        holiday["id"] ?? 
                        holiday["Id"] ?? 
                        holiday["ID"] ??
                        holiday["holiday_id"] ??
                        holiday["Holiday_ID"] ??
                        holiday["HolidayID"] ??
                        null;
    
    // If still null, try to parse as int from string
    if (holidayId == null) {
      // Try to find any numeric field that might be the ID
      for (var key in holiday.keys) {
        if (key.toString().toLowerCase().contains('id') || 
            key.toString().toLowerCase().contains('holiday')) {
          final value = holiday[key];
          if (value is int && value > 0) {
            holidayId = value;
            debugPrint("Found ID in field '$key': $holidayId");
            break;
          } else if (value is String && int.tryParse(value) != null) {
            holidayId = int.parse(value);
            debugPrint("Found ID in field '$key' (parsed from string): $holidayId");
            break;
          }
        }
      }
    }
    
    // Convert to int if it's a string
    int finalHolidayId = 0;
    if (holidayId != null) {
      if (holidayId is int) {
        finalHolidayId = holidayId;
      } else if (holidayId is String) {
        finalHolidayId = int.tryParse(holidayId) ?? 0;
      } else {
        finalHolidayId = int.tryParse(holidayId.toString()) ?? 0;
      }
    }
    
    // Get current reason if available
    final currentReason = holiday["reason"] ?? 
                         holiday["Reason"] ?? 
                         holiday["holidayName"] ??
                         "";
    
    final TextEditingController changeReasonCtrl = TextEditingController(text: currentReason);

    if (finalHolidayId == 0) {
      // Show error with more details
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: Holiday ID not found. Available fields: ${holiday.keys.join(', ')}"),
          duration: const Duration(seconds: 4),
        ),
      );
      debugPrint("ERROR: Could not find holiday ID in data structure");
      debugPrint("Available fields: ${holiday.keys.toList()}");
      debugPrint("Holiday values: ${holiday.values.toList()}");
      return;
    }
    
    debugPrint("Found holiday ID: $finalHolidayId");

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text("Update Holiday"),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: changeReasonCtrl,
                  decoration: const InputDecoration(
                    labelText: "Change Reason",
                    hintText: "Enter new reason",
                  ),
                  maxLines: 3,
                  autofocus: true,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: isUpdating ? null : () => Navigator.pop(ctx),
              child: const Text("Cancel"),
            ),
            ElevatedButton(
              onPressed: isUpdating
                  ? null
                  : () async {
                      if (changeReasonCtrl.text.trim().isEmpty) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text("Please enter a reason")),
                        );
                        return;
                      }
                      final ok = await updateHoliday(holiday, changeReasonCtrl.text.trim());
                      if (ctx.mounted && ok) Navigator.pop(ctx);
                    },
              child: isUpdating
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text("Done"),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ParentAppbar(title: "Holidays"),
      // appBar: AppBar(
      //   title: const Text("Holidays"),
      //   actions: [
      //     IconButton(
      //       icon: const Icon(Icons.add),
      //       onPressed: showAddHolidayDialog,
      //     )
      //   ],
      // ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : holidays.isEmpty
              ? RefreshIndicator(
                  onRefresh: _loadHolidays,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    child: SizedBox(
                      height: MediaQuery.of(context).size.height * 0.5,
                      child: const Center(child: Text("No holidays found")),
                    ),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadHolidays,
                  child: ListView.builder(
                    padding: const EdgeInsets.only(left: 14, right: 14, top: 8, bottom: 80),
                    itemCount: holidays.length,
                    itemBuilder: (ctx, i) {
                      final h = holidays[i];
                      final reason = h["reason"] ?? h["holidayName"] ?? "";
                      final rawDate = h["holiday_On"] ?? h["holidayOn"] ?? "";
                      DateTime? parsedDate;
                      if (rawDate.isNotEmpty) {
                        try {
                          parsedDate = DateFormat("dd-MM-yyyy").parse(rawDate);
                        } catch (e) {
                          parsedDate = DateTime.tryParse(rawDate);
                        }
                      }

                      return Padding(
                        padding: const EdgeInsets.only(top: 5),
                        child: Card(
                          child: ListTile(
                            leading: const Icon(Icons.event),
                            title: GestureDetector(
                              onTap: () => showUpdateHolidayDialog(h),
                              child: Text(
                                reason.isEmpty ? "Holiday" : reason,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w500,
                                  decoration: TextDecoration.underline,
                                  decorationColor: Colors.grey,
                                ),
                              ),
                            ),
                            subtitle: Text(
                              parsedDate != null
                                  ? DateFormat("dd MMM yyyy").format(parsedDate)
                                  : rawDate.isNotEmpty ? rawDate : "-",
                            ),
                            trailing: IconButton(
                              icon: const Icon(Icons.edit),
                              onPressed: () => showUpdateHolidayDialog(h),
                            ),
                            onLongPress: () => showUpdateHolidayDialog(h),
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue,
        onPressed: showAddHolidayDialog,
        child: Icon(Icons.add, color: Colors.white, size: 35),
      ),
    );
  }
}
