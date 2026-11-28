import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:screen_capture_client/screen_capture_client.dart';
import 'package:screen_capture_client/src/messages.g.dart';

class _MockHostApi extends Mock implements ScreenCaptureHostApi;

void main() {
  setUpAll(() {
    registerFallbackValue(
      CaptureSourceMessage(type: CaptureSourceTypeMessage.display, id: 0),
    );
    registerFallbackValue(
      RecordingOptionsMessage(
        framesPerSecond: 0,
        showsCursor: false,
        outputPath: '',
      ),
    );
  });

  group(ScreenCaptureClient, () {
    late ScreenCaptureHostApi hostApi;
    late ScreenCaptureFlutterApi? flutterApi;
    late ScreenCaptureClient client;

    setUp(() {
      hostApi = _MockHostApi();
      flutterApi = null;
      client = ScreenCaptureClient(
        hostApi: hostApi,
        flutterApiSetUp: (api) => flutterApi = api,
      );
    });

    test('can be instantiated with default dependencies', () {
      TestWidgetsFlutterBinding.ensureInitialized();
      expect(ScreenCaptureClient.new, returnsNormally);
    });

    group('hasPermission', () {
      test('returns value from host', () async {
        when(() => hostApi.hasPermission()).thenAnswer((_) async => true);

        expect(await client.hasPermission(), isTrue);
      });

      test('throws $ScreenCaptureException on $PlatformException', () {
        when(
          () => hostApi.hasPermission(),
        ).thenThrow(PlatformException(code: 'channel-error', message: 'oops'));

        expect(
          client.hasPermission,
          throwsA(
            isA<ScreenCaptureException>()
                .having((e) => e.code, 'code', 'channel-error')
                .having((e) => e.message, 'message', 'oops'),
          ),
        );
      });
    });

    test('requestPermission returns value from host', () async {
      when(() => hostApi.requestPermission()).thenAnswer((_) async => false);

      expect(await client.requestPermission(), isFalse);
    });

    test('openPermissionSettings calls host', () async {
      when(() => hostApi.openPermissionSettings()).thenAnswer((_) async {});

      await client.openPermissionSettings();

      verify(() => hostApi.openPermissionSettings()).called(1);
    });

    test('getDefaultOutputDirectory returns value from host', () async {
      when(() => hostApi.getDefaultOutputDirectory())
          .thenAnswer((_) async => '/Movies/Showtime');

      expect(await client.getDefaultOutputDirectory(), '/Movies/Showtime');
    });

    test('getDisplays maps host messages', () async {
      when(() => hostApi.getDisplays()).thenAnswer(
        (_) async => [DisplayMessage(id: 1, width: 1440, height: 900)],
      );

      expect(await client.getDisplays(), const [
        CaptureDisplay(id: 1, width: 1440, height: 900),
      ]);
    });

    test('getWindows maps host messages', () async {
      when(() => hostApi.getWindows()).thenAnswer(
        (_) async => [
          WindowMessage(
            id: 7,
            title: 'main.dart',
            applicationName: 'Code',
            bundleIdentifier: 'com.microsoft.VSCode',
            width: 800,
            height: 600,
            isOnScreen: true,
          ),
        ],
      );

      expect(await client.getWindows(), const [
        CaptureWindow(
          id: 7,
          title: 'main.dart',
          applicationName: 'Code',
          bundleIdentifier: 'com.microsoft.VSCode',
          width: 800,
          height: 600,
          isOnScreen: true,
        ),
      ]);
    });

    group('startRecording', () {
      setUp(() {
        when(() => hostApi.startRecording(any(), any()))
            .thenAnswer((_) async {});
      });

      test('sends display source with region', () async {
        await client.startRecording(
          source: const DisplayCaptureSource(
            displayId: 1,
            region: CaptureRegion(x: 10, y: 20, width: 300, height: 200),
          ),
          outputPath: '/tmp/a.mp4',
          framesPerSecond: 30,
          showsCursor: false,
        );

        final captured = verify(
          () => hostApi.startRecording(captureAny(), captureAny()),
        ).captured;
        final source = captured[0] as CaptureSourceMessage;
        final options = captured[1] as RecordingOptionsMessage;
        expect(source.type, CaptureSourceTypeMessage.display);
        expect(source.id, 1);
        expect(source.region?.x, 10);
        expect(source.region?.y, 20);
        expect(source.region?.width, 300);
        expect(source.region?.height, 200);
        expect(options.framesPerSecond, 30);
        expect(options.showsCursor, isFalse);
        expect(options.outputPath, '/tmp/a.mp4');
      });

      test('sends display source without region', () async {
        await client.startRecording(
          source: const DisplayCaptureSource(displayId: 2),
          outputPath: '/tmp/a.mp4',
        );

        final captured = verify(
          () => hostApi.startRecording(captureAny(), captureAny()),
        ).captured;
        final source = captured[0] as CaptureSourceMessage;
        final options = captured[1] as RecordingOptionsMessage;
        expect(source.region, isNull);
        expect(options.framesPerSecond, 60);
        expect(options.showsCursor, isTrue);
      });

      test('sends window source', () async {
        await client.startRecording(
          source: const WindowCaptureSource(windowId: 7),
          outputPath: '/tmp/a.mp4',
        );

        final source =
            verify(() => hostApi.startRecording(captureAny(), any()))
                    .captured
                    .single
                as CaptureSourceMessage;
        expect(source.type, CaptureSourceTypeMessage.window);
        expect(source.id, 7);
      });
    });

    test('stopRecording returns path from host', () async {
      when(() => hostApi.stopRecording()).thenAnswer((_) async => '/tmp/a.mp4');

      expect(await client.stopRecording(), '/tmp/a.mp4');
    });

    test('revealFile calls host', () async {
      when(() => hostApi.revealFile(any())).thenAnswer((_) async {});

      await client.revealFile('/tmp/a.mp4');

      verify(() => hostApi.revealFile('/tmp/a.mp4')).called(1);
    });

    test('interruptions emits calls from the platform', () {
      expect(
        client.interruptions,
        emits(
          const RecordingInterruption(path: '/tmp/a.mp4', message: 'closed'),
        ),
      );

      flutterApi!.onRecordingInterrupted('/tmp/a.mp4', 'closed');
    });
  });

  group(ScreenCaptureException, () {
    test('toString contains code and message', () {
      expect(
        const ScreenCaptureException('code', 'message').toString(),
        'ScreenCaptureException(code, message)',
      );
    });
  });
}
