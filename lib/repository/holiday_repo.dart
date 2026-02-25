import 'dart:convert';
import 'dart:developer';
import 'package:school_nx_pro/repository/base_repo.dart';
import 'package:school_nx_pro/utils/api_urls.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

class HolidayRepo extends BaseRepository {
  Future getHolidayApi() async {
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId");
    
    final params = '?instituteId=${instituteId ?? "10085"}';
    final response = await getHttp(api: ApiUrls.holiday + params);
    log(response.body, name: 'response getHolidayApi');
    return json.decode(response.body);
  }
}
