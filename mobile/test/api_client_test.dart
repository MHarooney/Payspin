import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:payspin_mobile/core/errors/api_exception.dart';
import 'package:payspin_mobile/data/datasources/payspin_api_client.dart';

import 'helpers/fakes.dart';

PayspinApiClient _client(
  MockClient mock, {
  FakeTokenStorage? storage,
}) =>
    PayspinApiClient(client: mock, storage: storage ?? FakeTokenStorage());

void main() {
  group('PayspinApiClient auth header', () {
    test('attaches Bearer token when one is stored', () async {
      String? seenAuth;
      final mock = MockClient((req) async {
        seenAuth = req.headers['Authorization'];
        return http.Response(jsonEncode([]), 200);
      });
      await _client(mock, storage: FakeTokenStorage('tok-123')).listLinks();
      expect(seenAuth, 'Bearer tok-123');
    });

    test('omits Authorization when no token is stored', () async {
      String? seenAuth = 'sentinel';
      final mock = MockClient((req) async {
        seenAuth = req.headers['Authorization'];
        return http.Response(jsonEncode([]), 200);
      });
      await _client(mock).listLinks();
      expect(seenAuth, isNull);
    });
  });

  group('401 handling', () {
    test('deletes the stored token and throws', () async {
      final storage = FakeTokenStorage('stale');
      final mock = MockClient((req) async => http.Response('Unauthorized', 401));
      await expectLater(
        _client(mock, storage: storage).getMe(),
        throwsA(isA<ApiException>().having((e) => e.statusCode, 'status', 401)),
      );
      expect(storage.deleteCount, 1);
      expect(await storage.read(), isNull);
    });
  });

  group('error body propagation', () {
    test('throws ApiException carrying the server body', () async {
      final mock = MockClient(
        (req) async => http.Response(jsonEncode({'message': 'Nope'}), 409),
      );
      try {
        await _client(mock).createLink(amountCents: 100);
        fail('expected throw');
      } on ApiException catch (e) {
        expect(e.statusCode, 409);
        expect(e.serverMessage, 'Nope');
      }
    });
  });

  group('network sentinels', () {
    test('timeout maps to CONNECTION_TIMEOUT', () async {
      final mock = MockClient((req) async => throw TimeoutException('slow'));
      try {
        await _client(mock).listLinks();
        fail('expected throw');
      } on ApiException catch (e) {
        expect(e.statusCode, 0);
        expect(e.body, 'CONNECTION_TIMEOUT');
      }
    });

    test('socket error maps to CONNECTION_REFUSED', () async {
      final mock = MockClient((req) async => throw const SocketException('refused'));
      try {
        await _client(mock).listLinks();
        fail('expected throw');
      } on ApiException catch (e) {
        expect(e.statusCode, 0);
        expect(e.body, 'CONNECTION_REFUSED');
      }
    });
  });

  group('happy-path payloads', () {
    test('register stores the returned access token', () async {
      final storage = FakeTokenStorage();
      final mock = MockClient(
        (req) async => http.Response(
          jsonEncode({'accessToken': 'new-tok', 'user': {}}),
          201,
        ),
      );
      await _client(mock, storage: storage).register(email: 'a@b.com', password: 'pw');
      expect(await storage.read(), 'new-tok');
    });

    test('createLink sends amount/description/currency and parses result', () async {
      Map<String, dynamic>? sentBody;
      final mock = MockClient((req) async {
        sentBody = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'id': 'l1'}), 201);
      });
      final res = await _client(mock).createLink(amountCents: 500, description: 'Lunch');
      expect(res['id'], 'l1');
      expect(sentBody!['amountCents'], 500);
      expect(sentBody!['description'], 'Lunch');
      expect(sentBody!['currency'], 'EUR');
    });

    test('cancelLink issues a DELETE to the link path', () async {
      String? method;
      String? path;
      final mock = MockClient((req) async {
        method = req.method;
        path = req.url.path;
        return http.Response('', 204);
      });
      await _client(mock).cancelLink('abc');
      expect(method, 'DELETE');
      expect(path, endsWith('/links/abc'));
    });

    test('listInstitutions forwards the country query param', () async {
      String? country;
      final mock = MockClient((req) async {
        country = req.url.queryParameters['country'];
        return http.Response(jsonEncode([]), 200);
      });
      await _client(mock).listInstitutions(country: 'NL');
      expect(country, 'NL');
    });

    test('connectBank posts institutionId and parses connection start', () async {
      Map<String, dynamic>? sent;
      final mock = MockClient((req) async {
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(
          jsonEncode({'connectionId': 'c1', 'authorisationUrl': 'https://bank/auth'}),
          200,
        );
      });
      final res = await _client(mock).connectBank(institutionId: 'ing');
      expect(sent!['institutionId'], 'ing');
      expect(res['connectionId'], 'c1');
    });

    test('completeBankConnection posts the consent payload', () async {
      Map<String, dynamic>? sent;
      final mock = MockClient((req) async {
        sent = jsonDecode(req.body) as Map<String, dynamic>;
        return http.Response(jsonEncode({'id': 'ba1'}), 200);
      });
      await _client(mock).completeBankConnection(
        connectionId: 'c1',
        consentToken: 'consent',
        expectedIban: 'NL00BANK',
      );
      expect(sent!['connectionId'], 'c1');
      expect(sent!['consentToken'], 'consent');
      expect(sent!['expectedIban'], 'NL00BANK');
    });
  });
}
