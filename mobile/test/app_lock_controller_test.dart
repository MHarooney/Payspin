import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payspin_mobile/core/security/app_lock_controller.dart';
import 'package:payspin_mobile/core/security/app_lock_service.dart';

class _MockLockService extends Mock implements AppLockService {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late _MockLockService service;
  late AppLockController controller;

  setUp(() {
    service = _MockLockService();
    when(() => service.isLockEnabled()).thenAnswer((_) async => true);
    controller = AppLockController(
      service,
      autoLockTimeout: const Duration(milliseconds: 200),
    );
  });

  tearDown(() {
    controller.dispose();
  });

  test('does not lock immediately on paused/hidden lifecycle', () {
    controller.markEnabledUnlocked();
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    controller.didChangeAppLifecycleState(AppLifecycleState.hidden);
    expect(controller.isLocked, isFalse);
  });

  test('does not lock on resume when activity was recent', () {
    controller.markEnabledUnlocked();
    controller.recordUserActivity();
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(controller.isLocked, isFalse);
  });

  test('locks on resume after inactivity timeout', () async {
    controller.markEnabledUnlocked();
    controller.recordUserActivity();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    controller.didChangeAppLifecycleState(AppLifecycleState.paused);
    controller.didChangeAppLifecycleState(AppLifecycleState.resumed);
    expect(controller.isLocked, isTrue);
  });

  test('locks on foreground idle timer', () async {
    controller.markEnabledUnlocked();
    controller.recordUserActivity();
    await Future<void>.delayed(const Duration(milliseconds: 250));
    expect(controller.isLocked, isTrue);
  });

  test('recordUserActivity resets the idle timer', () async {
    controller.markEnabledUnlocked();
    controller.recordUserActivity();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    controller.recordUserActivity();
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(controller.isLocked, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(controller.isLocked, isTrue);
  });

  test('unlock restarts the inactivity window', () async {
    controller.markEnabledUnlocked();
    controller.lockNow();
    expect(controller.isLocked, isTrue);
    controller.unlock();
    expect(controller.isLocked, isFalse);
    await Future<void>.delayed(const Duration(milliseconds: 120));
    expect(controller.isLocked, isFalse);
  });
}
