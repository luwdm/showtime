import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:path/path.dart' as p;
import 'package:showtime/recording/bloc/recording_bloc.dart';
import 'package:showtime/recording/widgets/elapsed_time.dart';

/// Starts and stops recordings and shows the last saved recording.
class RecordBar extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecordingBloc>().state;
    final theme = Theme.of(context);
    final startedAt = state.startedAt;
    final lastRecording = state.lastRecording;

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Expanded(
            child: switch (state.status) {
              RecordingStatus.recording when startedAt != null => Row(
                children: [
                  Icon(Icons.circle, size: 12, color: theme.colorScheme.error),
                  const SizedBox(width: 8),
                  ElapsedTime(
                    since: startedAt,
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
              _ when lastRecording != null => Row(
                children: [
                  Flexible(
                    child: Text(
                      'Saved ${p.basename(lastRecording.path)}',
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.read<RecordingBloc>().add(
                      const RecordingRevealRequested(),
                    ),
                    child: const Text('Show in Finder'),
                  ),
                ],
              ),
              _ => const SizedBox.shrink(),
            },
          ),
          const SizedBox(width: 16),
          if (state.status == RecordingStatus.recording)
            FilledButton.icon(
              style: FilledButton.styleFrom(
                backgroundColor: theme.colorScheme.error,
                foregroundColor: theme.colorScheme.onError,
              ),
              onPressed: () => context.read<RecordingBloc>().add(
                const RecordingStopRequested(),
              ),
              icon: const Icon(Icons.stop),
              label: const Text('Stop'),
            )
          else
            FilledButton.icon(
              onPressed: state.canStart
                  ? () => context.read<RecordingBloc>().add(
                      const RecordingStartRequested(),
                    )
                  : null,
              icon: state.status.isBusy
                  ? const SizedBox.square(
                      dimension: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.fiber_manual_record),
              label: const Text('Record'),
            ),
        ],
      ),
    );
  }
}
