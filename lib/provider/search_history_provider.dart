import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SearchHistoryProvider with ChangeNotifier {
  // Maybe later for real search history, for now this class only saves the history for autofill search mapping
  final _storage = FlutterSecureStorage();
  Map<String, String> _autofillSearchHistory = {};

  var _loaded = false;

  void setAutofillHistory(String key, String value) {
    _autofillSearchHistory[key] = value;
    _saveInStorage();
  }

  String getSearchSuggestionFromAutofillKey(String key) {
    return _autofillSearchHistory.putIfAbsent(key, () => key);
  }

  Future<void> _saveInStorage() async {
    final s = json.encode(_autofillSearchHistory);
    await _storage.write(key: 'autofillSearchHistory', value: s);
  }

  Future<void> loadFromStorage() async {
    if (_loaded) return;
    _autofillSearchHistory = {};
    final s = await _storage.read(key: 'autofillSearchHistory');
    if (s == null || s.isEmpty) return;
    _autofillSearchHistory = Map.castFrom(json.decode(s));
    _loaded = true;
  }

  Future<void> clearHistory() async {
    _autofillSearchHistory = {};
    await _saveInStorage();
  }
}
