import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../provider/nextcloud_auth_provider.dart';
import '../provider/settings_provider.dart';

class ThemeProvider with ChangeNotifier {
  final NextcloudAuthProvider ncProvider;
  final SettingsProvider settings;

  ThemeProvider(this.ncProvider, this.settings);

  void update() {
    notifyListeners();
  }

  ThemeData currentTheme(bool isDark) {
    Color toColor(String value) {
      return Color(int.parse(value.replaceAll('#', ''), radix: 16));
    }

    final isSystem = settings.themeStyle == ThemeStyle.System;
    final darkModeEnabled =
        isDark && isSystem || settings.themeStyle == ThemeStyle.Dark;
    final amoledEnabled = settings.themeStyle == ThemeStyle.Amoled;

    final ThemeData themeData =
        darkModeEnabled || amoledEnabled ? ThemeData.dark() : ThemeData.light();

    Color c1 = toColor('#0082C9');
    if (!isSystem && settings.useCustomAccentColor) {
      c1 = settings.customAccentColor;
    } else if (ncProvider != null) {
      final colors = ncProvider.getNCColors();
      if (colors != null) {
        c1 = toColor(colors['color']);
      }
    }
    Color fontColor = c1.computeLuminance() > 0.5 ? Colors.black : Colors.white;
    final c1M = toMaterialColor(c1.withAlpha(255));
    return ThemeData(
      primarySwatch: c1M,
      scaffoldBackgroundColor:
          amoledEnabled ? Colors.black : themeData.scaffoldBackgroundColor,
      //password overview background color
      canvasColor: amoledEnabled ? Colors.black : themeData.canvasColor,
      //app drawer background color
      textSelectionHandleColor:
          amoledEnabled ? Colors.white : themeData.textSelectionHandleColor,
      //text cursor grabber color
      primaryColor: amoledEnabled ? Colors.black : c1.withAlpha(255),
      //appbar color
      brightness:
          darkModeEnabled || amoledEnabled ? Brightness.dark : Brightness.light,
      accentColor: toMaterialColor(c1).shade700,
      fontFamily: "Quicksand",
      textTheme: themeData.textTheme.copyWith(
        bodyText1: TextStyle(
          fontFamily: 'Roboto',
          fontWeight: FontWeight.w500,
          fontSize: 15,
          color: darkModeEnabled || amoledEnabled ? Colors.white : Colors.black,
        ),
        bodyText2: TextStyle(
          fontWeight: FontWeight.w500,
          color: darkModeEnabled || amoledEnabled ? Colors.white : Colors.black,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        labelStyle: TextStyle(
          color: darkModeEnabled || amoledEnabled ? Colors.white : Colors.black,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(primary: Colors.blueGrey),
      ),
      appBarTheme: AppBarTheme(
        textTheme: themeData.textTheme.copyWith(
          headline6: TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
            color: darkModeEnabled || amoledEnabled ? Colors.white : fontColor,
          ),
        ),
      ),
    );
  }

  static MaterialColor toMaterialColor(Color color) {
    color = color.withAlpha(255);
    final hslColor = HSLColor.fromColor(color);
    final lightness = hslColor.lightness;
    final lowDivisor = 6;
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
