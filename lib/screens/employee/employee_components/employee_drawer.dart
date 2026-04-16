import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/provider/auth_provider.dart';
import 'package:school_nx_pro/screens/auth/login_screen.dart';
import 'package:school_nx_pro/screens/auth/select_institute_screen.dart';
import 'package:school_nx_pro/screens/auth/select_student_screen.dart';
import 'package:school_nx_pro/screens/common_screens/homework_screen.dart';
import 'package:school_nx_pro/screens/common_screens/rules_regulation_screen.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_attendance_screen.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_event_screen.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_gallery_screen.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_holiday_screen.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/CustomText.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';
import 'package:school_nx_pro/utils/safe_logout.dart';

class EmployeeDrawer extends StatefulWidget {
  final List<dynamic> children;
  final List<String> institutes;
  const EmployeeDrawer({super.key, required this.institutes, required this.children});

  @override
  State<EmployeeDrawer> createState() => _EmployeeDrawerState();
}

class _EmployeeDrawerState extends State<EmployeeDrawer> {
  // Cache formatted date and institutes string to avoid recalculation
  String? _cachedInstitutesString;
  String? _cachedFormattedDate;
  DateTime? _lastDateUpdate;

  String _getInstitutesString() {
    if (_cachedInstitutesString == null) {
      _cachedInstitutesString = widget.institutes.join(", ");
    }
    return _cachedInstitutesString!;
  }

  String _getFormattedDate() {
    final now = DateTime.now();
    // Only recalculate if date changed (new day)
    if (_lastDateUpdate == null || 
        _lastDateUpdate!.day != now.day ||
        _lastDateUpdate!.month != now.month ||
        _lastDateUpdate!.year != now.year) {
      _cachedFormattedDate = DateFormat('dd-MMM-yyyy').format(now);
      _lastDateUpdate = now;
    }
    return _cachedFormattedDate!;
  }

  @override
  Widget build(BuildContext context) {
    // Use cached values for instant rendering
    final institutesString = _getInstitutesString();
    final formattedDate = _getFormattedDate();

    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          SizedBox(
            height: MediaQuery.of(context).size.height / 4.2,
            child: DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.blue,
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // School Name with Academic Year
                    CustomText.TextSemiBold(institutesString,color: AppColors.whiteColor,fontSize: 16.0),
                    const SizedBox(width: 7),
                    Container(
                      child: CustomText.TextMedium('[2023 - 2024]',color: AppColors.whiteColor),
                    ),
                    const SizedBox(height: 15),
                    // Today's Date
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Today’s Date : ",
                          style:
                              normalWhite.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: CustomText.TextMedium(formattedDate,color: AppColors.whiteColor,),
                        )
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Fin. Year
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        CustomText.TextMedium(
                          "Fin. Year : ",
                          color: Colors.white,
                            fontSize: 16.0
                        ),
                        const SizedBox(width: 7),
                        Expanded(
                          child: CustomText.TextMedium('Apr-2024 To Mar-2025',color: Colors.white,fontSize: 16.0),
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            height: MediaQuery.of(context).size.height / 1.4,
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  _buildListTile(
                    context,
                    icon: AppIcons.attendance,
                    title: "Attendance",
                    page: const EmployeeAttendanceScreen(),
                  ),
                  _buildListTile(
                    context,
                    icon: AppIcons.homeWork,
                    title: "Home Work",
                    page: HomeworkScreen(userType: UserType.employee),
                  ),
                  _buildListTile(
                    context,
                    icon: AppIcons.schoolCircular,
                    title: "Events",
                    page: const EmployeeEventScreen(userType: UserType.employee),
                  ),
                  _buildListTile(
                    context,
                    icon: AppIcons.holidays,
                    title: "Holidays",
                    page: const EmployeeHolidayScreen(userType: UserType.employee),
                  ),
                  _buildListTile(
                    context,
                    icon: AppIcons.gallery,
                    title: "Gallery",
                    page: const EmployeeGalleryScreen(),
                  ),
                  _buildListTile(
                    context,
                    icon: AppIcons.rules,
                    title: "Rules & Regulations",
                    page: const RulesRegulationScreen(),
                  ),
                  Column(
                    children: [
                      GestureDetector(
                        onTap: () {
                          SafeLogout.logout().then((value) {
                            Navigator.pushAndRemoveUntil(
                              context,
                              MaterialPageRoute(
                                builder: (context) => const LoginScreen(),
                              ),
                              (route) => false,
                            );
                          });
                        },
                        child: ListTile(
                          leading: SizedBox(
                            height: 30,
                            width: 30,
                            child: Image.asset(AppIcons.logout),
                          ),
                          title: Text(
                            "Log Out",
                            style: boldBlack.copyWith(fontSize: 18),
                          ),
                        ),
                      ),
                      Consumer<AuthProvider>(
                        builder: (context, authProvider, child) {
                          // Only show switch if user has both roles
                          if (!authProvider.hasParentRole || !authProvider.hasEmployeeRole) {
                            return const SizedBox.shrink();
                          }
              
                          final isParent = authProvider.userType.toLowerCase() == 'parent';
              
                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 15),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  "Employee",
                                  style: boldBlack.copyWith(fontSize: 18),
                                ),
                                Switch(
                                  activeColor: AppColors.blue,
                                  value: isParent,
                                  onChanged: (value) async {
                                    // value is true when switching to Parent, false when switching to Employee
                                    if (value) {
                                      // Switching to Parent role
                                      final success = await authProvider.switchRole('parent');
                                      if (success && context.mounted) {
                                        // Navigate to SelectStudentScreen
                                        final loginDataString = await MySharedPreferences.instance
                                            .getStringValue('loginRequestData');
                                        if (loginDataString != null) {
                                          try {
                                            final loginData = json.decode(loginDataString) as Map<String, dynamic>;
                                            // Get children from authProvider or SharedPreferences
                                            List<dynamic> children = authProvider.children.isNotEmpty
                                                ? authProvider.children
                                                : [];
                                            if (children.isEmpty) {
                                              final childrenString = await MySharedPreferences.instance
                                                  .getStringValue('childrenList');
                                              if (childrenString != null) {
                                                try {
                                                  children = json.decode(childrenString);
                                                } catch (e) {
                                                  children = [];
                                                }
                                              }
                                            }
                                            if (context.mounted) {
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => SelectStudentScreen(
                                                    children: children,
                                                    loginData: loginData,
                                                  ),
                                                ),
                                                (route) => false,
                                              );
                                            }
                                          } catch (e) {
                                            // Handle error
                                          }
                                        }
                                      }
                                    } else {
                                      // Switching to Employee role
                                      final success = await authProvider.switchRole('employee');
                                      if (success && context.mounted) {
                                        // Navigate to SelectInstituteScreen
                                        final loginDataString = await MySharedPreferences.instance
                                            .getStringValue('loginRequestData');
                                        if (loginDataString != null) {
                                          try {
                                            final loginData = json.decode(loginDataString) as Map<String, dynamic>;
                                            // Use instituteNames from authProvider directly
                                            final institutes = authProvider.instituteNames;
                                            // Get children from authProvider or SharedPreferences
                                            List<dynamic> children = authProvider.children.isNotEmpty
                                                ? authProvider.children
                                                : [];
                                            if (children.isEmpty) {
                                              final childrenString = await MySharedPreferences.instance
                                                  .getStringValue('childrenList');
                                              if (childrenString != null) {
                                                try {
                                                  children = json.decode(childrenString);
                                                } catch (e) {
                                                  children = [];
                                                }
                                              }
                                            }
                                            if (context.mounted) {
                                              Navigator.pushAndRemoveUntil(
                                                context,
                                                MaterialPageRoute(
                                                  builder: (context) => SelectInstituteScreen(
                                                    institutes: institutes,
                                                    children: children,
                                                    loginData: loginData,
                                                  ),
                                                ),
                                                (route) => false,
                                              );
                                            }
                                          } catch (e) {
                                            // Handle error
                                          }
                                        }
                                      }
                                    }
                                  },
                                ),
                                Text(
                                  "Parent",
                                  style: boldBlack.copyWith(fontSize: 18),
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(
    BuildContext context, {
    required String icon,
    required String title,
    required Widget page,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 15),
      child: Card(
        margin: const EdgeInsets.symmetric(vertical: 6),
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: const BorderSide(color: AppColors.blue),
        ),
        child: ListTile(
          leading: SizedBox(
            height: 30,
            width: 30,
            child: Image.asset(
              icon,
              cacheWidth: 30,
              cacheHeight: 30,
            ),
          ),
          title: Text(
            title,
            style: boldBlack.copyWith(fontSize: 18),
          ),
          contentPadding: const EdgeInsets.symmetric(horizontal: 15),
          onTap: () {
            Navigator.pop(context);
            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => page),
            );
          },
        ),
      ),
    );
  }
}
