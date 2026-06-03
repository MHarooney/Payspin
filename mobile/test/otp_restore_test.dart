import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/app/app.dart';
import 'package:payspin_mobile/app/di/injection.dart';
import 'package:payspin_mobile/app/router.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Simulates an iOS process restart during Firebase reCAPTCHA: the in-memory
/// onboarding draft is gone, but the persisted progress must restore the OTP
/// step (with the phone number) instead of dropping the user back to Welcome.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({
      'payspin_onboarding_phone_progress': jsonEncode({
        'countryCode': '+20',
        'phone': '1060908902',
        'displayName': 'Mo',
        'verificationId': null,
        'codeSent': false,
        'savedAt': DateTime.now().millisecondsSinceEpoch,
      }),
    });
    await configureDependencies();
  });

  testWidgets('OTP page restores the persisted phone after a cold start',
      (tester) async {
    final router = createRouter(initialLocation: '/onboarding/otp');
    await tester.pumpWidget(PayspinApp(router: router));
    await tester.pump();
    for (var i = 0; i < 30; i++) {
      await tester.pump(const Duration(milliseconds: 100));
      if (find.textContaining('1060908902').evaluate().isNotEmpty) break;
    }

    expect(find.text('Enter the code'), findsOneWidget);
    expect(find.textContaining('1060908902'), findsWidgets);
  });
}
