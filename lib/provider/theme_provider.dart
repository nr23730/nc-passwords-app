import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:google_fonts/google_fonts.dart';

import '../provider/nextcloud_auth_provider.dart';

class ThemeProvider with ChangeNotifier {
  final NextcloudAuthProvider ncProvider;

  ThemeProvider(this.ncProvider);

  void update() {
    notifyListeners();
  }

  ThemeData currentTheme() {
    Color toColor(String value) {
      return Color(int.parse(value.replaceAll('#', ''), radix: 16));
    }

    Color c1 = toColor('#0082C9');
    Color fontColor = Colors.white;
    if (ncProvider != null) {
      final colors = ncProvider.getNCColors();
      if (colors != null) {
        c1 = toColor(colors['color']);
        fontColor =
            c1.computeLuminance() > 0.5 ? Colors.black87 : Colors.white70;
      }
    }
    c1 = c1.withAlpha(255);
    return ThemeData(
      primarySwatch: toMaterialColor(c1),
      primaryColor: c1,
      brightness: Brightness.light,
      accentColor: toMaterialColor(c1).shade600,
      fontFamily: "Quicksand",
      textTheme: ThemeData.light().textTheme.copyWith(
            bodyText1: GoogleFonts.raleway(),
            bodyText2: GoogleFonts.raleway(),
          ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(primary: Colors.blueGrey),
      ),
      appBarTheme: AppBarTheme(
        textTheme: ThemeData.light().textTheme.copyWith(
              headline6: GoogleFonts.raleway(
                textStyle: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  color: fontColor,
                ),
              ),
            ),
      ),
    );
  }

  static MaterialColor toMaterialColor(Color color) {
    color = color.withAlpha(255);
    final hslColor = HSLColor.fromColor(color);
    final lightness = hslColor.lightness;

    /// if [500] is the default color, there are at LEAST five
    /// steps below [500]. (i.e. 400, 300, 200, 100, 50.) A
    /// divisor of 5 would mean [50] is a lightness of 1.0 or
    /// a color of #ffffff. A value of six would be near white
    /// but not quite.
    final lowDivisor = 6;

    /// if [500] is the default color, there are at LEAST four
    /// steps above [500]. A divisor of 4 would mean [900] is
    /// a lightness of 0.0 or color of #000000
    final highDivisor = 5;

    final lowStep = (1.0 - lightness) / lowDivisor;
    final highStep = lightness / highDivisor;

    return MaterialColor(color.value, {
      50: (hslColor.withLightness(lightness + (lowStep * 5))).toColor(),
      100: (hslColor.withLightness(lightness + (lowStep * 4))).toColor(),
      200: (hslColor.withLightness(lightness + (lowStep * 3))).toColor(),
      300: (hslColor.withLightness(lightness + (lowStep * 2))).toColor(),
      400: (hslColor.withLightness(lightness + lowStep)).toColor(),
      500: (hslColor.withLightness(lightness)).toColor(),
      600: (hslColor.withLightness(lightness - highStep)).toColor(),
      700: (hslColor.withLightness(lightness - (highStep * 2))).toColor(),
      800: (hslColor.withLightness(lightness - (highStep * 3))).toColor(),
      900: (hslColor.withLightness(lightness - (highStep * 4))).toColor(),
    });
  }
}
