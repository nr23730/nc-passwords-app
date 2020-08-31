import 'package:flutter/cupertino.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class LocalAuthProvider with ChangeNotifier {
  final _storage = FlutterSecureStorage();
  static const _localPinFieldName = 'localPin';
  String _localPin;

  bool _isAuthenticated = false;

  LocalAuthProvider() {
    _storage.read(key: _localPinFieldName).then((value) {
      _localPin = value;
    });
  }

  bool get hasLocalPin => _localPin != null && _localPin.isNotEmpty;

  bool get isAuthenticated => _isAuthenticated;

  set authenticated(bool value) {
    _isAuthenticated = value;
    notifyListeners();
  }

  set localPin(String pin) {
    _localPin = pin;
    _storage.write(key: _localPinFieldName, value: _localPin);
  }

  bool checkLocalPin(String pin) {
    if (_localPin == pin) {
      authenticated = true;
      return true;
    }
    return false;
  }
}
