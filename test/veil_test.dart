import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/veil.dart';

void main() {
  group('Veil', () {
    testWidgets('renders child', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(child: Text('hello')),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('renders with enable false', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(enable: false, child: Text('hello')),
        ),
      );
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('toggles enable without error', (tester) async {
      bool enable = true;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                Veil(
                  enable: enable,
                  duration: const Duration(milliseconds: 100),
                  child: const Text('hello'),
                ),
                GestureDetector(
                  onTap: () => setState(() => enable = !enable),
                  child: const Text('toggle'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('toggle'));
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);

      await tester.tap(find.text('toggle'));
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('asserts invalid greyOpacity', (tester) async {
      expect(
        () => Veil(greyOpacity: 1.5, child: const SizedBox()),
        throwsAssertionError,
      );
      expect(
        () => Veil(greyOpacity: -0.1, child: const SizedBox()),
        throwsAssertionError,
      );
    });

    testWidgets('asserts invalid overlayOpacity', (tester) async {
      expect(
        () => Veil(overlayOpacity: 1.5, child: const SizedBox()),
        throwsAssertionError,
      );
      expect(
        () => Veil(overlayOpacity: -0.1, child: const SizedBox()),
        throwsAssertionError,
      );
    });

    testWidgets('renders with overlay', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            overlayOpacity: 0.5,
            overlayColor: Color(0xFFFF0000),
            child: Text('hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });
  });

  group('Unveiled', () {
    testWidgets('renders child inside Veil', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            child: Column(
              children: [
                Text('veiled'),
                Unveiled(child: Text('clear')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('veiled'), findsOneWidget);
      expect(find.text('clear'), findsOneWidget);
    });

    testWidgets('works outside Veil without error', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Unveiled(child: Text('standalone')),
        ),
      );
      expect(find.text('standalone'), findsOneWidget);
    });

    testWidgets('multiple Unveiled instances work', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            child: Column(
              children: [
                Unveiled(child: Text('one')),
                Unveiled(child: Text('two')),
                Unveiled(child: Text('three')),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('one'), findsOneWidget);
      expect(find.text('two'), findsOneWidget);
      expect(find.text('three'), findsOneWidget);
    });

    testWidgets('Unveiled unregisters on dispose without error',
        (tester) async {
      bool show = true;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) => Veil(
              child: Column(
                children: [
                  if (show) const Unveiled(child: Text('removable')),
                  GestureDetector(
                    onTap: () => setState(() => show = false),
                    child: const Text('remove'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('removable'), findsOneWidget);

      await tester.tap(find.text('remove'));
      await tester.pumpAndSettle();
      expect(find.text('removable'), findsNothing);
    });
  });
}
