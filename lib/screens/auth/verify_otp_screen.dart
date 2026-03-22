import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:school_nx_pro/components/app_button.dart';
import 'package:school_nx_pro/components/app_textfield.dart';
import 'package:school_nx_pro/provider/auth_provider.dart';
import 'package:school_nx_pro/screens/auth/change_pass_screen.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/CustomText.dart';
import 'package:school_nx_pro/utils/StringUtils.dart';

import '../../utils/CustomAppBar.dart';
import '../../utils/CustomButton.dart';
import '../../utils/CustomTextFormField.dart';
import '../../utils/ValidationUtils.dart';

class VerifyOtpScreen extends StatefulWidget {
  const VerifyOtpScreen({super.key});

  @override
  State<VerifyOtpScreen> createState() => VerifyOtpScreenState();
}

class VerifyOtpScreenState extends State<VerifyOtpScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController otpController = TextEditingController();

  late AuthProvider provider;

  // @override
  // void initState() {
  //   provider = Provider.of<AuthProvider>(context, listen: false);
  //   super.initState();
  // }

  @override
  void dispose() {
    otpController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CustomAppBar(appBar: AppBar(), title: verifyOTP,isBackIcon: true,),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
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
                  padding: const EdgeInsets.all(20),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: <Widget>[

                        CustomText.TextMedium(verifyOTP,fontSize: 22.0),
                        const SizedBox(height: 10,),
                        CustomText.TextRegular("Enter the OTP we sent to the Mobile Number!",
                            fontSize: 14.0,maxLine: 4,textAlign: TextAlign.center),

                        const SizedBox(height: 20),

                        CustomTextFormField(
                            controller: otpController,
                            hintText: validationOTP,
                            textInputType: TextInputType.number,
                            textInputAction: TextInputAction.done,
                            isSuffixIcon: false,
                            isPrefixIcon: false,
                            isDigit: true,
                            maxLength: 6,
                            radius: 10,
                            onChange: (value){

                            },
                            onTap: (){}
                        ),

                        SizedBox(
                          height: 40,
                        ),

                        SizedBox(
                          width:  MediaQuery.of(context).size.width,
                          height: 50.0,
                          child: CustomButton(
                            text: verifyOTP,
                            radius: 20,
                            fontSize: 18.0,
                            callback: (){

                              if(ValidationUtils.inputValidation(context, otpController, validationOTP)){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const ChangePassScreen(),
                                  ),
                                );
                              }

                            },
                          ),
                        ),
                        const SizedBox(height: 20),

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
