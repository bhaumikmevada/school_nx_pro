import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/utils/api_urls.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';
import 'package:school_nx_pro/utils/CustomText.dart';

class HolidayItem {
  final int holidayId;
  final String holidayName;
  final String holidayForMonthDate;
  final String holidayOn;

  HolidayItem({
    required this.holidayId,
    required this.holidayName,
    required this.holidayForMonthDate,
    required this.holidayOn,
  });

  factory HolidayItem.fromJson(Map<String, dynamic> json) {
    return HolidayItem(
      holidayId: json['Holiday_ID'] ?? json['holiday_ID'] ?? json['holidayId'] ?? 0,
      holidayName: json['HolidayName'] ?? json['holidayName'] ?? json['reason'] ?? '',
      holidayForMonthDate: json['HolidayForMonthDate'] ?? json['holidayForMonthDate'] ?? '',
      holidayOn: json['Holiday_On'] ?? json['holiday_On'] ?? json['holidayOn'] ?? '',
    );
  }
}

class EmployeeHolidayScreen extends StatefulWidget {
  final UserType userType;

  const EmployeeHolidayScreen({super.key, required this.userType});

  @override
  State<EmployeeHolidayScreen> createState() => _EmployeeHolidayScreenState();
}

class _EmployeeHolidayScreenState extends State<EmployeeHolidayScreen> {
  late Future<List<HolidayItem>> futureHolidays;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  void _loadHolidays() {
    setState(() {
      futureHolidays = fetchHolidaysFromApi();
    });
  }

  Future<List<HolidayItem>> fetchHolidaysFromApi() async {
    try {
      final instituteId =
          await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";
      final token =
          await MySharedPreferences.instance.getStringValue("token") ?? "";

      final url = Uri.parse("${ApiUrls.baseUrl}holiday?instituteId=$instituteId");

      final response = await http.get(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("Holiday API URL : $url");
      debugPrint("Holiday API Response : ${response.body}");

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);

        if (body['success'] == true && body['data'] != null) {
          final List data = body['data'];
          return data.map((e) => HolidayItem.fromJson(e)).toList();
        }
      }

      debugPrint("Holiday API Error: ${response.statusCode}");
      return [];
    } catch (e) {
      debugPrint("Error fetching holidays: $e");
      return [];
    }
  }

  // ---------- ADD Holiday ----------
  Future<bool> addHoliday(DateTime date, String reason) async {
    final trimmedReason = reason.trim();

    if (trimmedReason.isEmpty) {
      return false;
    }

    try {
      final instituteId =
          await MySharedPreferences.instance.getStringValue("instituteId") ??
              "10085";

      final token =
          await MySharedPreferences.instance.getStringValue("token") ?? "";

      final employeeId =
          await MySharedPreferences.instance.getStringValue("employeeId") ??
              "70095";

      final courseId =
          await MySharedPreferences.instance.getStringValue("courseId") ??
              "11460";

      final url = Uri.parse(
        "${ApiUrls.baseUrl}holiday/create-holiday",
      );

      // final holidayDate = date.toUtc().toIso8601String();
      final holidayDate = DateTime(date.year, date.month, date.day)
          .toIso8601String()
          .split('T')
          .first;

      // IMPORTANT:
      // This creates Postman "form-data"
      // It is NOT JSON.
      final request = http.MultipartRequest("POST", url);

      request.headers["Authorization"] = "Bearer $token";

      // Postman form-data TEXT fields
      request.fields["InstituteId"] = instituteId;
      request.fields["EmployeeId"] = employeeId;
      request.fields["CourseId"] = courseId;
      request.fields["HolidayDate"] = holidayDate;
      request.fields["Reason"] = trimmedReason;
      request.fields["HolidayForMonthDate"] = holidayDate;

      debugPrint("========== ADD HOLIDAY ==========");
      debugPrint("URL: $url");
      debugPrint("InstituteId: $instituteId");
      debugPrint("EmployeeId: $employeeId");
      debugPrint("CourseId: $courseId");
      debugPrint("HolidayDate: $holidayDate");
      debugPrint("Reason: $trimmedReason");
      debugPrint("HolidayForMonthDate: $holidayDate");

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(streamedResponse);

      debugPrint("Status: ${response.statusCode}");
      debugPrint("Response: ${response.body}");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        final responseBody = jsonDecode(response.body);

        if (responseBody["success"] == true) {
          _loadHolidays();
          return true;
        }

        debugPrint(
          "Add Holiday Failed: ${responseBody["message"]}",
        );

        return false;
      }

      debugPrint(
        "Add Holiday HTTP Error: ${response.statusCode}",
      );

      return false;
    } catch (e) {
      debugPrint("Add Holiday Error: $e");
      return false;
    }
  }

  // ---------- UPDATE Holiday ----------
  Future<bool> updateHoliday(
      HolidayItem holiday,
      String changeReason,
      DateTime selectedDate,
      ) async {
    if (!mounted) return false;

    setState(() => isUpdating = true);

    final trimmedReason = changeReason.trim();

    if (trimmedReason.isEmpty) {
      if (mounted) {
        setState(() => isUpdating = false);
      }
      return false;
    }

    try {
      final instituteId =
          await MySharedPreferences.instance.getStringValue("instituteId") ??
              "10085";

      final token =
          await MySharedPreferences.instance.getStringValue("token") ?? "";

      final employeeId =
          await MySharedPreferences.instance.getStringValue("employeeId") ??
              "70095";

      final courseId =
          await MySharedPreferences.instance.getStringValue("courseId") ??
              "11460";

      final url = Uri.parse(
        "${ApiUrls.baseUrl}holiday/create-holiday",
      );

      // final holidayDate = selectedDate.toUtc().toIso8601String();
      final holidayDate = DateTime(selectedDate.year, selectedDate.month, selectedDate.day)
          .toIso8601String()
          .split('T')
          .first;   // → "2026-09-10"

      // FORM-DATA
      final request = http.MultipartRequest("POST", url);

      request.headers["Authorization"] = "Bearer $token";

      // TEXT FIELDS ONLY
      request.fields["InstituteId"] = instituteId;
      request.fields["EmployeeId"] = employeeId;
      request.fields["CourseId"] = courseId;
      request.fields["HolidayDate"] = holidayDate;
      request.fields["Reason"] = trimmedReason;
      request.fields["HolidayForMonthDate"] = holidayDate;
      request.fields["HolidayId"] = holiday.holidayId.toString();

      debugPrint("========== UPDATE HOLIDAY ==========");
      debugPrint("URL: $url");
      debugPrint("InstituteId: $instituteId");
      debugPrint("HolidayId: ${holiday.holidayId}");
      debugPrint("EmployeeId: $employeeId");
      debugPrint("CourseId: $courseId");
      debugPrint("HolidayDate: $holidayDate");
      debugPrint("Reason: $trimmedReason");
      debugPrint("HolidayForMonthDate: $holidayDate");

      final streamedResponse = await request.send();

      final response = await http.Response.fromStream(
        streamedResponse,
      );

      debugPrint("Status: ${response.statusCode}");
      debugPrint("Response: ${response.body}");

      if (response.statusCode == 200 ||
          response.statusCode == 201) {

        final responseBody = jsonDecode(response.body);

        if (responseBody["success"] == true) {
          _loadHolidays();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text("Holiday updated successfully"),
                backgroundColor: Colors.green,
              ),
            );
          }

          return true;
        }

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                responseBody["message"]?.toString() ??
                    "Failed to update holiday",
              ),
              backgroundColor: Colors.red,
            ),
          );
        }

        return false;
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Failed to update: ${response.body}",
            ),
            backgroundColor: Colors.red,
          ),
        );
      }

      return false;
    } catch (e) {
      debugPrint("Update Holiday Error: $e");

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Update error: $e"),
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

  // ---------- Dialogs ----------
  void showAddHolidayDialog() {
    final reasonCtrl = TextEditingController();
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
                  if (ctx.mounted && ok) Navigator.pop(ctx);
                  if (ctx.mounted && !ok) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text("Failed to add holiday"),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Please enter reason and pick a date")),
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

  void showUpdateHolidayDialog(HolidayItem holiday) {
    final changeReasonCtrl = TextEditingController(text: holiday.holidayName);

    // Current holiday date ko parse karke pre-select karo
    DateTime selectedDate;
    try {
      selectedDate = DateTime.parse(holiday.holidayOn);
    } catch (_) {
      selectedDate = DateTime.now();
    }

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setStateDialog) => AlertDialog(
          title: const Text("Update Holiday"),
          content: Column(
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
              const SizedBox(height: 16),
              // Date selection button - current date already selected
              ElevatedButton(
                onPressed: isUpdating
                    ? null
                    : () async {
                  final picked = await showDatePicker(
                    context: context,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2030),
                    initialDate: selectedDate,
                  );
                  if (picked != null) {
                    setStateDialog(() => selectedDate = picked);
                  }
                },
                child: Text(
                  DateFormat("dd MMM yyyy").format(selectedDate),
                ),
              ),
            ],
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
                final ok = await updateHoliday(
                  holiday,
                  changeReasonCtrl.text.trim(),
                  selectedDate,
                );
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

  String _formatDate(String raw) {
    try {
      final dt = DateTime.parse(raw);
      return DateFormat('dd-MM-yyyy').format(dt);
    } catch (_) {
      return raw;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ParentAppbar(title: "Holidays"),
      body: FutureBuilder<List<HolidayItem>>(
        future: futureHolidays,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text("Failed to load holidays"),
                  const SizedBox(height: 10),
                  ElevatedButton(
                    onPressed: _loadHolidays,
                    child: const Text("Retry"),
                  ),
                ],
              ),
            );
          }

          final holidays = snapshot.data ?? [];

          if (holidays.isEmpty) {
            return const Center(child: Text("No holidays found"));
          }

          return RefreshIndicator(
            onRefresh: () async => _loadHolidays(),
            child: ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: holidays.length,
              itemBuilder: (context, index) {
                final holiday = holidays[index];
                final dateStr = _formatDate(holiday.holidayOn);

                return Card(
                  color: AppColors.whiteColor,
                  margin: const EdgeInsets.only(bottom: 10),
                  child: Container(
                    margin: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      border: Border.all(color: AppColors.colorcfcfcf, width: 1),
                      color: AppColors.whiteColor,
                      borderRadius: BorderRadius.circular(10),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.colorcfcfcf,
                          blurRadius: 2.0,
                          offset: const Offset(1.0, 0.0),
                        )
                      ],
                    ),
                    child: Stack(
                      alignment: Alignment.topRight,
                      children: [
                        // Date badge
                        Container(
                          width: 100,
                          height: 30,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            borderRadius: const BorderRadius.only(
                              topRight: Radius.circular(9),
                            ),
                            color: AppColors.blue,
                          ),
                          child: CustomText.TextMedium(
                            dateStr,
                            fontSize: 13.0,
                            color: AppColors.whiteColor,
                            textAlign: TextAlign.center,
                          ),
                        ),

                        // Content
                        Padding(
                          padding: const EdgeInsets.all(12),
                          child: Row(
                            children: [
                              Container(
                                width: 70,
                                height: 70,
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Icon(Icons.event, size: 40, color: Colors.grey),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    CustomText.TextSemiBold(
                                      holiday.holidayName.isNotEmpty
                                          ? holiday.holidayName
                                          : "Holiday",
                                      color: AppColors.blackColor,
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      "ID: ${holiday.holidayId}",
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.shade600,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                icon: const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () => showUpdateHolidayDialog(holiday),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: AppColors.blue,
        onPressed: showAddHolidayDialog,
        child: const Icon(Icons.add, color: Colors.white, size: 35),
      ),
    );
  }
}