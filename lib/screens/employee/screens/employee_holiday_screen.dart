import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/provider/holiday_provider.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/utils/api_urls.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

import '../../../models/holiday_list_model.dart';
import '../../../utils/CustomText.dart';
import '../../../utils/utils.dart';

class EmployeeHolidayScreen extends StatefulWidget {
  final UserType userType;

  const EmployeeHolidayScreen({super.key, required this.userType});

  @override
  State<EmployeeHolidayScreen> createState() => _EmployeeHolidayScreenState();
}

class _EmployeeHolidayScreenState extends State<EmployeeHolidayScreen> {

  List<Map<String, dynamic>> holidays = [];
  late Future<HolidayListModel?> futureHolidays;
  bool isLoading = true;
  bool isUpdating = false;

  @override
  void initState() {
    super.initState();
    _loadHolidays();
  }

  /// 🔹 Load holidays: try HolidayProvider first (same as rest of app), then direct API with saved instituteId
  // Future<void> _loadHolidays() async {
  //   if (!mounted) return;
  //   setState(() => isLoading = true);
  //
  //   try {
  //     // Use HolidayProvider (same API as attendance/parent) so data shows consistently
  //     final provider = Provider.of<HolidayProvider>(context, listen: false);
  //     final count = await provider.getHoliday();
  //     if (count > 0 && mounted) {
  //       final list = provider.getHolidayList;
  //       setState(() {
  //         holidays = list.map((m) => {
  //           "holiday_ID": m.holidayID,
  //           "holidayId": m.holidayID,
  //           "reason": m.eventName,
  //           "holidayName": m.eventName,
  //           "holiday_On": m.holidayOn,
  //           "holidayOn": m.holidayOn,
  //           "holidayForMonthDate": m.holidayForMonthDate,
  //         }).toList();
  //         isLoading = false;
  //       });
  //       return;
  //     }
  //   } catch (e) {
  //     debugPrint("HolidayProvider load error: $e");
  //   }
  //
  //   // Fallback: direct API with instituteId from preferences
  //   final instituteId = await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";
  //   await fetchHolidaysFromApi(instituteId);
  // }

  Future<void> _loadHolidays() async {
    setState(() {}); // Just to trigger rebuild if needed

    futureHolidays = fetchHolidaysFromCalendar();
  }

  Future<HolidayListModel?> fetchHolidaysFromCalendar() async {
    try {
      final instituteId = await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";

      final url = Uri.parse(
        "${ApiUrls.baseUrl}Holiday/GetHolidayCalendar?instituteId=$instituteId",
      );

      final response = await http.get(url);
      debugPrint("Holiday Calendar API URL : $url");
      debugPrint("Holiday Calendar API Response : ${response.body}");
      if (response.statusCode == 200) {
        final holidayListModel = holidayListModelFromJson(response.body);
        return holidayListModel;
      } else {
        debugPrint("Holiday Calendar API Error: ${response.statusCode}");
        return null;
      }
    } catch (e) {
      debugPrint("Error fetching holiday calendar: $e");
      return null;
    }
  }

  /// 🔹 GET Holidays from API (direct) – supports flat list or nested HolidayDetails
  // Future<void> fetchHolidaysFromApi(String instituteId) async {
  //   if (!mounted) return;
  //
  //   final url = Uri.parse("$baseUrl?instituteId=$instituteId");
  //   final response = await http.get(url);
  //
  //   if (!mounted) return;
  //   if (response.statusCode == 200) {
  //     final body = jsonDecode(response.body);
  //     dynamic data = body["data"];
  //     if (data == null && body["success"] == true) data = body["data"];
  //     if (data == null) data = [];
  //
  //     List<Map<String, dynamic>> flatList = [];
  //     if (data is List) {
  //       for (var item in data) {
  //         final map = Map<String, dynamic>.from(item as Map);
  //         final details = map["holidayDetails"] ?? map["HolidayDetails"];
  //         if (details is List && details.isNotEmpty) {
  //           for (var d in details) {
  //             final detail = Map<String, dynamic>.from(d as Map);
  //             flatList.add({
  //               ...map,
  //               "reason": detail["reason"] ?? map["reason"] ?? map["holidayName"] ?? "",
  //               "holiday_On": detail["holiday_On"] ?? detail["holidayOn"] ?? map["holiday_On"] ?? map["holidayOn"] ?? "",
  //               "holidayDetailId": detail["holidayDetailId"] ?? detail["holidayDetail_ID"],
  //             });
  //           }
  //         } else {
  //           flatList.add(map);
  //         }
  //       }
  //     }
  //     if (mounted) {
  //       setState(() {
  //         holidays = flatList;
  //         isLoading = false;
  //       });
  //     }
  //   } else {
  //     if (mounted) setState(() => isLoading = false);
  //     debugPrint("Holiday API Error: ${response.body}");
  //   }
  // }

  // Future<void> fetchHolidays() async {
  //   final instituteId = await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";
  //   await fetchHolidaysFromApi(instituteId);
  // }

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
    final url = Uri.parse("${ApiUrls.baseUrl}Holiday/CreateHoliday");

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
      await fetchHolidaysFromCalendar();
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

    final url = Uri.parse("${ApiUrls.baseUrl}Holiday/CreateHoliday");

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
        await fetchHolidaysFromCalendar();
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
      body: FutureBuilder<HolidayListModel?>(
      future: futureHolidays,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError || snapshot.data == null) {
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

        final holidayModel = snapshot.data!;

        if (!holidayModel.success || holidayModel.days.isEmpty) {
          return const Center(child: Text("No holidays found"));
        }

        // Flatten all holidays from all days
        final List<Holiday> allHolidays = [];
        for (var day in holidayModel.days) {
          allHolidays.addAll(day.holidays);
        }

        return RefreshIndicator(
          onRefresh: _loadHolidays,
          child: ListView.builder(
            padding: const EdgeInsets.all(12),
            itemCount: allHolidays.length,
            itemBuilder: (context, index) {
              final holiday = allHolidays[index];

              // Find the date for this holiday
              DateTime? holidayDate;
              for (var day in holidayModel.days) {
                if (day.holidays.contains(holiday)) {
                  holidayDate = day.date;
                  break;
                }
              }
              String holidayDateStr = DateFormat('dd-MM-yyyy').format(holidayDate!);
              return Card(
                color: AppColors.whiteColor,
                margin: const EdgeInsets.only(bottom: 10),
                child: Column(
                  children: [

                    Container(
                      margin: EdgeInsets.all(5),
                      decoration: BoxDecoration(
                          border: Border.all(color: AppColors.colorcfcfcf,width: 1),
                          color: AppColors.whiteColor,
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(color: AppColors.colorcfcfcf,blurRadius: 2.0,offset: Offset(1.0, 0.0))
                          ]
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [

                          Stack(
                            alignment: Alignment.topRight,
                            children: [

                              Container(
                                width: 100,
                                height: 30,
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                    borderRadius: BorderRadius.only(
                                        topRight: Radius.circular(9)
                                    ),
                                    color: AppColors.blue
                                ),
                                child: CustomText.TextMedium(holidayDateStr,fontSize: 13.0,color: AppColors.whiteColor,textAlign: TextAlign.center),
                              ),

                              Container(
                                padding: EdgeInsets.all(10),
                                child: Row(
                                  children: [

                                    holiday.images.isNotEmpty ?
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(10),
                                      child: Image.network(
                                        holiday.images[0],
                                        width: 80,
                                        height: 80,
                                        fit: BoxFit.cover,
                                      ),
                                    ) : Container(width: 80,height: 80,child: Icon(Icons.image, color: Colors.grey,size: 80,),),

                                    const SizedBox(width: 10,),

                                    CustomText.TextSemiBold(holiday.reason,color: AppColors.blackColor),


                                  ],
                                ),
                              )

                            ],
                          )
                        ],
                      ),
                    )

                  ],
                ),
                // child: ListTile(
                //   leading: const Icon(Icons.event, color: Colors.orange),
                //   title: Text(
                //     holiday.reason.isNotEmpty ? holiday.reason : "Holiday",
                //     style: const TextStyle(fontWeight: FontWeight.w500),
                //   ),
                //   subtitle: Text(
                //     holidayDate != null
                //         ? DateFormat("dd MMM yyyy").format(holidayDate)
                //         : "No date",
                //   ),
                //   trailing: holiday.images.isNotEmpty
                //       ? const Icon(Icons.image, color: Colors.grey)
                //       : null,
                // ),
              );
            },
          ),
        );
      },
    ),
      // floatingActionButton: FloatingActionButton(
      //   backgroundColor: AppColors.blue,
      //   onPressed: showAddHolidayDialog,
      //   child: Icon(Icons.add, color: Colors.white, size: 35),
      // ),
    );
  }
}
