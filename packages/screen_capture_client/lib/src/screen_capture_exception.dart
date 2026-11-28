/// Thrown when a screen capture operation fails.
class ScreenCaptureException implements Exception {
  /// Creates a screen capture exception.
  const new(this.code, [this.message]);

  /// Machine readable error code, e.g. `permission-denied`.
  final String code;

  /// Human readable description.
  final String? message;

  @override
  String toString() => 'ScreenCaptureException($code, $message)';
}
