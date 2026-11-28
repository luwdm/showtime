import 'package:equatable/equatable.dart';

/// A window that can be captured.
class CaptureWindow extends Equatable {
  /// Creates a window that can be captured.
  const new({
    required this.id,
    required this.width,
    required this.height,
    required this.isOnScreen,
    this.title,
    this.applicationName,
    this.bundleIdentifier,
  });

  /// The platform id of the window.
  final int id;

  /// The window title, if the window has one.
  final String? title;

  /// The name of the application that owns the window.
  final String? applicationName;

  /// The bundle identifier of the application that owns the window.
  final String? bundleIdentifier;

  /// Width in logical pixels.
  final double width;

  /// Height in logical pixels.
  final double height;

  /// Whether the window is currently visible.
  final bool isOnScreen;

  @override
  List<Object?> get props => [
    id,
    title,
    applicationName,
    bundleIdentifier,
    width,
    height,
    isOnScreen,
  ];
}
