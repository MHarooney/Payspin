import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/errors/api_exception.dart';

void main() {
  group('ApiException parsing', () {
    test('parses string message and issues from a 400 body', () {
      final body = jsonEncode({
        'statusCode': 400,
        'message': 'Validation failed',
        'issues': [
          {'path': 'amountCents', 'message': 'Amount must be positive'},
          {'path': 'description', 'message': 'Too long'},
        ],
      });
      final ex = ApiException(400, body);
      expect(ex.serverMessage, 'Validation failed');
      expect(ex.issues.length, 2);
      expect(ex.issues.first.path, 'amountCents');
      expect(ex.issues.first.message, 'Amount must be positive');
    });

    test('joins a list-shaped message (Nest style)', () {
      final body = jsonEncode({
        'message': ['email must be an email', 'password too short'],
      });
      final ex = ApiException(400, body);
      expect(ex.serverMessage, 'email must be an email, password too short');
    });

    test('tolerates a non-JSON / malformed body', () {
      final ex = ApiException(500, '<html>502 Bad Gateway</html>');
      expect(ex.serverMessage, isNull);
      expect(ex.issues, isEmpty);
    });

    test('tolerates an empty body', () {
      final ex = ApiException(204, '');
      expect(ex.serverMessage, isNull);
      expect(ex.issues, isEmpty);
    });

    test('ignores issues that are not a list', () {
      final ex = ApiException(400, jsonEncode({'issues': 'nope'}));
      expect(ex.issues, isEmpty);
    });
  });

  group('apiErrorMessage', () {
    test('non-ApiException maps to a generic message', () {
      expect(apiErrorMessage(Exception('boom')), 'Something went wrong');
    });

    test('network sentinels', () {
      expect(
        apiErrorMessage(ApiException(0, 'CONNECTION_TIMEOUT')),
        contains('Could not reach the server'),
      );
      expect(
        apiErrorMessage(ApiException(0, 'CONNECTION_REFUSED')),
        contains('Connection refused'),
      );
      expect(
        apiErrorMessage(ApiException(0, 'unknown')),
        contains('Could not reach the server'),
      );
    });

    test('400 prefers the first field issue, then server message', () {
      final withIssue = ApiException(
        400,
        jsonEncode({
          'message': 'Validation failed',
          'issues': [
            {'path': 'iban', 'message': 'Invalid IBAN'},
          ],
        }),
      );
      expect(apiErrorMessage(withIssue), 'Invalid IBAN');

      final noIssue = ApiException(400, jsonEncode({'message': 'Bad request'}));
      expect(apiErrorMessage(noIssue), 'Bad request');

      final empty = ApiException(400, '');
      expect(apiErrorMessage(empty), 'Please check your input.');
    });

    test('401 prefers a friendly session-expired message for generic body', () {
      expect(
        apiErrorMessage(ApiException(401, jsonEncode({'message': 'Unauthorized'}))),
        contains('session expired'),
      );
      expect(
        apiErrorMessage(ApiException(401, '')),
        contains('session expired'),
      );
      expect(
        apiErrorMessage(ApiException(401, jsonEncode({'message': 'Token revoked'}))),
        'Token revoked',
      );
    });

    test('403 / 404 / 409 surface server message or sensible defaults', () {
      expect(apiErrorMessage(ApiException(403, '')), 'You are not allowed to do that.');
      expect(apiErrorMessage(ApiException(404, '')), 'Not found.');
      expect(
        apiErrorMessage(ApiException(409, '')),
        contains('conflicts'),
      );
      expect(
        apiErrorMessage(ApiException(404, jsonEncode({'message': 'Link not found'}))),
        'Link not found',
      );
    });

    test('429 and 502/503 have fixed friendly copy', () {
      expect(apiErrorMessage(ApiException(429, '')), contains('Too many attempts'));
      expect(apiErrorMessage(ApiException(502, '')), contains('temporarily unavailable'));
      expect(apiErrorMessage(ApiException(503, '')), contains('temporarily unavailable'));
    });

    test('generic 5xx and unknown 4xx', () {
      expect(apiErrorMessage(ApiException(500, '')), contains('on our end'));
      expect(
        apiErrorMessage(ApiException(418, jsonEncode({'message': 'teapot'}))),
        'teapot',
      );
      expect(apiErrorMessage(ApiException(418, '')), contains('418'));
    });
  });
}
