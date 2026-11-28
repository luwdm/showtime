import 'package:equatable/equatable.dart';

/// A rectangle on a display in logical pixels.
class CaptureRegion extends Equatable {
  /// Creates a rectangle on a display in logical pixels.
  const new({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
  });

  /// Distance from the left edge of the display.
  final double x;

  /// Distance from the top edge of the display.
  final double y;

  /// Width of the region.
  final double width;

  /// Height of the region.
  final double height;

  @override
  List<Object> get props => [x, y, width, height];
}
