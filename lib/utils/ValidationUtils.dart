
import 'package:email_validator/email_validator.dart';
import 'package:flutter/cupertino.dart';
import 'package:school_nx_pro/utils/utils.dart';

class ValidationUtils{


  static bool inputValidation(BuildContext context,TextEditingController controller, String message){

    if(controller.text.isEmpty){
      Utils.toastMessage(message);
      return false;
    }
    return true;
  }

  static bool emailValidation(BuildContext context,TextEditingController controller,String emptyMsg,String invalidMsg){

    if(controller.text.isEmpty){
      Utils.toastMessage(emptyMsg);
      return false;
    }
    else if(!EmailValidator.validate(controller.text)){
      Utils.toastMessage(invalidMsg);
      return false;
    }
    return true;
  }

  static bool passwordValidation(BuildContext context,TextEditingController controller,String emptyMsg){

    if(controller.text.isEmpty){
      Utils.toastMessage(emptyMsg);
      return false;
    }

    return true;
  }

  static bool passwordCharacterValidation(BuildContext context,TextEditingController controller,String emptyMsg,
      String invalidMsg){

    if(controller.text.isEmpty){
      Utils.toastMessage(emptyMsg);
      return false;
    }
    else if(controller.text.length < 6){
      Utils.toastMessage(invalidMsg);
      return false;
    }

    return true;
  }

  static bool conformPasswordValidation(BuildContext context,TextEditingController password,
    TextEditingController confirmPassword,String emptyMsg){

    if(password.value.text != confirmPassword.value.text){
      Utils.toastMessage(emptyMsg);
      return false;
    }

    return true;
  }

  static bool mobileNoValidation(BuildContext context,TextEditingController controller,String emptyMsg){

    if(controller.text.isEmpty){
      Utils.toastMessage(emptyMsg);
      return false;
    }
    /*else if(controller.text.length < 10){
      Utilities.showEdgeAlert(context, invalidMsg, false);
      return false;
    }*/

    return true;
  }

}