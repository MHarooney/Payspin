import '../../core/state/support_refresh_notifier.dart';
import '../../domain/entities/support_thread.dart';
import '../../domain/repositories/support_repository.dart';
import '../datasources/payspin_api_client.dart';

class SupportRepositoryImpl implements SupportRepository {
  SupportRepositoryImpl(this._api, this._refresh);

  final PayspinApiClient _api;
  final SupportRefreshNotifier _refresh;

  @override
  Future<List<SupportThread>> listThreads() async {
    final list = await _api.listSupportThreads();
    return list
        .map((e) => SupportThread.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<SupportThreadDetail> createThread({
    String? subject,
    SupportCategory? category,
    required String body,
    String? contextRef,
  }) async {
    final json = await _api.createSupportThread(
      subject: subject,
      category: category?.wire,
      body: body,
      contextRef: contextRef,
    );
    _refresh.bump();
    return SupportThreadDetail.fromJson(json);
  }

  @override
  Future<SupportThreadDetail> getThread(String id) async {
    final json = await _api.getSupportThread(id);
    return SupportThreadDetail.fromJson(json);
  }

  @override
  Future<SupportThreadDetail> sendMessage(String threadId, String body) async {
    final json = await _api.sendSupportMessage(threadId: threadId, body: body);
    _refresh.bump();
    return SupportThreadDetail.fromJson(json);
  }

  @override
  Future<void> markRead(String threadId) async {
    await _api.markSupportThreadRead(threadId);
    _refresh.bump();
  }

  @override
  Future<int> unreadCount() => _api.supportUnreadCount();
}
