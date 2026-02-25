import 'dart:convert';
import 'dart:developer';
import 'package:school_nx_pro/repository/base_repo.dart';
import 'package:school_nx_pro/utils/api_urls.dart';

class OldReceiptsRepo extends BaseRepository {
  Future getOldReceiptsApi() async {
    final response = await getHttp(api: ApiUrls.oldreciept);
    log(response.body, name: 'response getOldReceiptsApi');
    return json.decode(response.body);
  }
}
