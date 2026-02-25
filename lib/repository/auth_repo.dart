import 'dart:convert';
import 'dart:developer';

import 'package:school_nx_pro/repository/base_repo.dart';
import 'package:school_nx_pro/utils/api_urls.dart';

class AuthRepository extends BaseRepository {
  //login
  Future<Map<String, dynamic>?> loginApi(Map<String, dynamic> data) async {
    final response = await postHttp(api: ApiUrls.login, data: data);
    log(response.body, name: 'response loginApi');
    if (response.body.isNotEmpty) {
      return json.decode(response.body);
    }
    return null;
  }
}
