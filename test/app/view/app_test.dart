import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recording_repository/recording_repository.dart';
import 'package:showtime/app/app.dart';
import 'package:showtime/recording/recording.dart';

import '../../helpers/helpers.dart';

void main() {
  group(App, () {
    testWidgets('renders $RecordingPage', (tester) async {
      final repository = MockRecordingRepository();
      when(repository.hasPermission).thenAnswer((_) async => false);
      when(() => repository.interruptions)
          .thenAnswer((_) => const Stream<RecordingInterrupted>.empty());

      await tester.pumpWidget(App(recordingRepository: repository));

      expect(find.byType(RecordingPage), findsOneWidget);
    });
  });
}
