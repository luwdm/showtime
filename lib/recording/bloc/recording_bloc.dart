import 'package:bloc/bloc.dart';
import 'package:equatable/equatable.dart';
import 'package:recording_repository/recording_repository.dart';

part 'recording_event.dart';
part 'recording_state.dart';

class RecordingBloc extends Bloc<RecordingEvent, RecordingState> {
  new({required RecordingRepository recordingRepository})
    : _repository = recordingRepository,
      super(const RecordingState()) {
    on<RecordingSubscriptionRequested>(_onSubscriptionRequested);
    on<RecordingPermissionRequested>(_onPermissionRequested);
    on<RecordingPermissionSettingsRequested>(_onPermissionSettingsRequested);
    on<RecordingSourcesRefreshed>(_onSourcesRefreshed);
    on<RecordingSourceSelected>(_onSourceSelected);
    on<RecordingStartRequested>(_onStartRequested);
    on<RecordingStopRequested>(_onStopRequested);
    on<RecordingRevealRequested>(_onRevealRequested);
  }

  final RecordingRepository _repository;

  Future<void> _onSubscriptionRequested(
    RecordingSubscriptionRequested event,
    Emitter<RecordingState> emit,
  ) async {
    await _updatePermission(_repository.hasPermission, emit);

    await emit.forEach<RecordingInterrupted>(
      _repository.interruptions,
      onData: (interruption) => state.copyWith(
        status: RecordingStatus.idle,
        startedAt: () => null,
        lastRecording: () => interruption.recording ?? state.lastRecording,
        failure: () => interruption.recording == null
            ? RecordingFailureReason.unknown
            : null,
      ),
    );
  }

  Future<void> _onPermissionRequested(
    RecordingPermissionRequested event,
    Emitter<RecordingState> emit,
  ) => _updatePermission(_repository.requestPermission, emit);

  Future<void> _onPermissionSettingsRequested(
    RecordingPermissionSettingsRequested event,
    Emitter<RecordingState> emit,
  ) async {
    try {
      await _repository.openPermissionSettings();
    } on RecordingFailure catch (failure, stackTrace) {
      addError(failure, stackTrace);
      emit(state.copyWith(failure: () => failure.reason));
    }
  }

  Future<void> _updatePermission(
    Future<bool> Function() check,
    Emitter<RecordingState> emit,
  ) async {
    try {
      final granted = await check();
      emit(
        state.copyWith(
          permission: granted
              ? PermissionStatus.granted
              : PermissionStatus.denied,
          failure: () => null,
        ),
      );
      if (granted) await _loadSources(emit);
    } on RecordingFailure catch (failure, stackTrace) {
      addError(failure, stackTrace);
      emit(
        state.copyWith(
          permission: PermissionStatus.denied,
          failure: () => failure.reason,
        ),
      );
    }
  }

  Future<void> _onSourcesRefreshed(
    RecordingSourcesRefreshed event,
    Emitter<RecordingState> emit,
  ) => _loadSources(emit);

  Future<void> _loadSources(Emitter<RecordingState> emit) async {
    emit(state.copyWith(sourcesStatus: SourcesStatus.loading));
    try {
      final sources = await _repository.getSources();
      final selectedKey = state.selectedSource?.key;
      emit(
        state.copyWith(
          sourcesStatus: SourcesStatus.success,
          sources: sources,
          // Keep the selection if the source still exists, otherwise pick the
          // first display.
          selectedSource: () =>
              sources.where((s) => s.key == selectedKey).firstOrNull ??
              sources.firstOrNull,
        ),
      );
    } on RecordingFailure catch (failure, stackTrace) {
      addError(failure, stackTrace);
      emit(
        state.copyWith(
          sourcesStatus: SourcesStatus.failure,
          failure: () => failure.reason,
        ),
      );
    }
  }

  void _onSourceSelected(
    RecordingSourceSelected event,
    Emitter<RecordingState> emit,
  ) {
    if (state.status != RecordingStatus.idle) return;
    emit(state.copyWith(selectedSource: () => event.source));
  }

  Future<void> _onStartRequested(
    RecordingStartRequested event,
    Emitter<RecordingState> emit,
  ) async {
    final source = state.selectedSource;
    if (!state.canStart || source == null) return;

    emit(state.copyWith(status: RecordingStatus.starting, failure: () => null));
    try {
      final startedAt = await _repository.startRecording(source);
      emit(
        state.copyWith(
          status: RecordingStatus.recording,
          startedAt: () => startedAt,
        ),
      );
    } on RecordingFailure catch (failure, stackTrace) {
      addError(failure, stackTrace);
      emit(
        state.copyWith(
          status: RecordingStatus.idle,
          failure: () => failure.reason,
        ),
      );
    }
  }

  Future<void> _onStopRequested(
    RecordingStopRequested event,
    Emitter<RecordingState> emit,
  ) async {
    if (state.status != RecordingStatus.recording) return;

    emit(state.copyWith(status: RecordingStatus.stopping));
    try {
      final recording = await _repository.stopRecording();
      emit(
        state.copyWith(
          status: RecordingStatus.idle,
          startedAt: () => null,
          lastRecording: () => recording,
        ),
      );
    } on RecordingFailure catch (failure, stackTrace) {
      addError(failure, stackTrace);
      emit(
        state.copyWith(
          status: RecordingStatus.idle,
          startedAt: () => null,
          failure: () => failure.reason,
        ),
      );
    }
  }

  Future<void> _onRevealRequested(
    RecordingRevealRequested event,
    Emitter<RecordingState> emit,
  ) async {
    final recording = state.lastRecording;
    if (recording == null) return;
    try {
      await _repository.revealRecording(recording);
    } on RecordingFailure catch (failure, stackTrace) {
      addError(failure, stackTrace);
      emit(state.copyWith(failure: () => failure.reason));
    }
  }
}
