import 'dart:async';

import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recording_repository/recording_repository.dart';
import 'package:showtime/recording/recording.dart';

import '../../helpers/helpers.dart';

const _display = DisplayRecordingSource(
  id: 1,
  number: 1,
  width: 1440,
  height: 900,
);
const _window = WindowRecordingSource(
  id: 2,
  applicationName: 'Code',
  title: 'main.dart',
);
final _startedAt = DateTime(2026, 11, 28, 10);
final _recording = Recording(
  path: '/a.mp4',
  startedAt: _startedAt,
  duration: const Duration(seconds: 3),
);

void main() {
  setUpAll(() {
    registerFallbackValue(_display);
    registerFallbackValue(_recording);
  });

  group(RecordingBloc, () {
    late RecordingRepository repository;
    late StreamController<RecordingInterrupted> interruptions;

    setUp(() {
      repository = MockRecordingRepository();
      interruptions = StreamController<RecordingInterrupted>.broadcast();
      when(() => repository.interruptions)
          .thenAnswer((_) => interruptions.stream);
      when(repository.getSources)
          .thenAnswer((_) async => const [_display, _window]);
    });

    tearDown(() => interruptions.close());

    RecordingBloc buildBloc() => RecordingBloc(recordingRepository: repository);

    const ready = RecordingState(
      permission: PermissionStatus.granted,
      sourcesStatus: SourcesStatus.success,
      sources: [_display, _window],
      selectedSource: _display,
    );

    test('initial state is $RecordingState', () {
      expect(buildBloc().state, const RecordingState());
    });

    group(RecordingSubscriptionRequested, () {
      blocTest<RecordingBloc, RecordingState>(
        'loads sources when permission is granted',
        setUp: () =>
            when(repository.hasPermission).thenAnswer((_) async => true),
        build: buildBloc,
        act: (bloc) => bloc.add(const RecordingSubscriptionRequested()),
        expect: () => const [
          RecordingState(permission: PermissionStatus.granted),
          RecordingState(
            permission: PermissionStatus.granted,
            sourcesStatus: SourcesStatus.loading,
          ),
          ready,
        ],
      );

      blocTest<RecordingBloc, RecordingState>(
        'emits denied without loading sources',
        setUp: () =>
            when(repository.hasPermission).thenAnswer((_) async => false),
        build: buildBloc,
        act: (bloc) => bloc.add(const RecordingSubscriptionRequested()),
        expect: () => const [
          RecordingState(permission: PermissionStatus.denied),
        ],
        verify: (_) => verifyNever(repository.getSources),
      );

      blocTest<RecordingBloc, RecordingState>(
        'emits denied with failure when the check fails',
        setUp: () => when(repository.hasPermission)
            .thenThrow(const RecordingFailure(RecordingFailureReason.unknown)),
        build: buildBloc,
        act: (bloc) => bloc.add(const RecordingSubscriptionRequested()),
        expect: () => const [
          RecordingState(
            permission: PermissionStatus.denied,
            failure: RecordingFailureReason.unknown,
          ),
        ],
        errors: () => [isA<RecordingFailure>()],
      );

      blocTest<RecordingBloc, RecordingState>(
        'keeps saved recording on interruption',
        setUp: () =>
            when(repository.hasPermission).thenAnswer((_) async => false),
        build: buildBloc,
        seed: () => RecordingState(
          permission: PermissionStatus.granted,
          status: RecordingStatus.recording,
          startedAt: _startedAt,
        ),
        act: (bloc) async {
          bloc.add(const RecordingSubscriptionRequested());
          await Future<void>.delayed(Duration.zero);
          interruptions.add(
            RecordingInterrupted(message: 'closed', recording: _recording),
          );
        },
        skip: 1,
        expect: () => [
          RecordingState(
            permission: PermissionStatus.denied,
            lastRecording: _recording,
          ),
        ],
      );

      blocTest<RecordingBloc, RecordingState>(
        'emits failure on interruption without recording',
        setUp: () =>
            when(repository.hasPermission).thenAnswer((_) async => false),
        build: buildBloc,
        act: (bloc) async {
          bloc.add(const RecordingSubscriptionRequested());
          await Future<void>.delayed(Duration.zero);
          interruptions.add(const RecordingInterrupted(message: 'failed'));
        },
        skip: 1,
        expect: () => const [
          RecordingState(
            permission: PermissionStatus.denied,
            failure: RecordingFailureReason.unknown,
          ),
        ],
      );
    });

    group(RecordingPermissionRequested, () {
      blocTest<RecordingBloc, RecordingState>(
        'requests permission and loads sources',
        setUp: () =>
            when(repository.requestPermission).thenAnswer((_) async => true),
        build: buildBloc,
        act: (bloc) => bloc.add(const RecordingPermissionRequested()),
        expect: () => const [
          RecordingState(permission: PermissionStatus.granted),
          RecordingState(
            permission: PermissionStatus.granted,
            sourcesStatus: SourcesStatus.loading,
          ),
          ready,
        ],
      );
    });

    group(RecordingPermissionSettingsRequested, () {
      blocTest<RecordingBloc, RecordingState>(
        'opens settings',
        setUp: () =>
            when(repository.openPermissionSettings).thenAnswer((_) async {}),
        build: buildBloc,
        act: (bloc) => bloc.add(const RecordingPermissionSettingsRequested()),
        expect: () => const <RecordingState>[],
        verify: (_) => verify(repository.openPermissionSettings).called(1),
      );

      blocTest<RecordingBloc, RecordingState>(
        'emits failure when opening fails',
        setUp: () => when(repository.openPermissionSettings)
            .thenThrow(const RecordingFailure(RecordingFailureReason.unknown)),
        build: buildBloc,
        act: (bloc) => bloc.add(const RecordingPermissionSettingsRequested()),
        expect: () => const [
          RecordingState(failure: RecordingFailureReason.unknown),
        ],
        errors: () => [isA<RecordingFailure>()],
      );
    });

    group(RecordingSourcesRefreshed, () {
      blocTest<RecordingBloc, RecordingState>(
        'keeps the selected source if it still exists',
        build: buildBloc,
        seed: () => ready.copyWith(selectedSource: () => _window),
        act: (bloc) => bloc.add(const RecordingSourcesRefreshed()),
        expect: () => [
          ready.copyWith(
            selectedSource: () => _window,
            sourcesStatus: SourcesStatus.loading,
          ),
          ready.copyWith(selectedSource: () => _window),
        ],
      );

      blocTest<RecordingBloc, RecordingState>(
        'selects the first source if the selection is gone',
        setUp: () =>
            when(repository.getSources)
                .thenAnswer((_) async => const [_window]),
        build: buildBloc,
        seed: () => ready,
        act: (bloc) => bloc.add(const RecordingSourcesRefreshed()),
        skip: 1,
        expect: () => [
          ready.copyWith(
            sources: const [_window],
            selectedSource: () => _window,
          ),
        ],
      );

      blocTest<RecordingBloc, RecordingState>(
        'emits failure when loading fails',
        setUp: () => when(repository.getSources)
            .thenThrow(const RecordingFailure(RecordingFailureReason.unknown)),
        build: buildBloc,
        act: (bloc) => bloc.add(const RecordingSourcesRefreshed()),
        expect: () => const [
          RecordingState(sourcesStatus: SourcesStatus.loading),
          RecordingState(
            sourcesStatus: SourcesStatus.failure,
            failure: RecordingFailureReason.unknown,
          ),
        ],
        errors: () => [isA<RecordingFailure>()],
      );
    });

    group(RecordingSourceSelected, () {
      blocTest<RecordingBloc, RecordingState>(
        'selects the source',
        build: buildBloc,
        seed: () => ready,
        act: (bloc) => bloc.add(const RecordingSourceSelected(_window)),
        expect: () => [ready.copyWith(selectedSource: () => _window)],
      );

      blocTest<RecordingBloc, RecordingState>(
        'is ignored while recording',
        build: buildBloc,
        seed: () => ready.copyWith(status: RecordingStatus.recording),
        act: (bloc) => bloc.add(const RecordingSourceSelected(_window)),
        expect: () => const <RecordingState>[],
      );
    });

    group(RecordingStartRequested, () {
      blocTest<RecordingBloc, RecordingState>(
        'starts recording the selected source',
        setUp: () =>
            when(() => repository.startRecording(any()))
                .thenAnswer((_) async => _startedAt),
        build: buildBloc,
        seed: () => ready,
        act: (bloc) => bloc.add(const RecordingStartRequested()),
        expect: () => [
          ready.copyWith(status: RecordingStatus.starting),
          ready.copyWith(
            status: RecordingStatus.recording,
            startedAt: () => _startedAt,
          ),
        ],
        verify: (_) => verify(() => repository.startRecording(_display)),
      );

      blocTest<RecordingBloc, RecordingState>(
        'does nothing when it cannot start',
        build: buildBloc,
        act: (bloc) => bloc.add(const RecordingStartRequested()),
        expect: () => const <RecordingState>[],
      );

      blocTest<RecordingBloc, RecordingState>(
        'emits failure when starting fails',
        setUp: () => when(() => repository.startRecording(any())).thenThrow(
          const RecordingFailure(RecordingFailureReason.sourceNotFound),
        ),
        build: buildBloc,
        seed: () => ready,
        act: (bloc) => bloc.add(const RecordingStartRequested()),
        expect: () => [
          ready.copyWith(status: RecordingStatus.starting),
          ready.copyWith(failure: () => RecordingFailureReason.sourceNotFound),
        ],
        errors: () => [isA<RecordingFailure>()],
      );
    });

    group(RecordingStopRequested, () {
      final recordingState = ready.copyWith(
        status: RecordingStatus.recording,
        startedAt: () => _startedAt,
      );

      blocTest<RecordingBloc, RecordingState>(
        'stops and keeps the recording',
        setUp: () =>
            when(repository.stopRecording).thenAnswer((_) async => _recording),
        build: buildBloc,
        seed: () => recordingState,
        act: (bloc) => bloc.add(const RecordingStopRequested()),
        expect: () => [
          recordingState.copyWith(status: RecordingStatus.stopping),
          ready.copyWith(lastRecording: () => _recording),
        ],
      );

      blocTest<RecordingBloc, RecordingState>(
        'does nothing when not recording',
        build: buildBloc,
        seed: () => ready,
        act: (bloc) => bloc.add(const RecordingStopRequested()),
        expect: () => const <RecordingState>[],
      );

      blocTest<RecordingBloc, RecordingState>(
        'emits failure when stopping fails',
        setUp: () => when(repository.stopRecording)
            .thenThrow(const RecordingFailure(RecordingFailureReason.noFrames)),
        build: buildBloc,
        seed: () => recordingState,
        act: (bloc) => bloc.add(const RecordingStopRequested()),
        expect: () => [
          recordingState.copyWith(status: RecordingStatus.stopping),
          ready.copyWith(failure: () => RecordingFailureReason.noFrames),
        ],
        errors: () => [isA<RecordingFailure>()],
      );
    });

    group(RecordingRevealRequested, () {
      blocTest<RecordingBloc, RecordingState>(
        'reveals the last recording',
        setUp: () =>
            when(() => repository.revealRecording(any()))
                .thenAnswer((_) async {}),
        build: buildBloc,
        seed: () => ready.copyWith(lastRecording: () => _recording),
        act: (bloc) => bloc.add(const RecordingRevealRequested()),
        expect: () => const <RecordingState>[],
        verify: (_) => verify(() => repository.revealRecording(_recording)),
      );

      blocTest<RecordingBloc, RecordingState>(
        'does nothing without recording',
        build: buildBloc,
        act: (bloc) => bloc.add(const RecordingRevealRequested()),
        verify: (_) => verifyNever(() => repository.revealRecording(any())),
      );

      blocTest<RecordingBloc, RecordingState>(
        'emits failure when revealing fails',
        setUp: () => when(() => repository.revealRecording(any()))
            .thenThrow(const RecordingFailure(RecordingFailureReason.unknown)),
        build: buildBloc,
        seed: () => RecordingState(lastRecording: _recording),
        act: (bloc) => bloc.add(const RecordingRevealRequested()),
        expect: () => [
          RecordingState(
            lastRecording: _recording,
            failure: RecordingFailureReason.unknown,
          ),
        ],
        errors: () => [isA<RecordingFailure>()],
      );
    });
  });

  test('$RecordingStatus.isBusy', () {
    expect(RecordingStatus.starting.isBusy, isTrue);
    expect(RecordingStatus.stopping.isBusy, isTrue);
    expect(RecordingStatus.idle.isBusy, isFalse);
    expect(RecordingStatus.recording.isBusy, isFalse);
  });

  test('events support value equality', () {
    expect(
      const RecordingSourceSelected(_display),
      const RecordingSourceSelected(_display),
    );
  });
}
