import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../models/kyc_models.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient._();
  static final ApiClient instance = ApiClient._();

  /// Override with: flutter run --dart-define=API_BASE=http://192.168.1.10:8000
  static const _envBase = String.fromEnvironment('API_BASE');

  String get baseUrl {
    if (_envBase.isNotEmpty) return _envBase;
    if (!kIsWeb && Platform.isAndroid) return 'http://10.0.2.2:8000';
    return 'http://localhost:8000';
  }

  Uri _uri(String path) => Uri.parse('$baseUrl$path');

  /// Absolute URL for a backend-relative upload path.
  String fileUrl(String path) => path.startsWith('http')
      ? path
      : '$baseUrl/${path.replaceFirst(RegExp(r'^/'), '')}';

  Future<String> submitApplication({
    required String firstName,
    required String lastName,
    required String dob,
    required File document,
    required File selfie,
  }) async {
    final request = http.MultipartRequest('POST', _uri('/api/kyc/apply'))
      ..fields['first_name'] = firstName
      ..fields['last_name'] = lastName
      ..fields['dob'] = dob
      ..files.add(await http.MultipartFile.fromPath('document', document.path))
      ..files.add(await http.MultipartFile.fromPath('selfie', selfie.path));

    final response = await http.Response.fromStream(
      await request.send().timeout(const Duration(seconds: 30)),
    );
    _ensureOk(response, 'submit your application');
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['application_id'] as String;
  }

  Future<ApplicationStatus> getStatus(String applicationId) async {
    final response = await http
        .get(_uri('/api/kyc/$applicationId/status'))
        .timeout(const Duration(seconds: 15));
    _ensureOk(response, 'fetch the application status');
    return ApplicationStatus.fromJson(
      jsonDecode(response.body) as Map<String, dynamic>,
    );
  }

  Future<List<ApplicationSummary>> listApplications() async {
    final response = await http
        .get(_uri('/api/kyc/applications'))
        .timeout(const Duration(seconds: 15));
    _ensureOk(response, 'load the review queue');
    final items = jsonDecode(response.body) as List<dynamic>;
    return items
        .map((e) => ApplicationSummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> reviewApplication(String applicationId, String decision) async {
    final response = await http
        .post(
          _uri('/api/kyc/$applicationId/review'),
          body: {'decision': decision},
        )
        .timeout(const Duration(seconds: 15));
    _ensureOk(response, 'save the review decision');
  }

  void _ensureOk(http.Response response, String action) {
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw ApiException(
        'Could not $action (server replied ${response.statusCode}). '
        'Check that the KYC server is running and try again.',
      );
    }
  }
}
