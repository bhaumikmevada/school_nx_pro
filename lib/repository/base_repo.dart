// import 'dart:convert';
// import 'dart:developer';
// import 'package:http/http.dart' as http;
// import 'package:schoolproject/utils/api_urls.dart';
// import 'package:schoolproject/utils/my_sharepreferences.dart';

// class BaseRepository {
//   /// For POST request
//   Future<http.Response> postHttp({
//     required Map<String, dynamic> data,
//     required String api,
//     bool token = false,
//   }) async {
//     String? accessToken;
//     final url = ApiUrls.baseUrl + api;
//     log(url, name: 'postHttp');
//     log(data.toString(), name: '$api data');
//     if (token) {
//       accessToken = await MySharedPreferences.instance.getStringValue("token");
//       log(accessToken.toString(), name: "token");
//     }

//     final response = await http.post(
//       Uri.parse(url),
//       headers: accessToken == null
//           ? {'Content-Type': 'application/json'}
//           : {
//               'Content-Type': 'application/json',
//               'Authorization': 'Bearer $accessToken'
//             },
//       body: json.encode(data),
//     );

//     log(response.statusCode.toString(), name: 'Response Code');
//     // log(response.headers.toString(), name: 'Response Headers');

//     // if (response.statusCode == 307) {
//     //   final newUrl = response.headers['location'];
//     //   if (newUrl != null) {
//     //     log('Redirecting to $newUrl', name: 'postHttp');
//     //     return await http.post(
//     //       Uri.parse(newUrl),
//     //       headers: {
//     //         'Content-Type': 'application/json',
//     //         if (accessToken != null) 'Authorization': 'Bearer $accessToken',
//     //       },
//     //       body: json.encode(data),
//     //     );
//     //   }
//     // }

//     if (response.statusCode == 403 || token) {
//       return refreshToken()
//           .then((value) => postHttp(data: data, api: api, token: token));
//     }
//     return response;
//   }

//   /// For GET request
//   Future<http.Response> getHttp({
//     required String api,
//     bool token = false,
//   }) async {
//     String? accessToken;
//     final url = ApiUrls.baseUrl + api;
//     log(url, name: 'getHttp');
//     if (token) {
//       accessToken =
//           await MySharedPreferences.instance.getStringValue("access_token");
//       log(accessToken.toString(), name: "access_token");
//     }

//     final response = await http.get(
//       Uri.parse(url),
//       headers: accessToken == null
//           ? {'Content-Type': 'application/json'}
//           : {
//               'Content-Type': 'application/json',
//               'Authorization': 'Bearer $accessToken'
//             },
//     );
//     log(response.statusCode.toString());
//     if (response.statusCode == 403 && token) {
//       return refreshToken().then((value) => getHttp(api: api, token: token));
//     }
//     return response;
//   }

//   /// For PUT request
//   Future<http.Response> putHttp({
//     required Map<String, dynamic> data,
//     required String api,
//     bool token = false,
//   }) async {
//     String? accessToken;
//     final url = ApiUrls.baseUrl + api;
//     log(url, name: 'putHttp');
//     log(data.toString(), name: '$api data');
//     if (token) {
//       accessToken =
//           await MySharedPreferences.instance.getStringValue("access_token");
//       log(accessToken.toString(), name: "access_token");
//     }
//     final response = await http.put(
//       Uri.parse(url),
//       headers: accessToken == null
//           ? {'Content-Type': 'application/json'}
//           : {
//               'Content-Type': 'application/json',
//               'Authorization': 'Bearer $accessToken'
//             },
//       body: json.encode(data),
//     );
//     log(response.statusCode.toString());
//     if (response.statusCode == 403 && token) {
//       return refreshToken()
//           .then((value) => putHttp(data: data, api: api, token: token));
//     }
//     return response;
//   }

//   /// For DELETE request
//   Future<http.Response> deleteHttp({
//     required String api,
//     bool token = false,
//   }) async {
//     String? accessToken;
//     final url = ApiUrls.baseUrl + api;
//     log(url, name: 'deleteHttp');
//     if (token) {
//       accessToken =
//           await MySharedPreferences.instance.getStringValue("access_token");
//       log(accessToken.toString(), name: "access_token");
//     }

//     final response = await http.delete(
//       Uri.parse(url),
//       headers: accessToken == null
//           ? {'Content-Type': 'application/json'}
//           : {
//               'Content-Type': 'application/json',
//               'Authorization': 'Bearer $accessToken'
//             },
//     );
//     if (response.statusCode == 403 && token) {
//       log(response.statusCode.toString());
//       return refreshToken().then((value) => deleteHttp(api: api, token: token));
//     }
//     return response;
//   }

//   Future<void> refreshToken() async {
//     String? refreshToken =
//         await MySharedPreferences.instance.getStringValue("refresh_token");
//     final url = ApiUrls.baseUrl + ApiUrls.refreshToken;
//     log(refreshToken.toString(), name: 'refreshToken');
//     log(url, name: 'refreshToken URL');

//     final response = await http.post(
//       Uri.parse(url),
//       headers: {
//         'Content-Type': 'application/json',
//         'Authorization': 'Bearer $refreshToken'
//       },
//     );
//     log(response.body, name: 'response refreshToken');
//     String accessToken = json.decode(response.body)['data'];
//     MySharedPreferences.instance.setStringValue("token", accessToken);
//   }

//   Future<http.Response> getRequest({
//     required Map<String, dynamic> data,
//     required String api,
//     bool token = false,
//   }) async {
//     final url = ApiUrls.baseUrl + api;
//     log(url, name: 'getRequest');
//     log(data.toString(), name: '$api data');

//     final headers = {'Content-Type': 'application/json'};

//     final request = http.Request('GET', Uri.parse(url));
//     request.body = json.encode(data);
//     request.headers.addAll(headers);

//     final streamResponse = await request.send();
//     final response = await http.Response.fromStream(streamResponse);

//     if (response.statusCode == 403 && token) {
//       log(response.statusCode.toString());
//       return refreshToken()
//           .then((value) => putHttp(data: data, api: api, token: token));
//     }
//     return response;
//   }

//   Future<http.Response> newPostHttp({
//     required List<Map<String, dynamic>> data,
//     required String api,
//     bool token = false,
//   }) async {
//     String? accessToken;
//     final url = ApiUrls.baseUrl + api;
//     log(url, name: 'postHttp');
//     log(data.toString(), name: '$api data');
//     if (token) {
//       accessToken = await MySharedPreferences.instance.getStringValue("token");
//       log(accessToken.toString(), name: "token");
//     }

//     final response = await http.post(
//       Uri.parse(url),
//       headers: accessToken == null
//           ? {'Content-Type': 'application/json'}
//           : {
//               'Content-Type': 'application/json',
//               'Authorization': 'Bearer $accessToken'
//             },
//       body: json.encode(data),
//     );

//     log(response.statusCode.toString(), name: 'Response Code');

//     if (response.statusCode == 403 || token) {
//       return refreshToken()
//           .then((value) => newPostHttp(data: data, api: api, token: token));
//     }
//     return response;
//   }
// }


import 'dart:convert';
import 'dart:developer';
import 'package:http/http.dart' as http;
import 'package:school_nx_pro/utils/api_urls.dart';
import 'package:school_nx_pro/utils/my_sharepreferences.dart';
import 'package:school_nx_pro/utils/http_client_manager.dart';

class BaseRepository {
  /// Get HTTP client from centralized manager
  /// This ensures proper timeout settings and connection management
  http.Client _createSafeClient() {
    return HttpClientManager.instance.getClient();
  }

  /// ========== POST ==========
  Future<http.Response> postHttp({
    required Map<String, dynamic> data,
    required String api,
    bool token = false,
  }) async {
    String? accessToken;
    final url = ApiUrls.baseUrl + api;
    final client = _createSafeClient();

    log(url, name: 'POST');
    log(data.toString(), name: '$api data');

    if (token) {
      accessToken = await MySharedPreferences.instance.getStringValue("token");
      log(accessToken.toString(), name: "token");
    }

    final response = await client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken'
      },
      body: json.encode(data),
    );

    log(response.statusCode.toString(), name: 'Response Code');

    if (response.statusCode == 403 && token) {
      await refreshToken();
      return postHttp(data: data, api: api, token: token);
    }
    return response;
  }

  /// ========== GET ==========
  Future<http.Response> getHttp({
    required String api,
    bool token = false,
  }) async {
    String? accessToken;
    final url = ApiUrls.baseUrl + api;
    final client = _createSafeClient();

    log(url, name: 'GET');

    if (token) {
      accessToken =
          await MySharedPreferences.instance.getStringValue("token");
      log(accessToken.toString(), name: "token");
    }

    final response = await client.get(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken'
      },
    );

    log(response.statusCode.toString(), name: 'Response Code');

    if (response.statusCode == 403 && token) {
      await refreshToken();
      return getHttp(api: api, token: token);
    }
    return response;
  }

  /// ========== PUT ==========
  Future<http.Response> putHttp({
    required Map<String, dynamic> data,
    required String api,
    bool token = false,
  }) async {
    String? accessToken;
    final url = ApiUrls.baseUrl + api;
    final client = _createSafeClient();

    log(url, name: 'PUT');
    log(data.toString(), name: '$api data');

    if (token) {
      accessToken =
          await MySharedPreferences.instance.getStringValue("token");
      log(accessToken.toString(), name: "token");
    }

    final response = await client.put(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken'
      },
      body: json.encode(data),
    );

    log(response.statusCode.toString(), name: 'Response Code');

    if (response.statusCode == 403 && token) {
      await refreshToken();
      return putHttp(data: data, api: api, token: token);
    }
    return response;
  }

  /// ========== DELETE ==========
  Future<http.Response> deleteHttp({
    required String api,
    bool token = false,
  }) async {
    String? accessToken;
    final url = ApiUrls.baseUrl + api;
    final client = _createSafeClient();

    log(url, name: 'DELETE');

    if (token) {
      accessToken =
          await MySharedPreferences.instance.getStringValue("token");
      log(accessToken.toString(), name: "token");
    }

    final response = await client.delete(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken'
      },
    );

    log(response.statusCode.toString(), name: 'Response Code');

    if (response.statusCode == 403 && token) {
      await refreshToken();
      return deleteHttp(api: api, token: token);
    }
    return response;
  }

  /// ========== Refresh Token ==========
  Future<void> refreshToken() async {
    String? refreshToken =
        await MySharedPreferences.instance.getStringValue("refresh_token");
    final url = ApiUrls.baseUrl + ApiUrls.refreshToken;
    final client = _createSafeClient();

    log(refreshToken.toString(), name: 'refreshToken');
    log(url, name: 'refreshToken URL');

    final response = await client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $refreshToken'
      },
    );

    log(response.body, name: 'response refreshToken');

    try {
      final accessToken = json.decode(response.body)['data'];
      await MySharedPreferences.instance
          .setStringValue("token", accessToken.toString());
    } catch (e) {
      log("Failed to parse refresh token response: $e");
    }
  }

  /// ========== Extra Helpers ==========
  Future<http.Response> getRequest({
    required Map<String, dynamic> data,
    required String api,
    bool token = false,
  }) async {
    final url = ApiUrls.baseUrl + api;
    final client = _createSafeClient();

    log(url, name: 'GET Request');
    log(data.toString(), name: '$api data');

    final request = http.Request('GET', Uri.parse(url))
      ..body = json.encode(data)
      ..headers['Content-Type'] = 'application/json';

    final streamResponse = await client.send(request);
    final response = await http.Response.fromStream(streamResponse);

    if (response.statusCode == 403 && token) {
      await refreshToken();
      return getRequest(data: data, api: api, token: token);
    }
    return response;
  }

  Future<http.Response> newPostHttp({
    required List<Map<String, dynamic>> data,
    required String api,
    bool token = false,
  }) async {
    String? accessToken;
    final url = ApiUrls.baseUrl + api;
    final client = _createSafeClient();

    log(url, name: 'newPostHttp');
    log(data.toString(), name: '$api data');

    if (token) {
      accessToken = await MySharedPreferences.instance.getStringValue("token");
      log(accessToken.toString(), name: "token");
    }

    final response = await client.post(
      Uri.parse(url),
      headers: {
        'Content-Type': 'application/json',
        if (accessToken != null) 'Authorization': 'Bearer $accessToken'
      },
      body: json.encode(data),
    );

    log(response.statusCode.toString(), name: 'Response Code');

    if (response.statusCode == 403 && token) {
      await refreshToken();
      return newPostHttp(data: data, api: api, token: token);
    }
    return response;
  }
}
