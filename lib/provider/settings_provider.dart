import 'package:flutter/foundation.dart';

enum StartView { AllPasswords, Folders, Favorites }

class SettingsProvider with ChangeNotifier {
  StartView _startView = StartView.AllPasswords;

  get startView {
    return _startView;
  }

  set startView(StartView startView) {
    _startView = startView;
    notifyListeners();
  }
}
