/// Why a recording operation failed.
enum RecordingFailureReason {
  /// The app is not allowed to capture the screen.
  permissionDenied,

  /// The selected display or window no longer exists.
  sourceNotFound,

  /// The recording stopped before any frame was captured.
  noFrames,

  /// Any other error.
  unknown,
}

/// Thrown when a recording operation fails.
class RecordingFailure implements Exception {
  /// Creates a recording failure.
  const new(this.reason, [this.message]);

  /// Why the operation failed.
  final RecordingFailureReason reason;

  /// Technical details, if available.
  final String? message;

  @override
  String toString() => 'RecordingFailure($reason, $message)';
}
