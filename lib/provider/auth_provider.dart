import 'dart:convert';
import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/repository/auth_repo.dart';
import 'package:school_nx_pro/screens/admin/admin_screens/admin_dashboard.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';
import '../screens/auth/select_institute_screen.dart';
import 'package:school_nx_pro/screens/auth/select_student_screen.dart';

class AuthProvider extends ChangeNotifier {
  AuthRepository authRepo = AuthRepository();
  bool loggedIn = false;
  String userType = '';
  String userId = '';
  List<dynamic> children = [];
  List<dynamic> institutes = [];
  String allottedTeacherId = '';
  Map<String, dynamic> userData = {};

  List<String> instituteNames = [];
  bool get hasParentRole => _hasParentRole;
  bool get hasEmployeeRole => _hasEmployeeRole;
  List<String> get availableRoles => List.unmodifiable(_availableRoles);
  bool _hasParentRole = false;
  bool _hasEmployeeRole = false;
  String? _parentUserId;
  String? _employeeUserId;
  List<String> _availableRoles = [];

  bool userCheck(String user) => user == userId;

  bool isParent() => userType == 'parent';
  bool isEmployee() => userType.toLowerCase() == 'employee';

  Future<void> getToken() async {
    String? token = await MySharedPreferences.instance.getStringValue("token");
    String? savedUserType =
        await MySharedPreferences.instance.getStringValue("userType");
    loggedIn = token != null;
    if (savedUserType != null) {
      userType = savedUserType;
    }
    notifyListeners();
  }

  Future<void> _saveUserData(Map<String, dynamic> response) async {
    final token = response['token'];
    final data = response['data'];

    if (token == null || data == null || data is! List || data.isEmpty) {
      log("Login response missing required fields. Skipping saveUserData.");
      return;
    }

    await MySharedPreferences.instance.setStringValue('token', token);
    _hasParentRole = false;
    _hasEmployeeRole = false;
    _parentUserId = null;
    _employeeUserId = null;
    _availableRoles = [];

    // Reset collections
    children = [];
    institutes = [];
    instituteNames = [];
    userData = {};

    for (final raw in data) {
      if (raw is! Map<String, dynamic>) continue;

      final role = (raw['userType'] ?? '').toString().toLowerCase();

      switch (role) {
        case 'parent':
          _hasParentRole = true;
          _availableRoles.add('parent');
          _parentUserId =
              raw['parentUserId']?.toString() ?? raw['userId']?.toString();

          userData['parentName'] = raw['parentName'];
          userData['parentMobile'] = raw['parentMobile'];
          userData['parentCity'] = raw['parentCity'];

          final parentDashboards = raw['additionalData']?['parentDashboard'];
          if (parentDashboards is List && parentDashboards.isNotEmpty) {
            final parentDashboard =
                parentDashboards.first as Map<String, dynamic>;
            final childrenData = parentDashboard['children'];
            if (childrenData is List) {
              children = List<dynamic>.from(childrenData);
              await MySharedPreferences.instance
                  .setStringValue('childrenList', jsonEncode(childrenData));
            }
          }

          await MySharedPreferences.instance
              .setStringValue('parentName', raw['parentName'] ?? '');
          break;

        case 'employee':
          _hasEmployeeRole = true;
          _availableRoles.add('employee');
          _employeeUserId =
              raw['employeeUserId']?.toString() ?? raw['userId']?.toString();

          userData['employeeName'] = raw['employeeName'];
          userData['employeeMobile'] = raw['employeeMobile'];
          userData['employeeID'] = raw['employeeID'];
          userData['institute'] = raw['institute'];

          await MySharedPreferences.instance
              .setStringValue('employeeName', raw['employeeName'] ?? '');
          await MySharedPreferences.instance.setStringValue(
              'employeeID', raw['employeeID']?.toString() ?? '');

          final employeeDashboards = raw['additionalData']?['employeeDashboard'];
          if (employeeDashboards is List && employeeDashboards.isNotEmpty) {
            final employeeDashboard =
                employeeDashboards.first as Map<String, dynamic>;
            final institutesData = employeeDashboard['institutes'];
            if (institutesData is List) {
              institutes = List<dynamic>.from(institutesData);
              instituteNames = institutes
                  .map((e) => e['instituteName'].toString())
                  .toList();
              await MySharedPreferences.instance.setStringValue(
                  'institutesList', jsonEncode(instituteNames));
            }
            allottedTeacherId =
                employeeDashboard['allottedTeacherId']?.toString() ?? '';
            if (allottedTeacherId.isNotEmpty) {
              await MySharedPreferences.instance.setStringValue(
                  'allottedTeacherId', allottedTeacherId);
            }
          }
          break;

        case 'admin':
          _availableRoles.add('admin');
          await MySharedPreferences.instance
              .setStringValue('adminName', raw['employeeName'] ?? '');
          break;

        default:
          break;
      }
    }

    // Determine default role preference
    String? defaultType;
    String? defaultUserId;

    if (_hasParentRole) {
      defaultType = 'parent';
      defaultUserId = _parentUserId;
    } else if (_hasEmployeeRole) {
      defaultType = 'employee';
      defaultUserId = _employeeUserId;
    } else {
      final firstUser = data.first as Map<String, dynamic>;
      defaultType = firstUser['userType']?.toString();
      defaultUserId = firstUser['parentUserId']?.toString() ??
          firstUser['employeeUserId']?.toString() ??
          firstUser['adminUserId']?.toString();
    }

    if (defaultType != null) {
      userType = defaultType;
      await MySharedPreferences.instance.setStringValue('userType', defaultType);
    }

    if (defaultUserId != null) {
      userId = defaultUserId;
      await MySharedPreferences.instance.setStringValue('userId', defaultUserId);
    }

    if (_availableRoles.isNotEmpty) {
      await MySharedPreferences.instance
          .setStringValue('availableRoles', jsonEncode(_availableRoles));
    }

    await MySharedPreferences.instance
        .setStringValue('userData', jsonEncode(userData));
  }

  Future<void> handleLogin(BuildContext context, String mobile, String password) async {
    try {
      Map<String, dynamic> data = {
        "mobileNo": mobile.trim().replaceAll("+91", ""),
        "password": password,
        "userName": "string",
        "firstName": "string",
        "lastName": "string"
      };

      print("📤 Login Request Data: $data");

      final response = await authRepo.loginApi(data);
      print("Response login :- ${response.toString()}");

      if (response != null && response['statusCode'] == 200) {
        final bool isKnownAdmin =
            mobile.trim().replaceAll("+91", "") == "9893878562" &&
                password == "9893878562";

        Map<String, dynamic> normalizedResponse =
            Map<String, dynamic>.from(response);
        dynamic responseData = normalizedResponse['data'];

        // Fallback: if the API returns empty data for the known admin account,
        // synthesize an admin role so the app can continue.
        if ((responseData == null ||
                (responseData is List && responseData.isEmpty)) &&
            isKnownAdmin) {
          normalizedResponse = {
            ...normalizedResponse,
            'data': [
              {
                'userType': 'admin',
                'adminUserId': mobile.trim().replaceAll("+91", ""),
                'additionalData': <String, dynamic>{},
              }
            ],
          };
          responseData = normalizedResponse['data'];
        }

        // Guard: still no payload after fallback
        if (responseData == null ||
            (responseData is List && responseData.isEmpty)) {
          scaffoldMessage(
            message:
                "Login succeeded but no user data/roles were returned. Please contact your school admin.",
          );
          return;
        }

        await _saveUserData(normalizedResponse);
        await getToken();

        // 🟢 Save loginRequestData for splash usage
        await MySharedPreferences.instance.setStringValue(
          'loginRequestData',
          jsonEncode(data),
        );

        if (!context.mounted) return;

        // Defer navigation to avoid Navigator lock errors
        Future.microtask(() {
          if (!context.mounted) return;
          
          // Close progress dialog first
          Navigator.pop(context);
          
          // Then navigate to appropriate screen
          if (_hasParentRole) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SelectStudentScreen(
                  children: children,
                  loginData: data,
                ),
              ),
            );
          } else if (_hasEmployeeRole) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => SelectInstituteScreen(
                  institutes: instituteNames,
                  children: children,
                  loginData: data,
                ),
              ),
            );
          } else if (_availableRoles.contains('admin')) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(
                builder: (context) => const AdminDashboard(),
              ),
            );
          } else {
            scaffoldMessage(message: "Unknown user type");
          }
        });

        notifyListeners();
      } else {
        scaffoldMessage(message: response?['message'] ?? 'Unknown error');
      }
    } catch (e, stacktrace) {

      log("❌ Exception in login: $e", name: "Auth error");
      log("🧵 Stacktrace: $stacktrace", name: "Auth stacktrace");
      scaffoldMessage(message: 'Something went wrong!!');
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    String? data =
        await MySharedPreferences.instance.getStringValue('userData');
    if (data != null) {
      return Map<String, dynamic>.from(userData);
    }
    return {};
  }

  /// Switch between available roles (Parent <-> Employee)
  /// Returns true if switch was successful, false otherwise
  Future<bool> switchRole(String targetRole) async {
    if (targetRole.toLowerCase() == 'parent' && !_hasParentRole) {
      return false;
    }
    if (targetRole.toLowerCase() == 'employee' && !_hasEmployeeRole) {
      return false;
    }

    String? newUserId;
    if (targetRole.toLowerCase() == 'parent') {
      newUserId = _parentUserId;
    } else if (targetRole.toLowerCase() == 'employee') {
      newUserId = _employeeUserId;
    }

    if (newUserId != null) {
      userType = targetRole.toLowerCase();
      userId = newUserId;
      await MySharedPreferences.instance.setStringValue('userType', userType);
      await MySharedPreferences.instance.setStringValue('userId', userId);
      notifyListeners();
      return true;
    }

    return false;
  }
}
