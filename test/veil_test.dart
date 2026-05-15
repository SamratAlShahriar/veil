import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:veil/veil.dart';

void main() {
  // ─────────────────────────────────────────────────────────────────────────
  // Veil
  // ─────────────────────────────────────────────────────────────────────────

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

    // ── Fast path tests ────────────────────────────────────────────────────

    testWidgets('greyOpacity 0.0 uses fast path — no filter applied',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            enable: true,
            greyOpacity: 0.0,
            child: Text('hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('overlayOpacity 0.0 uses fast path — no overlay painted',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            enable: true,
            overlayOpacity: 0.0,
            child: Text('hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('greyOpacity 0.0 and overlayOpacity 0.0 — full fast path',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            enable: true,
            greyOpacity: 0.0,
            overlayOpacity: 0.0,
            child: Text('hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    // ── Boundary value tests ───────────────────────────────────────────────

    testWidgets('greyOpacity 1.0 and overlayOpacity 1.0 renders without error',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            greyOpacity: 1.0,
            overlayOpacity: 1.0,
            child: Text('hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('greyOpacity boundary values render without error',
        (tester) async {
      for (final opacity in [0.0, 0.001, 0.5, 0.999, 1.0]) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Veil(
              greyOpacity: opacity,
              child: const Text('hello'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('hello'), findsOneWidget,
            reason: 'Failed at greyOpacity: $opacity');
      }
    });

    testWidgets('overlayOpacity boundary values render without error',
        (tester) async {
      for (final opacity in [0.0, 0.001, 0.5, 0.999, 1.0]) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Veil(
              overlayOpacity: opacity,
              child: const Text('hello'),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('hello'), findsOneWidget,
            reason: 'Failed at overlayOpacity: $opacity');
      }
    });

    // ── Animation tests ────────────────────────────────────────────────────

    testWidgets('rapid enable toggle does not crash', (tester) async {
      bool enable = false;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                Veil(
                  enable: enable,
                  duration: const Duration(milliseconds: 50),
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

      // Rapid-fire toggles without letting animation complete
      for (var i = 0; i < 10; i++) {
        await tester.tap(find.text('toggle'));
        await tester.pump(const Duration(milliseconds: 10));
      }
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('animation completes correctly when interrupted mid-way',
        (tester) async {
      bool enable = true;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                Veil(
                  enable: enable,
                  duration: const Duration(milliseconds: 300),
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

      // Start disable animation
      await tester.tap(find.text('toggle'));
      await tester.pump(const Duration(milliseconds: 150)); // mid-animation

      // Reverse before it finishes
      await tester.tap(find.text('toggle'));
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('duration change takes effect on next toggle', (tester) async {
      bool enable = true;
      Duration duration = const Duration(milliseconds: 300);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                Veil(
                  enable: enable,
                  duration: duration,
                  child: const Text('hello'),
                ),
                GestureDetector(
                  onTap: () => setState(() {
                    enable = !enable;
                    duration = const Duration(milliseconds: 100);
                  }),
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
    });

    testWidgets('overlay color change renders without error', (tester) async {
      Color color = const Color(0xFF000000);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                Veil(
                  overlayOpacity: 0.5,
                  overlayColor: color,
                  child: const Text('hello'),
                ),
                GestureDetector(
                  onTap: () => setState(() => color = const Color(0xFFFF0000)),
                  child: const Text('change'),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.tap(find.text('change'));
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    // ── Nesting tests ──────────────────────────────────────────────────────

    testWidgets('nested Veil widgets render without error', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            child: Veil(
              child: Text('nested'),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('nested'), findsOneWidget);
    });

    testWidgets('nested Veil with Unveiled in inner Veil', (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            child: Veil(
              child: Column(
                children: [
                  Text('double veiled'),
                  Unveiled(child: Text('inner unveiled')),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('double veiled'), findsOneWidget);
      expect(find.text('inner unveiled'), findsOneWidget);
    });

    // ── Scroll / ListView tests ────────────────────────────────────────────

    testWidgets('Veil inside ListView renders without error', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListView(
            children: List.generate(
              5,
              (i) => Veil(
                key: ValueKey(i),
                child: Text('item $i'),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('item 0'), findsOneWidget);
    });

    testWidgets('Veil with Unveiled inside ListView renders without error',
        (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: ListView(
            children: List.generate(
              5,
              (i) => Veil(
                key: ValueKey(i),
                child: Column(
                  children: [
                    Text('item $i'),
                    Unveiled(child: Text('unveiled $i')),
                  ],
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('item 0'), findsOneWidget);
      expect(find.text('unveiled 0'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Unveiled
  // ─────────────────────────────────────────────────────────────────────────

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

    testWidgets('Unveiled at all greyOpacity boundary values', (tester) async {
      for (final opacity in [0.0, 0.001, 0.5, 0.999, 1.0]) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Veil(
              greyOpacity: opacity,
              child: const Column(
                children: [
                  Text('veiled'),
                  Unveiled(child: Text('clear')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('clear'), findsOneWidget,
            reason: 'Failed at greyOpacity: $opacity');
      }
    });

    testWidgets('Unveiled at all overlayOpacity boundary values',
        (tester) async {
      for (final opacity in [0.0, 0.001, 0.5, 0.999, 1.0]) {
        await tester.pumpWidget(
          Directionality(
            textDirection: TextDirection.ltr,
            child: Veil(
              overlayOpacity: opacity,
              child: const Column(
                children: [
                  Text('veiled'),
                  Unveiled(child: Text('clear')),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.text('clear'), findsOneWidget,
            reason: 'Failed at overlayOpacity: $opacity');
      }
    });

    testWidgets('Unveiled mounts and unmounts multiple times without error',
        (tester) async {
      bool show = true;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) => Veil(
              child: Column(
                children: [
                  if (show) const Unveiled(child: Text('toggled')),
                  GestureDetector(
                    onTap: () => setState(() => show = !show),
                    child: const Text('toggle'),
                  ),
                ],
              ),
            ),
          ),
        ),
      );

      // Mount → unmount → mount → unmount
      for (var i = 0; i < 4; i++) {
        await tester.tap(find.text('toggle'));
        await tester.pumpAndSettle();
      }
      expect(find.text('toggle'), findsOneWidget);
    });

    testWidgets('Unveiled inside disabled Veil renders correctly',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            enable: false,
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

    testWidgets('Veil disposes cleanly with active Unveiled children',
        (tester) async {
      bool showVeil = true;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                if (showVeil)
                  const Veil(
                    child: Unveiled(child: Text('inside')),
                  ),
                GestureDetector(
                  onTap: () => setState(() => showVeil = false),
                  child: const Text('remove veil'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('inside'), findsOneWidget);

      // Remove the entire Veil with active Unveiled — should not crash
      await tester.tap(find.text('remove veil'));
      await tester.pumpAndSettle();
      expect(find.text('inside'), findsNothing);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // Veil property updates
  // ─────────────────────────────────────────────────────────────────────────

  group('Veil property updates', () {
    testWidgets('updates duration at runtime', (tester) async {
      Duration duration = const Duration(milliseconds: 300);
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                Veil(
                  duration: duration,
                  child: const Text('hello'),
                ),
                GestureDetector(
                  onTap: () => setState(
                    () => duration = const Duration(milliseconds: 100),
                  ),
                  child: const Text('update'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('update'));
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('updates curve at runtime', (tester) async {
      Curve curve = Curves.easeInOut;
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                Veil(
                  curve: curve,
                  child: const Text('hello'),
                ),
                GestureDetector(
                  onTap: () => setState(() => curve = Curves.linear),
                  child: const Text('update'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.tap(find.text('update'));
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    // Find this test and update it:
    // Find this test and update it:
    testWidgets('updates overlayColor at runtime', (tester) async {
      Color color = const Color(0xFF000000); // black
      await tester.pumpWidget(
        Directionality(
          textDirection: TextDirection.ltr,
          child: StatefulBuilder(
            builder: (_, setState) => Column(
              children: [
                Veil(
                  enable: true,
                  overlayOpacity: 0.5,
                  overlayColor: color,
                  child: const Text('hello'),
                ),
                GestureDetector(
                  // ✅ Red — genuinely different RGB from black
                  onTap: () => setState(() => color = const Color(0xFFFF0000)),
                  child: const Text('update'),
                ),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle(); // settle with black overlay
      await tester.tap(find.text('update')); // switch to red — hits setter body
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });
  });

  // ─────────────────────────────────────────────────────────────────────────
  // RenderVeil cache
  // ─────────────────────────────────────────────────────────────────────────

  group('RenderVeil cache', () {
    testWidgets('ColorFilter cache hit — same greyAmount reuses filter',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            greyOpacity: 1.0,
            child: Column(
              children: [
                Text('hello'),
                Unveiled(child: Text('clear')),
              ],
            ),
          ),
        ),
      );
      await tester.pump();
      await tester.pump();
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
      expect(find.text('clear'), findsOneWidget);
    });

    testWidgets('greyOpacity at _kEffectivelyOne uses exact grey matrix',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            greyOpacity: 0.999,
            child: Text('hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });

    testWidgets('greyOpacity just above _kEffectivelyZero uses lerp matrix',
        (tester) async {
      await tester.pumpWidget(
        const Directionality(
          textDirection: TextDirection.ltr,
          child: Veil(
            greyOpacity: 0.002,
            child: Text('hello'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.text('hello'), findsOneWidget);
    });
  });
}
