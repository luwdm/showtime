import 'package:material_ui/material_ui.dart';
import 'package:showtime/home/home.dart';

/// The root widget of the Showtime app.
class App extends StatelessWidget {
  /// Creates the root widget of the Showtime app.
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
      home: const HomePage(),
    );
  }
}
