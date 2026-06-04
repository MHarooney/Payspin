import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/data/mappers/api_mappers.dart';

void main() {
  group('mapUser', () {
    test('maps the verified phone number and flag from /users/me', () {
      final user = mapUser({
        'id': 'u1',
        'email': '31612345678@phone.payspin.app',
        'displayName': 'Jane Doe',
        'phoneE164': '+31612345678',
        'phoneVerified': true,
        'createdAt': '2026-01-01T10:00:00.000Z',
      });
      expect(user.phoneE164, '+31612345678');
      expect(user.phoneVerified, isTrue);
      expect(user.isPhoneAccount, isTrue);
      // The profile must show the real phone, never the synthetic login email
      // (which is just raw digits and gets mistaken for the IBAN).
      expect(user.contactLabel, '+31612345678');
    });

    test('defaults phone fields when the API omits them', () {
      final user = mapUser({
        'id': 'u2',
        'email': 'real@example.com',
        'displayName': 'Real User',
        'createdAt': '2026-01-01T10:00:00.000Z',
      });
      expect(user.phoneE164, isNull);
      expect(user.phoneVerified, isFalse);
      expect(user.isPhoneAccount, isFalse);
      // Email-registered users still see their email under the name.
      expect(user.contactLabel, 'real@example.com');
    });

    test('hides the synthetic phone-login email when no E.164 is present', () {
      final user = mapUser({
        'id': 'u3',
        'email': '31600000000@phone.payspin.app',
        'createdAt': '2026-01-01T10:00:00.000Z',
      });
      expect(user.isPhoneAccount, isTrue);
      expect(user.contactLabel, isEmpty);
    });
  });


  group('mapPaymentLink', () {
    test('maps all fields including the new MULTI/expiry parity fields', () {
      final link = mapPaymentLink({
        'id': 'l1',
        'shortCode': 'abc',
        'amountCents': 1500,
        'currency': 'EUR',
        'description': 'Dinner',
        'status': 'COLLECTING',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'payUrl': 'https://pay/abc',
        'completedPaymentCount': 2,
        'totalReceivedCents': 3000,
        'linkType': 'MULTI',
        'maxUses': 3,
        'useCount': 2,
        'expiresAt': '2026-02-01T10:00:00.000Z',
      });
      expect(link.linkType, 'MULTI');
      expect(link.maxUses, 3);
      expect(link.useCount, 2);
      expect(link.expiresAt, '2026-02-01T10:00:00.000Z');
      expect(link.amountCents, 1500);
    });

    test('defaults missing optional fields to SINGLE / 0 / null', () {
      final link = mapPaymentLink({
        'id': 'l2',
        'shortCode': 'xyz',
        'currency': 'EUR',
        'status': 'ACTIVE',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'payUrl': 'https://pay/xyz',
      });
      expect(link.linkType, 'SINGLE');
      expect(link.maxUses, isNull);
      expect(link.useCount, 0);
      expect(link.expiresAt, isNull);
      expect(link.amountCents, isNull);
      expect(link.completedPaymentCount, 0);
      expect(link.totalReceivedCents, 0);
    });
  });

  group('mapPaymentLinkDetail', () {
    test('maps payments and parity fields', () {
      final detail = mapPaymentLinkDetail({
        'id': 'l1',
        'shortCode': 'abc',
        'amountCents': 1000,
        'currency': 'EUR',
        'status': 'ACTIVE',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'payUrl': 'https://pay/abc',
        'linkType': 'SINGLE',
        'payments': [
          {
            'id': 'p1',
            'amountCents': 1000,
            'status': 'PROCESSING',
            'payerBankName': 'ING',
            'initiatedAt': '2026-01-01T11:00:00.000Z',
          },
        ],
      });
      expect(detail.payments.length, 1);
      expect(detail.payments.first.status, 'PROCESSING');
      expect(detail.payments.first.payerBankName, 'ING');
      expect(detail.hasPendingPayments, isTrue);
    });

    test('tolerates a missing payments key', () {
      final detail = mapPaymentLinkDetail({
        'id': 'l1',
        'shortCode': 'abc',
        'currency': 'EUR',
        'status': 'SETTLED',
        'createdAt': '2026-01-01T10:00:00.000Z',
        'payUrl': 'https://pay/abc',
      });
      expect(detail.payments, isEmpty);
      expect(detail.hasPendingPayments, isFalse);
    });
  });

  group('mapInstitution / mapBankConnectionStart / mapBankAccount', () {
    test('institution falls back across name/fullName', () {
      final inst = mapInstitution({'id': 'ing', 'fullName': 'ING Bank'});
      expect(inst.name, 'ING Bank');
      expect(inst.fullName, 'ING Bank');

      final bare = mapInstitution({'id': 'x'});
      expect(bare.name, 'Bank');
    });

    test('connection start maps id + url', () {
      final start = mapBankConnectionStart({
        'connectionId': 'c1',
        'authorisationUrl': 'https://bank/auth',
      });
      expect(start.connectionId, 'c1');
      expect(start.authorisationUrl, 'https://bank/auth');
    });

    test('bank account defaults verified + isPrimary to false', () {
      final acc = mapBankAccount({
        'id': 'ba1',
        'ibanLast4': '3000',
        'accountHolder': 'Jane Doe',
      });
      expect(acc.verified, isFalse);
      expect(acc.isPrimary, isFalse);
      expect(acc.ibanLast4, '3000');
    });

    test('bank account maps isPrimary when present', () {
      final acc = mapBankAccount({
        'id': 'ba1',
        'ibanLast4': '3000',
        'accountHolder': 'Jane Doe',
        'verified': true,
        'isPrimary': true,
      });
      expect(acc.isPrimary, isTrue);
      expect(acc.verified, isTrue);
    });
  });
}
