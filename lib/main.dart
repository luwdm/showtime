import 'package:material_ui/material_ui.dart';
import 'package:recording_repository/recording_repository.dart';
import 'package:screen_capture_client/screen_capture_client.dart';
import 'package:showtime/app/app.dart';

/// Bundle identifier of the app, used to hide its own windows.
const _bundleIdentifier = 'io.github.luwdm.showtime';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  final recordingRepository = RecordingRepository(
    screenCaptureClient: ScreenCaptureClient(),
    excludedBundleIdentifiers: {_bundleIdentifier},
  );
  runApp(App(recordingRepository: recordingRepository));
}
