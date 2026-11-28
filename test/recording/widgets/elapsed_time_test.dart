import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:showtime/recording/widgets/widgets.dart';

void main() {
  group(ElapsedTime, () {
    test('format pads seconds', () {
      expect(ElapsedTime.format(Duration.zero), '0:00');
      expect(ElapsedTime.format(const Duration(seconds: 65)), '1:05');
      expect(
        ElapsedTime.format(const Duration(minutes: 12, seconds: 3)),
        '12:03',
      );
    });

    testWidgets('updates every second', (tester) async {
      final start = DateTime(2026, 11, 28, 10);
      var now = start.add(const Duration(seconds: 5));

      await withClock(Clock(() => now), () async {
        await tester.pumpWidget(MaterialApp(home: ElapsedTime(since: start)));
        expect(find.text('0:05'), findsOneWidget);

        now = now.add(const Duration(seconds: 1));
        await tester.pump(const Duration(seconds: 1));
        expect(find.text('0:06'), findsOneWidget);
      });
    });

    testWidgets('never shows negative time', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: ElapsedTime(
            since: DateTime.now().add(const Duration(hours: 1)),
          ),
        ),
      );

      expect(find.text('0:00'), findsOneWidget);
    });
  });
}
