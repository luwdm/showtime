import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:showtime/home/home.dart';

void main() {
  group(HomePage, () {
    testWidgets('renders app name', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: HomePage()));

      expect(find.text('Showtime'), findsOneWidget);
    });
  });
}
