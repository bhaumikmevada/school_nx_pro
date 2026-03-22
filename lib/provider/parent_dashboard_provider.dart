import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/models/parent_dashboard_model.dart';
import 'package:school_nx_pro/repository/parent_dashboard_repo.dart';

//khushi
class ParentDashboardProvider extends ChangeNotifier {
  final repo = ParentDashboardRepo();
  StudentDetailsModel? studentDetails;

  Future<void> getStudentDetails() async {
    try {
      studentDetails = await repo.getStudentDetailsAPI();

      log(studentDetails.toString(), name: "getStudentDetails");
      notifyListeners();
    } catch (e) {
      // scaffoldMessage(message: "Something went wrong");
    }
  }

  Future<String?> addPayment({
    required String paymentAmount,
    required String paymentMethod,
  }) async {
    try {
      final response = await repo.addPaymentAPI(
        paymentAmount: paymentAmount,
        paymentMethod: paymentMethod,
      );

      log(response.toString(), name: "response addPayment");

      if (response?['paymentUrl'] != null) {
        String paymentUrl = response?['paymentUrl'];
        log(paymentUrl, name: "payment Url");
        scaffoldMessage(message: "Redirecting to payment gateway");
        return paymentUrl;
      } else {
        scaffoldMessage(message: "Payment URL not found");
        return null;
      }
    } catch (e, stacktrace) {
      log("Error: $e", name: "addPayment");
      log("Stacktrace: $stacktrace", name: "addPayment");
      scaffoldMessage(message: "Something went wrong: $e");
      return null;
    }
  }
}
