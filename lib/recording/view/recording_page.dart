import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recording_repository/recording_repository.dart';
import 'package:showtime/recording/bloc/recording_bloc.dart';
import 'package:showtime/recording/widgets/widgets.dart';

class RecordingPage extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RecordingBloc(
        recordingRepository: context.read<RecordingRepository>(),
      )..add(const RecordingSubscriptionRequested()),
      child: const RecordingView(),
    );
  }
}

class RecordingView extends StatelessWidget {
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocListener<RecordingBloc, RecordingState>(
      listenWhen: (previous, current) =>
          previous.failure != current.failure && current.failure != null,
      listener: (context, state) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(content: Text(failureMessage(state.failure!))),
          );
      },
      child: Scaffold(
        appBar: AppBar(title: const Text('Showtime')),
        body: BlocBuilder<RecordingBloc, RecordingState>(
          buildWhen: (previous, current) =>
              previous.permission != current.permission,
          builder: (context, state) => switch (state.permission) {
            PermissionStatus.unknown => const Center(
              child: CircularProgressIndicator(),
            ),
            PermissionStatus.denied => const PermissionPrompt(),
            PermissionStatus.granted => const Column(
              children: [
                Expanded(child: SourceList()),
                Divider(height: 1),
                RecordBar(),
              ],
            ),
          },
        ),
      ),
    );
  }

  @visibleForTesting
  static String failureMessage(RecordingFailureReason reason) =>
      switch (reason) {
        RecordingFailureReason.permissionDenied =>
          'Showtime is not allowed to record the screen.',
        RecordingFailureReason.sourceNotFound =>
          'The selected display or window is no longer available.',
        RecordingFailureReason.noFrames =>
          'Nothing was recorded. Try recording a little longer.',
        RecordingFailureReason.unknown => 'Something went wrong.',
      };
}
