import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../theme/app_colors.dart';
import 'CustomText.dart';

class CustomButton extends StatelessWidget {


  VoidCallback callback;
  String text;
  Color? backgroundColor;
  double radius;
  double fontSize;
  bool isIconShow;
  Widget? iconWidget;
  MainAxisAlignment mainAxisAlignment;

  CustomButton({super.key,
    required this.text,
    required this.callback,
    this.backgroundColor = AppColors.blue,
    this.radius = 20,
    this.fontSize = 14.0,
    this.isIconShow = false,
    this.iconWidget,
    this.mainAxisAlignment = MainAxisAlignment.center
  });

  @override
  Widget build(BuildContext context) {


    return ElevatedButton(
      onPressed: callback,
      style: ElevatedButton.styleFrom(
        backgroundColor:  backgroundColor,
        shape: RoundedRectangleBorder(
          side: BorderSide(color:  AppColors.blue,width: 1),
          borderRadius: BorderRadius.circular(radius),
        ),

      ),
      child: Row(
        mainAxisAlignment: mainAxisAlignment,
        children: [

          if(isIconShow && iconWidget != null)
            Container(
              margin: const EdgeInsets.only(right: 10),
              child: iconWidget,
            ),

          CustomText.TextMedium(text,fontSize: fontSize, color:  AppColors.whiteColor,maxLine: 3)

        ],
      ),
    );
  }
}
