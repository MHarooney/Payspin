import 'dart:convert';

import '../network/api_config.dart';

/// Wraps a non-2xx HTTP response (or a network sentinel).
///
/// The backend's global exception filter returns a JSON body shaped as
/// `{ statusCode, error, message, issues? }`. We parse it best-effort so the
/// UI can surface the real server message instead of a bare status code.
class ApiException implements Exception {
  ApiException(this.statusCode, this.body)
      : serverMessage = _parseMessage(body),
        issues = _parseIssues(body);

  final int statusCode;
  final String body;

  /// Human-readable `message` from the backend, when the body was JSON.
  final String? serverMessage;

  /// Field-level validation issues (`path` + `message`) for 400 responses.
  final List<ApiIssue> issues;

  @override
  String toString() => 'ApiException($statusCode)';

  static Map<String, dynamic>? _decode(String body) {
    if (body.isEmpty || (body[0] != '{' && body[0] != '[')) return null;
    try {
      final decoded = jsonDecode(body);
      return decoded is Map<String, dynamic> ? decoded : null;
    } catch (_) {
      return null;
    }
  }

  static String? _parseMessage(String body) {
    final json = _decode(body);
    final message = json?['message'];
    if (message is String && message.isNotEmpty) return message;
    // Nest sometimes returns message as a list of strings.
    if (message is List && message.isNotEmpty) {
      return message.map((e) => e.toString()).join(', ');
    }
    return null;
  }

  static List<ApiIssue> _parseIssues(String body) {
    final raw = _decode(body)?['issues'];
    if (raw is! List) return const [];
    return raw
        .whereType<Map<String, dynamic>>()
        .map((e) => ApiIssue(
              path: e['path']?.toString() ?? '',
              message: e['message']?.toString() ?? '',
            ))
        .toList();
  }
}

class ApiIssue {
  const ApiIssue({required this.path, required this.message});

  final String path;
  final String message;
}

/// Maps any thrown error to a concise, user-facing message.
String apiErrorMessage(Object error) {
  if (error is! ApiException) return 'Something went wrong';

  // Network sentinels emitted by PayspinApiClient.
  if (error.statusCode == 0) {
    if (error.body == 'CONNECTION_TIMEOUT') {
      return 'Could not reach the server. Check your connection and try again.';
    }
    if (error.body == 'CONNECTION_REFUSED') {
      if (ApiConfig.isLocalHost) {
        return 'Cannot reach the API at ${ApiConfig.baseUrl}. '
            'Start the local backend or run with '
            '--dart-define=API_URL=${ApiConfig.productionUrl}.';
      }
      return 'Cannot reach the server at ${ApiConfig.baseUrl}. Check your connection.';
    }
    return 'Could not reach the server. Check your connection and try again.';
  }

  switch (error.statusCode) {
    case 400:
      // Prefer the first field-level issue, else the server message.
      if (error.issues.isNotEmpty) {
        final first = error.issues.first;
        return first.message.isNotEmpty ? first.message : 'Please check your input.';
      }
      return error.serverMessage ?? 'Please check your input.';
    case 401:
      // The backend sends a generic "Unauthorized"; prefer a friendly message.
      final msg = error.serverMessage;
      if (msg == null || msg.toLowerCase() == 'unauthorized') {
        return 'Your session expired. Please log in again.';
      }
      return msg;
    case 403:
      return error.serverMessage ?? 'You are not allowed to do that.';
    case 404:
      return error.serverMessage ?? 'Not found.';
    case 409:
      return error.serverMessage ?? 'That conflicts with something that already exists.';
    case 429:
      return 'Too many attempts. Please wait a minute and try again.';
    case 502:
    case 503:
      return 'The bank connection is temporarily unavailable. Please try again.';
    default:
      if (error.statusCode >= 500) {
        return 'Something went wrong on our end. Please try again.';
      }
      return error.serverMessage ?? 'Something went wrong (${error.statusCode})';
  }
}
