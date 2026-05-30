import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/domain/entities/payment_link.dart';

PaymentLink _link({
  int? amountCents = 1000,
  String status = 'ACTIVE',
  String linkType = 'SINGLE',
  int? maxUses,
  int useCount = 0,
  String? expiresAt,
}) =>
    PaymentLink(
      id: 'l1',
      shortCode: 'abc',
      amountCents: amountCents,
      currency: 'EUR',
      status: status,
      createdAt: '2026-01-01T10:00:00.000Z',
      payUrl: 'https://pay/abc',
      completedPaymentCount: 0,
      totalReceivedCents: 0,
      linkType: linkType,
      maxUses: maxUses,
      useCount: useCount,
      expiresAt: expiresAt,
    );

void main() {
  group('amountLabel', () {
    test('formats euros', () {
      expect(_link(amountCents: 1234).amountLabel, '€12.34');
    });
    test('open amount when null', () {
      expect(_link(amountCents: null).amountLabel, 'Open amount');
    });
  });

  group('statusLabel', () {
    test('known statuses incl COLLECTING', () {
      expect(_link(status: 'ACTIVE').statusLabel, 'Active');
      expect(_link(status: 'COLLECTING').statusLabel, 'Collecting');
      expect(_link(status: 'SETTLED').statusLabel, 'Paid');
      expect(_link(status: 'EXPIRED').statusLabel, 'Expired');
      expect(_link(status: 'CANCELLED').statusLabel, 'Cancelled');
    });
    test('unknown status passes through', () {
      expect(_link(status: 'WEIRD').statusLabel, 'WEIRD');
    });
  });

  group('usageLabel (MULTI summary)', () {
    test('null for SINGLE links', () {
      expect(_link(linkType: 'SINGLE').usageLabel, isNull);
    });
    test('capped MULTI shows used X of N', () {
      expect(_link(linkType: 'MULTI', maxUses: 3, useCount: 1).usageLabel, 'Used 1 of 3');
    });
    test('uncapped MULTI shows X received', () {
      expect(_link(linkType: 'MULTI', useCount: 4).usageLabel, '4 received');
    });
  });

  group('payability / cancellability', () {
    test('ACTIVE non-expired is payable and cancellable', () {
      final l = _link(status: 'ACTIVE');
      expect(l.isPayable, isTrue);
      expect(l.canCancel, isTrue);
    });
    test('COLLECTING is payable and cancellable', () {
      final l = _link(status: 'COLLECTING');
      expect(l.isPayable, isTrue);
      expect(l.canCancel, isTrue);
    });
    test('SETTLED is neither', () {
      final l = _link(status: 'SETTLED');
      expect(l.isPayable, isFalse);
      expect(l.canCancel, isFalse);
    });
    test('past expiresAt makes an ACTIVE link non-payable', () {
      final l = _link(status: 'ACTIVE', expiresAt: '2000-01-01T00:00:00.000Z');
      expect(l.isExpired, isTrue);
      expect(l.isPayable, isFalse);
    });
    test('future expiresAt stays payable', () {
      final l = _link(status: 'ACTIVE', expiresAt: '2999-01-01T00:00:00.000Z');
      expect(l.isExpired, isFalse);
      expect(l.isPayable, isTrue);
    });
    test('unparseable expiresAt falls back to status', () {
      final l = _link(status: 'ACTIVE', expiresAt: 'not-a-date');
      expect(l.isExpired, isFalse);
    });
  });

  group('paymentStatusLabel', () {
    test('maps known enum values', () {
      expect(paymentStatusLabel('AWAITING_AUTHORIZATION'), 'Awaiting bank');
      expect(paymentStatusLabel('PENDING'), 'Pending');
      expect(paymentStatusLabel('PROCESSING'), 'Processing');
      expect(paymentStatusLabel('COMPLETED'), 'Paid');
      expect(paymentStatusLabel('FAILED'), 'Failed');
      expect(paymentStatusLabel('CANCELLED'), 'Cancelled');
    });
    test('passes through unknowns', () {
      expect(paymentStatusLabel('SOMETHING'), 'SOMETHING');
    });
  });

  group('PaymentRecord', () {
    test('isTerminal for COMPLETED/FAILED/CANCELLED only', () {
      PaymentRecord rec(String s) => PaymentRecord(
            id: 'p',
            amountCents: 100,
            status: s,
            initiatedAt: '2026-01-01T10:00:00.000Z',
          );
      expect(rec('COMPLETED').isTerminal, isTrue);
      expect(rec('FAILED').isTerminal, isTrue);
      expect(rec('CANCELLED').isTerminal, isTrue);
      expect(rec('PENDING').isTerminal, isFalse);
      expect(rec('PROCESSING').isTerminal, isFalse);
      expect(rec('PENDING').statusLabel, 'Pending');
    });
  });

  group('PaymentLinkDetail.hasPendingPayments', () {
    PaymentLinkDetail detail(List<String> statuses) => PaymentLinkDetail(
          id: 'l1',
          shortCode: 'abc',
          amountCents: 100,
          currency: 'EUR',
          status: 'ACTIVE',
          createdAt: '2026-01-01T10:00:00.000Z',
          payUrl: 'https://pay/abc',
          completedPaymentCount: 0,
          totalReceivedCents: 0,
          payments: [
            for (final s in statuses)
              PaymentRecord(id: s, amountCents: 100, status: s, initiatedAt: '2026-01-01T10:00:00.000Z'),
          ],
        );

    test('true while any payment is non-terminal', () {
      expect(detail(['COMPLETED', 'PROCESSING']).hasPendingPayments, isTrue);
    });
    test('false when all terminal or empty', () {
      expect(detail(['COMPLETED', 'FAILED']).hasPendingPayments, isFalse);
      expect(detail([]).hasPendingPayments, isFalse);
    });
  });
}
