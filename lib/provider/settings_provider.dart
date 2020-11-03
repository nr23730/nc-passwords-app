import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../provider/theme_provider.dart';
import '../provider/nextcloud_auth_provider.dart';

enum StartView { AllPasswords, Folders, Favorites }
enum FolderView { FlatView, TreeView }

class SettingsProvider with ChangeNotifier {
  final _storage = FlutterSecureStorage();
  var _loaded = false;

  StartView _startView = StartView.AllPasswords;
  bool _useBiometricAuth = false;
  bool _usePinAuth = false;
  int _passwordStrength = 20;
  FolderView _folderView = FolderView.FlatView;

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

  Future<void> loadFromStorage(
    NextcloudAuthProvider webAuth,
    ThemeProvider themeProvider,
  ) async {
    if (_loaded) return;
    _loaded = true;
    final futures = await Future.wait([
      webAuth.autoLogin(),
      _storage.read(key: 'startView'),
      _storage.read(key: 'useBiometricAuth'),
      _storage.read(key: 'passwordStrength'),
      _storage.read(key: 'usePinAuth'),
      _storage.read(key: 'folderView'),
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
  }
}
