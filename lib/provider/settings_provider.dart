import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../provider/theme_provider.dart';
import '../provider/nextcloud_auth_provider.dart';

enum StartView { AllPasswords, Folders, Favorites }

class SettingsProvider with ChangeNotifier {
  final _storage = FlutterSecureStorage();
  var _loaded = false;

  StartView _startView = StartView.AllPasswords;
  bool _useBiometricAuth = false;
  int _passwordStrength = 20;

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

  Future<void> loadFromStorage(NextcloudAuthProvider webAuth, ThemeProvider themeProvider) async {
    if (_loaded) return;
    _loaded = true;
    final futures = await Future.wait([
      webAuth.autoLogin(),
      _storage.read(key: 'startView'),
      _storage.read(key: 'useBiometricAuth'),
      _storage.read(key: 'passwordStrength'),
    ]);
    if(webAuth.isAuthenticated){
      themeProvider.update();
    }
    // startView
    final sv = futures[1];
    if (sv != null) {
      _startView = StartView.values[int.parse(sv)];
    }
    // useBiometricAuth
    _useBiometricAuth = futures[2] == 'true';
    // passwordStrength
    final ps = futures[3];
    if (ps != null) {
      _passwordStrength = int.parse(ps);
    }
  }
}
