import '../entities/payment_link.dart';

abstract class PaymentLinkRepository {
  Future<List<PaymentLink>> listLinks();
  Future<PaymentLink> createLink({int? amountCents, String? description});
  Future<PaymentLinkDetail> getLink(String id);
  Future<void> cancelLink(String id);
}
