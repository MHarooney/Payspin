import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/app/app.dart';
import 'package:payspin_mobile/app/di/injection.dart';

void main() {
  setUpAll(() async {
    await configureDependencies();
  });

  testWidgets('PayspinApp shows welcome on first frame', (tester) async {
    await tester.pumpWidget(PayspinApp());
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Get started'), findsOneWidget);
    expect(find.text('Payspin'), findsOneWidget);
  });
}
