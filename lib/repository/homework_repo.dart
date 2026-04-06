import 'dart:convert';
import 'dart:developer';
import 'package:flutter/widgets.dart';
import 'package:intl/intl.dart';
import 'package:school_nx_pro/repository/base_repo.dart';
import 'package:school_nx_pro/utils/api_urls.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';
import 'package:http/http.dart' as http;

import '../components/scaffold_message.dart';

class HomeworkRepo extends BaseRepository {
  Future getHomeworkApi(String id) async {
    // Get instituteId from SharedPreferences
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId");
    
    // Include both admissionId and instituteId in params
    final params = '?admissionId=$id${instituteId != null ? '&instituteId=$instituteId' : ''}';

    final response = await getHttp(api: ApiUrls.homework + params);
    log(response.body, name: 'response getHomeworkApi');
    log("API URL: ${ApiUrls.baseUrl}${ApiUrls.homework}$params", name: 'getHomeworkApi URL');
    return json.decode(response.body);
  }

  Future getSubjectAPI() async {
    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId");

    final params = '?instituteId=$instituteId';

    final response = await getHttp(api: ApiUrls.subject + params);
    log(response.body, name: 'response getSubjectAPI');
    return json.decode(response.body);
  }

  Future<Map<String, dynamic>?> addHomeworkAPI({
    required String subjectId,
    required String homeWorkDate,
    required String homeWorkDueOnDate,
    required String homeWorkName,
    required String homeWorkDescription,
    String? filePath,
  }) async {
    String? allottedTeacherId =
        await MySharedPreferences.instance.getStringValue("allottedTeacherId");

    String? instituteId =
        await MySharedPreferences.instance.getStringValue("instituteId");

    String? instituteUserId = await MySharedPreferences.instance
        .getStringValue("createdByInstituteUserId");

    debugPrint("instituteUserId : $instituteUserId");

    var uri = Uri.parse(ApiUrls.baseUrl + ApiUrls.addHomework);
    var request = http.MultipartRequest('POST', uri);
    log("API URL: ${uri.toString()}", name: "addHomeworkAPI URL");

    final formattedHWDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(
      DateFormat("dd-MM-yyyy").parse(homeWorkDate).toUtc(),
    );

    final formattedDueDate = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").format(
      DateFormat("dd-MM-yyyy").parse(homeWorkDueOnDate).toUtc(),
    );

    // Add form-data fields - IMPORTANT: Use 'homeworkName' (lowercase 'w') as per API requirement
    request.fields['allotTeacherId'] = allottedTeacherId ?? '';
    request.fields['instituteId'] = instituteId ?? '';
    request.fields['instituteUserId'] = instituteUserId ?? '';
    request.fields['subjectId'] = subjectId;
    request.fields['homeWorkDate'] = formattedHWDate;
    request.fields['homeWorkDueOnDate'] = formattedDueDate;
    request.fields['homeworkName'] = homeWorkName; // Changed from 'homeWorkName' to 'homeworkName'
    request.fields['homeWorkDescription'] = homeWorkDescription;

    log(request.fields['allotTeacherId'].toString(), name: "allotTeacherId");
    log(request.fields['instituteId'].toString(), name: "instituteId");
    log(request.fields['instituteUserId'].toString(), name: "instituteUserId");
    log(request.fields['subjectId'].toString(), name: "subjectId");
    log(request.fields['homeWorkDate'].toString(), name: "homeWorkDate");
    log(request.fields['homeWorkDueOnDate'].toString(),
        name: "homeWorkDueOnDate");
    log(request.fields['homeworkName'].toString(), name: "homeworkName");
    log(request.fields['homeWorkDescription'].toString(),
        name: "homeWorkDescription");

    if (filePath != null && filePath.isNotEmpty) {
      request.files.add(await http.MultipartFile.fromPath('file', filePath));
      log("File attached: $filePath", name: "addHomeworkAPI");
    }

    try {
      var streamedResponse = await request.send();
      var response = await http.Response.fromStream(streamedResponse);

      log("Response Status: ${response.statusCode}", name: "addHomeworkAPI");
      log("Response Body: ${response.body}", name: "addHomeworkAPI");
      scaffoldMessage(message: "Homework Added Successfully!");
      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        log("Error: ${response.statusCode} ${response.reasonPhrase}", name: "addHomeworkAPI");
        log("Error Body: ${response.body}", name: "addHomeworkAPI");
        return null;
      }
    } catch (e) {
      log("Exception in addHomeworkAPI: $e", name: "addHomeworkAPI");
      return null;
    }
  }
}
