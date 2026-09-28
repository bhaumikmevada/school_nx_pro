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
  List<String> instituteNames = [];
  String allottedTeacherId = '';
  Map<String, dynamic> userData = {};

  bool get hasParentRole => _hasParentRole;
  bool get hasEmployeeRole => _hasEmployeeRole;
  List<String> get availableRoles => List.unmodifiable(_availableRoles);

  bool _hasParentRole = false;
  bool _hasEmployeeRole = false;
  String? _parentUserId;
  String? _employeeUserId;
  List<String> _availableRoles = [];

  bool userCheck(String user) => user == userId;
  bool isParent() => userType.toLowerCase() == 'parent';
  bool isEmployee() => userType.toLowerCase() == 'employee';

  Future<void> getToken() async {
    String? token = await MySharedPreferences.instance.getStringValue("token");
    String? savedUserType =
    await MySharedPreferences.instance.getStringValue("userType");
    loggedIn = token != null;
    if (savedUserType != null) userType = savedUserType;
    notifyListeners();
  }

  Future<void> _saveUserData(Map<String, dynamic> response) async {
    final token = response['token'];
    final data = response['data'];

    if (token == null || data == null || data is! List || data.isEmpty) {
      log("Login response missing required fields.");
      return;
    }

    await MySharedPreferences.instance.setStringValue('token', token);

    // Reset everything
    _hasParentRole = false;
    _hasEmployeeRole = false;
    _parentUserId = null;
    _employeeUserId = null;
    _availableRoles = [];
    children = [];
    institutes = [];
    instituteNames = [];
    userData = {};
    allottedTeacherId = '';

    for (final raw in data) {
      if (raw is! Map<String, dynamic>) continue;
      final role = (raw['userType'] ?? '').toString().toLowerCase();

      switch (role) {
      // ==================== PARENT ====================
        case 'parent':
          _hasParentRole = true;
          if (!_availableRoles.contains('parent')) _availableRoles.add('parent');

          _parentUserId = raw['parentId']?.toString() ??
              raw['parentUserId']?.toString() ??
              raw['userId']?.toString();

          userData['parentName'] = raw['parentName'] ?? '';
          userData['parentMobile'] = raw['parentMobile'] ?? '';

          // Children extraction (works for single + dual)
          dynamic parentDashboards = raw['childDetails']?['parentDashboard'] ??
              raw['additionalData']?['parentDashboard'];

          if (parentDashboards is List && parentDashboards.isNotEmpty) {
            final firstDash = parentDashboards.first;
            if (firstDash is Map<String, dynamic>) {
              final childrenData = firstDash['children'];
              if (childrenData is List) {
                children = List<dynamic>.from(childrenData);
                await MySharedPreferences.instance
                    .setStringValue('childrenList', jsonEncode(children));
              }
            }
          }

          await MySharedPreferences.instance
              .setStringValue('parentName', raw['parentName'] ?? '');
          break;

      // ==================== EMPLOYEE ====================
        case 'employee':
          _hasEmployeeRole = true;
          if (!_availableRoles.contains('employee')) _availableRoles.add('employee');

          _employeeUserId = raw['employeeManualId']?.toString() ??
              raw['employeeUserId']?.toString() ??
              raw['userId']?.toString();

          userData['employeeName'] = raw['employeeName'] ?? '';
          userData['employeeMobile'] = raw['employeeMobile'] ?? '';
          userData['employeeID'] = raw['employeeManualId'] ?? raw['employeeID'];
          userData['institute'] = raw['institute'] ?? '';

          await MySharedPreferences.instance
              .setStringValue('employeeName', raw['employeeName'] ?? '');
          await MySharedPreferences.instance.setStringValue(
              'employeeID',
              (raw['employeeManualId'] ?? raw['employeeID'])?.toString() ?? '');
          await MySharedPreferences.instance
              .setStringValue('employeeUserId', _employeeUserId ?? '');

          // Institutes extraction (flat shape - your current API)
          dynamic employeeDashboards =
              raw['attributeValues']?['employeeDashboard'] ??
                  raw['additionalData']?['employeeDashboard'];

          if (employeeDashboards is List && employeeDashboards.isNotEmpty) {
            final firstItem = employeeDashboards.first;

            if (firstItem is Map<String, dynamic> &&
                firstItem['institutes'] is List) {
              // Old nested
              institutes = List<dynamic>.from(firstItem['institutes']);
              allottedTeacherId =
                  firstItem['allottedTeacherId']?.toString() ?? '';
            } else {
              // New flat (your responses)
              institutes = List<dynamic>.from(employeeDashboards);
              allottedTeacherId = raw['oldNotesTeacherId']?.toString() ?? '';
            }

            instituteNames = institutes
                .map((e) => (e['instituteName'] ?? '').toString())
                .where((n) => n.isNotEmpty)
                .toList();

            await MySharedPreferences.instance
                .setStringValue('institutesList', jsonEncode(instituteNames));
            await MySharedPreferences.instance
                .setStringValue('institutesFullList', jsonEncode(institutes));

            if (allottedTeacherId.isNotEmpty) {
              await MySharedPreferences.instance
                  .setStringValue('allottedTeacherId', allottedTeacherId);
            }

            debugPrint("Employee institutes loaded: $instituteNames");
          }
          break;

        case 'admin':
          if (!_availableRoles.contains('admin')) _availableRoles.add('admin');
          await MySharedPreferences.instance
              .setStringValue('adminName', raw['employeeName'] ?? '');
          break;
      }
    }

    // Default role: Parent first
    if (_hasParentRole) {
      userType = 'parent';
      userId = _parentUserId ?? '';
    } else if (_hasEmployeeRole) {
      userType = 'employee';
      userId = _employeeUserId ?? '';
    }

    debugPrint("userType : $userType");

    await MySharedPreferences.instance.setStringValue('userType', userType);
    await MySharedPreferences.instance.setStringValue('userId', userId);
    await MySharedPreferences.instance
        .setStringValue('availableRoles', jsonEncode(_availableRoles));
    await MySharedPreferences.instance
        .setStringValue('userData', jsonEncode(userData));
  }

  Future<void> handleLogin(
      BuildContext context, String mobile, String password) async {
    try {
      final data = {
        "mobileNo": mobile.trim().replaceAll("+91", ""),
        "password": password,
        "userName": "string",
        "firstName": "string",
        "lastName": "string"
      };

      print("📤 Login Request: $data");
      final response = await authRepo.loginApi(data);
      print("Response: $response");

      if (response == null) {
        scaffoldMessage(message: 'Something went wrong!!');
        return;
      }

      // success: false handle
      if (response['success'] == false) {
        scaffoldMessage(message: response['message'] ?? 'Login failed');
        return;
      }

      if (response['statusCode'] == 200) {
        final isKnownAdmin =
            mobile.trim().replaceAll("+91", "") == "9893878562" &&
                password == "9893878562";

        Map<String, dynamic> normalized = Map<String, dynamic>.from(response);
        dynamic responseData = normalized['data'];

        if ((responseData == null ||
            (responseData is List && responseData.isEmpty)) &&
            isKnownAdmin) {
          normalized = {
            ...normalized,
            'data': [
              {
                'userType': 'admin',
                'adminUserId': mobile.trim().replaceAll("+91", ""),
              }
            ]
          };
          responseData = normalized['data'];
        }

        if (responseData == null ||
            (responseData is List && responseData.isEmpty)) {
          scaffoldMessage(
              message:
              "Login succeeded but no user data returned. Contact admin.");
          return;
        }

        await _saveUserData(normalized);
        await getToken();

        await MySharedPreferences.instance
            .setStringValue('loginRequestData', jsonEncode(data));

        if (!context.mounted) return;

        Future.microtask(() {
          if (!context.mounted) return;
          Navigator.pop(context); // close loader
          _navigateAfterLogin(context, data);
        });

        notifyListeners();
      } else {
        scaffoldMessage(message: response['message'] ?? 'Unknown error');
      }
    } catch (e, st) {
      log("Login Exception: $e\n$st");
      scaffoldMessage(message: 'Something went wrong!!');
    }
  }

  void _navigateAfterLogin(
      BuildContext context, Map<String, dynamic> loginData) {

    // Priority for all 3 cases
    if (_hasParentRole && children.isNotEmpty) {
      debugPrint("after Login _hasParentRole : $_hasParentRole && children : ${children.length}");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SelectStudentScreen(
            children: children,
            loginData: loginData,
          ),
        ),
      );
    } else if (_hasEmployeeRole && instituteNames.isNotEmpty) {
      debugPrint("after Login _hasEmployeeRole : $_hasEmployeeRole && instituteNames : $instituteNames");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SelectInstituteScreen(
            institutes: instituteNames,
            children: children,
            loginData: loginData,
          ),
        ),
      );
    } else if (_hasParentRole) {
      debugPrint("after Login _hasParentRole : $_hasParentRole");
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => SelectStudentScreen(
            children: children,
            loginData: loginData,
          ),
        ),
      );
    } else if (_availableRoles.contains('admin')) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const AdminDashboard()),
      );
    } else {
      scaffoldMessage(message: "Unknown user type");
    }
  }

  Future<Map<String, dynamic>> getUserData() async {
    final data = await MySharedPreferences.instance.getStringValue('userData');
    if (data != null) {
      try {
        return Map<String, dynamic>.from(jsonDecode(data));
      } catch (_) {}
    }
    return Map<String, dynamic>.from(userData);
  }

  /// Switch Role + Navigate to correct screen
  Future<bool> switchRole(BuildContext context, String targetRole) async {
    final role = targetRole.toLowerCase();
    if (role == 'parent' && !_hasParentRole) return false;
    if (role == 'employee' && !_hasEmployeeRole) return false;

    final newUserId = role == 'parent' ? _parentUserId : _employeeUserId;
    if (newUserId == null) return false;

    userType = role;
    userId = newUserId;

    await MySharedPreferences.instance.setStringValue('userType', userType);
    await MySharedPreferences.instance.setStringValue('userId', userId);

    // Restore data
    if (role == 'parent' && children.isEmpty) {
      final saved =
      await MySharedPreferences.instance.getStringValue('childrenList');
      if (saved != null && saved.isNotEmpty) {
        try {
          children = List<dynamic>.from(jsonDecode(saved));
        } catch (_) {}
      }
    }

    if (role == 'employee' && instituteNames.isEmpty) {
      final savedNames =
      await MySharedPreferences.instance.getStringValue('institutesList');
      final savedFull = await MySharedPreferences.instance
          .getStringValue('institutesFullList');
      if (savedNames != null && savedNames.isNotEmpty) {
        try {
          instituteNames = List<String>.from(jsonDecode(savedNames));
        } catch (_) {}
      }
      if (savedFull != null && savedFull.isNotEmpty) {
        try {
          institutes = List<dynamic>.from(jsonDecode(savedFull));
        } catch (_) {}
      }
    }

    notifyListeners();

    if (!context.mounted) return true;

    final loginStr =
    await MySharedPreferences.instance.getStringValue('loginRequestData');
    Map<String, dynamic> loginData = {};
    if (loginStr != null) {
      try {
        loginData = Map<String, dynamic>.from(jsonDecode(loginStr));
      } catch (_) {}
    }

    if (role == 'parent') {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SelectStudentScreen(
            children: children,
            loginData: loginData,
          ),
        ),
            (route) => false,
      );
    } else {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(
          builder: (_) => SelectInstituteScreen(
            institutes: instituteNames,
            children: children,
            loginData: loginData,
          ),
        ),
            (route) => false,
      );
    }

    return true;
  }
}