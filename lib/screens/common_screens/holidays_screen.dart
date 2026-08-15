import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/api_urls.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/http_client_manager.dart';

import '../../utils/CustomText.dart';
import '../../utils/my_sharepreferences.dart';
import '../../utils/utils.dart';

class HolidayModels {
  final String holidayOn;
  final String reason;
  final String formattedDate;
  final String holidayDetailId;

  HolidayModels({
    required this.holidayOn,
    required this.reason,
    required this.formattedDate,
    required this.holidayDetailId,
  });

  factory HolidayModels.fromJson(Map<String, dynamic> json) {
    return HolidayModels(
      holidayOn: json['holiday_On'] ?? '',
      reason: json['reason'] ?? '',
      formattedDate: json['formatted_date'] ?? '',
      holidayDetailId: json['holiday_detail_id'] ?? '',
    );
  }
}

class HolidayProviders extends ChangeNotifier {
  List<HolidayModels> _holidayList = [];

  List<HolidayModels> get getHolidayList => _holidayList;

  Future<void> getHoliday(String studentId) async {
    try {
      final client = HttpClientManager.instance.getClient();
      final instituteId = await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";
      final token = await MySharedPreferences.instance.getStringValue("token") ?? "";

      debugPrint("getHoliday studentId : $studentId");
      final response = await client.get(
        // Uri.parse('${ApiUrls.baseUrl}holiday?instituteId=$instituteId'),
        Uri.parse('${ApiUrls.baseUrl}holidays/my?studentId=$studentId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      debugPrint("getHoliday url : ${ApiUrls.baseUrl}holidays/my?studentId=$studentId");
      debugPrint("getHoliday response : ${response.body}");

      if (response.statusCode == 200) {
        final body = json.decode(response.body);

        if (body['success'] == true && body['data'] != null) {
          final List data = body['data'];
          _holidayList = data.map((e) => HolidayModels.fromJson(e)).toList();
        } else {
          _holidayList = [];
        }
      } else {
        _holidayList = [];
      }
    } catch (e) {
      debugPrint("Error fetching holidays: $e");
      _holidayList = [];
    }

    notifyListeners();
  }
}

class HolidaysScreen extends StatefulWidget {
   HolidaysScreen({super.key, required this.userType,required this.studentId});

  final UserType userType;
  final String studentId;

  @override
  State<HolidaysScreen> createState() => _HolidaysScreenState();
}

class _HolidaysScreenState extends State<HolidaysScreen> {
  late HolidayProviders provider;

  bool loading = true, loader = false;

  @override
  void initState() {
    super.initState();
    setState(() {
      loader = true;
    });

    provider = Provider.of<HolidayProviders>(context, listen: false);

    debugPrint("holiday screen studentId : ${widget.studentId}");

    provider.getHoliday(widget.studentId).then((value) {
      loader = false;
      loading = false;
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgColor,
      appBar: const ParentAppbar(
        title: "Holidays",
      ),
      body: loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.symmetric(horizontal: 15),
              child: Selector<HolidayProviders, List<HolidayModels>>(
                selector: (p0, p1) => p1.getHolidayList,
                builder: (context, holidayList, child) {
                  return holidayList.isEmpty
                      ? const Center(
                          child: Text("No Data Awailable", style: TextStyle(color: Colors.black),),
                        )
                      : ListView.builder(
                          shrinkWrap: true,
                          itemCount: holidayList.length,
                          itemBuilder: (context, index) {
                            final holiday = holidayList[index];
                            return Container(
                              margin: EdgeInsets.all(5),
                              decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.colorcfcfcf,width: 1),
                                  color: AppColors.whiteColor,
                                  borderRadius: BorderRadius.circular(10),
                                  boxShadow: [
                                    BoxShadow(color: AppColors.colorcfcfcf,blurRadius: 2.0,offset: Offset(1.0, 0.0))
                                  ]
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                mainAxisAlignment: MainAxisAlignment.start,
                                children: [

                                  Stack(
                                    alignment: Alignment.topRight,
                                    children: [

                                      Container(
                                        width: 100,
                                        height: 30,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                            borderRadius: BorderRadius.only(
                                                topRight: Radius.circular(9)
                                            ),
                                            color: AppColors.blue
                                        ),
                                        child: CustomText.TextMedium(holiday.formattedDate,fontSize: 13.0,color: AppColors.whiteColor,textAlign: TextAlign.center),
                                      ),

                                      Container(
                                        padding: EdgeInsets.all(20),
                                        child: Row(
                                          children: [

                                            const SizedBox(width: 10,),

                                            CustomText.TextSemiBold(holiday.reason,color: AppColors.blackColor),


                                          ],
                                        ),
                                      )

                                    ],
                                  )
                                ],
                              ),
                            );

                            // return Card(
                            //   margin: const EdgeInsets.symmetric(vertical: 5),
                            //   elevation: 2,
                            //   shape: RoundedRectangleBorder(
                            //     borderRadius: BorderRadius.circular(25),
                            //     side: const BorderSide(color: AppColors.blue),
                            //   ),
                            //   child: Container(
                            //     // height: double.infinity,
                            //     width: double.infinity,
                            //     decoration: const BoxDecoration(
                            //       color: Colors.white,
                            //       borderRadius: BorderRadius.all(Radius.circular(25)),
                            //     ),
                            //     child: IntrinsicHeight(
                            //       child: Row(
                            //         crossAxisAlignment: CrossAxisAlignment.start,
                            //         children: [
                            //           Container(
                            //             width: MediaQuery.of(context).size.width / 2.8,
                            //             decoration: const BoxDecoration(
                            //               color: AppColors.blue,
                            //               borderRadius: BorderRadius.all(Radius.circular(25)),
                            //             ),
                            //             child: Center(
                            //               child: Text(holiday.holidayOn,
                            //                 textAlign: TextAlign.center,
                            //                 style: normalWhite.copyWith(
                            //                   fontWeight: FontWeight.w700,
                            //                 ),
                            //               ),
                            //             ),
                            //           ),
                            //           Expanded(
                            //             child: Padding(
                            //               padding: const EdgeInsets.symmetric(vertical: 10),
                            //               child: Column(
                            //                 crossAxisAlignment: CrossAxisAlignment.center,
                            //                 mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            //                 mainAxisSize: MainAxisSize.max,
                            //                 children: [
                            //                   Padding(
                            //                     padding: const EdgeInsets.symmetric(horizontal: 2),
                            //                     child: Text(holiday.reason,
                            //                       textAlign: TextAlign.center,
                            //                       style: normalBlack.copyWith(
                            //                         fontWeight: FontWeight.w700,
                            //                       ),
                            //                     ),
                            //                   ),
                            //                 ],
                            //               ),
                            //             ),
                            //           ),
                            //         ],
                            //       ),
                            //     ),
                            //   ),
                            // );
                            // return AppCard(
                            //   mainTitle: holiday.holidayOn,
                            //   upperTitle: holiday.reason,
                            //   widget: const SizedBox.shrink(),
                            // );
                          },
                        );
                },
              ),
            ),
    );
  }
}
