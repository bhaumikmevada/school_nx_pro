import 'package:flutter/material.dart';
import 'package:school_nx_pro/screens/admin/admin_components/admin_appbar.dart';
import 'package:school_nx_pro/screens/admin/admin_components/admin_drawer.dart';
import 'package:school_nx_pro/screens/common_screens/profile_screen.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

class AdminDashboard extends StatefulWidget {
  const AdminDashboard({super.key});

  @override
  State<AdminDashboard> createState() => _AdminDashboardState();
}

class _AdminDashboardState extends State<AdminDashboard> {
  String? adminName;

  @override
  void initState() {
    super.initState();
    initPref();
  }

  Future<void> initPref() async {
    String? adminNameNew = await MySharedPreferences.instance.getStringValue('adminName');
    setState(() {
      adminName = adminNameNew;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const AdminAppbar(isDash: true),
      drawerEnableOpenDragGesture: false,
      drawer: const AdminDrawer(),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const ProfileScreen(
                        userType: UserType.admin,
                      ),
                    ),
                  );
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
                    Text(
                      adminName ?? "N/A",
                      style: boldBlack.copyWith(fontSize: 23),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              height: MediaQuery.of(context).size.height / 4.3,
              width: double.maxFinite,
              decoration: const BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.only(bottom: 25),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    _buildAttendanceState(
                      icon: AppIcons.group,
                      value: "301",
                      label: "Total Students",
                    ),
                    _buildAttendanceState(
                      icon: AppIcons.profileIcon,
                      value: "25",
                      label: "Total Employee",
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
                padding: const EdgeInsets.only(top: 30),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _dashboardState(
                          icon: AppIcons.manCheck,
                          value: "57",
                          label: "Student Absent",
                        ),
                        _dashboardState(
                          icon: AppIcons.manCross,
                          value: "248",
                          label: "Student Present",
                        ),
                      ],
                    ),
                    const SizedBox(height: 30),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        _dashboardState(
                          icon: AppIcons.manCheck,
                          value: "3",
                          label: "Employee Absent",
                        ),
                        _dashboardState(
                          icon: AppIcons.manCross,
                          value: "22",
                          label: "Employee Present",
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Widget _buildAttendanceState({
    required String icon,
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
          crossAxisAlignment: CrossAxisAlignment.center,
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
    );
  }

  Widget _dashboardState({
    required String icon,
    required String value,
    required String label,
  }) {
    return Container(
      height: 150,
      width: 150,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: AppColors.blue),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Container(
              width: double.infinity,
              decoration: BoxDecoration(
                color: AppColors.blue,
                borderRadius: BorderRadius.circular(25),
                border: Border.all(color: AppColors.blue),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: Image.asset(
                  icon,
                  color: Colors.white,
                  height: 30,
                  width: 30,
                ),
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                children: [
                  Text(
                    value,
                    style: boldBlack,
                  ),
                  Text(
                    label,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
