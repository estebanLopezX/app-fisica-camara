import 'package:flutter/material.dart';
// ignore: unused_import
import 'constants.dart';

final ThemeData appTheme = ThemeData(
  // 🎨 Colores principales
  colorScheme: ColorScheme.fromSeed(
    seedColor: primaryColor, // azul base
    brightness: Brightness.light,
  ),

  // 🧱 Fondo y estilo base
  scaffoldBackgroundColor: whiteColor,

  // 🖋️ Tipografía global
  textTheme: const TextTheme(
    headlineLarge: TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      color: blackColor,
    ),
    bodyMedium: TextStyle(fontSize: 16, color: blackColor),
  ),

  // 🔘 Botones
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: primaryColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(30)),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24, vertical: 12),
    ),
  ),

  // 📱 AppBar
  appBarTheme: const AppBarTheme(
    backgroundColor: primaryColor,
    foregroundColor: whiteColor,
    centerTitle: true,
  ),
);

Color get newMethod => whiteColor;
