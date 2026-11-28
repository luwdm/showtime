import 'package:equatable/equatable.dart';

/// Something that can be recorded.
sealed class RecordingSource extends Equatable {
  const new();

  /// Unique key of the source, stable while the source exists.
  String get key;
}

/// A whole display.
final class DisplayRecordingSource extends RecordingSource {
  /// Creates a display source.
  const new({
    required this.id,
    required this.number,
    required this.width,
    required this.height,
  });

  /// Platform id of the display.
  final int id;

  /// 1-based position of the display, for labels like "Display 1".
  final int number;

  /// Width in logical pixels.
  final int width;

  /// Height in logical pixels.
  final int height;

  @override
  String get key => 'display-$id';

  @override
  List<Object> get props => [id, number, width, height];
}

/// A single window.
final class WindowRecordingSource extends RecordingSource {
  /// Creates a window source.
  const new({
    required this.id,
    required this.applicationName,
    required this.title,
  });

  /// Platform id of the window.
  final int id;

  /// Name of the application that owns the window.
  final String applicationName;

  /// Window title. Empty if the window has none.
  final String title;

  @override
  String get key => 'window-$id';

  @override
  List<Object> get props => [id, applicationName, title];
}
