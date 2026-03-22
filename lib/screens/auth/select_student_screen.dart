import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/components/app_button.dart';
import 'package:school_nx_pro/components/app_dropdown.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/provider/auth_provider.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_dashboard.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/CustomText.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

import '../../utils/CustomAppBar.dart';
import '../../utils/CustomButton.dart';
import '../../utils/StringUtils.dart';

class SelectStudentScreen extends StatefulWidget {
  final List<dynamic> children;
  final Map<String, dynamic> loginData;

  const SelectStudentScreen({super.key, required this.children, required this.loginData});

  @override
  State<SelectStudentScreen> createState() => SelectStudentScreenState();
}

class SelectStudentScreenState extends State<SelectStudentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedStudent = '';
  String? selectedStudentId;

  late AuthProvider provider;

  @override
  void initState() {
    super.initState();
    final provider = Provider.of<AuthProvider>(context, listen: false);
    if (provider.children.isNotEmpty) {
      final first = provider.children.first as Map<String, dynamic>;
      selectedStudent = first['studentName']?.toString() ?? '';
      selectedStudentId = first['studentId']?.toString();
    }

    print("---------${widget.children}");
    print("Login Data :- ${widget.loginData}");
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    provider = Provider.of<AuthProvider>(context, listen: false);

    if (provider.children.isNotEmpty && selectedStudent != null && selectedStudentId == null) {
      final first = provider.children.first as Map<String, dynamic>;
      selectedStudent = first['studentName']?.toString() ?? '';
      selectedStudentId = first['studentId']?.toString();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CustomAppBar(appBar: AppBar(), title: "",isBackIcon: true,
      onBackPress: (){
        Navigator.of(context).pop();
      },
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height / 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(50.0),
                child: Image.asset(
                  AppLogos.logo,
                  height: 100,
                ),
              ),
              SizedBox(height: 20),
              Center(
                child: Container(

                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        CustomText.TextMedium(
                          "Select Student",
                          fontSize: 20.0
                        ),
                        const SizedBox(height: 20),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.bgColor,       // background color of the button
                            borderRadius: BorderRadius.circular(16), // ← rounded corners (adjust as needed)
                            border: Border.all(
                              color: AppColors.colorDADADA.withOpacity(0.6), // border color – customize
                              width: 1.5,
                            ),

                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,               // ← makes it take full available width
                              value: selectedStudent,
                              style: TextStyle(color: AppColors.blackColor), // text color of selected item
                              dropdownColor: AppColors.bgColor, // menu background
                              icon: Icon(Icons.arrow_drop_down, color: AppColors.blue),
                              items: widget.children
                                  .map((child) => DropdownMenuItem<String>(
                                value: child['studentName'].toString(),
                                child: CustomText.TextRegular(
                                  child['studentName'].toString(),
                                  color: AppColors.blackColor,
                                ),
                              ))
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  selectedStudent = value;
                                  selectedStudentId = widget.children
                                      .firstWhere((child) => child['studentName'] == value)['studentId']
                                      .toString();
                                });
                              },
                            ),
                          ),
                        ),

                        SizedBox(
                          height: 50,
                        ),

                        SizedBox(
                          width:  MediaQuery.of(context).size.width,
                          height: 50.0,
                          child: CustomButton(
                            text: login,
                            radius: 20,
                            callback: () async {

                              if (selectedStudent == null ||
                                  selectedStudentId == null ||
                                  selectedStudentId!.isEmpty) {
                                scaffoldMessage(
                                    message: "Please select a student");
                                return;
                              }
                              try {
                                // Save to SharedPreferences BEFORE navigation so
                                // HomeworkScreen and other screens get studentId
                                // from server after reinstall
                                await MySharedPreferences.instance
                                    .setStringValue(
                                    'studentId', selectedStudentId!);
                                final child = widget.children.firstWhere(
                                        (c) =>
                                    c['studentId']?.toString() ==
                                        selectedStudentId) as Map<String, dynamic>;
                                final instituteId =
                                child['instituteId']?.toString();
                                if (instituteId != null &&
                                    instituteId.isNotEmpty) {
                                  await MySharedPreferences.instance
                                      .setStringValue(
                                      'instituteId', instituteId);
                                }
                                log("Selected Student ID: $selectedStudentId");
                                if (!mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParentDashboard(
                                      loginData: widget.loginData,
                                      children: widget.children,
                                    ),
                                  ),
                                      (route) => false,
                                );
                              } catch (e) {
                                scaffoldMessage(
                                    message: "Please select a student");
                              }

                            },
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
