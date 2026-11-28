import 'package:pigeon/pigeon.dart';

@ConfigurePigeon(
  PigeonOptions(
    dartPackageName: 'screen_capture_client',
    dartOut: 'lib/src/messages.g.dart',
    swiftOut: 'macos/screen_capture_client/Sources/screen_capture_client/Messages.g.swift',
  ),
)
/// A display that can be captured.
class DisplayMessage {
  DisplayMessage({required this.id, required this.width, required this.height});

  /// The CoreGraphics display id.
  int id;

  /// Width in points.
  double width;

  /// Height in points.
  double height;
}

/// A window that can be captured.
class WindowMessage {
  WindowMessage({
    required this.id,
    required this.width,
    required this.height,
    required this.isOnScreen,
    this.title,
    this.applicationName,
    this.bundleIdentifier,
  });

  /// The CoreGraphics window id.
  int id;

  String? title;

  String? applicationName;

  String? bundleIdentifier;

  /// Width in points.
  double width;

  /// Height in points.
  double height;

  bool isOnScreen;
}

/// A rectangle in points.
class RectMessage {
  RectMessage({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  double x;
  double y;
  double width;
  double height;
}

enum CaptureSourceTypeMessage { display, window }

/// What to capture.
class CaptureSourceMessage {
  CaptureSourceMessage({required this.type, required this.id, this.region});

  CaptureSourceTypeMessage type;

  /// Display id or window id, depending on [type].
  int id;

  /// Optional part of a display to capture. Ignored for windows.
  RectMessage? region;
}

class RecordingOptionsMessage {
  RecordingOptionsMessage({
    required this.framesPerSecond,
    required this.showsCursor,
    required this.outputPath,
  });

  int framesPerSecond;
  bool showsCursor;

  /// Absolute path of the MP4 file to write.
  String outputPath;
}

@HostApi()
abstract class ScreenCaptureHostApi {
  /// Whether the app may capture the screen.
  bool hasPermission();

  /// Asks the user for screen capture permission.
  ///
  /// Returns whether permission is granted. On macOS the system dialog only
  /// appears once; afterwards the user has to change it in System Settings.
  bool requestPermission();

  /// Opens the screen recording page in System Settings.
  void openPermissionSettings();

  /// The default directory for recordings.
  String getDefaultOutputDirectory();

  @async
  List<DisplayMessage> getDisplays();

  @async
  List<WindowMessage> getWindows();

  @async
  void startRecording(
    CaptureSourceMessage source,
    RecordingOptionsMessage options,
  );

  /// Stops the running recording and returns the path of the written file.
  @async
  String stopRecording();

  /// Shows the file in Finder.
  void revealFile(String path);
}

@FlutterApi()
abstract class ScreenCaptureFlutterApi {
  /// Called when the system stopped a recording, e.g. because the captured
  /// window was closed. [path] is set if a file was written.
  void onRecordingInterrupted(String? path, String message);
}
