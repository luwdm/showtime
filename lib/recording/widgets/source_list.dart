import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recording_repository/recording_repository.dart';
import 'package:showtime/recording/bloc/recording_bloc.dart';

/// Lists the displays and windows that can be recorded.
class SourceList extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<RecordingBloc>().state;
    final displays = state.sources.whereType<DisplayRecordingSource>();
    final windows = state.sources.whereType<WindowRecordingSource>();
    final enabled = state.status == RecordingStatus.idle;

    if (state.sources.isEmpty) {
      return Center(
        child: switch (state.sourcesStatus) {
          SourcesStatus.initial ||
          SourcesStatus.loading => const CircularProgressIndicator(),
          SourcesStatus.failure => const _RefreshHint(
            text: 'Could not load displays and windows.',
          ),
          SourcesStatus.success => const _RefreshHint(
            text: 'No displays or windows found.',
          ),
        },
      );
    }

    return RadioGroup<String>(
      groupValue: state.selectedSource?.key,
      onChanged: (key) {
        final source = state.sources.firstWhere((s) => s.key == key);
        context.read<RecordingBloc>().add(RecordingSourceSelected(source));
      },
      child: ListView(
        children: [
          _Header(
            title: 'Displays',
            trailing: IconButton(
              tooltip: 'Refresh',
              onPressed: enabled
                  ? () => context.read<RecordingBloc>().add(
                      const RecordingSourcesRefreshed(),
                    )
                  : null,
              icon: const Icon(Icons.refresh),
            ),
          ),
          for (final display in displays)
            RadioListTile<String>(
              value: display.key,
              enabled: enabled,
              secondary: const Icon(Icons.desktop_mac_outlined),
              title: Text('Display ${display.number}'),
              subtitle: Text('${display.width} × ${display.height}'),
            ),
          if (windows.isNotEmpty) const _Header(title: 'Windows'),
          for (final window in windows)
            RadioListTile<String>(
              value: window.key,
              enabled: enabled,
              secondary: const Icon(Icons.web_asset_outlined),
              title: Text(
                window.title.isEmpty ? window.applicationName : window.title,
                overflow: TextOverflow.ellipsis,
              ),
              subtitle: window.title.isEmpty
                  ? null
                  : Text(window.applicationName),
            ),
        ],
      ),
    );
  }
}

class _Header extends StatelessWidget {
  const new({required this.title, this.trailing});

  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 8, 4),
      child: Row(
        children: [
          Expanded(
            child: Text(title, style: Theme.of(context).textTheme.titleSmall),
          ),
          ?trailing,
        ],
      ),
    );
  }
}

class _RefreshHint extends StatelessWidget {
  const new({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(text),
        const SizedBox(height: 12),
        OutlinedButton.icon(
          onPressed: () => context.read<RecordingBloc>().add(
            const RecordingSourcesRefreshed(),
          ),
          icon: const Icon(Icons.refresh),
          label: const Text('Try again'),
        ),
      ],
    );
  }
}
