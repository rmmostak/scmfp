import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:scmfp/common/constants.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/api_response.dart';
import '../models/user.dart';

Future<APIResponse> login(String phone, String password) async {
  APIResponse apiResponse = APIResponse();
  try {
    final response = await http.post(Uri.parse(loginURL),
        headers: {'Accept': 'application/json'},
        body: {'phone': phone, 'password': password});

    switch (response.statusCode) {
      case 200:
        apiResponse.data = User.fromJson(jsonDecode(response.body));
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[0][0];
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        break;
      default:
        apiResponse.error = somethingWrong;
        break;
    }
  } catch (e) {
    apiResponse.error = serverError;
  }
  return apiResponse;
}

Future<APIResponse> register(
    String name, String phone, String password, String confirm) async {
  APIResponse apiResponse = APIResponse();
  try {
    final response = await http.post(Uri.parse(regURL), headers: {
      'Accept': 'application/json'
    }, body: {
      'name': name,
      'phone': phone,
      'password': password,
      'password_confirmation': confirm
    });
    print('$regURL \t ${response.statusCode} \t ${response.body}');
    switch (response.statusCode) {
      case 200:
        apiResponse.data = User.fromJson(jsonDecode(response.body));
        break;
      case 422:
        final errors = jsonDecode(response.body)['errors'];
        apiResponse.error = errors[0][0];
        break;
      case 403:
        apiResponse.error = jsonDecode(response.body)['message'];
        break;
      default:
        apiResponse.error = somethingWrong;
        break;
    }
  } catch (e) {
    apiResponse.error = serverError;
  }
  return apiResponse;
}

Future<APIResponse> userDetails() async {
  APIResponse apiResponse = APIResponse();
  try {
    String token = await getToken();
    final response = await http.get(Uri.parse(userURL), headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    });
    print('$userURL, \t${response.statusCode}');
    switch (response.statusCode) {
      case 200:
        apiResponse.data = User.fromJson(jsonDecode(response.body));
        break;
      case 401:
        apiResponse.error = unAuthError;
        break;
      default:
        apiResponse.error = somethingWrong;
        break;
    }
  } catch (e) {
    apiResponse.error = serverError;
  }
  return apiResponse;
}

Future<APIResponse> decisionHistory() async {
  APIResponse apiResponse = APIResponse();
  try {
    String token = await getToken();
    final response = await http.get(Uri.parse(historyURL), headers: {
      'Accept': 'application/json',
      'Authorization': 'Bearer $token'
    });

    switch (response.statusCode) {
      case 200:
        apiResponse.data = User.fromJson(jsonDecode(response.body));
        break;
      case 401:
        apiResponse.error = unAuthError;
        break;
      default:
        apiResponse.error = somethingWrong;
        break;
    }
  } catch (e) {
    apiResponse.error = serverError;
  }
  return apiResponse;
}

Future<String> getToken() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getString('token') ?? '';
}

Future<int> getUserId() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.getInt('userId') ?? 0;
}

Future<bool> logout() async {
  SharedPreferences preferences = await SharedPreferences.getInstance();
  return preferences.remove('token');
}
