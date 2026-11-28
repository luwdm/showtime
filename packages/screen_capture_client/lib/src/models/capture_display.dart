import 'package:equatable/equatable.dart';

/// A display that can be captured.
class CaptureDisplay extends Equatable {
  /// Creates a display that can be captured.
  const new({required this.id, required this.width, required this.height});

  /// The platform id of the display.
  final int id;

  /// Width in logical pixels.
  final double width;

  /// Height in logical pixels.
  final double height;

  @override
  List<Object> get props => [id, width, height];
}
