import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:school_nx_pro/utils/api_urls.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/provider/employee_attendance_provider.dart';
import '../../../components/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/font_theme.dart';
import '../../employee/screens/employee_attendance_screen.dart';
import '../parent_components/parent_appbar.dart';

class AttendanceScreen extends StatefulWidget {
  final UserType userType;
  final String studentId;

  const AttendanceScreen({
    super.key,
    required this.userType,
    required this.studentId,
  });

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late EmployeeAttendanceProvider provider;

  DateTime selectedMonth = DateTime.now();

  int present = 0;
  int absent = 0;
  Set<String> absentDateSet = {}; // Changed to Set<String> for fast lookup
  bool loading = false;

  // Remove unused variables if not needed
  // int? selectedCourseIds; ...

  @override
  void initState() {
    super.initState();
    fetchInitialDetails();
  }

  Future<void> fetchInitialDetails() async {
    provider = Provider.of<EmployeeAttendanceProvider>(context, listen: false);

    await provider.getCourse();
    await provider.getSection();
    await provider.getMedium();
    await provider.getStream();
    await provider.getSubStream();

    // Remove this if you're not using these variables anymore
    // setState(() { ... });
    fetchAttendance();
  }

  Future<void> fetchAttendance() async {
    setState(() => loading = true);

    final year = selectedMonth.year;
    final month = selectedMonth.month;

    final url = Uri.parse(
      '${ApiUrls.baseUrl}Attendance/attendance/student/${widget.studentId}/monthly-summary?'
          '&year=$year'
          '&month=$month',
    );

    print("Fetching attendance: $url");

    try {
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);

        setState(() {
          absent = data['total_absent_days'] ?? 0;
          absentDateSet = Set<String>.from(data['absent_dates'] ?? []);

          final totalDaysInMonth = DateTime(year, month + 1, 0).day;
          int sundays = 0;

          for (int i = 1; i <= totalDaysInMonth; i++) {
            if (DateTime(year, month, i).weekday == DateTime.sunday) {
              sundays++;
            }
          }

          present = totalDaysInMonth - sundays - absent;

          loading = false;
        });
      } else {
        throw Exception('Failed to load');
      }
    } catch (e) {
      print("Error fetching attendance: $e");
      setState(() => loading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Failed to load attendance')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    print("Parent Attendance Student ID :- ${widget.studentId}");

    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const ParentAppbar(title: "Attendance"),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            children: [
              // Month Selector
              TextFormField(
                readOnly: true,
                controller: TextEditingController(
                  text: "${selectedMonth.month.toString().padLeft(2, '0')}/${selectedMonth.year}",
                ),
                decoration: const InputDecoration(
                  labelText: "Select Month",
                  border: OutlineInputBorder(),
                ),
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: selectedMonth,
                    firstDate: DateTime(2023),
                    lastDate: DateTime(2030),
                  );
                  if (picked != null) {
                    setState(() {
                      selectedMonth = DateTime(picked.year, picked.month);
                    });
                    // Optional: Auto fetch after month change
                    // fetchAttendance();
                  }
                },
              ),

              const SizedBox(height: 20),

              // Date From - To
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDateInfo("Date From",
                      DateTime(selectedMonth.year, selectedMonth.month, 1)
                          .toString()
                          .split(' ')[0]),
                  _buildDateInfo("Date To",
                      DateTime(selectedMonth.year, selectedMonth.month + 1, 0)
                          .toString()
                          .split(' ')[0]),
                ],
              ),

              const SizedBox(height: 20),

              AppButton(
                buttonText: "Show",
                padding: const EdgeInsets.symmetric(vertical: 10),
                onTap: fetchAttendance,
              ),

              const SizedBox(height: 25),

              // Summary Stats
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttendanceStat(
                    icon: Icons.check,
                    iconColor: Colors.green,
                    value: present.toString(),
                    label: "Total Present Days",
                  ),
                  _buildAttendanceStat(
                    icon: Icons.close_rounded,
                    iconColor: Colors.red,
                    value: absent.toString(),
                    label: "Total Absent Days",
                  ),
                ],
              ),

              const SizedBox(height: 25),

              // ListView of All Days
              Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(color: AppColors.blue.withOpacity(0.3)),
                ),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day,
                  itemBuilder: (context, index) {
                    final day = index + 1;
                    final date = DateTime(selectedMonth.year, selectedMonth.month, day);

                    // Format date to match API format: "2026-03-07"
                    final dateString = "${date.year}-${date.month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}";

                    final isAbsent = absentDateSet.contains(dateString);
                    final isSunday = date.weekday == DateTime.sunday;

                    return Container(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: isAbsent
                              ? Colors.red
                              : isSunday
                              ? Colors.red.withOpacity(0.5)
                              : Colors.green,
                          width: 1.5,
                        ),
                      ),
                      child: Row(
                        children: [
                          // Day Circle
                          Container(
                            height: 45,
                            width: 45,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isAbsent
                                  ? Colors.red
                                  : isSunday
                                  ? Colors.red.withOpacity(0.2)
                                  : Colors.green,
                              border: Border.all(
                                color: isAbsent
                                    ? Colors.red.shade700
                                    : Colors.green.shade700,
                                width: 2,
                              ),
                            ),
                            child: Center(
                              child: Text(
                                day.toString().padLeft(2, '0'),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                          ),

                          const SizedBox(width: 16),

                          // Day Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getDayName(date),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w600,
                                    color: isSunday ? Colors.red : Colors.black87,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  dateString,
                                  style: const TextStyle(
                                    color: Colors.grey,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),

                          // Status Text
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                            decoration: BoxDecoration(
                              color: isAbsent
                                  ? Colors.red.shade50
                                  : isSunday
                                  ? Colors.red.shade50
                                  : Colors.green.shade50,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              isAbsent
                                  ? "Absent"
                                  : isSunday
                                  ? "Sunday"
                                  : "Present",
                              style: TextStyle(
                                color: isAbsent
                                    ? Colors.red
                                    : isSunday
                                    ? Colors.red
                                    : Colors.green,
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _getDayName(DateTime date) {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    return days[date.weekday - 1];
  }

  Widget _buildDateInfo(String label, String date) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black)),
        const SizedBox(height: 5),
        Container(
          height: 60,
          width: 170,
          decoration: BoxDecoration(
            color: Colors.transparent,
            border: Border.all(color: Colors.black),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
            child: Text(
              date,
              style: const TextStyle(color: Colors.black, fontSize: 18),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAttendanceStat({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Container(
      height: 130,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.blue),
      ),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            Container(
              height: 30,
              width: 30,
              decoration: BoxDecoration(
                color: iconColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: Colors.white, size: 25),
            ),
            Text(value, style: boldBlack),
            Text(label),
          ],
        ),
      ),
    );
  }
}