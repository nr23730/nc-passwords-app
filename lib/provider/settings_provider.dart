import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

enum StartView { AllPasswords, Folders, Favorites }

class SettingsProvider with ChangeNotifier {
  StartView _startView = StartView.AllPasswords;
  final _storage = FlutterSecureStorage();

  SettingsProvider() {
    loadFromStorage();
  }

  get startView {
    return _startView;
  }

  set startView(StartView startView) {
    _startView = startView;
    notifyListeners();
    _storage.write(key: 'startView', value: startView.index.toString());
  }

  void loadFromStorage() async {
    final i = await _storage.read(key: 'startView');
    if (i != null) {
      startView = StartView.values[int.parse(i)];
    }
  }
}
