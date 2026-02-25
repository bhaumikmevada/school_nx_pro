import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/models/school_circular_model.dart';
import 'package:school_nx_pro/repository/school_circular_repo.dart';

//khushI
class SchoolCircularProvider extends ChangeNotifier {
  final repo = SchoolCircularRepo();

  List<SchoolCircularModel> getSchoolCircularList = [];

  Future<int> getSchoolCircular() async {
    try {
      final response = await repo.getSchoolCircularApi();
      log(response.toString(), name: "getSchoolCircular");
      if (response['statusCode'] == 200) {
        getSchoolCircularList = List<SchoolCircularModel>.from(
          response["data"].map((e) => SchoolCircularModel.fromJson(e)),
        );
      }
      notifyListeners();
      return getSchoolCircularList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getUserDetails', stackTrace: s);
    }
    return 0;
  }
}
