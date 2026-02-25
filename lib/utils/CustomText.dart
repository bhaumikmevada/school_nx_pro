
import 'package:flutter/cupertino.dart';

import '../theme/app_colors.dart';

class CustomText{


  static String fontPoppins = "Poppins";

  static Widget TextRegular(String message,{fontSize = 14.0,color = AppColors.blackColor,textAlign = TextAlign.left,
    TextDecoration decoration = TextDecoration.none,TextOverflow overflow = TextOverflow.clip,int maxLine = 1}){
    return Text(message,style: TextStyle(fontFamily: fontPoppins,fontWeight: FontWeight.w400,fontSize: fontSize,color: color,
    decoration: decoration,decorationColor: AppColors.textHintColor,decorationThickness: 0.5,overflow: overflow),textAlign: textAlign,maxLines: maxLine,);
  }

  static Widget TextMedium(String message,{fontSize = 14.0,color = AppColors.blackColor,
    TextDecoration decoration = TextDecoration.none,TextAlign textAlign = TextAlign.start,
    TextOverflow overflow = TextOverflow.clip,int maxLine = 1}){
    return Text(message,style: TextStyle(fontFamily: fontPoppins,fontWeight: FontWeight.w500,fontSize: fontSize,color: color,
        decoration: decoration,overflow: overflow),textAlign: textAlign,maxLines: maxLine,);
  }

  static Widget TextSemiBold(String message,{fontSize = 14.0,color = AppColors.blackColor}){
    return Text(message,style: TextStyle(fontFamily: fontPoppins,fontWeight: FontWeight.w600,fontSize: fontSize,color: color),);
  }

  static Widget TextBold(String message,{fontSize = 14.0,color = AppColors.blackColor,TextDecoration decoration = TextDecoration.none,
  TextAlign textAlign = TextAlign.left}){
    return Text(message,style: TextStyle(fontFamily: fontPoppins,fontWeight: FontWeight.w700,fontSize: fontSize,color: color,
    decoration: decoration),textAlign: textAlign,);
  }

  static Widget AppText(String message,{fontSize = 16.0,color = AppColors.blackColor}){
    return Text(message,style: TextStyle(fontFamily: fontPoppins,fontWeight: FontWeight.w700,fontSize: fontSize,color: color),);
  }

}