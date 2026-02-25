import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/components/app_button.dart';
import 'package:school_nx_pro/components/app_dropdown.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/provider/auth_provider.dart';
import 'package:school_nx_pro/screens/employee/screens/employee_dashboard.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

class SelectInstituteScreen extends StatefulWidget {
  final List<String> institutes;
  final List<dynamic> children;
  final Map<String, dynamic> loginData;

  const SelectInstituteScreen({super.key, required this.institutes, required this.children, required this.loginData});

  @override
  State<SelectInstituteScreen> createState() => SelectInstituteScreenState();
}

class SelectInstituteScreenState extends State<SelectInstituteScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedInstitute = '';
  String? selectedInstituteId;
  String? createdByInstituteUserId;
  String? allottedTeacherId;

  late AuthProvider provider;

  @override
  void initState() {
    super.initState();
    provider = Provider.of<AuthProvider>(context, listen: false);
    if (provider.institutes.isNotEmpty) {
      selectedInstitute = provider.institutes.first['instituteName'].toString();
    }

    print("------------------${widget.institutes}, ${widget.children}");
    print("Login Data :- ${widget.loginData}");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    provider = Provider.of<AuthProvider>(context, listen: false);

    if (provider.institutes.isNotEmpty && selectedInstitute == null) {
      selectedInstitute = provider.institutes.first['instituteName'].toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height / 8),
              Image.asset(
                AppLogos.logo,
                height: 130,
              ),
              SizedBox(height: MediaQuery.of(context).size.height / 8),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.grey.withValues(alpha: 0.3),
                        spreadRadius: 3,
                        blurRadius: 5,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        Text(
                          "Select Institute",
                          style: normalBlack.copyWith(
                            fontSize: 28,
                          ),
                        ),
                        const SizedBox(height: 20),
                        AppDropDown(
                          labelText: "Institute",
                          value: selectedInstitute,
                          items: provider.institutes
                              .map<String>(
                                  (child) => child['instituteName'].toString())
                              .toList(),
                          onChanged: (value) {
                            setState(() {
                              selectedInstitute = value;
                            });
                          },
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.height / 6.7,
                        ),
                        AppButton(
                          buttonText: "Log in",
                          style: boldWhite,
                          onTap: () async {
                            if (selectedInstitute == null ||
                                selectedInstitute!.isEmpty) {
                              scaffoldMessage(
                                  message: "Please select an institute");
                              return;
                            }
                            try {
                              final institute = provider.institutes.firstWhere(
                                  (i) =>
                                      i['instituteName']?.toString() ==
                                      selectedInstitute);
                              final instId =
                                  institute['instituteId']?.toString() ?? '';
                              final createdBy = institute['createdByInstituteUserId']
                                      ?.toString() ??
                                  '';
                              if (instId.isEmpty) {
                                scaffoldMessage(
                                    message: "Invalid institute data");
                                return;
                              }
                              // Save to SharedPreferences BEFORE navigation so
                              // EmployeeHolidayScreen and other screens get
                              // instituteId after reinstall
                              await MySharedPreferences.instance
                                  .setStringValue('instituteId', instId);
                              if (createdBy.isNotEmpty) {
                                await MySharedPreferences.instance
                                    .setStringValue(
                                        'createdByInstituteUserId', createdBy);
                              }
                              log("Selected Institute ID: $instId");
                              if (!mounted) return;
                              Navigator.pushAndRemoveUntil(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => EmployeeDashboard(
                                    institutes: widget.institutes,
                                    loginData: widget.loginData,
                                    children: widget.children,
                                  ),
                                ),
                                (route) => false,
                              );
                            } catch (e) {
                              scaffoldMessage(
                                  message: "Please select an institute");
                            }
                          },
                        ),
                        const SizedBox(height: 20),
                        GestureDetector(
                          onTap: () {
                            Navigator.pop(context);
                          },
                          child: const Text(
                            "Go Back",
                            style: TextStyle(
                              color: AppColors.blue,
                              decoration: TextDecoration.underline,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
