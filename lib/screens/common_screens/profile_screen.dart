import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/app_button.dart';
import 'package:school_nx_pro/components/app_textfield.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({
    super.key,
    required this.userType,
    this.name = '',
    this.firstName = '',
    this.lastName = '',
    this.mobile = '',
    this.type = '',
  });

  final UserType userType;
  final String name;
  final String firstName;
  final String lastName;
  final String mobile;
  final String type;

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController nameController;
  late TextEditingController firstController;
  late TextEditingController lastController;
  late TextEditingController mobileController;
  late TextEditingController typeController;
  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    nameController = TextEditingController(text: widget.name);
    firstController = TextEditingController(text: widget.firstName);
    lastController = TextEditingController(text: widget.lastName);
    mobileController = TextEditingController(text: widget.mobile);
    typeController = TextEditingController(text: widget.type);
  }

  @override
  void dispose() {
    nameController.dispose();
    firstController.dispose();
    lastController.dispose();
    mobileController.dispose();
    typeController.dispose();
    super.dispose();
  }

  Future<void> _saveAndPop() async {
    // optional: validation
    // if (!formKey.currentState!.validate()) return;

    final updatedName = nameController.text.trim();
    final updatedFirst = firstController.text.trim();
    final updatedLast = lastController.text.trim();
    final updatedMobile = mobileController.text.trim();
    final updatedType = typeController.text.trim();

    // Example: save to SharedPreferences
    await MySharedPreferences.instance.setStringValue('parentName', updatedName);
    await MySharedPreferences.instance.setStringValue('firstName', updatedFirst);
    await MySharedPreferences.instance.setStringValue('lastName', updatedLast);
    await MySharedPreferences.instance.setStringValue('mobile', updatedMobile);
    await MySharedPreferences.instance.setStringValue('type', updatedType);

    // Return updated data to previous screen
    Navigator.pop(context, {
      'name': updatedName,
      'firstName': updatedFirst,
      'lastName': updatedLast,
      'mobile': updatedMobile,
      'type': updatedType,
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const ParentAppbar(title: "My Profile"),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 15),
          child: Form(
            key: formKey,
            child: Column(
              children: [
                AppTextField(controller: nameController, labelText: "User Name"),
                AppTextField(controller: firstController, labelText: "First Name"),
                AppTextField(controller: lastController, labelText: "Last Name"),
                AppTextField(controller: mobileController, labelText: "Mobile Number"),
                AppTextField(controller: typeController, labelText: "Type"),
                AppButton(
                  buttonText: "Update",
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  onTap: _saveAndPop,
                ),
              ].map((e) => Padding(padding: const EdgeInsets.only(top: 25), child: e)).toList(),
            ),
          ),
        ),
      ),
    );
  }
}
