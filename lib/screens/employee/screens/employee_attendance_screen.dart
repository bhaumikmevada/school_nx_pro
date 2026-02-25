import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/components/app_button.dart';
import 'package:school_nx_pro/components/app_dropdown.dart';
import 'package:school_nx_pro/models/course_model.dart';
import 'package:school_nx_pro/models/holiday_model.dart';
import 'package:school_nx_pro/models/medium_model.dart';
import 'package:school_nx_pro/models/section_model.dart';
import 'package:school_nx_pro/models/stream_model.dart';
import 'package:school_nx_pro/models/student_list_for_attendance_model.dart';
import 'package:school_nx_pro/models/sub_stream_model.dart';
import 'package:school_nx_pro/provider/employee_attendance_provider.dart';
import 'package:school_nx_pro/provider/holiday_provider.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/utils/utils.dart';
import 'package:shared_preferences/shared_preferences.dart';

int? selectedCourseId;
int? selectedSectionId;
int? selectedMediumId;
int? selectedStreamId;
int? selectedSubStreamId;

class EmployeeAttendanceScreen extends StatefulWidget {
  const EmployeeAttendanceScreen({super.key});

  @override
  State<EmployeeAttendanceScreen> createState() => _EmployeeAttendanceScreenState();
}

class _EmployeeAttendanceScreenState extends State<EmployeeAttendanceScreen> {
  DateTime selectedDate = DateTime.now();
  late EmployeeAttendanceProvider provider;
  late HolidayProvider holidayProvider;

  bool loading = true;
  bool loadingHolidays = false;
  
  CourseModel? selectedCourseObject;
  SectionModel? selectedSectionObject;
  MediumModel? selectedMediumObject;
  StreamModel? selectedStreamObject;
  SubStreamModel? selectedSubStreamObject;

  // Date-based attendance: Map<dateString, Map<studentId, isPresent>>
  // Format: "yyyy-MM-dd" -> {studentId: true/false}
  Map<String, Map<int, bool>> dateBasedAttendance = {};
  
  // Current month's holidays
  List<HolidayModel> currentMonthHolidays = [];
  
  // Current month for display
  DateTime currentMonth = DateTime.now();

  @override
  void initState() {
    super.initState();
    selectedDate = DateTime.now();
    currentMonth = DateTime(selectedDate.year, selectedDate.month);
    initPref().then((value) {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    });
  }

  Future<void> _loadSavedAttendance() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? savedData = prefs.getString('dateBasedAttendance');
    if (savedData != null) {
      try {
        Map<String, dynamic> jsonMap = jsonDecode(savedData);
        dateBasedAttendance = jsonMap.map((dateKey, studentMap) {
          Map<int, bool> studentAttendance = {};
          if (studentMap is Map) {
            studentMap.forEach((key, value) {
              studentAttendance[int.parse(key.toString())] = value as bool;
            });
          }
          return MapEntry(dateKey, studentAttendance);
        });
      } catch (e) {
        print("Error loading saved attendance: $e");
      }
    }
  }

  Future<void> _loadHolidays() async {
    setState(() => loadingHolidays = true);
    await holidayProvider.getHoliday();
    
    // Filter holidays for current month
    final year = currentMonth.year;
    final month = currentMonth.month;
    
    currentMonthHolidays = holidayProvider.getHolidayList.where((holiday) {
      try {
        // Parse holiday date - format might be "yyyy-MM-dd" or "dd-MM-yyyy"
        DateTime? holidayDate;
        if (holiday.holidayOn.contains('-')) {
          List<String> parts = holiday.holidayOn.split('-');
          if (parts.length == 3) {
            // Try different formats
            try {
              holidayDate = DateTime.parse(holiday.holidayOn);
            } catch (_) {
              // Try dd-MM-yyyy format
              if (parts[0].length == 2) {
                holidayDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
              }
            }
          }
        }
        
        if (holidayDate != null) {
          return holidayDate.year == year && holidayDate.month == month;
        }
        return false;
      } catch (e) {
        return false;
      }
    }).toList();
    
    setState(() => loadingHolidays = false);
  }

  initPref() async {
    provider = Provider.of<EmployeeAttendanceProvider>(context, listen: false);
    holidayProvider = Provider.of<HolidayProvider>(context, listen: false);
    
    await provider.getCourse();
    await provider.getSection();
    await provider.getMedium();
    await provider.getStream();
    await provider.getSubStream();
    await _loadSavedAttendance();
    await _loadHolidays();
  }

  void _saveAttendanceLocally() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    
    // Convert Map<int, bool> to Map<String, bool> for JSON encoding
    final encodedMap = dateBasedAttendance.map((dateKey, studentMap) {
      final encodedStudentMap = studentMap.map((key, value) => MapEntry(key.toString(), value));
      return MapEntry(dateKey, encodedStudentMap);
    });
    
    await prefs.setString('dateBasedAttendance', jsonEncode(encodedMap));
  }

  String _formatDate(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  String _formatDisplayDate(DateTime date) {
    return DateFormat('dd/MM/yyyy').format(date);
  }

  // Get attendance status for a student on selected date
  bool _getStudentAttendanceStatus(int studentId) {
    final dateKey = _formatDate(selectedDate);
    if (dateBasedAttendance.containsKey(dateKey)) {
      return dateBasedAttendance[dateKey]![studentId] ?? true; // Default to Present
    }
    return true; // Default to Present
  }

  // Set attendance status for a student on selected date
  void _setStudentAttendanceStatus(int studentId, bool isPresent) {
    final dateKey = _formatDate(selectedDate);
    if (!dateBasedAttendance.containsKey(dateKey)) {
      dateBasedAttendance[dateKey] = {};
    }
    dateBasedAttendance[dateKey]![studentId] = isPresent;
    _saveAttendanceLocally();
  }

  // Calculate total present and absent days for a student in current month
  Map<String, int> _calculateAttendanceStats(int studentId) {
    int presentDays = 0;
    int absentDays = 0;
    
    final year = currentMonth.year;
    final month = currentMonth.month;
    final totalDaysInMonth = DateTime(year, month + 1, 0).day;
    
    // Count Sundays
    int sundays = 0;
    for (int i = 1; i <= totalDaysInMonth; i++) {
      DateTime day = DateTime(year, month, i);
      if (day.weekday == DateTime.sunday) {
        sundays++;
      }
    }
    
    // Count holidays
    int holidays = currentMonthHolidays.length;
    
    // Count working days (excluding Sundays and holidays)
    int workingDays = totalDaysInMonth - sundays - holidays;
    
    // Count attendance from saved data
    for (int i = 1; i <= totalDaysInMonth; i++) {
      DateTime day = DateTime(year, month, i);
      
      // Skip Sundays
      if (day.weekday == DateTime.sunday) continue;
      
      // Skip holidays
      bool isHoliday = currentMonthHolidays.any((holiday) {
        try {
          DateTime? holidayDate;
          if (holiday.holidayOn.contains('-')) {
            List<String> parts = holiday.holidayOn.split('-');
            if (parts.length == 3) {
              try {
                holidayDate = DateTime.parse(holiday.holidayOn);
              } catch (_) {
                if (parts[0].length == 2) {
                  holidayDate = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
                }
              }
            }
          }
          return holidayDate != null && 
                 holidayDate.year == day.year && 
                 holidayDate.month == day.month && 
                 holidayDate.day == day.day;
        } catch (_) {
          return false;
        }
      });
      
      if (isHoliday) continue;
      
      final dateKey = _formatDate(day);
      if (dateBasedAttendance.containsKey(dateKey)) {
        final isPresent = dateBasedAttendance[dateKey]![studentId] ?? true;
        if (isPresent) {
          presentDays++;
        } else {
          absentDays++;
        }
      } else {
        // If no attendance marked, default to present
        presentDays++;
      }
    }
    
    return {
      'present': presentDays,
      'absent': absentDays,
      'total': workingDays,
      'holidays': holidays,
    };
  }

  // Get list of absent dates for a student
  List<DateTime> _getAbsentDates(int studentId) {
    List<DateTime> absentDates = [];
    
    final year = currentMonth.year;
    final month = currentMonth.month;
    final totalDaysInMonth = DateTime(year, month + 1, 0).day;
    
    for (int i = 1; i <= totalDaysInMonth; i++) {
      DateTime day = DateTime(year, month, i);
      final dateKey = _formatDate(day);
      
      if (dateBasedAttendance.containsKey(dateKey)) {
        final isPresent = dateBasedAttendance[dateKey]![studentId] ?? true;
        if (!isPresent) {
          absentDates.add(day);
        }
      }
    }
    
    return absentDates;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const ParentAppbar(
        title: "Attendance",
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 15),
                child: Column(
                  children: [
                    // Date Selection Section
                    Container(
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(color: Colors.grey.shade300),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            "Select Date",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: GestureDetector(
                                  onTap: () async {
                                    final picked = await showDatePicker(
                                      context: context,
                                      initialDate: selectedDate,
                                      firstDate: DateTime(2020),
                                      lastDate: DateTime(2030),
                                    );
                                    if (picked != null) {
                                      setState(() {
                                        selectedDate = picked;
                                        currentMonth = DateTime(picked.year, picked.month);
                                        _loadHolidays();
                                      });
                                    }
                                  },
                                  child: Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.grey),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          _formatDisplayDate(selectedDate),
                                          style: const TextStyle(fontSize: 16),
                                        ),
                                        const Icon(Icons.calendar_today),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _buildDateInfo("Date", _formatDisplayDate(selectedDate)),
                              _buildDateInfo("Month", DateFormat('MMMM yyyy').format(currentMonth)),
                              _buildDateInfo("Year", selectedDate.year.toString()),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 15),
                    
                    // Course, Section, etc. dropdowns
                    AppDropDown(
                      labelText: "Select Course",
                      value: selectedCourseObject != null
                          ? '${selectedCourseObject!.courseName} (${selectedCourseObject!.courseId})'
                          : null,
                      items: provider.courseList
                          .map((course) =>
                              '${course.courseName} (${course.courseId})')
                          .toList(),
                      onChanged: (String? newValue) {
                        if (newValue != null) {
                          setState(() {
                            selectedCourseObject =
                                provider.courseList.firstWhere(
                              (course) =>
                                  '${course.courseName} (${course.courseId})' ==
                                  newValue,
                              orElse: () => CourseModel(
                                  courseId: -1, courseName: 'Unknown'),
                            );
                            selectedCourseId = selectedCourseObject?.courseId;
                          });
                        }
                      },
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: AppDropDown(
                            labelText: "Select Section",
                            value: selectedSectionObject != null
                                ? '${selectedSectionObject!.sectionName} (${selectedSectionObject!.sectionId})'
                                : null,
                            items: provider.sectionList
                                .map((section) =>
                                    '${section.sectionName} (${section.sectionId})')
                                .toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedSectionObject =
                                      provider.sectionList.firstWhere(
                                    (section) =>
                                        '${section.sectionName} (${section.sectionId})' ==
                                        newValue,
                                    orElse: () => SectionModel(
                                        sectionId: -1, sectionName: 'Unknown'),
                                  );
                                  selectedSectionId =
                                      selectedSectionObject?.sectionId;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: AppDropDown(
                            labelText: "Select Medium",
                            value: selectedMediumObject != null
                                ? '${selectedMediumObject!.mediumName} (${selectedMediumObject!.mediumId})'
                                : null,
                            items: provider.mediumList
                                .map((medium) =>
                                    '${medium.mediumName} (${medium.mediumId})')
                                .toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedMediumObject =
                                      provider.mediumList.firstWhere(
                                    (medium) =>
                                        '${medium.mediumName} (${medium.mediumId})' ==
                                        newValue,
                                    orElse: () => MediumModel(
                                        mediumId: -1, mediumName: 'Unknown'),
                                  );
                                  selectedMediumId =
                                      selectedMediumObject?.mediumId;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(
                          child: AppDropDown(
                            labelText: "Select Stream",
                            value: selectedStreamObject != null
                                ? '${selectedStreamObject!.streamName} (${selectedStreamObject!.streamId})'
                                : null,
                            items: provider.streamList
                                .map((stream) =>
                                    '${stream.streamName} (${stream.streamId})')
                                .toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedStreamObject =
                                      provider.streamList.firstWhere(
                                    (stream) =>
                                        '${stream.streamName} (${stream.streamId})' ==
                                        newValue,
                                    orElse: () => StreamModel(
                                        streamId: -1, streamName: 'Unknown'),
                                  );
                                  selectedStreamId =
                                      selectedStreamObject?.streamId;
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: AppDropDown(
                            labelText: "Sub Stream",
                            value: selectedSubStreamObject != null
                                ? '${selectedSubStreamObject!.subStreamName} (${selectedSubStreamObject!.subStreamId})'
                                : null,
                            items: provider.subStreamList
                                .map((subStream) =>
                                    '${subStream.subStreamName} (${subStream.subStreamId})')
                                .toList(),
                            onChanged: (String? newValue) {
                              if (newValue != null) {
                                setState(() {
                                  selectedSubStreamObject =
                                      provider.subStreamList.firstWhere(
                                    (subStream) =>
                                        '${subStream.subStreamName} (${subStream.subStreamId})' ==
                                        newValue,
                                    orElse: () => SubStreamModel(
                                        subStreamId: -1,
                                        subStreamName: 'Unknown'),
                                  );
                                  selectedSubStreamId =
                                      selectedSubStreamObject?.subStreamId;
                                });
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: AppButton(
                            buttonText: "Show",
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            onTap: () async {
                              if (selectedCourseObject == null) {
                                Utils.toastMessage("Please select Course");
                              } else if (selectedSectionObject == null) {
                                Utils.toastMessage("Please select Section");
                              } else if (selectedMediumObject == null) {
                                Utils.toastMessage("Please select Medium");
                              } else if (selectedStreamObject == null) {
                                Utils.toastMessage("Please select Stream");
                              } else if (selectedSubStreamObject == null) {
                                Utils.toastMessage("Please select Sub Stream");
                              } else {
                                setState(() {
                                  loading = true;
                                });
                                await provider.getStudentListForAttendance(
                                  selectedCourseId ?? 0,
                                  selectedSectionId ?? 0,
                                  selectedMediumId ?? 0,
                                  selectedStreamId ?? 0,
                                  selectedSubStreamId ?? 0,
                                ).then((value) {
                                  loading = false;
                                  setState(() {});
                                });
                              }
                            },
                          ),
                        ),
                        const SizedBox(width: 15),
                        Expanded(
                          child: AppButton(
                            buttonText: "Submit",
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            onTap: () async {
                              _submitAttendance();
                            },
                          ),
                        ),
                      ],
                    ),
                    Selector<EmployeeAttendanceProvider,
                            List<StudentListForAttendanceModel>>(
                        selector: (p0, p1) => p1.studentList,
                        builder: (context, studentList, child) {
                          return studentList.isEmpty
                              ? const Center(
                                  child: Text("No Data!"),
                                )
                              : ListView.separated(
                                  shrinkWrap: true,
                                  physics: const NeverScrollableScrollPhysics(),
                                  itemCount: studentList.length,
                                  itemBuilder: (context, index) {
                                    final student = studentList[index];
                                    final attendanceStatus = _getStudentAttendanceStatus(student.admissionId);
                                    final stats = _calculateAttendanceStats(student.admissionId);
                                    final absentDates = _getAbsentDates(student.admissionId);
                                    
                                    return Card(
                                      margin: const EdgeInsets.symmetric(vertical: 8),
                                      child: Padding(
                                        padding: const EdgeInsets.all(12),
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Row(
                                              children: [
                                                // Present/Absent buttons
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _setStudentAttendanceStatus(student.admissionId, true);
                                                    });
                                                  },
                                                  child: Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      color: attendanceStatus
                                                          ? Colors.green
                                                          : Colors.white,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                          color: Colors.black),
                                                    ),
                                                    child: attendanceStatus
                                                        ? const Icon(Icons.check, color: Colors.white, size: 20)
                                                        : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 10),
                                                GestureDetector(
                                                  onTap: () {
                                                    setState(() {
                                                      _setStudentAttendanceStatus(student.admissionId, false);
                                                    });
                                                  },
                                                  child: Container(
                                                    width: 30,
                                                    height: 30,
                                                    decoration: BoxDecoration(
                                                      color: !attendanceStatus
                                                          ? Colors.red
                                                          : Colors.white,
                                                      shape: BoxShape.circle,
                                                      border: Border.all(
                                                          color: Colors.black),
                                                    ),
                                                    child: !attendanceStatus
                                                        ? const Icon(Icons.close, color: Colors.white, size: 20)
                                                        : null,
                                                  ),
                                                ),
                                                const SizedBox(width: 15),
                                                Text(
                                                  student.admissionId.toString(),
                                                  style: const TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      fontSize: 16),
                                                ),
                                                const SizedBox(width: 15),
                                                Expanded(
                                                  child: Column(
                                                    crossAxisAlignment:
                                                        CrossAxisAlignment.start,
                                                    children: [
                                                      Text(
                                                        student.firstName,
                                                        style: const TextStyle(
                                                            fontWeight: FontWeight.bold),
                                                      ),
                                                      Text(
                                                        student.fathersname,
                                                        style: TextStyle(
                                                            color: Colors.grey[600]),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ],
                                            ),
                                            const SizedBox(height: 10),
                                            // Attendance Statistics
                                            Row(
                                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                                              children: [
                                                _buildStatCard(
                                                  "Present",
                                                  stats['present'].toString(),
                                                  Colors.green,
                                                ),
                                                _buildStatCard(
                                                  "Absent",
                                                  stats['absent'].toString(),
                                                  Colors.red,
                                                ),
                                                _buildStatCard(
                                                  "Total",
                                                  stats['total'].toString(),
                                                  Colors.blue,
                                                ),
                                                _buildStatCard(
                                                  "Holidays",
                                                  stats['holidays'].toString(),
                                                  Colors.orange,
                                                ),
                                              ],
                                            ),
                                            if (absentDates.isNotEmpty) ...[
                                              const SizedBox(height: 10),
                                              const Text(
                                                "Absent Dates:",
                                                style: TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 12,
                                                ),
                                              ),
                                              const SizedBox(height: 5),
                                              Wrap(
                                                spacing: 8,
                                                runSpacing: 4,
                                                children: absentDates.map((date) {
                                                  return Chip(
                                                    label: Text(
                                                      _formatDisplayDate(date),
                                                      style: const TextStyle(fontSize: 10),
                                                    ),
                                                    backgroundColor: Colors.red.shade100,
                                                    padding: EdgeInsets.zero,
                                                  );
                                                }).toList(),
                                              ),
                                            ],
                                            // Current date status
                                            const SizedBox(height: 10),
                                            Container(
                                              padding: const EdgeInsets.all(8),
                                              decoration: BoxDecoration(
                                                color: attendanceStatus
                                                    ? Colors.green.shade50
                                                    : Colors.red.shade50,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Row(
                                                children: [
                                                  Icon(
                                                    attendanceStatus
                                                        ? Icons.check_circle
                                                        : Icons.cancel,
                                                    color: attendanceStatus
                                                        ? Colors.green
                                                        : Colors.red,
                                                    size: 16,
                                                  ),
                                                  const SizedBox(width: 8),
                                                  Text(
                                                    "Today (${_formatDisplayDate(selectedDate)}): ${attendanceStatus ? "Present" : "Absent"}",
                                                    style: TextStyle(
                                                      fontWeight: FontWeight.bold,
                                                      color: attendanceStatus
                                                          ? Colors.green.shade700
                                                          : Colors.red.shade700,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  },
                                  separatorBuilder: (context, index) {
                                    return const SizedBox(height: 5);
                                  },
                                );
                        }),
                  ]
                      .map(
                        (e) => Padding(
                          padding: const EdgeInsets.only(bottom: 15, top: 5),
                          child: e,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
    );
  }

  Widget _buildDateInfo(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildStatCard(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Colors.grey[700],
            ),
          ),
        ],
      ),
    );
  }

  void _submitAttendance() async {
    if (provider.studentList.isEmpty) {
      Utils.toastMessage("Please load students first");
      return;
    }

    final dateKey = _formatDate(selectedDate);
    
    // Only submit attendance for selected date
    // Default all students to Present, only mark Absent if explicitly set
    List<Map<String, dynamic>> attendanceData = provider.studentList.map((student) {
      final isPresent = dateBasedAttendance.containsKey(dateKey) 
          ? (dateBasedAttendance[dateKey]![student.admissionId] ?? true)
          : true; // Default to Present
      
      return {
        "studentId": student.admissionId,
        "status": isPresent ? "Present" : "Absent",
      };
    }).toList();

    await provider.addStudentAttendance(
      studentId: attendanceData.map<int>((e) => e["studentId"] as int).toList(),
      studentAttendanceList: attendanceData,
      courseID: selectedCourseId ?? 0,
      sectionID: selectedSectionId ?? 0,
      mediumID: selectedMediumId ?? 0,
      streamID: selectedStreamId ?? 0,
      subStreamID: selectedSubStreamId ?? 0,
    );

    _saveAttendanceLocally();

    Utils.toastMessage("Attendance submitted successfully for ${_formatDisplayDate(selectedDate)}!");
    
    setState(() {}); // Refresh UI
  }
}
