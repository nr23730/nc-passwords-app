import 'dart:async';
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../provider/nextcloud_auth_provider.dart';
import '../provider/theme_provider.dart';

enum StartView { AllPasswords, Folders, Favorites }
enum FolderView { FlatView, TreeView }
enum ThemeStyle { System, Dark, Light, Amoled }

class SettingsProvider with ChangeNotifier {
  final _storage = FlutterSecureStorage();
  var _loaded = false;

  StartView _startView = StartView.AllPasswords;
  bool _useBiometricAuth = false;
  bool _usePinAuth = false;
  int _passwordStrength = 20;
  FolderView _folderView = FolderView.FlatView;
  ThemeStyle _themeStyle = ThemeStyle.System;
  Color _customAccentColor = Colors.white;
  bool _useCustomAccentColor = true;
  int _deleteClipboardAfterSeconds = 0;
  int _lockAfterPausedSeconds = 0;
  bool _loadIcons = true;

  StartView get startView => _startView;

  set startView(StartView startView) {
    _startView = startView;
    notifyListeners();
    _storage.write(key: 'startView', value: startView.index.toString());
  }

  bool get useBiometricAuth => _useBiometricAuth;

  set useBiometricAuth(bool value) {
    _useBiometricAuth = value;
    notifyListeners();
    _storage.write(
        key: 'useBiometricAuth', value: _useBiometricAuth.toString());
  }

  int get passwordStrength => _passwordStrength;

  set passwordStrength(int value) {
    passwordStrengthNoWrite = value;
    _storage.write(
        key: 'passwordStrength', value: _passwordStrength.toString());
  }

  set passwordStrengthNoWrite(int value) {
    _passwordStrength = value;
    notifyListeners();
  }

  bool get usePinAuth => _usePinAuth;

  set usePinAuth(bool value) {
    _usePinAuth = value;
    notifyListeners();
    _storage.write(key: 'usePinAuth', value: _usePinAuth.toString());
  }

  FolderView get folderView => _folderView;

  set folderView(FolderView folderView) {
    _folderView = folderView;
    notifyListeners();
    _storage.write(key: 'folderView', value: folderView.index.toString());
  }

  ThemeStyle get themeStyle => _themeStyle;

  set themeStyle(ThemeStyle value) {
    _themeStyle = value;
    notifyListeners();
    _storage.write(key: 'themeStyle', value: _themeStyle.index.toString());
  }

  Color get customAccentColor => _customAccentColor;

  set customAccentColor(Color value) {
    _customAccentColor = value;
    notifyListeners();
    _storage.write(
      key: 'customAccentColor',
      value: _customAccentColor.value.toString(),
    );
  }

  bool get useCustomAccentColor => _useCustomAccentColor;

  set useCustomAccentColor(bool value) {
    _useCustomAccentColor = value;
    notifyListeners();
    _storage.write(
        key: 'useCustomAccentColor', value: _useCustomAccentColor.toString());
  }

  int get deleteClipboardAfterSeconds => _deleteClipboardAfterSeconds;

  set deleteClipboardAfterSeconds(int value) {
    _deleteClipboardAfterSeconds = value;
    notifyListeners();
    _storage.write(
        key: 'deleteClipboardAfterSeconds',
        value: _deleteClipboardAfterSeconds.toString());
  }

  int get lockAfterPausedSeconds => _lockAfterPausedSeconds;

  set lockAfterPausedSeconds(int value) {
    _lockAfterPausedSeconds = value;
    notifyListeners();
    _storage.write(
        key: 'lockAfterPausedSeconds',
        value: _lockAfterPausedSeconds.toString());
  }

  bool get loadIcons => _loadIcons;

  set loadIcons(bool value) {
    _loadIcons = value;
    notifyListeners();
    _storage.write(key: 'loadIcons', value: _loadIcons.toString());
  }

  Future<void> loadFromStorage(
    NextcloudAuthProvider webAuth,
    ThemeProvider themeProvider,
  ) async {
    if (_loaded) return;
    _loaded = true;
    final futures = await Future.wait([
      webAuth.autoLogin(), // 0
      _storage.read(key: 'startView'), // 1
      _storage.read(key: 'useBiometricAuth'), // 2
      _storage.read(key: 'passwordStrength'), // 3
      _storage.read(key: 'usePinAuth'), // 4
      _storage.read(key: 'folderView'), // 5
      _storage.read(key: 'themeStyle'), // 6
      _storage.read(key: 'customAccentColor'), // 7
      _storage.read(key: 'useCustomAccentColor'), // 8
      _storage.read(key: 'deleteClipboardAfterSeconds'), // 9
      _storage.read(key: 'lockAfterPausedSeconds'), // 10
      _storage.read(key: 'loadIcons'), // 11
    ]);
    if (webAuth.isAuthenticated) {
      themeProvider.update();
    }
    // startView
    final sv = futures[1];
    if (sv != null) {
      _startView = StartView.values[int.parse(sv)];
    }
    // folderView
    final fv = futures[5];
    if (fv != null) {
      _folderView = FolderView.values[int.parse(fv)];
    }
    // useBiometricAuth
    _useBiometricAuth = futures[2] == 'true';
    // passwordStrength
    final ps = futures[3];
    if (ps != null) {
      _passwordStrength = int.parse(ps);
    }
    // usePinAuth
    _usePinAuth = futures[4] == 'true';
    // themeStyle
    final ts = futures[6];
    if (ts != null) {
      _themeStyle = ThemeStyle.values[int.parse(ts)];
    }
    // customAccentColor
    final cas = futures[7];
    if (cas != null) {
      _customAccentColor = Color(int.parse(cas));
    }
    // useCustomAccentColor
    _useCustomAccentColor = futures[8] == 'true';

    // deleteClipboardAfterSeconds
    final delc = futures[9];
    if (delc != null) {
      _deleteClipboardAfterSeconds = int.parse(delc);
    }

    // lockAfterPausedSeconds
    final laps = futures[10];
    if (laps != null) {
      _lockAfterPausedSeconds = int.parse(laps);
    }

    _loadIcons = futures[11] == 'true';
  }
}
