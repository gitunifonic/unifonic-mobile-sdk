import 'dart:convert';

import 'package:http/http.dart' as http;

import '../model/notification_update.dart';

class HttpService {
  final String _baseUrl =
      // "https://8ef1-178-220-181-108.ngrok-free.app"; //DotEnv().env['BASE_URL']!;
      "https://push-notification-api.prod.cloud.unifonic.com";
  final Map<String, String> _headers = {};

  HttpService() {
    _headers.addAll({
      'Content-Type': 'application/json',
      'api_key': '' //DotEnv().env['api_key']!
    });
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final Map<String, dynamic> data = json.decode(response.body);

    if (response.statusCode >= 200 && response.statusCode <= 205) {
      // Successful response
      return data;
    } else {
      // Handle error
      throw Exception('Failed to make POST request: ${response.statusCode}');
    }
  }

  registerDevice(Map<String, dynamic> deviceInfoRequestDTO) async {
    final response = await http.post(Uri.parse('$_baseUrl/api/v1/device-info/'),
        body: json.encode(deviceInfoRequestDTO), headers: _headers);

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> unregisterDevice(
      String id, String userId) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/v1/device-info/$id/$userId'),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> updateLocation(
      Map<String, dynamic> deviceInfoRequestDTO) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/v1/device-info/'),
      body: json.encode(deviceInfoRequestDTO),
      headers: _headers,
    );

    return _handleResponse(response);
  }

  updateStatus(NotificationUpdateModel notificationUpdateModel) async {
    // @TODO get accountId from env variables
    String accountId = '4fb25f62-d908-40f5-a932-6e40870d9907';
    final response = await http.patch(
      Uri.parse(
          "$_baseUrl/api/v1/notification/update-status?accountId=$accountId"),
      body: jsonEncode(notificationUpdateModel),
      headers: _headers,
    );

    return _handleResponse(response);
  }
}
