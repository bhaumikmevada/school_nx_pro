import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/components/app_button.dart';
import 'package:school_nx_pro/components/app_textfield.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/provider/auth_provider.dart';
import 'package:school_nx_pro/screens/auth/send_mail_screen.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/CustomTextFormField.dart';
import 'package:school_nx_pro/utils/StringUtils.dart';

import '../../utils/CustomButton.dart';
import '../../utils/ValidationUtils.dart';
import '../../utils/utils.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  bool _obscureText = true;
  TextEditingController mobileController = TextEditingController();
  TextEditingController passController = TextEditingController();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  late AuthProvider provider;

  @override
  void initState() {
    provider = Provider.of<AuthProvider>(context, listen: false);
    super.initState();
  }

  @override
  void dispose() {
    mobileController.dispose();
    passController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[
              SizedBox(height: MediaQuery.of(context).size.height / 8),
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
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(25),
                    boxShadow: [
                      // BoxShadow(
                      //   color: Colors.grey.withValues(alpha: 0.3),
                      //   spreadRadius: 3,
                      //   blurRadius: 5,
                      //   offset: const Offset(0, 3),
                      // ),
                    ],
                  ),
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[
                        const SizedBox(height: 20),

                        CustomTextFormField(
                            controller: mobileController,
                            hintText: mobileNo,
                            textInputType: TextInputType.phone,
                            textInputAction: TextInputAction.next,
                            isMobileNo: true,
                            isSuffixIcon: false,
                            isPrefixIcon: false,
                            radius: 10,
                            onChange: (value){

                            },
                            onTap: (){}
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                            controller: passController,
                            hintText: password,
                            textInputType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.done,
                            obscureText: true,
                            isSuffixIcon: true,
                            isPrefixIcon: false,
                            radius: 10,
                            onChange: (value){

                            },
                            onTap: (){}
                        ),
                        const SizedBox(height: 5),
                        Align(
                          alignment: Alignment.centerRight,
                          child: GestureDetector(
                            onTap: () {
                              Navigator.push(context,
                                MaterialPageRoute(
                                  builder: (context) => const SendMailScreen(),
                                ),
                              );
                            },
                            child: const Text("Forgot Password?",
                              style: TextStyle(color: AppColors.blue, decoration: TextDecoration.underline),
                            ),
                          ),
                        ),
                        const SizedBox(height: 30.0),
                        SizedBox(
                          width:  MediaQuery.of(context).size.width,
                          height: 50.0,
                          child: CustomButton(
                            text: login,
                            radius: 20,
                            callback: (){

                              if(ValidationUtils.mobileNoValidation(context, mobileController,validationMobile,) &&
                                  ValidationUtils.passwordValidation(context, passController, validationPassword)){

                                showDialog(
                                  context: context,
                                  builder: (context) => Center(
                                    child: Utils.showCircularProgress(),
                                  ),
                                );

                                provider.handleLogin(
                                  context,
                                  mobileController.text,
                                  passController.text,
                                );

                              }

                            },
                          ),
                        ),
                        const SizedBox(height: 35),
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
