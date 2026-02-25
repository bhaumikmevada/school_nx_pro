import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/provider/auth_provider.dart';
import 'package:school_nx_pro/provider/employee_attendance_provider.dart';
import 'package:school_nx_pro/provider/holiday_provider.dart';
import 'package:school_nx_pro/provider/homework_provider.dart';
import 'package:school_nx_pro/provider/parent_homework_provider.dart';
import 'package:school_nx_pro/provider/old_receipts_provider.dart';
import 'package:school_nx_pro/provider/parent_dashboard_provider.dart';
import 'package:school_nx_pro/provider/result_provider.dart';
import 'package:school_nx_pro/provider/school_circular_provider.dart';
import 'package:school_nx_pro/screens/auth/splash_screen.dart';
import 'package:school_nx_pro/screens/common_screens/holidays_screen.dart';
import 'package:school_nx_pro/utils/PreferenceUtils.dart';

Future<void> main() async {
  // ✅ Ignore bad SSL certs ONLY in debug mode
  // if (kDebugMode) {
  WidgetsFlutterBinding.ensureInitialized();
  HttpOverrides.global = MyHttpOverrides();
  // }
  await PreferenceUtils.getInstance();
  runApp(const MyApp());
}

class MyHttpOverrides extends HttpOverrides {
  @override
  HttpClient createHttpClient(SecurityContext? context) {
    return super.createHttpClient(context)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) => true;
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => AuthProvider()),
        ChangeNotifierProvider(create: (context) => SchoolCircularProvider()),
        ChangeNotifierProvider(create: (context) => HolidayProvider()),
        ChangeNotifierProvider(create: (context) => HolidayProviders()),
        ChangeNotifierProvider(create: (context) => HomeworkProviders()),
        ChangeNotifierProvider(create: (context) => OldReceiptsProvider()),
        ChangeNotifierProvider(create: (context) => HomeworkProvider()),
        ChangeNotifierProvider(create: (context) => ResultProvider()),
        ChangeNotifierProvider(create: (context) => ParentDashboardProvider()),
        ChangeNotifierProvider(create: (context) => EmployeeAttendanceProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        home: SplashScreen(),
      ),
    );
  }
}
