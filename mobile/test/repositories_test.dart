import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:payspin_mobile/core/errors/api_exception.dart';
import 'package:payspin_mobile/core/state/links_refresh_notifier.dart';
import 'package:payspin_mobile/data/datasources/payspin_api_client.dart';
import 'package:payspin_mobile/data/repositories/bank_account_repository_impl.dart';
import 'package:payspin_mobile/data/repositories/payment_link_repository_impl.dart';

import 'helpers/fakes.dart';

PayspinApiClient _api(MockClient mock) =>
    PayspinApiClient(client: mock, storage: FakeTokenStorage('tok'));

void main() {
  group('PaymentLinkRepositoryImpl', () {
    test('listLinks maps a list of payment links', () async {
      final mock = MockClient(
        (req) async => http.Response(
          jsonEncode([
            {
              'id': 'l1',
              'shortCode': 'abc',
              'amountCents': 1000,
              'currency': 'EUR',
              'status': 'ACTIVE',
              'createdAt': '2026-01-01T10:00:00.000Z',
              'payUrl': 'https://pay/abc',
            },
          ]),
          200,
        ),
      );
      final repo = PaymentLinkRepositoryImpl(_api(mock), LinksRefreshNotifier());
      final links = await repo.listLinks();
      expect(links, hasLength(1));
      expect(links.first.id, 'l1');
    });

    test('createLink bumps the refresh notifier', () async {
      final mock = MockClient(
        (req) async => http.Response(
          jsonEncode({
            'id': 'l1',
            'shortCode': 'abc',
            'currency': 'EUR',
            'status': 'ACTIVE',
            'createdAt': '2026-01-01T10:00:00.000Z',
            'payUrl': 'https://pay/abc',
          }),
          201,
        ),
      );
      final notifier = LinksRefreshNotifier();
      final repo = PaymentLinkRepositoryImpl(_api(mock), notifier);
      expect(notifier.value, 0);
      await repo.createLink(amountCents: 100);
      expect(notifier.value, 1);
    });

    test('cancelLink bumps the refresh notifier', () async {
      final mock = MockClient((req) async => http.Response('', 204));
      final notifier = LinksRefreshNotifier();
      final repo = PaymentLinkRepositoryImpl(_api(mock), notifier);
      await repo.cancelLink('l1');
      expect(notifier.value, 1);
    });

    test('createLink failure does NOT bump and propagates ApiException', () async {
      final mock = MockClient(
        (req) async => http.Response(jsonEncode({'message': 'Bad'}), 400),
      );
      final notifier = LinksRefreshNotifier();
      final repo = PaymentLinkRepositoryImpl(_api(mock), notifier);
      await expectLater(repo.createLink(), throwsA(isA<ApiException>()));
      expect(notifier.value, 0);
    });

    test('getLink maps detail', () async {
      final mock = MockClient(
        (req) async => http.Response(
          jsonEncode({
            'id': 'l1',
            'shortCode': 'abc',
            'amountCents': 1000,
            'currency': 'EUR',
            'status': 'ACTIVE',
            'createdAt': '2026-01-01T10:00:00.000Z',
            'payUrl': 'https://pay/abc',
            'payments': [],
          }),
          200,
        ),
      );
      final repo = PaymentLinkRepositoryImpl(_api(mock), LinksRefreshNotifier());
      final detail = await repo.getLink('l1');
      expect(detail.id, 'l1');
      expect(detail.payments, isEmpty);
    });
  });

  group('BankAccountRepositoryImpl', () {
    test('startConnect maps connection start', () async {
      final mock = MockClient(
        (req) async => http.Response(
          jsonEncode({'connectionId': 'c1', 'authorisationUrl': 'https://bank/auth'}),
          200,
        ),
      );
      final repo = BankAccountRepositoryImpl(_api(mock));
      final start = await repo.startConnect(institutionId: 'ing');
      expect(start.connectionId, 'c1');
      expect(start.authorisationUrl, 'https://bank/auth');
    });

    test('completeConnect maps the resulting bank account', () async {
      final mock = MockClient(
        (req) async => http.Response(
          jsonEncode({
            'id': 'ba1',
            'ibanLast4': '3000',
            'accountHolder': 'Jane Doe',
            'verified': true,
          }),
          200,
        ),
      );
      final repo = BankAccountRepositoryImpl(_api(mock));
      final acc = await repo.completeConnect(connectionId: 'c1', consentToken: 'consent');
      expect(acc.id, 'ba1');
      expect(acc.verified, isTrue);
    });

    test('listInstitutions propagates errors', () async {
      final mock = MockClient((req) async => http.Response('boom', 502));
      final repo = BankAccountRepositoryImpl(_api(mock));
      await expectLater(repo.listInstitutions(), throwsA(isA<ApiException>()));
    });
  });
}
