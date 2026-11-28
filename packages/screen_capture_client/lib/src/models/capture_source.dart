import 'package:equatable/equatable.dart';
import 'package:screen_capture_client/src/models/capture_region.dart';

/// What to capture.
sealed class CaptureSource extends Equatable {
  const new();
}

/// Captures a whole display or a [region] of it.
final class DisplayCaptureSource extends CaptureSource {
  /// Captures a whole display or a [region] of it.
  const new({required this.displayId, this.region});

  /// The id of the display.
  final int displayId;

  /// The part of the display to capture. Captures the whole display if null.
  final CaptureRegion? region;

  @override
  List<Object?> get props => [displayId, region];
}

/// Captures a single window.
final class WindowCaptureSource extends CaptureSource {
  /// Captures a single window.
  const new({required this.windowId});

  /// The id of the window.
  final int windowId;

  @override
  List<Object> get props => [windowId];
}
