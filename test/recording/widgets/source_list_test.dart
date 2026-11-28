import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mocktail/mocktail.dart';
import 'package:recording_repository/recording_repository.dart';
import 'package:showtime/recording/recording.dart';
import 'package:showtime/recording/widgets/widgets.dart';

import '../../helpers/helpers.dart';

const _display = DisplayRecordingSource(
  id: 1,
  number: 1,
  width: 1440,
  height: 900,
);
const _window = WindowRecordingSource(
  id: 2,
  applicationName: 'Code',
  title: 'main.dart',
);
const _untitled = WindowRecordingSource(
  id: 3,
  applicationName: 'Finder',
  title: '',
);

void main() {
  setUpAll(() {
    registerFallbackValue(const RecordingStartRequested());
  });

  group(SourceList, () {
    late RecordingBloc bloc;

    setUp(() {
      bloc = MockRecordingBloc();
    });

    Future<void> pump(WidgetTester tester, RecordingState state) {
      when(() => bloc.state).thenReturn(state);
      return tester.pumpApp(
        BlocProvider.value(value: bloc, child: const SourceList()),
      );
    }

    const ready = RecordingState(
      permission: PermissionStatus.granted,
      sourcesStatus: SourcesStatus.success,
      sources: [_display, _window, _untitled],
      selectedSource: _display,
    );

    testWidgets('shows progress while loading', (tester) async {
      await pump(
        tester,
        const RecordingState(sourcesStatus: SourcesStatus.loading),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);
    });

    testWidgets('offers retry on failure', (tester) async {
      await pump(
        tester,
        const RecordingState(sourcesStatus: SourcesStatus.failure),
      );

      expect(find.text('Could not load displays and windows.'), findsOneWidget);
      await tester.tap(find.text('Try again'));

      verify(() => bloc.add(const RecordingSourcesRefreshed())).called(1);
    });

    testWidgets('shows hint when nothing was found', (tester) async {
      await pump(
        tester,
        const RecordingState(sourcesStatus: SourcesStatus.success),
      );

      expect(find.text('No displays or windows found.'), findsOneWidget);
    });

    testWidgets('lists displays and windows', (tester) async {
      await pump(tester, ready);

      expect(find.text('Display 1'), findsOneWidget);
      expect(find.text('1440 × 900'), findsOneWidget);
      expect(find.text('main.dart'), findsOneWidget);
      expect(find.text('Code'), findsOneWidget);
      expect(find.text('Finder'), findsOneWidget);
    });

    testWidgets('selects a source', (tester) async {
      await pump(tester, ready);

      await tester.tap(find.text('main.dart'));

      verify(() => bloc.add(const RecordingSourceSelected(_window))).called(1);
    });

    testWidgets('refreshes sources', (tester) async {
      await pump(tester, ready);

      await tester.tap(find.byTooltip('Refresh'));

      verify(() => bloc.add(const RecordingSourcesRefreshed())).called(1);
    });

    testWidgets('disables selection while recording', (tester) async {
      await pump(tester, ready.copyWith(status: RecordingStatus.recording));

      await tester.tap(find.text('main.dart'));
      await tester.tap(find.byTooltip('Refresh'));

      verifyNever(() => bloc.add(any()));
    });
  });
}
