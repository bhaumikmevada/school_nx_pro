import 'dart:convert';
import 'dart:developer';
import 'package:school_nx_pro/repository/base_repo.dart';
import 'package:school_nx_pro/utils/api_urls.dart';

class ResultRepo extends BaseRepository {
  Future getResultApi(String? studentId, int tearmId, int examId) async {
    final params = '?termid=$tearmId&examid=$examId';

    // final response = await getHttp(api: ApiUrls.result + "19831" + params);
    final response = await getHttp(api: ApiUrls.result + studentId! + params);
    log(response.body, name: 'response getResultApi');
    return json.decode(response.body);
  }

  Future getTermApi() async {
    final response = await getHttp(api: ApiUrls.termname);
    log(response.body, name: 'response getTearmApi');
    return json.decode(response.body);
  }

  Future getExamApi() async {
    final response = await getHttp(api: ApiUrls.examname);
    log(response.body, name: 'response getExamApi');
    return json.decode(response.body);
  }
}
