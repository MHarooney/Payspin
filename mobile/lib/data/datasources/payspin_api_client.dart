import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../../core/errors/api_exception.dart';
import '../../core/network/api_config.dart';
import '../../core/storage/secure_token_storage.dart';

class PayspinApiClient {
  PayspinApiClient({http.Client? client, SecureTokenStorage? storage})
      : _client = client ?? http.Client(),
        _storage = storage ?? SecureTokenStorage();

  final http.Client _client;
  final SecureTokenStorage _storage;
  static const _timeout = Duration(seconds: 15);

  Future<http.Response> _send(Future<http.Response> request) async {
    try {
      return await request.timeout(_timeout);
    } on TimeoutException {
      throw ApiException(0, 'CONNECTION_TIMEOUT');
    } on SocketException {
      throw ApiException(0, 'CONNECTION_REFUSED');
    }
  }

  Future<Map<String, String>> _headers({bool auth = true}) async {
    final headers = <String, String>{'Content-Type': 'application/json'};
    if (auth) {
      final token = await _storage.read();
      if (token != null && token.isNotEmpty) headers['Authorization'] = 'Bearer $token';
    }
    return headers;
  }

  void _ensureOk(http.Response res) {
    if (res.statusCode >= 400) throw ApiException(res.statusCode, res.body);
  }

  Future<Map<String, dynamic>> register({
    required String email,
    required String password,
    String? displayName,
  }) async {
    final res = await _send(_client.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/register'),
      headers: await _headers(auth: false),
      body: jsonEncode({
        'email': email,
        'password': password,
        if (displayName != null) 'displayName': displayName,
      }),
    ));
    _ensureOk(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    await _storage.write(json['accessToken'] as String);
    return json;
  }

  Future<Map<String, dynamic>> login({required String email, required String password}) async {
    final res = await _send(_client.post(
      Uri.parse('${ApiConfig.baseUrl}/auth/login'),
      headers: await _headers(auth: false),
      body: jsonEncode({'email': email, 'password': password}),
    ));
    _ensureOk(res);
    final json = jsonDecode(res.body) as Map<String, dynamic>;
    await _storage.write(json['accessToken'] as String);
    return json;
  }

  Future<void> signOut() => _storage.delete();

  Future<bool> hasToken() => _storage.hasToken();

  Future<Map<String, dynamic>> getMe() async {
    final res = await _send(_client.get(Uri.parse('${ApiConfig.baseUrl}/users/me'), headers: await _headers()));
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> updateProfile({required String displayName}) async {
    final res = await _send(_client.patch(
      Uri.parse('${ApiConfig.baseUrl}/users/me'),
      headers: await _headers(),
      body: jsonEncode({'displayName': displayName}),
    ));
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<List<dynamic>> listLinks() async {
    final res = await _send(_client.get(Uri.parse('${ApiConfig.baseUrl}/links'), headers: await _headers()));
    _ensureOk(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> createLink({int? amountCents, String? description}) async {
    final res = await _send(_client.post(
      Uri.parse('${ApiConfig.baseUrl}/links'),
      headers: await _headers(),
      body: jsonEncode({
        if (amountCents != null) 'amountCents': amountCents,
        if (description != null) 'description': description,
        'currency': 'EUR',
      }),
    ));
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> getLink(String id) async {
    final res = await _send(_client.get(Uri.parse('${ApiConfig.baseUrl}/links/$id'), headers: await _headers()));
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }

  Future<void> cancelLink(String id) async {
    final res = await _send(_client.delete(Uri.parse('${ApiConfig.baseUrl}/links/$id'), headers: await _headers()));
    _ensureOk(res);
  }

  Future<List<dynamic>> listBankAccounts() async {
    final res = await _send(_client.get(Uri.parse('${ApiConfig.baseUrl}/bank-accounts'), headers: await _headers()));
    _ensureOk(res);
    return jsonDecode(res.body) as List<dynamic>;
  }

  Future<Map<String, dynamic>> addBankAccount({
    required String iban,
    required String accountHolder,
    String? bankName,
  }) async {
    final res = await _send(_client.post(
      Uri.parse('${ApiConfig.baseUrl}/bank-accounts'),
      headers: await _headers(),
      body: jsonEncode({
        'iban': iban,
        'accountHolder': accountHolder,
        if (bankName != null) 'bankName': bankName,
      }),
    ));
    _ensureOk(res);
    return jsonDecode(res.body) as Map<String, dynamic>;
  }
}
