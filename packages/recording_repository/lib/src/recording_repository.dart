import 'dart:async';

import 'package:clock/clock.dart';
import 'package:path/path.dart' as p;
import 'package:recording_repository/src/models/models.dart';
import 'package:screen_capture_client/screen_capture_client.dart';

/// Manages screen recordings and the sources that can be recorded.
class RecordingRepository {
  /// Creates a recording repository.
  ///
  /// Windows of applications in [_excludedBundleIdentifiers] are not offered
  /// as sources, e.g. the app's own windows.
  new({
    required ScreenCaptureClient screenCaptureClient,
    this._excludedBundleIdentifiers = const {},
  }) : _client = screenCaptureClient;

  /// Windows smaller than this (in logical pixels) are not offered.
  static const minimumWindowSize = 64.0;

  /// Frame rate of recordings.
  static const framesPerSecond = 60;

  final ScreenCaptureClient _client;
  final Set<String> _excludedBundleIdentifiers;

  DateTime? _startedAt;

  /// Whether the app may record the screen.
  Future<bool> hasPermission() => _guard(_client.hasPermission);

  /// Asks the user for permission to record the screen.
  Future<bool> requestPermission() => _guard(_client.requestPermission);

  /// Opens the system settings to grant permission manually.
  Future<void> openPermissionSettings() =>
      _guard(_client.openPermissionSettings);

  /// All displays, followed by all visible windows sorted by application and
  /// title.
  Future<List<RecordingSource>> getSources() async {
    final displays = await _guard(_client.getDisplays);
    final windows = await _guard(_client.getWindows);

    final windowSources =
        windows
            .where(_isRecordable)
            .map(
              (window) => WindowRecordingSource(
                id: window.id,
                applicationName: window.applicationName?.trim() ?? '',
                title: window.title?.trim() ?? '',
              ),
            )
            .toList()
          ..sort((a, b) {
            final byApp = a.applicationName.toLowerCase().compareTo(
              b.applicationName.toLowerCase(),
            );
            if (byApp != 0) return byApp;
            return a.title.toLowerCase().compareTo(b.title.toLowerCase());
          });

    return [
      for (final (index, display) in displays.indexed)
        DisplayRecordingSource(
          id: display.id,
          number: index + 1,
          width: display.width.round(),
          height: display.height.round(),
        ),
      ...windowSources,
    ];
  }

  bool _isRecordable(CaptureWindow window) {
    final hasName =
        (window.title?.trim().isNotEmpty ?? false) ||
        (window.applicationName?.trim().isNotEmpty ?? false);
    return window.isOnScreen &&
        hasName &&
        window.width >= minimumWindowSize &&
        window.height >= minimumWindowSize &&
        !_excludedBundleIdentifiers.contains(window.bundleIdentifier);
  }

  /// Whether a recording is running.
  bool get isRecording => _startedAt != null;

  /// Starts recording [source] into a new file in the default directory.
  ///
  /// Returns when the recording started.
  Future<DateTime> startRecording(RecordingSource source) async {
    if (isRecording) {
      throw const RecordingFailure(
        RecordingFailureReason.unknown,
        'A recording is already running.',
      );
    }
    final startedAt = clock.now();
    final directory = await _guard(_client.getDefaultOutputDirectory);
    await _guard(
      () => _client.startRecording(
        source: switch (source) {
          DisplayRecordingSource(:final id) => DisplayCaptureSource(
            displayId: id,
          ),
          WindowRecordingSource(:final id) => WindowCaptureSource(windowId: id),
        },
        outputPath: p.join(directory, fileNameFor(startedAt)),
      ),
    );
    _startedAt = startedAt;
    return startedAt;
  }

  /// Stops the running recording.
  Future<Recording> stopRecording() async {
    final startedAt = _startedAt;
    if (startedAt == null) {
      throw const RecordingFailure(
        RecordingFailureReason.unknown,
        'No recording is running.',
      );
    }
    _startedAt = null;
    final path = await _guard(_client.stopRecording);
    return Recording(
      path: path,
      startedAt: startedAt,
      duration: clock.now().difference(startedAt),
    );
  }

  /// Emits when the system stops a running recording.
  Stream<RecordingInterrupted> get interruptions =>
      _client.interruptions.map((interruption) {
        final startedAt = _startedAt;
        _startedAt = null;
        final path = interruption.path;
        return RecordingInterrupted(
          message: interruption.message,
          recording: path == null || startedAt == null
              ? null
              : Recording(
                  path: path,
                  startedAt: startedAt,
                  duration: clock.now().difference(startedAt),
                ),
        );
      });

  /// Shows [recording] in the file manager.
  Future<void> revealRecording(Recording recording) =>
      _guard(() => _client.revealFile(recording.path));

  /// File name of a recording started at [startedAt].
  static String fileNameFor(DateTime startedAt) {
    String two(int value) => value.toString().padLeft(2, '0');
    final date =
        '${startedAt.year}-${two(startedAt.month)}-${two(startedAt.day)}';
    final time =
        '${two(startedAt.hour)}.${two(startedAt.minute)}.'
        '${two(startedAt.second)}';
    return 'Showtime $date at $time.mp4';
  }

  Future<T> _guard<T>(Future<T> Function() call) async {
    try {
      return await call();
    } on ScreenCaptureException catch (error) {
      throw RecordingFailure(_reasonFor(error.code), error.message);
    }
  }

  static RecordingFailureReason _reasonFor(String code) => switch (code) {
    'permission-denied' => RecordingFailureReason.permissionDenied,
    'source-not-found' => RecordingFailureReason.sourceNotFound,
    'no-frames' => RecordingFailureReason.noFrames,
    _ => RecordingFailureReason.unknown,
  };
}
