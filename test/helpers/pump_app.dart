import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recording_repository/recording_repository.dart';

class MockRecordingRepository extends Mock implements RecordingRepository;

extension PumpApp on WidgetTester {
  Future<void> pumpApp(
    Widget widget, {
    RecordingRepository? recordingRepository,
  }) {
    return pumpWidget(
      RepositoryProvider.value(
        value: recordingRepository ?? MockRecordingRepository(),
        child: MaterialApp(home: Scaffold(body: widget)),
      ),
    );
  }
}
