import 'dart:async';

import 'package:clock/clock.dart';
import 'package:material_ui/material_ui.dart';

/// Shows the time since [since] as `m:ss`, updated every second.
class ElapsedTime extends StatefulWidget {
  const new({required this.since, super.key, this.style});

  final DateTime since;
  final TextStyle? style;

  @visibleForTesting
  static String format(Duration duration) {
    final minutes = duration.inMinutes;
    final seconds = (duration.inSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  @override
  State<ElapsedTime> createState() => _ElapsedTimeState();
}

class _ElapsedTimeState extends State<ElapsedTime> {
  late final Timer _timer;

  @override
  void initState() {
    super.initState();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) => setState(() {}));
  }

  @override
  void dispose() {
    _timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final elapsed = clock.now().difference(widget.since);
    return Text(
      ElapsedTime.format(elapsed.isNegative ? Duration.zero : elapsed),
      style: widget.style,
    );
  }
}
