import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:serpiente_io/src/app/app.dart';
import 'package:serpiente_io/src/data/persistence/game_preferences.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  await GamePreferences.initialize();
  runApp(const App());
}
