import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/models/homework_model.dart';
import 'package:school_nx_pro/models/subject_model.dart';
import 'package:school_nx_pro/repository/homework_repo.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

class HomeworkProvider extends ChangeNotifier {
  final repo = HomeworkRepo();

  List<HomeworkModel> getHomeworkList = [];
  List<SubjectModel> getSubjectList = [];

  Future<int> getHomework() async {
    String? id = await MySharedPreferences.instance.getStringValue("studentId");

    try {
      final response = await repo.getHomeworkApi(id ?? "0");
      log(response.toString(), name: "getHomework");
      if (response['statusCode'] == 200) {
        getHomeworkList = List<HomeworkModel>.from(
          response["data"].map((e) => HomeworkModel.fromJson(e)),
        );
      }
      notifyListeners();
      return getHomeworkList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getHomework', stackTrace: s);
    }
    return 0;
  }

  Future<int> getSubject() async {
    try {
      final response = await repo.getSubjectAPI();
      log(response.toString(), name: "getSubject");

      getSubjectList = List<SubjectModel>.from(
        (response as List?)?.map((e) => SubjectModel.fromJson(e)) ?? [],
      );

      notifyListeners();
      return getSubjectList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getSubject', stackTrace: s);
    }
    return 0;
  }

  Future<Map<String, dynamic>?> addHomework({
    required String subjectId,
    required String homeWorkDate,
    required String homeWorkDueOnDate,
    required String homeWorkName,
    required String homeWorkDescription,
    String? attachmentPath,
  }) async {
    try {
      final response = await repo.addHomeworkAPI(
        subjectId: subjectId,
        homeWorkDate: homeWorkDate,
        homeWorkDueOnDate: homeWorkDueOnDate,
        homeWorkName: homeWorkName,
        homeWorkDescription: homeWorkDescription,
        filePath: attachmentPath,
      );

      // log(response.toString(), name: "response addHomework");

      if (response?['statusCode'] == 200) {
        scaffoldMessage(message: "Homework Added Successfully!");
        if (response?['data'] is Map<String, dynamic>) {
          return Map<String, dynamic>.from(response?['data']);
        }
        return {};
      }

      // scaffoldMessage(message: "Something went wrong");
      return null;
    } catch (e, stacktrace) {
      log("Error: $e", name: "addHomework");
      log("Stacktrace: $stacktrace", name: "addHomework");
      scaffoldMessage(message: "Something went wrong: $e");
      return null;
    }
  }
}
