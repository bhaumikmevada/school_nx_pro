import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/models/result_model.dart';
import 'package:school_nx_pro/models/term_exam_model.dart';
import 'package:school_nx_pro/repository/result_repo.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

class ResultProvider extends ChangeNotifier {
  final repo = ResultRepo();

  List<TermModel> termsList = [];
  List<ExamModel> examList = [];
  List<ResultModel> getResultList = [];

  Future<int> getResult(int termId, int examId) async {
    String? studentId =
        await MySharedPreferences.instance.getStringValue("studentId");

    if (studentId == null || studentId.isEmpty) {
      scaffoldMessage(message: "Student ID is missing!");
      log("Student ID is null or empty", name: 'error getResult');
      return 0;
    }

    try {
      // Fetch response from API
      final response = await repo.getResultApi(studentId, termId, examId);
      log("API Response: $response", name: "getResult");

      // Check if response is null
      if (response == null) {
        scaffoldMessage(message: "Failed to retrieve results. Try again.");
        log("API response is null", name: 'error getResult');
        return 0;
      }

      // Ensure response has expected structure
      if (response is! Map<String, dynamic>) {
        scaffoldMessage(message: "Invalid response format.");
        log("API returned unexpected data format: $response",
            name: 'error getResult');
        return 0;
      }

      // Ensure 'success' is true and 'data' is present
      if (response['success'] == true &&
          response['data'] is Map<String, dynamic>) {
        final data = response['data'] as Map<String, dynamic>;

        // Validate 'studentId' in the response before using it
        if (!data.containsKey('studentId') || data['studentId'] == null) {
          scaffoldMessage(message: "Invalid student data.");
          log("Missing 'studentId' in API response", name: 'error getResult');
          return 0;
        }

        // Parse and update result list
        getResultList = [ResultModel.fromJson(data)];
        notifyListeners();
        return getResultList.length;
      } else {
        scaffoldMessage(message: response['message'] ?? "No data available!");
        log("Invalid API response structure: $response",
            name: 'error getResult');
      }
    } catch (e, s) {
      scaffoldMessage(message: "Error fetching results!");
      log("Exception: $e", name: 'error getResult', stackTrace: s);
    }

    return 0;
  }

  Future<int> getTerm() async {
    try {
      final response = await repo.getTermApi();
      log(response.toString(), name: "getTearm");

      termsList = List<TermModel>.from(
        (response as List?)?.map((e) => TermModel.fromJson(e)) ?? [],
      );

      notifyListeners();
      return termsList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getTearm', stackTrace: s);
    }
    return 0;
  }

  Future<int> getExam() async {
    try {
      final response = await repo.getExamApi();
      log(response.toString(), name: "getExam");

      examList = List<ExamModel>.from(
        (response as List?)?.map((e) => ExamModel.fromJson(e)) ?? [],
      );

      notifyListeners();
      return examList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getExam', stackTrace: s);
    }
    return 0;
  }
}
