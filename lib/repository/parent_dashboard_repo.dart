import 'dart:convert';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:school_nx_pro/models/parent_dashboard_model.dart';
import 'package:school_nx_pro/repository/base_repo.dart';
import 'package:school_nx_pro/utils/api_urls.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

//khushi
class ParentDashboardRepo extends BaseRepository {
  Future<StudentDetailsModel?> getStudentDetailsAPI() async {
    // String? sessionYear =
    //     await MySharedPreferences.instance.getStringValue("sessionYear") ??
    //         "2024-2025";

    debugPrint("Clicked detail called ");

    String? studentId =
        await MySharedPreferences.instance.getStringValue("studentId");
    String? instituteId = await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";

    log("Using studentId: $studentId", name: "🚀 getStudentDetailsAPI()");    

    try {
      final response = await getHttp(
          api: "Dashboard?studentId=$studentId&instituteId=$instituteId"
      );
      log(response.body, name: 'response getStudentDetailsAPI');

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return StudentDetailsModel.fromJson(data);
      }
    } catch (e) {
      log("Error fetching student details: $e");
    }
    return null;
  }

  Future<Map<String, dynamic>?> addPaymentAPI({
    required String paymentAmount,
    required String paymentMethod,
  }) async {
    String? studentId =
        await MySharedPreferences.instance.getStringValue("studentId");

    String? sessionYear =
        await MySharedPreferences.instance.getStringValue("sessionYear") ??
            "2024-2025";

    final encodedMethod = Uri.encodeQueryComponent(paymentMethod);
    final response = await postHttp(
      api:
          "${ApiUrls.addPayment}/$studentId?sessionYear=$sessionYear&paymentAmount=$paymentAmount&paymentMode=$encodedMethod",
      data: {
        "paymentMode": paymentMethod,
      },
    );
    log(response.body, name: 'response addPaymentAPI');
    return json.decode(response.body);
  }
}
