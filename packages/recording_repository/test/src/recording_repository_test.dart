import 'dart:async';

import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recording_repository/recording_repository.dart';
import 'package:screen_capture_client/screen_capture_client.dart';

class _MockScreenCaptureClient extends Mock implements ScreenCaptureClient;

CaptureWindow _window({
  int id = 1,
  String? title = 'Title',
  String? applicationName = 'App',
  String? bundleIdentifier = 'com.example.app',
  double width = 800,
  double height = 600,
  bool isOnScreen = true,
}) => CaptureWindow(
  id: id,
  title: title,
  applicationName: applicationName,
  bundleIdentifier: bundleIdentifier,
  width: width,
  height: height,
  isOnScreen: isOnScreen,
);

void main() {
  setUpAll(() {
    registerFallbackValue(const DisplayCaptureSource(displayId: 0));
  });

  group(RecordingRepository, () {
    late ScreenCaptureClient client;
    late RecordingRepository repository;
    final startedAt = DateTime(2026, 11, 28, 9, 5, 3);

    setUp(() {
      client = _MockScreenCaptureClient();
      repository = RecordingRepository(
        screenCaptureClient: client,
        excludedBundleIdentifiers: {'io.github.luwdm.showtime'},
      );
      when(() => client.getDefaultOutputDirectory())
          .thenAnswer((_) async => '/Movies/Showtime');
      when(
        () => client.startRecording(
          source: any(named: 'source'),
          outputPath: any(named: 'outputPath'),
          framesPerSecond: any(named: 'framesPerSecond'),
        ),
      ).thenAnswer((_) async {});
      when(() => client.stopRecording()).thenAnswer(
        (_) async => '/Movies/Showtime/Showtime 2026-11-28 at 09.05.03.mp4',
      );
    });

    group('permissions', () {
      test('hasPermission returns value from client', () async {
        when(() => client.hasPermission()).thenAnswer((_) async => true);

        expect(await repository.hasPermission(), isTrue);
      });

      test('requestPermission returns value from client', () async {
        when(() => client.requestPermission()).thenAnswer((_) async => false);

        expect(await repository.requestPermission(), isFalse);
      });

      test('openPermissionSettings calls client', () async {
        when(() => client.openPermissionSettings()).thenAnswer((_) async {});

        await repository.openPermissionSettings();

        verify(() => client.openPermissionSettings()).called(1);
      });

      test('maps permission-denied to $RecordingFailure', () {
        when(
          () => client.hasPermission(),
        ).thenThrow(const ScreenCaptureException('permission-denied', 'nope'));

        expect(
          repository.hasPermission,
          throwsA(
            isA<RecordingFailure>()
                .having(
                  (f) => f.reason,
                  'reason',
                  RecordingFailureReason.permissionDenied,
                )
                .having((f) => f.message, 'message', 'nope'),
          ),
        );
      });
    });

    group('getSources', () {
      test(
        'returns displays first, then windows sorted by app and title',
        () async {
          when(() => client.getDisplays()).thenAnswer(
            (_) async => const [
              CaptureDisplay(id: 10, width: 1512, height: 982),
              CaptureDisplay(id: 20, width: 2560.4, height: 1440),
            ],
          );
          when(() => client.getWindows()).thenAnswer(
            (_) async => [
              _window(applicationName: 'Xcode', title: 'b'),
              _window(id: 2, applicationName: 'code', title: 'B'),
              _window(id: 3, applicationName: 'Code', title: 'a'),
            ],
          );

          expect(await repository.getSources(), const [
            DisplayRecordingSource(id: 10, number: 1, width: 1512, height: 982),
            DisplayRecordingSource(
              id: 20,
              number: 2,
              width: 2560,
              height: 1440,
            ),
            WindowRecordingSource(id: 3, applicationName: 'Code', title: 'a'),
            WindowRecordingSource(id: 2, applicationName: 'code', title: 'B'),
            WindowRecordingSource(id: 1, applicationName: 'Xcode', title: 'b'),
          ]);
        },
      );

      test('skips hidden, tiny, unnamed and excluded windows', () async {
        when(() => client.getDisplays()).thenAnswer((_) async => const []);
        when(() => client.getWindows()).thenAnswer(
          (_) async => [
            _window(isOnScreen: false),
            _window(id: 2, width: 20),
            _window(id: 3, height: 20),
            _window(id: 4, title: ' ', applicationName: null),
            _window(id: 5, bundleIdentifier: 'io.github.luwdm.showtime'),
            _window(id: 6, title: null, applicationName: ' Finder '),
          ],
        );

        expect(await repository.getSources(), const [
          WindowRecordingSource(id: 6, applicationName: 'Finder', title: ''),
        ]);
      });

      test('maps errors to $RecordingFailure', () {
        when(() => client.getDisplays())
            .thenThrow(const ScreenCaptureException('content-unavailable'));

        expect(
          repository.getSources,
          throwsA(
            isA<RecordingFailure>().having(
              (f) => f.reason,
              'reason',
              RecordingFailureReason.unknown,
            ),
          ),
        );
      });
    });

    group('startRecording', () {
      test('records display into a timestamped file', () async {
        final result = await withClock(Clock.fixed(startedAt), () {
          return repository.startRecording(
            const DisplayRecordingSource(
              id: 10,
              number: 1,
              width: 1,
              height: 1,
            ),
          );
        });

        verify(
          () => client.startRecording(
            source: const DisplayCaptureSource(displayId: 10),
            outputPath: '/Movies/Showtime/Showtime 2026-11-28 at 09.05.03.mp4',
          ),
        ).called(1);
        expect(result, startedAt);
        expect(repository.isRecording, isTrue);
      });

      test('records window', () async {
        await repository.startRecording(
          const WindowRecordingSource(id: 7, applicationName: 'A', title: 'B'),
        );

        verify(
          () => client.startRecording(
            source: const WindowCaptureSource(windowId: 7),
            outputPath: any(named: 'outputPath'),
            framesPerSecond: any(named: 'framesPerSecond'),
          ),
        ).called(1);
      });

      test('throws when already recording', () async {
        const source = WindowRecordingSource(
          id: 7,
          applicationName: 'A',
          title: 'B',
        );
        await repository.startRecording(source);

        expect(
          () => repository.startRecording(source),
          throwsA(isA<RecordingFailure>()),
        );
      });

      test('maps source-not-found and stays idle', () async {
        when(
          () => client.startRecording(
            source: any(named: 'source'),
            outputPath: any(named: 'outputPath'),
            framesPerSecond: any(named: 'framesPerSecond'),
          ),
        ).thenThrow(const ScreenCaptureException('source-not-found'));

        await expectLater(
          repository.startRecording(
            const WindowRecordingSource(id: 7, applicationName: 'A', title: ''),
          ),
          throwsA(
            isA<RecordingFailure>().having(
              (f) => f.reason,
              'reason',
              RecordingFailureReason.sourceNotFound,
            ),
          ),
        );
        expect(repository.isRecording, isFalse);
      });
    });

    group('stopRecording', () {
      test('returns recording with duration', () async {
        await withClock(Clock.fixed(startedAt), () async {
          await repository.startRecording(
            const WindowRecordingSource(id: 7, applicationName: 'A', title: ''),
          );
        });

        final recording = await withClock(
          Clock.fixed(startedAt.add(const Duration(seconds: 42))),
          repository.stopRecording,
        );

        expect(
          recording,
          Recording(
            path: '/Movies/Showtime/Showtime 2026-11-28 at 09.05.03.mp4',
            startedAt: startedAt,
            duration: const Duration(seconds: 42),
          ),
        );
        expect(repository.isRecording, isFalse);
      });

      test('throws when not recording', () {
        expect(repository.stopRecording, throwsA(isA<RecordingFailure>()));
      });

      test('maps no-frames', () async {
        when(() => client.stopRecording())
            .thenThrow(const ScreenCaptureException('no-frames'));
        await repository.startRecording(
          const WindowRecordingSource(id: 7, applicationName: 'A', title: ''),
        );

        await expectLater(
          repository.stopRecording(),
          throwsA(
            isA<RecordingFailure>().having(
              (f) => f.reason,
              'reason',
              RecordingFailureReason.noFrames,
            ),
          ),
        );
        expect(repository.isRecording, isFalse);
      });
    });

    group('interruptions', () {
      late StreamController<RecordingInterruption> controller;

      setUp(() {
        controller = StreamController<RecordingInterruption>();
        when(() => client.interruptions).thenAnswer((_) => controller.stream);
      });

      tearDown(() => controller.close());

      test('emits recording when a file was saved', () async {
        await withClock(Clock.fixed(startedAt), () async {
          await repository.startRecording(
            const WindowRecordingSource(id: 7, applicationName: 'A', title: ''),
          );
        });

        final next = withClock(
          Clock.fixed(startedAt.add(const Duration(seconds: 5))),
          () => repository.interruptions.first,
        );
        controller.add(
          const RecordingInterruption(path: '/a.mp4', message: 'closed'),
        );

        expect(
          await next,
          RecordingInterrupted(
            message: 'closed',
            recording: Recording(
              path: '/a.mp4',
              startedAt: startedAt,
              duration: const Duration(seconds: 5),
            ),
          ),
        );
        expect(repository.isRecording, isFalse);
      });

      test('emits without recording when no file was saved', () async {
        final next = repository.interruptions.first;
        controller.add(const RecordingInterruption(message: 'failed'));

        expect(await next, const RecordingInterrupted(message: 'failed'));
      });
    });

    test('revealRecording reveals the file', () async {
      when(() => client.revealFile(any())).thenAnswer((_) async {});

      await repository.revealRecording(
        Recording(
          path: '/a.mp4',
          startedAt: startedAt,
          duration: Duration.zero,
        ),
      );

      verify(() => client.revealFile('/a.mp4')).called(1);
    });

    test('fileNameFor pads date and time', () {
      expect(
        RecordingRepository.fileNameFor(DateTime(2026, 1, 2, 3, 4, 5)),
        'Showtime 2026-01-02 at 03.04.05.mp4',
      );
    });
  });

  test('$RecordingFailure toString contains reason and message', () {
    expect(
      const RecordingFailure(RecordingFailureReason.noFrames, 'x').toString(),
      'RecordingFailure(RecordingFailureReason.noFrames, x)',
    );
  });

  test('source keys are unique per type', () {
    expect(
      const DisplayRecordingSource(id: 1, number: 1, width: 1, height: 1).key,
      'display-1',
    );
    expect(
      const WindowRecordingSource(id: 1, applicationName: '', title: '').key,
      'window-1',
    );
  });
}
