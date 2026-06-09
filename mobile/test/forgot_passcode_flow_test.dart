import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:payspin_mobile/core/design_system/theme/payspin_theme.dart';
import 'package:payspin_mobile/core/firebase/phone_auth_service.dart';
import 'package:payspin_mobile/core/l10n/payspin_localizations.dart';
import 'package:payspin_mobile/domain/entities/support_thread.dart';
import 'package:payspin_mobile/domain/entities/user.dart';
import 'package:payspin_mobile/domain/repositories/auth_repository.dart';
import 'package:payspin_mobile/domain/repositories/support_repository.dart';
import 'package:payspin_mobile/presentation/security/forgot_passcode_flow.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get_it/get_it.dart';

import 'helpers/fake_repositories.dart';

class _MockPhoneAuth extends Mock implements PhoneAuthService {}

class _FakeSupportRepository implements SupportRepository {
  bool createCalled = false;
  String? lastContextRef;

  @override
  Future<SupportThreadDetail> createThread({
    String? subject,
    SupportCategory? category,
    required String body,
    String? contextRef,
  }) async {
    createCalled = true;
    lastContextRef = contextRef;
    return SupportThreadDetail(
      id: 't1',
      subject: subject ?? 'Support',
      category: category,
      contextRef: contextRef,
      status: 'OPEN',
      userUnread: false,
      preview: body,
      lastMessageAt: DateTime.now().toIso8601String(),
      messages: const [],
    );
  }

  @override
  Future<List<SupportThread>> listThreads() async => [];

  @override
  Future<SupportThreadDetail> getThread(String id) => throw UnimplementedError();

  @override
  Future<SupportThreadDetail> sendMessage(String threadId, String body) => throw UnimplementedError();

  @override
  Future<void> markRead(String threadId) async {}

  @override
  Future<int> unreadCount() async => 0;
}

final _sl = GetIt.instance;

Future<void> _openFlow(
  WidgetTester tester, {
  required AuthRepository auth,
  PhoneAuthService? phoneAuth,
  SupportRepository? support,
}) async {
  if (_sl.isRegistered<AuthRepository>()) await _sl.unregister<AuthRepository>();
  _sl.registerSingleton<AuthRepository>(auth);

  final mockPhone = phoneAuth ?? _MockPhoneAuth();
  if (phoneAuth == null) {
    when(() => mockPhone.available).thenReturn(false);
  }
  if (_sl.isRegistered<PhoneAuthService>()) await _sl.unregister<PhoneAuthService>();
  _sl.registerSingleton<PhoneAuthService>(mockPhone);

  if (support != null) {
    if (_sl.isRegistered<SupportRepository>()) await _sl.unregister<SupportRepository>();
    _sl.registerSingleton<SupportRepository>(support);
  }

  BuildContext? hostContext;
  await tester.pumpWidget(
    MaterialApp(
      theme: PayspinTheme.dark(),
      locale: const Locale('en'),
      supportedLocales: const [Locale('en')],
      localizationsDelegates: const [
        PayspinLocalizations.delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: Builder(builder: (context) {
        hostContext = context;
        return const SizedBox.shrink();
      }),
    ),
  );
  await tester.pump();
  showForgotPasscodeFlow(hostContext!);
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 700));
}

void main() {
  testWidgets('no verified phone shows support path', (tester) async {
    final auth = FakeAuthRepository()
      ..user = User(
        id: 'u1',
        email: 'a@b.com',
        displayName: 'Alex',
        createdAt: 'now',
      );
    final support = _FakeSupportRepository();

    await _openFlow(tester, auth: auth, support: support);

    expect(find.text('Verify your identity'), findsOneWidget);
    expect(find.text('Contact support'), findsOneWidget);

    await tester.tap(find.text('Contact support'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(support.createCalled, isTrue);
    expect(support.lastContextRef, 'app-lock-forgot');
    expect(find.text('Request sent'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('verified phone without Firebase falls back to support path', (tester) async {
    final auth = FakeAuthRepository()
      ..user = User(
        id: 'u1',
        email: '31612345678@phone.payspin.app',
        phoneE164: '+31612345678',
        phoneVerified: true,
        createdAt: 'now',
      );
    final phoneAuth = _MockPhoneAuth();
    when(() => phoneAuth.available).thenReturn(false);

    await _openFlow(tester, auth: auth, phoneAuth: phoneAuth);

    expect(find.text('Verify your identity'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
