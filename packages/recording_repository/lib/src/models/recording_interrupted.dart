import 'package:equatable/equatable.dart';
import 'package:recording_repository/src/models/recording.dart';

/// The system stopped a recording, e.g. because the captured window was
/// closed.
class RecordingInterrupted extends Equatable {
  /// Creates a recording interruption.
  const new({required this.message, this.recording});

  /// The recording, if a file could be saved.
  final Recording? recording;

  /// Describes why the recording stopped.
  final String message;

  @override
  List<Object?> get props => [recording, message];
}
