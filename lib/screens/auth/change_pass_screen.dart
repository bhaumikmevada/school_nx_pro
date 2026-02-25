import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/app_button.dart';
import 'package:school_nx_pro/components/app_textfield.dart';
import 'package:school_nx_pro/provider/auth_provider.dart';
import 'package:school_nx_pro/theme/app_assets.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/CustomText.dart';
import 'package:school_nx_pro/utils/StringUtils.dart';

import '../../utils/CustomAppBar.dart';
import '../../utils/CustomButton.dart';
import '../../utils/CustomTextFormField.dart';
import '../../utils/ValidationUtils.dart';
import '../../utils/utils.dart';

class ChangePassScreen extends StatefulWidget {
  const ChangePassScreen({super.key});

  @override
  State<ChangePassScreen> createState() => ChangePassScreenState();
}

class ChangePassScreenState extends State<ChangePassScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  TextEditingController oldPassController = TextEditingController();
  TextEditingController newPassController = TextEditingController();

  late AuthProvider provider;

  // @override
  // void initState() {
  //   provider = Provider.of<AuthProvider>(context, listen: false);
  //   super.initState();
  // }

  @override
  void dispose() {
    oldPassController.dispose();
    newPassController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.whiteColor,
      appBar: CustomAppBar(appBar: AppBar(), title: changePassword,isBackIcon: true,),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 32,
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: <Widget>[

              SizedBox(height: 20.0),
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

                        CustomText.TextMedium(changePassword,fontSize: 18.0),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                            controller: oldPassController,
                            hintText: password,
                            textInputType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.next,
                            obscureText: true,
                            isSuffixIcon: true,
                            isPrefixIcon: false,
                            radius: 10,
                            onChange: (value){

                            },
                            onTap: (){}
                        ),
                        const SizedBox(height: 20),
                        CustomTextFormField(
                            controller: newPassController,
                            hintText: newPassword,
                            textInputType: TextInputType.visiblePassword,
                            textInputAction: TextInputAction.next,
                            obscureText: true,
                            isSuffixIcon: true,
                            isPrefixIcon: false,
                            radius: 10,
                            onChange: (value){

                            },
                            onTap: (){}
                        ),

                        SizedBox(
                          height:  15,
                        ),
                        SizedBox(
                          width:  MediaQuery.of(context).size.width,
                          height: 50.0,
                          child: CustomButton(
                            text: "Reset",
                            radius: 20,
                            callback: (){

                              if(ValidationUtils.passwordValidation(context, oldPassController,validationPassword,) &&
                                  ValidationUtils.passwordValidation(context, newPassController, validationNewPassword)){

                                showDialog(
                                  context: context,
                                  builder: (context) => Center(
                                    child: Utils.showCircularProgress(),
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
