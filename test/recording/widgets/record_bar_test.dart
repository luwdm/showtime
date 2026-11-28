import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recording_repository/recording_repository.dart';
import 'package:showtime/recording/recording.dart';
import 'package:showtime/recording/widgets/widgets.dart';

import '../../helpers/helpers.dart';

const _display = DisplayRecordingSource(
  id: 1,
  number: 1,
  width: 1440,
  height: 900,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const RecordingStartRequested());
  });

  group(RecordBar, () {
    late RecordingBloc bloc;

    setUp(() {
      bloc = MockRecordingBloc();
    });

    Future<void> pump(WidgetTester tester, RecordingState state) {
      when(() => bloc.state).thenReturn(state);
      return tester.pumpApp(
        BlocProvider.value(value: bloc, child: const RecordBar()),
      );
    }

    const ready = RecordingState(
      permission: PermissionStatus.granted,
      sourcesStatus: SourcesStatus.success,
      sources: [_display],
      selectedSource: _display,
    );

    testWidgets('starts recording', (tester) async {
      await pump(tester, ready);

      await tester.tap(find.text('Record'));

      verify(() => bloc.add(const RecordingStartRequested())).called(1);
    });

    testWidgets('disables record without source', (tester) async {
      await pump(tester, ready.copyWith(selectedSource: () => null));

      await tester.tap(find.text('Record'));

      verifyNever(() => bloc.add(any()));
    });

    testWidgets('shows progress while starting', (tester) async {
      await pump(tester, ready.copyWith(status: RecordingStatus.starting));

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows elapsed time and stops recording', (tester) async {
      await pump(
        tester,
        ready.copyWith(
          status: RecordingStatus.recording,
          startedAt: DateTime.now,
        ),
      );

      expect(find.byType(ElapsedTime), findsOneWidget);
      await tester.tap(find.text('Stop'));

      verify(() => bloc.add(const RecordingStopRequested())).called(1);
    });

    testWidgets('shows last recording and reveals it', (tester) async {
      await pump(
        tester,
        ready.copyWith(
          lastRecording: () => Recording(
            path: '/Movies/Showtime/clip.mp4',
            startedAt: DateTime(2026),
            duration: const Duration(seconds: 3),
          ),
        ),
      );

      expect(find.text('Saved clip.mp4'), findsOneWidget);
      await tester.tap(find.text('Show in Finder'));

      verify(() => bloc.add(const RecordingRevealRequested())).called(1);
    });
  });
}
