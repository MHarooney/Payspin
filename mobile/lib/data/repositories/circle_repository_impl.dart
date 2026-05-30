import '../../core/state/circles_refresh_notifier.dart';
import '../../domain/entities/circle.dart';
import '../../domain/repositories/circle_repository.dart';
import '../datasources/payspin_api_client.dart';
import '../mappers/api_mappers.dart';

class CircleRepositoryImpl implements CircleRepository {
  CircleRepositoryImpl(this._api, this._refresh);

  final PayspinApiClient _api;
  final CirclesRefreshNotifier _refresh;

  @override
  Future<List<Circle>> listCircles() async {
    final list = await _api.listCircles();
    return list.map((e) => mapCircleSummary(e as Map<String, dynamic>)).toList();
  }

  @override
  Future<Circle> createCircle({
    required String name,
    required int contributionCents,
    required int cycleDurationDays,
    required int memberCount,
  }) async {
    final json = await _api.createCircle(
      name: name,
      contributionCents: contributionCents,
      cycleDurationDays: cycleDurationDays,
      memberCount: memberCount,
    );
    _refresh.bump();
    return mapCircleSummary(json);
  }

  @override
  Future<Circle> getCircle(String id) async {
    final json = await _api.getCircle(id);
    return mapCircleDetail(json);
  }

  @override
  Future<Circle> joinCircle(String inviteCode) async {
    final json = await _api.joinCircle(inviteCode);
    _refresh.bump();
    return mapCircleSummary(json);
  }

  @override
  Future<Circle> activateCircle(String id) async {
    final json = await _api.activateCircle(id);
    _refresh.bump();
    return mapCircleDetail(json);
  }

  @override
  Future<Circle> advanceRound(String id) async {
    final json = await _api.advanceCircleRound(id);
    _refresh.bump();
    return mapCircleDetail(json);
  }

  @override
  Future<String> createContributionLink(String id) async {
    final json = await _api.createCircleContributionLink(id);
    return json['payUrl'] as String;
  }
}
