import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/utils/CustomText.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';
import '../../utils/CustomAppBar.dart';
import '../../utils/CustomButton.dart';
import '../../utils/StringUtils.dart';
import '../employee/screens/employee_dashboard.dart';
// Import your Employee Dashboard here
// import 'package:school_nx_pro/screens/employee/employee_dashboard.dart';

class SelectInstituteScreen extends StatefulWidget {
  final List<String> institutes;
  final List<dynamic> children;
  final Map<String, dynamic> loginData;

  const SelectInstituteScreen({
    super.key,
    required this.institutes,
    required this.children,
    required this.loginData,
  });

  @override
  State<SelectInstituteScreen> createState() => _SelectInstituteScreenState();
}

class _SelectInstituteScreenState extends State<SelectInstituteScreen> {
  String? selectedInstitute;

  @override
  void initState() {
    super.initState();
    if (widget.institutes.isNotEmpty) {
      selectedInstitute = widget.institutes.first;
    }
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
                borderRadius: BorderRadius.circular(50),
                child: Image.asset(AppLogos.logo, height: 100),
              ),
              const SizedBox(height: 20),
              CustomText.TextMedium("Select Institute", fontSize: 20.0),
              const SizedBox(height: 20),

              if (widget.institutes.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Text("No institutes found"),
                )
              else
                Container(
                  width: double.infinity,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
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
                      value: selectedInstitute,
                      dropdownColor: AppColors.bgColor,
                      icon: Icon(Icons.arrow_drop_down, color: AppColors.blue),
                      items: widget.institutes
                          .map((name) => DropdownMenuItem<String>(
                        value: name,
                        child: CustomText.TextRegular(
                          name,
                          color: AppColors.blackColor,
                        ),
                      ))
                          .toList(),
                      onChanged: (value) {
                        setState(() => selectedInstitute = value);
                      },
                    ),
                  ),
                ),

              const SizedBox(height: 50),

              SizedBox(
                width: double.infinity,
                height: 50,
                child: CustomButton(
                  text: login,
                  radius: 20,
                  callback: () async {
                    if (selectedInstitute == null ||
                        selectedInstitute!.isEmpty) {
                      scaffoldMessage(message: "Please select an institute");
                      return;
                    }

                    // Save selected institute name (you can also save ID if needed)
                    await MySharedPreferences.instance
                        .setStringValue('selectedInstitute', selectedInstitute!);

                    // TODO: Navigate to your Employee Dashboard
                    Example:
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(
                        builder: (_) => EmployeeDashboard(
                          institutes: widget.institutes,
                          loginData: widget.loginData,
                          children: widget.children,
                        ),
                      ),
                      (route) => false,
                    );

                    // scaffoldMessage(message: "Institute selected: $selectedInstitute");
                    // Replace above with real navigation
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}