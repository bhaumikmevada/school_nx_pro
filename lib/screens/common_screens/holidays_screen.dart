import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:school_nx_pro/screens/parent/parent_components/parent_appbar.dart';
import 'package:school_nx_pro/theme/app_colors.dart';
import 'package:school_nx_pro/theme/font_theme.dart';
import 'package:school_nx_pro/utils/enum.dart';
import 'package:school_nx_pro/utils/http_client_manager.dart';

class HolidayModels {
  final String holidayOn;
  final String reason;

  HolidayModels({
    required this.holidayOn,
    required this.reason,
  });

  factory HolidayModels.fromJson(Map<String, dynamic> json) {
    return HolidayModels(
      holidayOn: json['holiday_On'] ?? '',
      reason: json['reason'] ?? '',
    );
  }
}

class HolidayProviders extends ChangeNotifier {
  List<HolidayModels> _holidayList = [];

  List<HolidayModels> get getHolidayList => _holidayList;

  Future<void> getHoliday() async {
    try {
      final client = HttpClientManager.instance.getClient();
      final response = await client.get(
        Uri.parse('https://api.schoolnxpro.com/api/holiday?instituteId=10085'),
        headers: {'Content-Type': 'application/json'},
      );

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
  const HolidaysScreen({super.key, required this.userType});

  final UserType userType;

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

    provider.getHoliday().then((value) {
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

                            return Card(
                              margin: const EdgeInsets.symmetric(vertical: 5),
                              elevation: 2,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(25),
                                side: const BorderSide(color: AppColors.blue),
                              ),
                              child: Container(
                                // height: double.infinity,
                                width: double.infinity,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.all(Radius.circular(25)),
                                ),
                                child: IntrinsicHeight(
                                  child: Row(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Container(
                                        width: MediaQuery.of(context).size.width / 2.8,
                                        decoration: const BoxDecoration(
                                          color: AppColors.blue,
                                          borderRadius: BorderRadius.all(Radius.circular(25)),
                                        ),
                                        child: Center(
                                                child: Text(holiday.holidayOn,
                                                  textAlign: TextAlign.center,
                                                  style: normalWhite.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                      ),
                                      Expanded(
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          child: Column(
                                            crossAxisAlignment: CrossAxisAlignment.center,
                                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                            mainAxisSize: MainAxisSize.max,
                                            children: [
                                              Padding(
                                                padding: const EdgeInsets.symmetric(horizontal: 2),
                                                child: Text(holiday.reason,
                                                  textAlign: TextAlign.center,
                                                  style: normalBlack.copyWith(
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
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
