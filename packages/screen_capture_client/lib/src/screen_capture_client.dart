import 'dart:async';

import 'package:flutter/services.dart';
import 'package:meta/meta.dart';
import 'package:screen_capture_client/src/messages.g.dart';
import 'package:screen_capture_client/src/models/models.dart';
import 'package:screen_capture_client/src/screen_capture_exception.dart';

/// Signature of the function that registers the handler for calls from the
/// platform. Replaceable in tests.
@visibleForTesting
typedef FlutterApiSetUp = void Function(ScreenCaptureFlutterApi? api);

/// Records the screen using the native capture APIs of the platform.
///
/// Currently only macOS (ScreenCaptureKit, macOS 13+) is supported.
class ScreenCaptureClient {
  /// Creates a screen capture client.
  new({
    @visibleForTesting ScreenCaptureHostApi? hostApi,
    @visibleForTesting FlutterApiSetUp? flutterApiSetUp,
  }) : _hostApi = hostApi ?? ScreenCaptureHostApi() {
    (flutterApiSetUp ?? ScreenCaptureFlutterApi.setUp)(
      _FlutterApiHandler(_interruptions),
    );
  }

  final ScreenCaptureHostApi _hostApi;
  final _interruptions = StreamController<RecordingInterruption>.broadcast();

  /// Emits when the system stops a running recording, e.g. because the
  /// captured window was closed.
  Stream<RecordingInterruption> get interruptions => _interruptions.stream;

  /// Whether the app may capture the screen.
  Future<bool> hasPermission() => _guard(_hostApi.hasPermission);

  /// Asks the user for permission to capture the screen.
  ///
  /// Returns whether permission is granted. On macOS the system dialog is
  /// only shown once; afterwards see [openPermissionSettings].
  Future<bool> requestPermission() => _guard(_hostApi.requestPermission);

  /// Opens the system settings page for screen capture permissions.
  Future<void> openPermissionSettings() =>
      _guard(_hostApi.openPermissionSettings);

  /// The default directory for recordings.
  Future<String> getDefaultOutputDirectory() =>
      _guard(_hostApi.getDefaultOutputDirectory);

  /// The displays that can be captured.
  Future<List<CaptureDisplay>> getDisplays() async {
    final displays = await _guard(_hostApi.getDisplays);
    return [
      for (final display in displays)
        CaptureDisplay(
          id: display.id,
          width: display.width,
          height: display.height,
        ),
    ];
  }

  /// The windows that can be captured.
  Future<List<CaptureWindow>> getWindows() async {
    final windows = await _guard(_hostApi.getWindows);
    return [
      for (final window in windows)
        CaptureWindow(
          id: window.id,
          title: window.title,
          applicationName: window.applicationName,
          bundleIdentifier: window.bundleIdentifier,
          width: window.width,
          height: window.height,
          isOnScreen: window.isOnScreen,
        ),
    ];
  }

  /// Starts recording [source] into an MP4 file at [outputPath].
  Future<void> startRecording({
    required CaptureSource source,
    required String outputPath,
    int framesPerSecond = 60,
    bool showsCursor = true,
  }) {
    final message = switch (source) {
      DisplayCaptureSource(:final displayId, :final region) =>
        CaptureSourceMessage(
          type: CaptureSourceTypeMessage.display,
          id: displayId,
          region: region == null
              ? null
              : RectMessage(
                  x: region.x,
                  y: region.y,
                  width: region.width,
                  height: region.height,
                ),
        ),
      WindowCaptureSource(:final windowId) => CaptureSourceMessage(
        type: CaptureSourceTypeMessage.window,
        id: windowId,
      ),
    };
    return _guard(
      () => _hostApi.startRecording(
        message,
        RecordingOptionsMessage(
          framesPerSecond: framesPerSecond,
          showsCursor: showsCursor,
          outputPath: outputPath,
        ),
      ),
    );
  }

  /// Stops the running recording and returns the path of the written file.
  Future<String> stopRecording() => _guard(_hostApi.stopRecording);

  /// Shows the file at [path] in the file manager.
  Future<void> revealFile(String path) =>
      _guard(() => _hostApi.revealFile(path));

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on PlatformException catch (error) {
      throw ScreenCaptureException(error.code, error.message);
    }
  }
}

class _FlutterApiHandler implements ScreenCaptureFlutterApi {
  new(this._interruptions);

  final StreamController<RecordingInterruption> _interruptions;

  @override
  void onRecordingInterrupted(String? path, String message) {
    _interruptions.add(RecordingInterruption(path: path, message: message));
  }
}
