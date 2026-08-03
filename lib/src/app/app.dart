import 'package:flutter/material.dart';
import 'package:serpiente_io/src/presentation/screens/splash_screen.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Serpiente.io',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.green),
        fontFamily: 'Arial',
      ),
      home: const SplashScreen(),
    );
  }
}
