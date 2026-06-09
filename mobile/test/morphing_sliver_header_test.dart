import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_morphing_sliver_header.dart';
import 'package:payspin_mobile/core/design_system/widgets/payspin_shell_tab_headers.dart';

import 'helpers/l10n_test_app.dart';

void main() {
  group('PayspinHomeShellHeaderMetrics', () {
    test('expanded height grows when search is open', () {
      expect(
        PayspinHomeShellHeaderMetrics.expanded(searchOpen: false),
        PayspinHomeShellHeaderMetrics.expandedHeight,
      );
      expect(
        PayspinHomeShellHeaderMetrics.expanded(searchOpen: true),
        PayspinHomeShellHeaderMetrics.expandedHeight + PayspinHomeShellHeaderMetrics.searchExtraHeight,
      );
    });
  });

  group('morphLerp', () {
    test('interpolates between endpoints', () {
      expect(morphLerp(0, 100, 40), 100);
      expect(morphLerp(1, 100, 40), 40);
      expect(morphLerp(0.5, 100, 40), 70);
    });
  });

  testWidgets('PayspinMorphingSliverHeader renders greeting and compact title on scroll', (tester) async {
    await tester.pumpWidget(
      l10nTestApp(
        Scaffold(
          body: CustomScrollView(
          slivers: [
            PayspinMorphingSliverHeader(
              expandedHeight: PayspinHomeShellHeaderMetrics.expandedHeight,
              collapsedHeight: PayspinHomeShellHeaderMetrics.collapsedHeight,
              rebuildTrigger: 0,
              builder: (ctx, t, _) => PayspinHomeShellHeader(
                t: t,
                searchOpen: false,
                greetingPhrase: 'Good morning',
                userName: 'Alex',
                onToggleSearch: () {},
                onSearchChanged: (_) {},
                notificationBell: const Icon(Icons.notifications_none),
              ),
            ),
            const SliverToBoxAdapter(
              child: SizedBox(height: 2000),
            ),
          ],
        ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Good morning'), findsOneWidget);
    expect(find.text('Alex'), findsOneWidget);

    for (final offset in [60.0, 120.0, 200.0]) {
      await tester.drag(find.byType(CustomScrollView), Offset(0, -offset));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }

    expect(find.text('Payspin'), findsOneWidget);
  });

  testWidgets('freezeCollapse keeps greeting visible while search is open', (tester) async {
    await tester.pumpWidget(
      l10nTestApp(
        Scaffold(
          body: CustomScrollView(
          slivers: [
            PayspinMorphingSliverHeader(
              expandedHeight: PayspinHomeShellHeaderMetrics.expanded(searchOpen: true),
              collapsedHeight: PayspinHomeShellHeaderMetrics.collapsedHeight,
              freezeCollapse: true,
              rebuildTrigger: true,
              builder: (ctx, t, _) => PayspinHomeShellHeader(
                t: t,
                searchOpen: true,
                greetingPhrase: 'Good evening',
                userName: 'Sam',
                onToggleSearch: () {},
                onSearchChanged: (_) {},
                notificationBell: const Icon(Icons.notifications_none),
              ),
            ),
            const SliverToBoxAdapter(child: SizedBox(height: 2000)),
          ],
        ),
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -240));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 50));

    expect(find.text('Good evening'), findsOneWidget);
    expect(find.text('Sam'), findsOneWidget);
    expect(find.byType(TextField), findsOneWidget);
  });

  testWidgets('PayspinProfileShellHeader shows avatar and profile title', (tester) async {
    await tester.pumpWidget(
      l10nTestApp(
        SizedBox(
          height: PayspinProfileShellHeaderMetrics.expandedContentMinHeight + 20,
          child: PayspinProfileShellHeader(
            t: 0,
            name: 'Alex',
            initial: 'A',
            contact: 'alex@example.com',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Alex'), findsOneWidget);
    expect(find.text('alex@example.com'), findsOneWidget);
    expect(find.text('A'), findsOneWidget);

    await tester.pumpWidget(
      l10nTestApp(
        SizedBox(
          height: PayspinProfileShellHeaderMetrics.collapsedHeight,
          child: PayspinProfileShellHeader(
            t: 1,
            name: 'Alex',
            initial: 'A',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Profile'), findsOneWidget);
  });

  testWidgets('PayspinProfileShellHeader avoids overflow while collapsing', (tester) async {
    await tester.pumpWidget(
      l10nTestApp(
        Scaffold(
          body: CustomScrollView(
            slivers: [
              PayspinMorphingSliverHeader(
                expandedHeight: PayspinProfileShellHeaderMetrics.expandedHeight,
                collapsedHeight: PayspinProfileShellHeaderMetrics.collapsedHeight,
                builder: (ctx, t, _) => PayspinProfileShellHeader(
                  t: t,
                  name: 'Mahmoud AlHaroon',
                  initial: 'M',
                  contact: 'mahmoud@payspin.dev',
                ),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 2000)),
            ],
          ),
        ),
      ),
    );
    await tester.pump();
    for (final offset in [40.0, 80.0, 120.0, 160.0, 200.0]) {
      await tester.drag(find.byType(CustomScrollView), Offset(0, -offset));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      expect(tester.takeException(), isNull);
    }
  });

  testWidgets('PayspinGroepiesShellHeader renders title and subtitle', (tester) async {
    await tester.pumpWidget(
      l10nTestApp(
        SizedBox(
          height: PayspinGroepiesShellHeaderMetrics.expandedHeight,
          child: PayspinGroepiesShellHeader(t: 0),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('Community savings'), findsOneWidget);
    expect(find.text('Groepies'), findsWidgets);
  });
}
