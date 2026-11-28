import 'package:material_ui/material_ui.dart';

/// The start page of the app.
class HomePage extends StatelessWidget {
  /// Creates the start page of the app.
  const new({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(body: Center(child: Text('Showtime')));
  }
}
