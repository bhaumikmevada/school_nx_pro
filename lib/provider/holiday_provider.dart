import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/models/holiday_model.dart';
import 'package:school_nx_pro/repository/holiday_repo.dart';

class HolidayProvider extends ChangeNotifier {
  final repo = HolidayRepo();

  List<HolidayModel> getHolidayList = [];

  Future<int> getHoliday() async {
    try {
      final response = await repo.getHolidayApi();
      log(response.toString(), name: "getHoliday");
      if (response['statusCode'] == 200) {
        getHolidayList = List<HolidayModel>.from(
          response["data"].map((e) => HolidayModel.fromJson(e)),
        );
      }
      notifyListeners();
      return getHolidayList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getHoliday', stackTrace: s);
    }
    return 0;
  }
}
