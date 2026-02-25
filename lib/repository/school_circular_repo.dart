import 'dart:convert';
import 'dart:developer';
import 'package:school_nx_pro/repository/base_repo.dart';
import 'package:school_nx_pro/utils/api_urls.dart';
//khushi
class SchoolCircularRepo extends BaseRepository {
  Future getSchoolCircularApi() async {
    final response = await getHttp(api: ApiUrls.schoolcircular);
    print("getSchoolCircularApi :- ${response.body}");
    log(response.body, name: 'response getSchoolCircularApi');
    return json.decode(response.body);
  }
}
