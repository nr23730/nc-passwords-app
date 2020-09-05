import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import '../provider/nextcloud_auth_provider.dart';

enum StartView { AllPasswords, Folders, Favorites }

class SettingsProvider with ChangeNotifier {
  final _storage = FlutterSecureStorage();
  var loaded = false;

  StartView _startView = StartView.AllPasswords;
  bool _useBiometricAuth = false;

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

  Future<void> loadFromStorage(NextcloudAuthProvider webAuth) async {
    if (loaded) return;
    loaded = true;
    await webAuth.autoLogin();
    final i = await _storage.read(key: 'startView');
    if (i != null) {
      startView = StartView.values[int.parse(i)];
    }
    _useBiometricAuth = await _storage.read(key: 'useBiometricAuth') == 'true';
  }
}
