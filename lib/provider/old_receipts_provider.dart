import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:school_nx_pro/components/scaffold_message.dart';
import 'package:school_nx_pro/models/old_receipt_model.dart';
import 'package:school_nx_pro/repository/old_receipts_repo.dart';

class OldReceiptsProvider extends ChangeNotifier {
  final repo = OldReceiptsRepo();

  List<OldReceiptModel> getOldReceiptsList = [];

  Future<int> getOldReceipts() async {
    try {
      final response = await repo.getOldReceiptsApi();
      log(response.toString(), name: "getOldReceipts");
      // if (response['statusCode'] == 200) {
      //   getOldReceiptsList = List<OldReceiptModel>.from(
      //     response["data"].map((e) => OldReceiptModel.fromJson(e)),
      //   );
      // }
      getOldReceiptsList = List<OldReceiptModel>.from(
        (response as List?)?.map((e) => OldReceiptModel.fromJson(e)) ?? [],
      );
      notifyListeners();
      return getOldReceiptsList.length;
    } catch (e, s) {
      scaffoldMessage(message: "Something went wrong");
      log(e.toString(), name: 'error getOldReceipts', stackTrace: s);
    }
    return 0;
  }
}
