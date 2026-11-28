import 'package:bloc_test/bloc_test.dart';
import 'package:showtime/recording/recording.dart';

class MockRecordingBloc extends MockBloc<RecordingEvent, RecordingState>
    implements RecordingBloc;
