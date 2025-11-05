import 'package:flutter/material.dart';
import 'core/theme.dart';
import 'presentation/screen/login_screen.dart';
import 'presentation/screen/home_screen.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Mi App Parabólica',
      theme: appTheme, // 🎨 Se aplica el theme global
      home: const LoginScreen(),
    );
  }
}
