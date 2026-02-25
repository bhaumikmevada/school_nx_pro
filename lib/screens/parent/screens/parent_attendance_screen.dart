import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:table_calendar/table_calendar.dart';
import 'package:school_nx_pro/provider/employee_attendance_provider.dart';
import '../../../components/app_button.dart';
import '../../../theme/app_colors.dart';
import '../../../theme/font_theme.dart';
import '../../employee/screens/employee_attendance_screen.dart';
import '../parent_components/parent_appbar.dart';

class AttendanceScreen extends StatefulWidget {
  final UserType userType;
  final String studentId;
  
  const AttendanceScreen({super.key, required this.userType, required this.studentId});

  @override
  State<AttendanceScreen> createState() => _AttendanceScreenState();
}

class _AttendanceScreenState extends State<AttendanceScreen> {
  late EmployeeAttendanceProvider provider;

  DateTime selectedMonth = DateTime.now();
  // int studentId = 170709;

  int present = 0;
  int absent = 0;
  List<int> absentDates = [];
  bool loading = false;

  int? selectedCourseIds;
  int? selectedSectionIds;
  int? selectedMediumIds;
  int? selectedStreamIds;
  int? selectedSubStreamIds;
  List<Map<String, dynamic>> attendanceList = [];

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

    setState(() {
      selectedCourseIds = selectedCourseId;
      selectedSectionIds = selectedSectionId;
      selectedMediumIds = selectedMediumId;
      selectedStreamIds = selectedStreamId;
      selectedSubStreamIds = selectedSubStreamId;
    });
  }

  Future<void> fetchAttendance() async {
    setState(() => loading = true);

    final year = selectedMonth.year;
    final month = selectedMonth.month;

    final url = Uri.parse(
      'https://api.schoolnxpro.com/api/StudentAttandancewithCalender/attendance/student/${widget.studentId}/summary'
          '?courseId=$selectedCourseIds'
          '&sectionId=$selectedSectionIds'
          '&mediumId=$selectedMediumIds'
          '&streamId=$selectedStreamIds'
          '&subStreamId=$selectedSubStreamIds'
          '&year=$year'
          '&month=$month',
    );

    print("-----------------$url");

    final response = await http.get(url);

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      setState(() {
        present = data['presentDays'] ?? 0;
        absent = data['absentDays'] ?? 0;
        absentDates = List<int>.from(data['absentDates'] ?? []);

        final totalDaysInMonth = DateTime(year, month + 1, 0).day;

        int sundays = 0;
        for (int i = 1; i <= totalDaysInMonth; i++) {
          DateTime day = DateTime(year, month, i);
          if (day.weekday == DateTime.sunday) {
            sundays++;
          }
        }

        present = totalDaysInMonth - sundays - absent;

        loading = false;
      });
    } else {
      setState(() => loading = false);
      throw Exception('Failed to load attendance data');
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
              TextFormField(
                readOnly: true,
                controller: TextEditingController(text: "${selectedMonth.month}/${selectedMonth.year}"),
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
                    }
                  },
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildDateInfo("Date From", DateTime(selectedMonth.year, selectedMonth.month, 1).toLocal().toString().split(' ')[0]),
                  _buildDateInfo("Date To", DateTime(selectedMonth.year, selectedMonth.month + 1, 0).toLocal().toString().split(' ')[0]),
                ],
              ),
              const SizedBox(height: 20),
              AppButton(
                buttonText: "Show",
                padding: const EdgeInsets.symmetric(vertical: 10),
                onTap: fetchAttendance,
              ),
            
              const SizedBox(height: 20),
            
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
              const SizedBox(height: 20),
              TableCalendar(
                focusedDay: selectedMonth,
                firstDay: DateTime(2020),
                lastDay: DateTime(2030),
                calendarFormat: CalendarFormat.month,
                availableCalendarFormats: const {
                  CalendarFormat.month: 'Month', // Only show month format (no dropdown)
                },
                headerVisible: true,
                headerStyle: const HeaderStyle(
                  formatButtonVisible: false,
                  titleCentered: true,
                  titleTextStyle: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.black,
                  ),
                  leftChevronIcon: Icon(Icons.chevron_left, color: Colors.black),
                  rightChevronIcon: Icon(Icons.chevron_right, color: Colors.black),
                ),

                selectedDayPredicate: (day) => false,
                daysOfWeekHeight: 30,
                daysOfWeekStyle: const DaysOfWeekStyle(
                  weekdayStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                  weekendStyle: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),

                ),

                calendarStyle: const CalendarStyle(
                  todayDecoration: BoxDecoration(
                    color: Colors.blue,
                    shape: BoxShape.circle,
                  ),
                ),
                calendarBuilders: CalendarBuilders(
                  dowBuilder: (context, day) {
                    if (day.weekday == DateTime.sunday) {
                      final text = ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][day.weekday % 7];
                      return Center(
                        child: Text(
                          text,
                          style: const TextStyle(
                            color: Colors.red,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      );
                    }
                    return null;
                  },
                  defaultBuilder: (context, day, focusedDay) {
                    if (absentDates.contains(day.day) &&
                        day.month == selectedMonth.month &&
                        day.year == selectedMonth.year) {
                      return Container(
                        margin: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            "${day.day}",
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      );
                    }
                    if (day.weekday == DateTime.sunday) {
                      return Center(
                        child: Text(
                          "${day.day}",
                          style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                        ),
                      );
                    }
                    return null;
                  },
                ),
              ),
            ],
                    ),
                  ),
          ),
    );
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
              child: Icon(
                icon,
                color: Colors.white,
                size: 25,
              ),
            ),
            Text(value, style: boldBlack),
            Text(label),
          ],
        ),
      ),
    );
  }
}
