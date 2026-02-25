import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/app_button.dart';
import 'package:school_nx_pro/components/app_textfield.dart';
import 'package:school_nx_pro/provider/auth_provider.dart';
import 'package:school_nx_pro/screens/auth/verify_otp_screen.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/CustomAppBar.dart';
import 'package:school_nx_pro/utils/CustomText.dart';
import 'package:school_nx_pro/utils/StringUtils.dart';
import 'package:school_nx_pro/utils/ValidationUtils.dart';

import '../../utils/CustomButton.dart';
import '../../utils/CustomTextFormField.dart';

class SendMailScreen extends StatefulWidget {
  const SendMailScreen({super.key});

  @override
  State<SendMailScreen> createState() => SendMailScreenState();
}

class SendMailScreenState extends State<SendMailScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController mobileNoController = TextEditingController();

  late AuthProvider provider;

  // @override
  // void initState() {
  //   provider = Provider.of<AuthProvider>(context, listen: false);
  //   super.initState();
  // }

  @override
  void dispose() {
    mobileNoController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CustomAppBar(appBar: AppBar(), title: sendMail,isBackIcon: true,),
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
                        CustomText.TextRegular("Recover Password",fontSize: 20.0),
                        const SizedBox(height: 10,),
                        CustomText.TextRegular("Enter your mobileNo and instructions will be sent to your MobileNo!",
                            fontSize: 14.0,maxLine: 3,textAlign: TextAlign.center),

                        const SizedBox(height: 20),

                        CustomTextFormField(
                            controller: mobileNoController,
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

                        SizedBox(
                          height: 20,
                        ),

                        SizedBox(
                          width:  MediaQuery.of(context).size.width,
                          height: 50.0,
                          child: CustomButton(
                            text: sendMail,
                            radius: 20,
                            fontSize: 18.0,
                            callback: (){

                              if(ValidationUtils.mobileNoValidation(context, mobileNoController, validationMobile)){
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => const VerifyOtpScreen(),
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
