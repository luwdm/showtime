import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:showtime/recording/recording.dart';
import 'package:showtime/recording/widgets/widgets.dart';

import '../../helpers/helpers.dart';

void main() {
  group(PermissionPrompt, () {
    late RecordingBloc bloc;

    setUp(() {
      bloc = MockRecordingBloc();
      when(
        () => bloc.state,
      ).thenReturn(const RecordingState(permission: PermissionStatus.denied));
    });

    Future<void> pump(WidgetTester tester) => tester.pumpApp(
      BlocProvider.value(value: bloc, child: const PermissionPrompt()),
    );

    testWidgets('requests permission', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Grant access'));

      verify(() => bloc.add(const RecordingPermissionRequested())).called(1);
    });

    testWidgets('opens system settings', (tester) async {
      await pump(tester);

      await tester.tap(find.text('Open System Settings'));

      verify(() => bloc.add(const RecordingPermissionSettingsRequested()))
          .called(1);
    });
  });
}
