import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';

void scaffoldMessage({
  required String message,
  Duration duration = const Duration(seconds: 2),
}) {
  Fluttertoast.showToast(
    msg: message,
    toastLength: Toast.LENGTH_LONG,
    gravity: ToastGravity.BOTTOM,
    timeInSecForIosWeb: 1,
    backgroundColor: Colors.black,
    textColor: Colors.white,
    fontSize: 16,
  );
}
