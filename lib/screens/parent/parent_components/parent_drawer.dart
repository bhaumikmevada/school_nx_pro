import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/provider/auth_provider.dart';
import 'package:school_nx_pro/screens/auth/login_screen.dart';
import 'package:school_nx_pro/screens/auth/select_institute_screen.dart';
import 'package:school_nx_pro/screens/auth/select_student_screen.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_attendance_screen.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_gallery_screen.dart';
import 'package:school_nx_pro/screens/common_screens/holidays_screen.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_old_receipts_screen.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_result_screen.dart';
import 'package:school_nx_pro/screens/common_screens/rules_regulation_screen.dart';
import 'package:school_nx_pro/screens/common_screens/school_circular_screen.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';
import 'package:school_nx_pro/utils/safe_logout.dart';
import '../screens/parent_homework_screen.dart';

class ParentDrawer extends StatefulWidget {
  final String studentId;
  final List<dynamic> children;

  const ParentDrawer({super.key, required this.studentId, required this.children});

  @override
  State<ParentDrawer> createState() => _ParentDrawerState();
}

class _ParentDrawerState extends State<ParentDrawer> {
  // Cache the matching child to avoid repeated lookups
  Map<String, dynamic>? _cachedMatchingChild;
  String? _cachedStudentId;
  int? _cachedChildrenLength;

  // Get matching child (cached for performance)
  Map<String, dynamic>? _getMatchingChild() {
    // Only recalculate if studentId or children list changed
    final childrenLength = widget.children.length;
    if (_cachedStudentId != widget.studentId || 
        _cachedMatchingChild == null ||
        _cachedChildrenLength != childrenLength) {
      try {
        _cachedMatchingChild = widget.children.firstWhere(
          (child) => child["studentId"]?.toString() == widget.studentId.toString(),
          orElse: () => <String, dynamic>{},
        );
        _cachedStudentId = widget.studentId;
        _cachedChildrenLength = childrenLength;
        
        // If empty map, set to null
        if (_cachedMatchingChild != null && _cachedMatchingChild!.isEmpty) {
          _cachedMatchingChild = null;
        }
      } catch (e) {
        _cachedMatchingChild = null;
      }
    }
    return _cachedMatchingChild;
  }

  @override
  Widget build(BuildContext context) {
    // Use cached values for instant rendering
    final matchingChild = _getMatchingChild();
    final studentName = matchingChild?["studentName"]?.toString() ?? "N/A";
    final financialYear = matchingChild?["yearOfAdmission"]?.toString() ?? "N/A";
    
    // Format date once
    final formattedDate = DateFormat('dd-MMM-yyyy').format(DateTime.now());

    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.zero,
      ),
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[

          SizedBox(
            height: MediaQuery.of(context).size.height / 4.5,
            child: DrawerHeader(
              decoration: const BoxDecoration(
                color: AppColors.blue,
              ),
              child: SingleChildScrollView(
                physics: const NeverScrollableScrollPhysics(),
                child: Column(
                  children: [
                    // School Name with Academic Year
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(studentName,
                          style: boldWhite,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          "[$financialYear]",
                          style: normalWhite,
                        ),
                      ],
                    ),
                    const SizedBox(height: 15),
                    // Today's Date
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Today's Date : ",
                          style:
                              normalWhite.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          formattedDate,
                          style: normalWhite,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    // Fin. Year
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          "Fin. Year : ",
                          style:
                              normalWhite.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 7),
                        Text(financialYear,
                          style: normalWhite,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),

          _buildListTile(
            context,
            icon: AppIcons.oldReceipt,
            title: "Old Receipts",
            page: ParentOldReceiptsScreen(
              studentId: widget.studentId,
              studentName: studentName,
              studentPhone: matchingChild?["phone"]?.toString() ?? "N/A",
              studentEmail: matchingChild?["email"]?.toString() ?? "N/A",
            ),
          ),
          _buildListTile(
            context,
            icon: AppIcons.attendance,
            title: "Attendance",
            page: AttendanceScreen(userType: UserType.parent, studentId: widget.studentId)
            // page: AttendanceScreen(),
            // page: const ParentAttendanceScreen(),
          ),
          _buildListTile(
            context,
            icon: AppIcons.schoolCircular,
            title: "Events",
            page: const EventScreen(userType: UserType.parent),
          ),
          _buildListTile(
            context,
            icon: AppIcons.holidays,
            title: "Holidays",
            page: const HolidaysScreen(userType: UserType.parent),
          ),
          _buildListTile(
            context,
            icon: AppIcons.gallery,
            title: "Gallery",
            page: const ParentGalleryScreen(),
          ),
          _buildListTile(
            context,
            icon: AppIcons.homeWork,
            title: "Home Work",
            page: ParentHomeworkScreen(userType: UserType.parent, studentId: widget.studentId),
            // page: const HomeworkScreen(userType: UserType.parent),
          ),
          _buildListTile(
            context,
            icon: AppIcons.result,
            title: "Result",
            page: const ParentResultScreen(),
          ),
          _buildListTile(
            context,
            icon: AppIcons.rules,
            title: "Rules & Regulations",
            page: const RulesRegulationScreen(),
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 25),
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
          const SizedBox(height: 30),
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
