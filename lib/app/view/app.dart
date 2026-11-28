import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:material_ui/material_ui.dart';
import 'package:recording_repository/recording_repository.dart';
import 'package:showtime/recording/recording.dart';

/// The root widget of the Showtime app.
class App extends StatelessWidget {
  /// Creates the root widget of the Showtime app.
  const new({required this._recordingRepository, super.key});

  final RecordingRepository _recordingRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: _recordingRepository,
      child: const AppView(),
    );
  }
}

/// The [MaterialApp] of the Showtime app.
class AppView extends StatelessWidget {
  /// Creates the [MaterialApp] of the Showtime app.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Showtime',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      darkTheme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
      ),
      home: const RecordingPage(),
    );
  }
}
