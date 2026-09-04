import 'dart:convert';
import 'dart:io';
import 'dart:math';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:school_nx_pro/utils/StringUtils.dart';
import 'package:school_nx_pro/utils/keys.dart';

import '../theme/app_colors.dart';

class Utils {

  static Future<void> showAlertDialog(
      BuildContext context, {
        String title = appName,
        required String message,
        String okButtonText = 'OK',
        VoidCallback? onOkPressed,
        String? cancelButtonText,
        VoidCallback? onCancelPressed,
      }) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.symmetric(horizontal: 24),
          child: Container(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 16),
            decoration: BoxDecoration(
              color: AppColors.whiteColor,
              borderRadius: BorderRadius.circular(18),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.15),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (title.isNotEmpty) ...[
                  Text(
                    title,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 14.5,
                    color: Colors.black54,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 22),
                Row(
                  children: [
                    if (cancelButtonText != null) ...[
                      Expanded(
                        child: _AlertButton(
                          text: cancelButtonText,
                          isPrimary: false,
                          onPressed: () {
                            Navigator.of(dialogContext).pop();
                            onCancelPressed?.call();
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      child: _AlertButton(
                        text: okButtonText,
                        isPrimary: true,
                        onPressed: () {
                          Navigator.of(dialogContext).pop();
                          onOkPressed?.call();
                        },
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  static Future showSheet(
      BuildContext context, {
        required Widget child,
        required VoidCallback onClicked,
      }) =>
      showCupertinoModalPopup(
        useRootNavigator: false,
        context: context,
        builder: (context) => CupertinoActionSheet(
          actions: [child],
          cancelButton: CupertinoActionSheetAction(
            onPressed: onClicked,
            child: const Text('Select'),
          ),
        ),
      );

  static Widget showCircularProgress({Color color = AppColors.blue, bool isDarkMode = true}) {
    return CircularProgressIndicator(color: color);
  }

  static void showSnackBar(String text) {
    final snackBar = SnackBar(
      content: Text(text),
      behavior: SnackBarBehavior.floating,
    );

    Keys.messangerKey.currentState!
      ..removeCurrentSnackBar()
      ..showSnackBar(snackBar);
  }

  static void toastMessage(String message) {
    Fluttertoast.showToast(
      msg: message,
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.BOTTOM,
      timeInSecForIosWeb: 1,
      backgroundColor: Colors.black,
      textColor: Colors.white,
      fontSize: 16,
    );
  }

  static String generateRandomCode() {
    const String chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
    final Random rnd = Random();
    return String.fromCharCodes(
        List.generate(6, (_) => chars.codeUnitAt(rnd.nextInt(chars.length))));
  }

  static String convertDateFormat({
    required String inputDate,
    required String inputFormat,
    required String outputFormat,
  }) {
    try {
      final inputFormatter = DateFormat(inputFormat);
      final outputFormatter = DateFormat(outputFormat);

      DateTime dateTime = inputFormatter.parse(inputDate);
      return outputFormatter.format(dateTime);
    } catch (e) {
      return inputDate; // fallback if parsing fails
    }
  }

  static Future<List<String>> imagesToBase64(List<File> images) async {
    List<String> base64 = [];
    for (var e in images) {
      String temp = base64Encode(e.readAsBytesSync());
      base64.add(temp);
    }
    return base64;
  }

  static bool isEmail(String email) {
    String p =
        r'^(([^<>()[\]\\.,;:\s@\"]+(\.[^<>()[\]\\.,;:\s@\"]+)*)|(\".+\"))@((\[[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\.[0-9]{1,3}\])|(([a-zA-Z\-0-9]+\.)+[a-zA-Z]{2,}))$';
    RegExp regExp = RegExp(p);

    return regExp.hasMatch(email);
  }

  static bool isPhone(String input) {
    return RegExp(r'^[\+]?[(]?[0-9]{3}[)]?[-\s\.]?[0-9]{3}[-\s\.]?[0-9]{4,6}$')
        .hasMatch(input);
  }

  static bool isNum(String input) => int.tryParse(input) != null;

  static bool scrollNotifier(Object? notification, VoidCallback callback) {
    if (notification is ScrollEndNotification) {
      final before = notification.metrics.extentBefore;
      final max = notification.metrics.maxScrollExtent;

      if (before == max) callback();
    }
    return false;
  }
}

class _AlertButton extends StatelessWidget {
  final String text;
  final bool isPrimary;
  final VoidCallback onPressed;

  const _AlertButton({
    required this.text,
    required this.isPrimary,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isPrimary ? AppColors.blue : Colors.grey.shade200,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onPressed,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          alignment: Alignment.center,
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w600,
              color: isPrimary ? Colors.white : Colors.black87,
            ),
          ),
        ),
      ),
    );
  }
}