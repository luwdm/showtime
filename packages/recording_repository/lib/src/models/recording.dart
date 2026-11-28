import 'package:equatable/equatable.dart';

/// A finished recording.
class Recording extends Equatable {
  /// Creates a finished recording.
  const new({
    required this.path,
    required this.startedAt,
    required this.duration,
  });

  /// Absolute path of the video file.
  final String path;

  /// When the recording was started.
  final DateTime startedAt;

  /// How long the recording ran.
  final Duration duration;

  @override
  List<Object> get props => [path, startedAt, duration];
}
