import '../entities/circle.dart';

abstract class CircleRepository {
  Future<List<Circle>> listCircles();
  Future<Circle> createCircle({
    required String name,
    required int contributionCents,
    required int cycleDurationDays,
    required int memberCount,
  });
  Future<Circle> getCircle(String id);
  Future<Circle> joinCircle(String inviteCode);
  Future<Circle> activateCircle(String id);
  Future<Circle> advanceRound(String id);
  Future<String> createContributionLink(String id);
}
