import 'dart:convert';
import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/provider/auth_provider.dart';
import 'package:school_nx_pro/screens/parent/screens/parent_dashboard.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/utils/CustomText.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

import '../../utils/CustomAppBar.dart';
import '../../utils/CustomButton.dart';
import '../../utils/StringUtils.dart';

class SelectStudentScreen extends StatefulWidget {
  final List<dynamic> children;
  final Map<String, dynamic> loginData;

  const SelectStudentScreen({
    super.key,
    required this.children,
    required this.loginData,
  });

  @override
  State<SelectStudentScreen> createState() => SelectStudentScreenState();
}

class SelectStudentScreenState extends State<SelectStudentScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedValue;          // studentName ya instituteName
  String? selectedId;             // studentId ya instituteId
  List<dynamic> displayList = []; // final list jo dropdown me dikhegi
  bool isShowingInstitutes = false; // true = institutes dikha rahe hain

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final auth = Provider.of<AuthProvider>(context, listen: false);

    // 1. Pehle children try karo
    if (widget.children.isNotEmpty) {
      displayList = List<dynamic>.from(widget.children);
      isShowingInstitutes = false;
    } else if (auth.children.isNotEmpty) {
      displayList = List<dynamic>.from(auth.children);
      isShowingInstitutes = false;
    } else {
      // SharedPreferences se children
      final savedChildren =
      await MySharedPreferences.instance.getStringValue('childrenList');
      if (savedChildren != null && savedChildren.isNotEmpty) {
        try {
          displayList = List<dynamic>.from(jsonDecode(savedChildren));
          auth.children = displayList;
          isShowingInstitutes = false;
        } catch (e) {
          log("Error decoding childrenList: $e");
        }
      }
    }


    if (displayList.isEmpty) {
      if (auth.instituteNames.isNotEmpty) {
        displayList = List<dynamic>.from(auth.institutes);
        isShowingInstitutes = true;
      } else {
        // SharedPreferences se institutesList (names only) + try to rebuild
        final savedInst =
        await MySharedPreferences.instance.getStringValue('institutesList');
        if (savedInst != null && savedInst.isNotEmpty) {
          try {
            final names = List<String>.from(jsonDecode(savedInst));
            displayList = names
                .map((name) => {'instituteName': name, 'instituteId': null})
                .toList();
            isShowingInstitutes = true;
          } catch (e) {
            log("Error decoding institutesList: $e");
          }
        }
      }
    }

    // Default selection
    if (displayList.isNotEmpty) {
      final first = displayList.first as Map<String, dynamic>;
      if (isShowingInstitutes) {
        selectedValue = first['instituteName']?.toString() ?? '';
        selectedId = first['instituteId']?.toString();
      } else {
        selectedValue = first['studentName']?.toString() ?? '';
        selectedId = first['studentId']?.toString();
      }
    }

    if (mounted) setState(() {});

    print("======== FINAL displayList =========");
    print(displayList);
    print("isShowingInstitutes: $isShowingInstitutes");
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CustomAppBar(
        appBar: AppBar(),
        title: "",
        isBackIcon: true,
        onBackPress: () => Navigator.of(context).pop(),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            children: [
              SizedBox(height: MediaQuery.of(context).size.height / 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(50.0),
                child: Image.asset(AppLogos.logo, height: 100),
              ),
              const SizedBox(height: 20),
              Center(
                child: Container(
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        CustomText.TextMedium(
                          isShowingInstitutes
                              ? "Select Institute"
                              : "Select Student",
                          fontSize: 20.0,
                        ),
                        const SizedBox(height: 20),

                        if (displayList.isEmpty)
                          const Padding(
                            padding: EdgeInsets.all(20),
                            child: Text("No data found"),
                          )
                        else
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.bgColor,
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: AppColors.colorDADADA.withOpacity(0.6),
                                width: 1.5,
                              ),
                            ),
                            child: DropdownButtonHideUnderline(
                              child: DropdownButton<String>(
                                isExpanded: true,
                                value: selectedValue,
                                style: TextStyle(color: AppColors.blackColor),
                                dropdownColor: AppColors.bgColor,
                                icon: Icon(Icons.arrow_drop_down,
                                    color: AppColors.blue),
                                items: displayList.map((item) {
                                  final name = isShowingInstitutes
                                      ? item['instituteName']?.toString()
                                      : item['studentName']?.toString();
                                  return DropdownMenuItem<String>(
                                    value: name,
                                    child: CustomText.TextRegular(
                                      name ?? '',
                                      color: AppColors.blackColor,
                                    ),
                                  );
                                }).toList(),
                                onChanged: (value) {
                                  setState(() {
                                    selectedValue = value;
                                    final selectedItem = displayList.firstWhere(
                                          (item) => isShowingInstitutes
                                          ? item['instituteName']?.toString() ==
                                          value
                                          : item['studentName']?.toString() ==
                                          value,
                                    );
                                    selectedId = isShowingInstitutes
                                        ? selectedItem['instituteId']
                                        ?.toString()
                                        : selectedItem['studentId']?.toString();
                                  });
                                },
                              ),
                            ),
                          ),

                        const SizedBox(height: 50),

                        SizedBox(
                          width: MediaQuery.of(context).size.width,
                          height: 50.0,
                          child: CustomButton(
                            text: login,
                            radius: 20,
                            callback: () async {
                              if (selectedId == null || selectedId!.isEmpty) {
                                // agar instituteId null hai (sirf name pada tha) to bhi allow karo
                                if (!isShowingInstitutes) {
                                  scaffoldMessage(
                                      message: "Please select a student");
                                  return;
                                }
                              }

                              if (isShowingInstitutes) {
                                // Institute select kiya
                                if (selectedId != null &&
                                    selectedId!.isNotEmpty) {
                                  await MySharedPreferences.instance
                                      .setStringValue(
                                      'instituteId', selectedId!);
                                }
                                // ParentDashboard pe jao (children empty ho sakte hain)
                                if (!mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParentDashboard(
                                      loginData: widget.loginData,
                                      children: const [], // empty
                                    ),
                                  ),
                                      (route) => false,
                                );
                              } else {
                                // Normal student select
                                await MySharedPreferences.instance
                                    .setStringValue(
                                    'studentId', selectedId!);

                                final child = displayList.firstWhere((c) =>
                                c['studentId']?.toString() == selectedId);

                                final instituteId =
                                child['instituteId']?.toString();
                                if (instituteId != null &&
                                    instituteId.isNotEmpty) {
                                  await MySharedPreferences.instance
                                      .setStringValue(
                                      'instituteId', instituteId);
                                }

                                if (!mounted) return;
                                Navigator.pushAndRemoveUntil(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => ParentDashboard(
                                      loginData: widget.loginData,
                                      children: displayList,
                                    ),
                                  ),
                                      (route) => false,
                                );
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