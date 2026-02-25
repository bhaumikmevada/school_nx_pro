import 'package:flutter/material.dart';
import 'package:school_nx_pro/screens/auth/login_screen.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_gallery_screen.dart';
import 'package:school_nx_pro/screens/common_screens/holidays_screen.dart';
import 'package:school_nx_pro/screens/common_screens/rules_regulation_screen.dart';
import 'package:school_nx_pro/screens/common_screens/school_circular_screen.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/safe_logout.dart';

class AdminDrawer extends StatefulWidget {
  const AdminDrawer({super.key});

  @override
  State<AdminDrawer> createState() => _AdminDrawerState();
}

class _AdminDrawerState extends State<AdminDrawer> {
  @override
  Widget build(BuildContext context) {
    return Drawer(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(30),
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
                        Text(
                          "Demo School",
                          style: boldWhite,
                        ),
                        const SizedBox(width: 7),
                        Text(
                          "[2023 - 2024]",
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
                          "Today’s Date : ",
                          style:
                              normalWhite.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 7),
                        Text(
                          "19-Sep-2024",
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
                        Text(
                          "Apr-2024 To Mar-2025",
                          style: normalWhite,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          //khushi
          _buildListTile(
            context,
            icon: AppIcons.schoolCircular,
            title: "Events",
            page: const EventScreen(userType: UserType.admin),
          ),
          _buildListTile(
            context,
            icon: AppIcons.holidays,
            title: "Holidays",
            page: const HolidaysScreen(userType: UserType.admin),
          ),
          _buildListTile(
            context,
            icon: AppIcons.gallery,
            title: "Gallery",
            page: const ParentGalleryScreen(),
          ),
          _buildListTile(
            context,
            icon: AppIcons.rules,
            title: "Rules & Regulations",
            page: const RulesRegulationScreen(),
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 3),
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
