part of 'recording_bloc.dart';

sealed class RecordingEvent extends Equatable {
  const new();

  @override
  List<Object?> get props => [];
}

/// Checks the permission, loads the sources and listens for interruptions.
final class RecordingSubscriptionRequested extends RecordingEvent {
  const new();
}

/// Asks the user for screen recording permission.
final class RecordingPermissionRequested extends RecordingEvent {
  const new();
}

/// Opens the system settings to grant permission manually.
final class RecordingPermissionSettingsRequested extends RecordingEvent {
  const new();
}

/// Reloads the displays and windows that can be recorded.
final class RecordingSourcesRefreshed extends RecordingEvent {
  const new();
}

/// The user picked what to record.
final class RecordingSourceSelected extends RecordingEvent {
  const new(this.source);

  final RecordingSource source;

  @override
  List<Object?> get props => [source];
}

final class RecordingStartRequested extends RecordingEvent {
  const new();
}

final class RecordingStopRequested extends RecordingEvent {
  const new();
}

/// Shows the last recording in the file manager.
final class RecordingRevealRequested extends RecordingEvent {
  const new();
}
