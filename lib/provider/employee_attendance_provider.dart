import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/models/course_model.dart';
import 'package:school_nx_pro/models/medium_model.dart';
import 'package:school_nx_pro/models/section_model.dart';
import 'package:school_nx_pro/models/stream_model.dart';
import 'package:school_nx_pro/models/student_list_for_attendance_model.dart';
import 'package:school_nx_pro/models/sub_stream_model.dart';
import 'package:school_nx_pro/repository/employee_attendance_repo.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

class EmployeeAttendanceProvider extends ChangeNotifier {
  final repo = EmployeeAttendanceRepo();

  List<CourseModel> courseList = [];
  List<SectionModel> sectionList = [];
  List<MediumModel> mediumList = [];
  List<StreamModel> streamList = [];
  List<SubStreamModel> subStreamList = [];
  List<StudentListForAttendanceModel> studentList = [];

  Future<int> getCourse() async {
    try {
      final response = await repo.getCourseApi();
      log(response.toString(), name: "getCourse");

      courseList = List<CourseModel>.from(
        (response as List?)?.map((e) => CourseModel.fromJson(e)) ?? [],
      );

      notifyListeners();
      return courseList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getCourse', stackTrace: s);
    }
    return 0;
  }

  Future<int> getSection() async {
    try {
      final response = await repo.getSectionApi();
      log(response.toString(), name: "getSection");

      sectionList = List<SectionModel>.from(
        (response as List?)?.map((e) => SectionModel.fromJson(e)) ?? [],
      );

      notifyListeners();
      return sectionList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getSection', stackTrace: s);
    }
    return 0;
  }

  Future<int> getMedium() async {
    try {
      final response = await repo.getMediumApi();
      log(response.toString(), name: "getMedium");

      mediumList = List<MediumModel>.from(
        (response as List?)?.map((e) => MediumModel.fromJson(e)) ?? [],
      );

      notifyListeners();
      return mediumList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getMedium', stackTrace: s);
    }
    return 0;
  }

  Future<int> getStream() async {
    try {
      final response = await repo.getStreamApi();
      log(response.toString(), name: "getStream");

      streamList = List<StreamModel>.from(
        (response as List?)?.map((e) => StreamModel.fromJson(e)) ?? [],
      );

      notifyListeners();
      return streamList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getStream', stackTrace: s);
    }
    return 0;
  }

  Future<int> getSubStream() async {
    try {
      final response = await repo.getSubStreamApi();
      log(response.toString(), name: "getSubStream");

      if (response is List) {
        subStreamList =
            response.map((e) => SubStreamModel.fromJson(e)).toList();
      } else {
        log("Unexpected response format", name: "getSubStream");
      }

      notifyListeners();
      return subStreamList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getSubStream', stackTrace: s);
    }
    return 0;
  }

  Future<int> getStudentListForAttendance(
    int courseId,
    int sectionId,
    int mediumId,
    int streamId,
    int subStreamId,
  ) async {
    try {
      final response = await repo.getStudentsForAttendenceApi(
        courseId,
        sectionId,
        mediumId,
        streamId,
        subStreamId,
      );
      log(response.toString(), name: "getStudentListForAttendance");
      if (response is List) {
        studentList = response
            .map((e) => StudentListForAttendanceModel.fromJson(e))
            .toList();
      }
      notifyListeners();
      return studentList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(),
          name: 'error getStudentListForAttendance', stackTrace: s);
    }
    return 0;
  }

  Future addStudentAttendance({
    required List<int> studentId,
    required List<Map<String, dynamic>> studentAttendanceList,
    required int courseID,
    required int sectionID,
    required int mediumID,
    required int streamID,
    required int subStreamID,
  }) async {
    try {
      String? employeeID =
          await MySharedPreferences.instance.getStringValue("employeeID");
      // int employeeID = employeeID;

      final response = await repo.submitStudentAttendence(
        data: studentAttendanceList,
        employeeID: employeeID ?? "N/A",
        courseID: courseID,
        sectionID: sectionID,
        mediumID: mediumID,
        streamID: streamID,
        subStreamID: subStreamID,
      );

      log(response.toString(), name: "response addStudentAttendance");

      if (response != null && response.containsKey("message")) {
        String responseString = response["message"].toString();

        for (int id in studentId) {
          if (responseString.contains(
              "Attendance for student ID $id has already been submitted for today.")) {
            scaffoldMessage(message: responseString);
            return;
          }
        }
      }

      scaffoldMessage(message: "Attendance submitted successfully!");
    } catch (e, stacktrace) {
      log("Error: $e", name: "addStudentAttendance");
      log("Stacktrace: $stacktrace", name: "addStudentAttendance");
      scaffoldMessage(message: "Something went wrong: $e");
    }
  }
}
