import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/payment_link_repository.dart';
import '../datasources/payspin_api_client.dart';
import '../mappers/api_mappers.dart';

class PaymentLinkRepositoryImpl implements PaymentLinkRepository {
  PaymentLinkRepositoryImpl(this._api);

  final PayspinApiClient _api;

  @override
  Future<List<PaymentLink>> listLinks() async {
    final list = await _api.listLinks();
    return list.map((e) => mapPaymentLink(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<PaymentLink> createLink({int? amountCents, String? description}) async {
    final json = await _api.createLink(amountCents: amountCents, description: description);
    return mapPaymentLink(json);
  }

  @override
  Future<PaymentLinkDetail> getLink(String id) async {
    final json = await _api.getLink(id);
    return mapPaymentLinkDetail(json);
  }

  @override
  Future<void> cancelLink(String id) => _api.cancelLink(id);
}
