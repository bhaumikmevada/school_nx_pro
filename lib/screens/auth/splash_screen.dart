import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/provider/auth_provider.dart';
import 'package:school_nx_pro/screens/admin/admin_screens/admin_dashboard.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_dashboard.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_dashboard.dart';
import 'package:school_nx_pro/screens/auth/login_screen.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

import '../../utils/ConstantUtils.dart';
import '../../utils/PreferenceUtils.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  late AuthProvider authProvider;

  @override
  void initState() {
    super.initState();
    PreferenceUtils.saveInt(PREF_DRAWER_INDEX,0);
    requestPermissions();
    authProvider = Provider.of<AuthProvider>(context, listen: false);
    Future.delayed(const Duration(seconds: 1)).then((value) => redirect());
  }

  Future<void> requestPermissions() async {
    // 🎤 Microphone
    if (await Permission.microphone.request().isDenied) {
      // Show user message
    }

    // 🎶 Media Library (iOS) / Storage (Android)
    if (await Permission.storage.request().isDenied) {
      // Show user message
    }

    // 📂 For Android 13+ audio files
    if (await Permission.audio.request().isDenied) {
      // Show user message
    }
  }

  Future<void> redirect() async {
    String? token = await MySharedPreferences.instance.getStringValue("token");
    String? userType = await MySharedPreferences.instance.getStringValue(
      "userType",
    );
    String? loginDataString =
        await MySharedPreferences.instance.getStringValue("loginRequestData");

    // 🔹 Retrieve the login request data from SharedPrefs
    Map<String, dynamic> loginRequestData = {};
    if (loginDataString != null) {
      try {
        loginRequestData = jsonDecode(loginDataString);
      } catch (e) {
        print("❌ JSON parse error for loginRequestData: $e");
      }
    }

    print("🪪 token: $token");
    print("🔑 userType from SharedPrefs: $userType");
    print("📤 loginRequestData from SharedPrefs: $loginRequestData");

    if (token == null) {
      if (!mounted) return;
      navigateToLogin();
      return;
    }

    if (userType == null) {
      print("⚠️ No userType stored. Navigating to login.");
      navigateToLogin();
      return;
    }

    authProvider.userType = userType;
    authProvider.loggedIn = true;

    print("✅ Final userType in redirect: ${authProvider.userType}");

    switch (userType.trim()) {
      case 'parent':
        navigateToParentDashboard(loginRequestData);
        break;
      case 'employee':
        navigateToEmployeeDashboard(loginRequestData);
        break;
      case 'admin':
        navigateToAdminDashboard();
        break;
      default:
        navigateToLogin();
    }
  }

  void navigateToLogin() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const LoginScreen()),
      (route) => false,
    );
  }

  void navigateToParentDashboard(Map<String, dynamic> loginRequestData) async {
    String? childrenString = await MySharedPreferences.instance.getStringValue(
      'childrenList',
    );

    List<dynamic> children = [];
    if (childrenString != null) {
      try {
        children = jsonDecode(childrenString);
      } catch (e) {
        print("❌ JSON parse error: $e");
        children = [];
      }
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) =>
            ParentDashboard(loginData: loginRequestData, children: children),
      ),
      (route) => false,
    );
  }

  void navigateToEmployeeDashboard(Map<String, dynamic> loginRequestData) async {
    String? institutesString = await MySharedPreferences.instance
        .getStringValue('institutesList');

    List<String> instituteNames = [];
    if (institutesString != null) {
      try {
        // JSON decode karine List<dynamic male, map to String
        List<dynamic> decoded = jsonDecode(institutesString);
        instituteNames = decoded.map((e) => e.toString()).toList();
      } catch (e) {
        print("❌ JSON parse error for institutes: $e");
        instituteNames = [];
      }
    }

    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) => EmployeeDashboard(
          institutes: instituteNames,
          loginData: loginRequestData,
          children: [],
        ),
      ),
      (route) => false,
    );
  }

  void navigateToAdminDashboard() {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (context) => const AdminDashboard()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: Center(child: ClipRRect(
        borderRadius: BorderRadius.circular(100.0),
        child: Image.asset(AppLogos.logo, height: 200),
      )),
    );
  }
}
