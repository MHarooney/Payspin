import '../entities/support_thread.dart';

abstract class SupportRepository {
  Future<List<SupportThread>> listThreads();
  Future<SupportThreadDetail> createThread({
    String? subject,
    SupportCategory? category,
    required String body,
    String? contextRef,
  });
  Future<SupportThreadDetail> getThread(String id);
  Future<SupportThreadDetail> sendMessage(String threadId, String body);
  Future<void> markRead(String threadId);
  Future<int> unreadCount();
}
