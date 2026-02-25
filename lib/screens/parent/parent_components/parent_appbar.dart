import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/provider/holiday_provider.dart';
import 'package:school_nx_pro/provider/homework_provider.dart';
import 'package:school_nx_pro/provider/parent_dashboard_provider.dart';
import 'package:school_nx_pro/provider/school_circular_provider.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

class ParentAppbar extends StatefulWidget implements PreferredSizeWidget {
  const ParentAppbar({
    super.key,
    this.isDash = false,
    this.title = "",
    this.onStudentChanged,
  });

  final bool isDash;
  final String title;
  final Function(String studentId)? onStudentChanged;

  @override
  State<ParentAppbar> createState() => _ParentAppbarState();

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}

class _ParentAppbarState extends State<ParentAppbar> {
  String? selectedStudent;
  String? selectedStudentId;
  List<Map<String, dynamic>> childrenList = [];

  late ParentDashboardProvider parentDashboardProvider;
  late HolidayProvider holidayProvider;
  late HomeworkProvider homeworkProvider;
  late SchoolCircularProvider schoolCircularProvider;

  @override
  void initState() {
    super.initState();

    parentDashboardProvider =
        Provider.of<ParentDashboardProvider>(context, listen: false);
    holidayProvider = Provider.of<HolidayProvider>(context, listen: false);
    homeworkProvider = Provider.of<HomeworkProvider>(context, listen: false);
    schoolCircularProvider =
        Provider.of<SchoolCircularProvider>(context, listen: false);

    _loadSelectedStudent();
  }

  void _onStudentChange(String? value) {
    setState(() {
      selectedStudent = value;
      selectedStudentId = childrenList
          .firstWhere(
            (child) => child['studentName'] == selectedStudent,
          )['studentId']
          .toString();

      // Save the selected student ID
      MySharedPreferences.instance.setStringValue(
        'studentId',
        selectedStudentId!,
      );

      // Log student change
      log("Student changed to: $selectedStudent (ID: $selectedStudentId)");

      // Call the callback function if provided
      if (widget.onStudentChanged != null) {
        widget.onStudentChanged!(selectedStudentId!);
      }

      // Refresh the dashboard data
      _refreshDashboardData();
    });
  }

  void _loadSelectedStudent() async {
    String? storedStudentId =
        await MySharedPreferences.instance.getStringValue('studentId');
    String? storedChildrenList =
        await MySharedPreferences.instance.getStringValue('childrenList');

    if (storedChildrenList != null) {
      try {
        childrenList =
            List<Map<String, dynamic>>.from(json.decode(storedChildrenList));
      } catch (e) {
        try {
          childrenList = List<Map<String, dynamic>>.from(
            eval(storedChildrenList) as List,
          );
        } catch (e) {
          log("Error parsing children list: $e");
          childrenList = [];
        }
      }
    }

    if (storedStudentId != null && childrenList.isNotEmpty) {
      setState(() {
        selectedStudentId = storedStudentId;
        final selectedChild = childrenList.firstWhere(
          (child) => child['studentId'].toString() == storedStudentId,
          orElse: () => childrenList.first,
        );
        selectedStudent = selectedChild['studentName'].toString();
      });
    } else if (childrenList.isNotEmpty) {
      setState(() {
        selectedStudent = childrenList.first['studentName'].toString();
        selectedStudentId = childrenList.first['studentId'].toString();
        MySharedPreferences.instance
            .setStringValue('studentId', selectedStudentId!);
      });
    }
  }

  // Helper function to evaluate Dart list literals
  dynamic eval(String source) {
    // Remove any leading/trailing whitespace
    source = source.trim();

    // Check if the string starts with '[' and ends with ']'
    if (source.startsWith('[') && source.endsWith(']')) {
      // Remove the outer brackets
      source = source.substring(1, source.length - 1);

      // Split the string by commas, but not within nested structures
      List<String> parts = [];
      int nestLevel = 0;
      StringBuffer currentPart = StringBuffer();

      for (int i = 0; i < source.length; i++) {
        if (source[i] == '{') nestLevel++;
        if (source[i] == '}') nestLevel--;

        if (source[i] == ',' && nestLevel == 0) {
          parts.add(currentPart.toString().trim());
          currentPart.clear();
        } else {
          currentPart.write(source[i]);
        }
      }

      if (currentPart.isNotEmpty) {
        parts.add(currentPart.toString().trim());
      }

      // Parse each part as a Map
      return parts.map((part) {
        // Remove the curly braces
        part = part.substring(1, part.length - 1);

        // Split by commas, but not within quotes
        List<String> keyValuePairs = [];
        int quoteCount = 0;
        StringBuffer currentPair = StringBuffer();

        for (int i = 0; i < part.length; i++) {
          if (part[i] == '"') quoteCount++;
          if (part[i] == ',' && quoteCount % 2 == 0) {
            keyValuePairs.add(currentPair.toString().trim());
            currentPair.clear();
          } else {
            currentPair.write(part[i]);
          }
        }

        if (currentPair.isNotEmpty) {
          keyValuePairs.add(currentPair.toString().trim());
        }

        // Create a Map from the key-value pairs
        return Map.fromEntries(keyValuePairs.map((pair) {
          List<String> kv = pair.split(':');
          return MapEntry(kv[0].trim(), kv[1].trim());
        }));
      }).toList();
    } else {
      throw const FormatException('Invalid list format');
    }
  }

  void _refreshDashboardData() {
    parentDashboardProvider.getStudentDetails();
    holidayProvider.getHoliday();
    homeworkProvider.getHomework();
    schoolCircularProvider.getSchoolCircular();
  }

  @override
  Widget build(BuildContext context) {
    return AppBar(
      backgroundColor: AppColors.bgColor,
      automaticallyImplyLeading: false,
      centerTitle: false,
      title: Row(
        children: [

          widget.isDash
              ? IconButton(
            onPressed: () => Scaffold.of(context).openDrawer(),
            icon: const Icon(
              Icons.menu,
              size: 30,
            ),
          )
              : IconButton(
            onPressed: () {
              Navigator.pop(context);
            },
            icon: Container(
              height: 35,
              width: 35,
              decoration: const BoxDecoration(
                color: AppColors.blue,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.home,
                color: Colors.white,
                size: 30,
              ),
            ),
          ),

          const SizedBox(width: 20,),

          widget.isDash
              ? SizedBox(
            width: MediaQuery.of(context).size.width / 2.5,
            child: DropdownButtonFormField<String>(
              value: selectedStudent,
              decoration: const InputDecoration(border: InputBorder.none),
              items: childrenList.map<DropdownMenuItem<String>>((child) {
                return DropdownMenuItem<String>(
                  value: child['studentName'].toString(),
                  child: Text(child['studentName'].toString()),
                );
              }).toList(),
              onChanged: _onStudentChange,
            ),
          )
              : Text(
            widget.title,
            style: boldBlack.copyWith(fontSize: 18),
          ),
        ],
      ),
      actions: [

      ],
    );
  }
}
