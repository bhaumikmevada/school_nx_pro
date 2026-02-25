import 'dart:convert';
import 'dart:developer';
import 'package:school_nx_pro/repository/base_repo.dart';
import 'package:school_nx_pro/utils/api_urls.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';

class EmployeeAttendanceRepo extends BaseRepository {
  Future getCourseApi() async {
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId");

    final params = '?instituteId=${instituteId ?? "10085"}';

    final response = await getHttp(api: ApiUrls.course + params);
    log(response.body, name: 'response getCourseApi');
    return json.decode(response.body);
  }

  Future getSectionApi() async {
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId");

    final params = '?instituteId=${instituteId ?? "10085"}';

    final response = await getHttp(api: ApiUrls.section + params);
    log(response.body, name: 'response getSectionApi');
    return json.decode(response.body);
  }

  Future getMediumApi() async {
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId");

    final params = '?instituteId=${instituteId ?? "10085"}';

    final response = await getHttp(api: ApiUrls.medium + params);
    log(response.body, name: 'response getMediumApi');
    return json.decode(response.body);
  }

  Future getStreamApi() async {
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId");

    final params = '?instituteId=${instituteId ?? "10085"}';

    final response = await getHttp(api: ApiUrls.stream + params);
    log(response.body, name: 'response getStreamApi');
    return json.decode(response.body);
  }

  Future getSubStreamApi() async {
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId");

    final params = '?instituteId=${instituteId ?? "10085"}';

    final response = await getHttp(api: ApiUrls.substream + params);
    log(response.body, name: 'response getSubStreamApi');
    return json.decode(response.body);
  }

  Future getStudentsForAttendenceApi(
    int courseId,
    int sectionId,
    int mediumId,
    int streamId,
    int subStreamId,
  ) async {
    final params =
        '?courseId=$courseId&sectionId=$sectionId&mediumId=$mediumId&streamId=$streamId&subStreamId=$subStreamId';
    final response = await getHttp(api: ApiUrls.studentInCSMSS + params);
    log(response.body, name: 'response getStudentsForAttendenceApi');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>?> submitStudentAttendence({
    required List<Map<String, dynamic>> data,
    required String employeeID,
    required int courseID,
    required int sectionID,
    required int mediumID,
    required int streamID,
    required int subStreamID,
  }) async {
    final url =
        "${ApiUrls.submitAttandancewithCSMSS}/attendance/employee/$employeeID/class/$courseID/$sectionID/$mediumID/$streamID/$subStreamID";

    final response = await newPostHttp(
      api: url,
      data: data,
    );

    log(response.body, name: 'response submitStudentAttendence');

    if (response.body.isNotEmpty) {
      try {
        return json.decode(response.body);
      } catch (e) {
        return {"message": response.body};
      }
    }
    return null;
  }
}
