import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import 'package:school_nx_pro/components/app_card.dart';
import 'package:school_nx_pro/components/circular_detail_popup.dart';
import 'package:school_nx_pro/screens/common_screens/profile_screen.dart';
import 'package:school_nx_pro/screens/employee/employee_components/employee_appbar.dart';
import 'package:school_nx_pro/screens/employee/employee_components/employee_drawer.dart';
import 'package:school_nx_pro/screens/common_screens/homework_screen.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_attendance_screen.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_event_screen.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_gallery_screen.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_holiday_screen.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';
import 'package:school_nx_pro/utils/http_client_manager.dart';
import 'package:shared_preferences/shared_preferences.dart';

class EmployeeDashboard extends StatefulWidget {
  final List<dynamic> children;
  final List<String> institutes;
  final Map<String, dynamic> loginData;

  const EmployeeDashboard({super.key, required this.institutes, required this.children, required this.loginData});

  @override
  State<EmployeeDashboard> createState() => _EmployeeDashboardState();
}

class _EmployeeDashboardState extends State<EmployeeDashboard> {
  String? employeeName;
  bool loading = true;

  @override
  void initState() {
    super.initState();
    // Get employeeName from loginData immediately (no async needed)
    employeeName = widget.loginData['userName'] ?? 
                   widget.loginData['employeeName'];
    
    // Show UI immediately
    if (mounted) {
      setState(() {
        loading = false;
      });
    }
    
    // Load from SharedPreferences in background (for consistency)
    _loadEmployeeName();
  }

  // Load employee name from SharedPreferences in background
  Future<void> _loadEmployeeName() async {
    final employeeNameNew = await MySharedPreferences.instance.getStringValue('employeeName');
    if (mounted) {
      setState(() {
        employeeName = employeeNameNew ?? employeeName;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: EmployeeAppbar(isDash: true),
      drawerEnableOpenDragGesture: false,
      drawer: EmployeeDrawer(
        children: widget.children,
        institutes: widget.institutes
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: GestureDetector(
                      // onTap: () {
                      //   Navigator.push(
                      //     context,
                      //     MaterialPageRoute(
                      //       builder: (context) => const ProfileScreen(
                      //         userType: UserType.employee,
                      //       ),
                      //     ),
                      //   );
                      // },
                      onTap: () async {
                        final type = "Employee";

                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ProfileScreen(
                              userType: UserType.employee,
                              name: widget.loginData['userName'] ?? 'N/A',
                              firstName: widget.loginData['firstName'] ?? 'N/A',
                              lastName: widget.loginData['lastName'] ?? 'N/A',
                              mobile: widget.loginData['mobileNo'] ?? "+91",
                              type: type,
                            ),
                          ),
                        ).then((result) {
                          if (result != null && result is Map<String, dynamic>) {
                            setState(() {
                              employeeName = result['name'] ?? employeeName;
                            });
                          }
                        });
                      },
                      child: Row(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(100),
                            child: Image.asset(
                              AppImages.example,
                              height: 70,
                              width: 70,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(width: 25),
                          Expanded(
                            child: Text(
                              employeeName ?? "N/A",
                              style: boldBlack.copyWith(fontSize: 23),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    height: MediaQuery.of(context).size.height / 5,
                    width: double.maxFinite,
                    decoration: const BoxDecoration(
                      color: AppColors.blue,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(vertical: 20),
                      child: Column(
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildAttendanceState(
                                icon: AppIcons.group,
                                value: "301",
                                label: "Total Students",
                              ),
                              _buildAttendanceState(
                                icon: AppIcons.manCheck,
                                value: "230",
                                label: "Student Present",
                              ),
                              _buildAttendanceState(
                                icon: AppIcons.manCross,
                                value: "71",
                                label: "Student Absent",
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                  Container(
                    transform: Matrix4.translationValues(0.0, -25.0, 0.0),
                    decoration: const BoxDecoration(
                      color: AppColors.bgColor,
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(30),
                        topRight: Radius.circular(30),
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        children: [
                          // Today's Homework
                          todaysHomework(context),
                          // Events
                          FutureBuilder<List<EventModel>>(
                            future: EventService.fetchEvents(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(child: Text("Error: ${snapshot.error}"));
                              } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
                                return const Center(child: Text("No Events Found"));
                              } else {
                                return events(context, snapshot.data!);
                              }
                            },
                          ),
                          // Next Holidays
                          FutureBuilder<http.Response>(
                            future: HttpClientManager.instance.getClient().get(
                              Uri.parse("https://api.schoolnxpro.com/api/Holiday?instituteId=10085"),
                              headers: {'Content-Type': 'application/json'},
                            ),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState == ConnectionState.waiting) {
                                return const Center(child: CircularProgressIndicator());
                              } else if (snapshot.hasError) {
                                return Center(child: Text("Error: ${snapshot.error}"));
                              } else if (!snapshot.hasData || snapshot.data!.statusCode != 200) {
                                return const Center(child: Text("No Holidays Found"));
                              } else {
                                final body = jsonDecode(snapshot.data!.body);
                                final holidays = body["data"] ?? [];
                                if (holidays.isEmpty) {
                                  return const Center(child: Text("No Holidays Found"));
                                }
                                return nextHolidays(context, holidays);
                              }
                            },
                          ),

                          // Gallery
                          gallery(context),
                          SizedBox(height: MediaQuery.of(context).size.height / 30),
                        ],
                      ),
                    ),
                  )
                ],
              ),
            ),
    );
  }

  Future<List<Map<String, dynamic>>> loadTodayHomework() async {
    final prefs = await SharedPreferences.getInstance();
    final savedData = prefs.getString("homeworkList");

    if (savedData != null) {
      List<Map<String, dynamic>> allHomework =
          List<Map<String, dynamic>>.from(jsonDecode(savedData));

      // 🔹 No date filter — return all homework
      return allHomework;
    }
    return [];
  }

  Column todaysHomework(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "HomeWork",
              style: normalBlack.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>  HomeworkScreen(
                      userType: UserType.employee,
                    ),
                  ),
                );

                setState(() {});
              },
              icon: const Icon(
                Icons.keyboard_arrow_right,
                size: 30,
              ),
            ),
          ],
        ),

        FutureBuilder(
          future: loadTodayHomework(), // ✅ load all homework, not just today's
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }

            if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return Text("No homework available", style: normalBlack);
            }

            List<Map<String, dynamic>> allHomework = snapshot.data!;

            // ✅ If only 1, show 1; if more, show only first 2
            final limitedHomework = allHomework.length > 1
                ? allHomework.sublist(0, 2)
                : allHomework;

            return ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: limitedHomework.length,
              itemBuilder: (context, index) {
                final hw = limitedHomework[index];
                return AppCard(
                  onTap: () {
                    showDialog(
                      context: context,
                      builder: (_) => AlertDialog(
                        title: Text(hw["title"] ?? ""),
                        content: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text("Subject: ${hw["subject"]}"),
                            Text("From: ${hw["fromDate"]}"),
                            Text("To: ${hw["toDate"]}"),
                            Text("Description: ${hw["description"]}"),
                          ],
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text("Close"),
                          ),
                        ],
                      ),
                    );
                  },
                  mainTitle: hw["subject"],
                  upperTitle: hw["title"],
                  widget: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Text(hw["fromDate"], style: normalBlack),
                      Text("-", style: normalBlack),
                      Text(hw["toDate"], style: normalBlack),
                    ],
                  ),
                );
              },
            );
          },
        )

      ],
    );
  }

  Column events(BuildContext context, List<EventModel> events) {
    // 🔹 first 2 events j leva
    final limitedEvents = events.take(2).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Events",
              style: normalBlack.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeEventScreen(
                      userType: UserType.employee,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.keyboard_arrow_right,
                size: 30,
              ),
            ),
          ],
        ),

        // 🔹 Events list (only 2)
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: limitedEvents.length,
          itemBuilder: (context, index) {
            final event = limitedEvents[index];
            return AppCard(
              onTap: () {
                CircularDetailPopup(context: context).show();
              },
              isImage: true,
              upperTitle: event.eventName,
              widget: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    event.eventDate.toString().split(" ")[0],
                    style: normalBlack,
                  ),
                  Text("-", style: normalBlack),
                  Text(
                    event.eventDate.toString().split(" ")[0],
                    style: normalBlack,
                  ),
                ],
              ),
            );
          },
        ),
      ],
    );
  }

  Column nextHolidays(BuildContext context, List<dynamic> holidays) {
    final limitedHolidays = holidays.take(2).toList();

    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Next Holidays",
              style: normalBlack.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeHolidayScreen(
                      userType: UserType.employee,
                    ),
                  ),
                );
              },
              icon: const Icon(
                Icons.keyboard_arrow_right,
                size: 30,
              ),
            ),
          ],
        ),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: limitedHolidays.length,
          itemBuilder: (context, index) {
            final h = limitedHolidays[index];
            final reason = h["reason"] ?? "";
            final rawDate = h["holiday_On"]; // API field
            DateTime? parsedDate;

            try {
              parsedDate = DateFormat("dd-MM-yyyy").parse(rawDate);
            } catch (_) {}

            return AppCard(
              mainTitle: parsedDate != null
                  ? DateFormat("dd, MMM yyyy").format(parsedDate)
                  : rawDate,
              upperTitle: reason,
              widget: Text(
                parsedDate != null
                    ? DateFormat("EEEE").format(parsedDate) // weekday
                    : "",
                style: normalBlack,
              ),
            );
          },
        ),
      ],
    );
  }

  Column gallery(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              "Gallery",
              style: normalBlack.copyWith(
                fontSize: 20,
                fontWeight: FontWeight.w500,
              ),
            ),
            IconButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EmployeeGalleryScreen(),
                  ),
                );
              },
              icon: const Icon(
                Icons.keyboard_arrow_right,
                size: 30,
              ),
            ),
          ],
        ),
        FutureBuilder<List<EventModel>>(
          future: EventService.fetchEvents(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            } else if (snapshot.hasError) {
              return Center(child: Text("Error: ${snapshot.error}"));
            } else if (!snapshot.hasData || snapshot.data!.isEmpty) {
              return const Center(child: Text("No Images Found"));
            } else {
              // all events maathi images collect
              final events = snapshot.data!;
              final allImages = events.expand((e) => e.images).toList();

              // sirf 6 images show karo
              final limitedImages = allImages.take(6).toList();

              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                ),
                itemCount: limitedImages.length,
                itemBuilder: (context, index) {
                  final path = limitedImages[index];

                  return ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: _buildImage(path),
                  );
                },
              );
            }
          },
        ),
      ],
    );
  }

  // Helper function
  Widget _buildImage(String path) {
    if (path.startsWith("http")) {
      // Network image
      return Image.network(
        path,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 40),
      );
    } else {
      // Local file image
      return Image.file(
        File(path),
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) =>
            const Icon(Icons.broken_image, size: 40),
      );
    }
  }

  Widget _buildAttendanceState({
    required String icon,
    required String value,
    required String label,
  }) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => const EmployeeAttendanceScreen(),
          ),
        );
      },
      child: Container(
        // height: 130,
        // width: 130,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(25),
          border: Border.all(color: AppColors.blue),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(5, 15, 5, 15),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              Image.asset(
                icon,
                height: 30,
                width: 30,
              ),
              Text(
                value,
                style: boldBlack,
              ),
              Text(label),
            ],
          ),
        ),
      ),
    );
  }
}
