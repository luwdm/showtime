part of 'recording_bloc.dart';

enum PermissionStatus { unknown, granted, denied }

enum SourcesStatus { initial, loading, success, failure }

enum RecordingStatus {
  idle,
  starting,
  recording,
  stopping;

  bool get isBusy => this == starting || this == stopping;
}

final class RecordingState extends Equatable {
  const new({
    this.permission = PermissionStatus.unknown,
    this.sourcesStatus = SourcesStatus.initial,
    this.sources = const [],
    this.selectedSource,
    this.status = RecordingStatus.idle,
    this.startedAt,
    this.lastRecording,
    this.failure,
  });

  final PermissionStatus permission;
  final SourcesStatus sourcesStatus;
  final List<RecordingSource> sources;
  final RecordingSource? selectedSource;
  final RecordingStatus status;

  /// When the running recording started.
  final DateTime? startedAt;

  /// The most recently saved recording.
  final Recording? lastRecording;

  /// The error of the last action, if it failed.
  final RecordingFailureReason? failure;

  bool get canStart =>
      permission == PermissionStatus.granted &&
      selectedSource != null &&
      status == RecordingStatus.idle;

  RecordingState copyWith({
    PermissionStatus? permission,
    SourcesStatus? sourcesStatus,
    List<RecordingSource>? sources,
    RecordingSource? Function()? selectedSource,
    RecordingStatus? status,
    DateTime? Function()? startedAt,
    Recording? Function()? lastRecording,
    RecordingFailureReason? Function()? failure,
  }) {
    return RecordingState(
      permission: permission ?? this.permission,
      sourcesStatus: sourcesStatus ?? this.sourcesStatus,
      sources: sources ?? this.sources,
      selectedSource: selectedSource != null
          ? selectedSource()
          : this.selectedSource,
      status: status ?? this.status,
      startedAt: startedAt != null ? startedAt() : this.startedAt,
      lastRecording: lastRecording != null
          ? lastRecording()
          : this.lastRecording,
      failure: failure != null ? failure() : this.failure,
    );
  }

  @override
  List<Object?> get props => [
    permission,
    sourcesStatus,
    sources,
    selectedSource,
    status,
    startedAt,
    lastRecording,
    failure,
  ];
}
