import 'package:equatable/equatable.dart';

/// The system stopped a recording, e.g. because the captured window was
/// closed.
class RecordingInterruption extends Equatable {
  /// Creates a recording interruption.
  const new({required this.message, this.path});

  /// Path of the written file, if one could be saved.
  final String? path;

  /// Describes why the recording stopped.
  final String message;

  @override
  List<Object?> get props => [path, message];
}
