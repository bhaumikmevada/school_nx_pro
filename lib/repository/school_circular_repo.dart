import 'dart:convert';
import 'dart:developer';
import 'package:school_nx_pro/repository/base_repo.dart';
import 'package:school_nx_pro/utils/api_urls.dart';

import '../utils/my_sharepreferences.dart';
//khushi
class SchoolCircularRepo extends BaseRepository {
  Future getSchoolCircularApi() async {

    final instituteId = await MySharedPreferences.instance.getStringValue("instituteId") ?? "10085";

    final response = await getHttp(api: "${ApiUrls.schoolcircular}?instituteId=$instituteId",token: true);
    print("getSchoolCircularApi :- ${response.body}");
    log(response.body, name: 'response getSchoolCircularApi');
    return json.decode(response.body);
  }
}
