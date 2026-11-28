import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:showtime/recording/bloc/recording_bloc.dart';

/// Explains why Showtime needs screen recording permission.
class PermissionPrompt extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.screen_share_outlined,
                size: 48,
                color: theme.colorScheme.primary,
              ),
              const SizedBox(height: 16),
              Text(
                'Screen recording permission needed',
                style: theme.textTheme.titleLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              const Text(
                'Allow Showtime under System Settings › Privacy & Security › '
                'Screen & System Audio Recording. Restart Showtime afterwards.',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                alignment: WrapAlignment.center,
                children: [
                  FilledButton(
                    onPressed: () => context.read<RecordingBloc>().add(
                      const RecordingPermissionRequested(),
                    ),
                    child: const Text('Grant access'),
                  ),
                  OutlinedButton(
                    onPressed: () => context.read<RecordingBloc>().add(
                      const RecordingPermissionSettingsRequested(),
                    ),
                    child: const Text('Open System Settings'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
