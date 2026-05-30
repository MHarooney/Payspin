import '../../core/state/links_refresh_notifier.dart';
import '../../domain/entities/payment_link.dart';
import '../../domain/repositories/payment_link_repository.dart';
import '../datasources/payspin_api_client.dart';
import '../mappers/api_mappers.dart';

class PaymentLinkRepositoryImpl implements PaymentLinkRepository {
  PaymentLinkRepositoryImpl(this._api, this._refresh);

  final PayspinApiClient _api;
  final LinksRefreshNotifier _refresh;

  @override
  Future<List<PaymentLink>> listLinks() async {
    final list = await _api.listLinks();
    return list.map((e) => mapPaymentLink(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<PaymentLink> createLink({int? amountCents, String? description}) async {
    final json = await _api.createLink(amountCents: amountCents, description: description);
    _refresh.bump();
    return mapPaymentLink(json);
  }

  @override
  Future<PaymentLinkDetail> getLink(String id) async {
    final json = await _api.getLink(id);
    return mapPaymentLinkDetail(json);
  }

  @override
  Future<void> cancelLink(String id) async {
    await _api.cancelLink(id);
    _refresh.bump();
  }
}
