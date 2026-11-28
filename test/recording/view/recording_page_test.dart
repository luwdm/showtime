import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recording_repository/recording_repository.dart';
import 'package:showtime/recording/recording.dart';
import 'package:showtime/recording/widgets/widgets.dart';

import '../../helpers/helpers.dart';

void main() {
  group(RecordingPage, () {
    testWidgets('provides $RecordingBloc and checks permission', (
      tester,
    ) async {
      final repository = MockRecordingRepository();
      when(repository.hasPermission).thenAnswer((_) async => false);
      when(() => repository.interruptions)
          .thenAnswer((_) => const Stream<RecordingInterrupted>.empty());

      await tester.pumpApp(
        const RecordingPage(),
        recordingRepository: repository,
      );
      await tester.pump();

      expect(find.byType(RecordingView), findsOneWidget);
      expect(find.byType(PermissionPrompt), findsOneWidget);
      verify(repository.hasPermission).called(1);
    });
  });

  group(RecordingView, () {
    late RecordingBloc bloc;

    setUp(() {
      bloc = MockRecordingBloc();
    });

    Future<void> pumpView(WidgetTester tester) => tester.pumpApp(
      BlocProvider.value(value: bloc, child: const RecordingView()),
    );

    testWidgets('shows progress while permission is unknown', (tester) async {
      when(() => bloc.state).thenReturn(const RecordingState());

      await pumpView(tester);

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('shows $PermissionPrompt when denied', (tester) async {
      when(
        () => bloc.state,
      ).thenReturn(const RecordingState(permission: PermissionStatus.denied));

      await pumpView(tester);

      expect(find.byType(PermissionPrompt), findsOneWidget);
    });

    testWidgets('shows sources and record bar when granted', (tester) async {
      when(() => bloc.state).thenReturn(
        const RecordingState(
          permission: PermissionStatus.granted,
          sourcesStatus: SourcesStatus.success,
        ),
      );

      await pumpView(tester);

      expect(find.byType(SourceList), findsOneWidget);
      expect(find.byType(RecordBar), findsOneWidget);
    });

    testWidgets('shows snackbar on failure', (tester) async {
      const initial = RecordingState(permission: PermissionStatus.denied);
      whenListen(
        bloc,
        Stream.value(
          initial.copyWith(failure: () => RecordingFailureReason.noFrames),
        ),
        initialState: initial,
      );

      await pumpView(tester);
      await tester.pump();

      expect(
        find.text(
          RecordingView.failureMessage(RecordingFailureReason.noFrames),
        ),
        findsOneWidget,
      );
    });

    test('has a message for every failure', () {
      for (final reason in RecordingFailureReason.values) {
        expect(RecordingView.failureMessage(reason), isNotEmpty);
      }
    });
  });
}
