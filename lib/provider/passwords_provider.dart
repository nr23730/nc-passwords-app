import 'dart:convert';
import 'dart:io';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import './folder.dart';
import './nextcloud_auth_provider.dart';
import './nextcloud_passwords_session_provider.dart';
import './password.dart';
import '../helper/auth_exception.dart';
import '../helper/key_chain.dart';

class PasswordsProvider with ChangeNotifier {
  final NextcloudAuthProvider _ncProvider;
  final NextcloudPasswordsSessionProvider sessionProvider;

  static const urlFolderList = 'index.php/apps/passwords/api/1.0/folder/list';
  static const urlPasswordList =
      'index.php/apps/passwords/api/1.0/password/list';

  Map<String, Password> _passwords = {};
  Map<String, Folder> _folders = {};

  List<Password> get passwords => [..._passwords.values];

  List<Folder> get folder => [..._folders.values];

  bool _isFetched = false;
  bool _isLocal = false;
  String _masterPassword = '';
  bool storeMaster = false;

  bool get isFetched {
    return _isFetched;
  }

  bool get isLocal {
    return _isLocal;
  }

  String get masterPassword => _masterPassword;

  set masterPassword(String value) {
    _masterPassword = value;
    if (storeMaster)
      _ncProvider.storage.write(key: 'masterPw', value: _masterPassword);
  }

  PasswordsProvider(this._ncProvider, this.sessionProvider);

  List<Password> searchPasswords(String searchString) {
    searchString = searchString.toLowerCase();
    final searchStrings =
        searchString.split('.').where((e) => e.length > 3).toSet();
    if (searchStrings.length > 0) {
      return _passwords.values
          .where((p) => searchStrings.any((searchString) =>
              p.label.toLowerCase().contains(searchString) ||
              p.username.toLowerCase().contains(searchString) ||
              p.url.toLowerCase().contains(searchString)))
          .toList();
    }
    return _passwords.values
        .where((p) =>
            p.label.toLowerCase().contains(searchString) ||
            p.username.toLowerCase().contains(searchString) ||
            p.url.toLowerCase().contains(searchString))
        .toList();
  }

  List<Folder> getFoldersByParentFolder(String parentFolderId) =>
      _folders.values.where((f) => f.parent == parentFolderId).toList();

  List<Password> getPasswordsByFolder(String folderId) =>
      _passwords.values.where((f) => f.folder == folderId).toList();

  Folder findFolderById(String folderId) => _folders[folderId];

  Folder findPasswordById(String passwordId) => _folders[passwordId];

  Future<FetchResult> fetchAll({bool tryLocalOnly = false}) async {
    _passwords = {};
    _folders = {};
    _isFetched = false;
    _isLocal = false;
    if (masterPassword.isEmpty) {
      final masterPw = await _ncProvider.storage.read(key: 'masterPw');
      if (masterPw != null) {
        masterPassword = masterPw;
      }
    }
    // Request session and prepare keychain
    var keyChainSuccess = FetchResult.Success;
    if (!sessionProvider.hasSession) {
      keyChainSuccess = await sessionProvider.requestSession(masterPassword);
    }
    if (keyChainSuccess == FetchResult.WrongMasterPassword) {
      return FetchResult.WrongMasterPassword;
    }
    // try load from local cache
    final data = await _fetchLocal([urlPasswordList, urlFolderList]);
    if (data[urlPasswordList] != null && data[urlFolderList] != null) {
      _setPasswords(data[urlPasswordList]);
      _setFolders(data[urlFolderList]);
      _isFetched = true;
      notifyListeners();
      if (tryLocalOnly) {
        _isLocal = true;
        return FetchResult.Success;
      }
    }
    if (keyChainSuccess == FetchResult.NoConnection) {
      _isLocal = true;
      _isFetched = true;
      return FetchResult.NoConnection;
    }
    try {
      final resp = await Future.wait([
        _ncProvider.httpPost(
          urlPasswordList,
          body: json.encode({'detailLevel': 'model+folder'}),
        ),
        _ncProvider.httpPost(
          urlFolderList,
          body: json.encode({'detailLevel': 'model'}),
        )
      ]);
      // load passwords
      final passwordListResult = resp[0];
      if (passwordListResult.statusCode >= 300) {
        throw AuthException('Password app not installed.');
      }
      _setPasswords(passwordListResult.body);
      // load folders
      final folderListResult = resp[1];
      if (folderListResult.statusCode >= 300) {
        throw AuthException('Password app not installed.');
      }
      _setFolders(folderListResult.body);

      // try all passwords, folders, if they can be encrypted.
      // If not, invalid session.
      try {
        _folders.forEach((key, value) => value.label);
        _passwords.forEach((key, value) => value.label);
      } catch (e) {
        flush();
        return FetchResult.WrongMasterPassword;
      }

      _isFetched = true;
      notifyListeners();
      // cache local
      _storeLocal({
        urlPasswordList: passwordListResult.body,
        urlFolderList: folderListResult.body
      });
    } on SocketException catch (_) {
      // try load from local cache
      final data = await _fetchLocal([urlPasswordList, urlFolderList]);
      if (data[urlPasswordList] != null && data[urlFolderList] != null) {
        _isLocal = true;
        _isFetched = true;
        _setPasswords(data[urlPasswordList]);
        _setFolders(data[urlFolderList]);
        notifyListeners();
        return FetchResult.Success;
      }
      return FetchResult.NoConnection;
    } catch (error) {
      return FetchResult.NoConnection;
    }
    return FetchResult.Success;
  }

  void _setPasswords(String jsonData) {
    final data = json.decode(jsonData) as List<dynamic>;
    _passwords = Map.fromIterable(
      data.map((e) => Password.fromMap(_ncProvider, e as Map<String, dynamic>)),
      key: (e) => (e as Password).id,
      value: (e) => e,
    );
  }

  void _setFolders(String jsonData) {
    final data = json.decode(jsonData) as List<dynamic>;
    _folders = Map.fromIterable(
      data.map((e) => Folder.fromMap(_ncProvider, e as Map<String, dynamic>)),
      key: (e) => (e as Folder).id,
      value: (e) => e,
    );
  }

  Future<void> createPasswort(Map<String, dynamic> attributes) async {
    Password newPassword = await Password.create(_ncProvider, attributes);
    if (newPassword != null) {
      _passwords[newPassword.id] = newPassword;
      notifyListeners();
    }
  }

  Future<void> deletePasswort(String passwordId) async {
    final password = _passwords[passwordId];
    _passwords.removeWhere((key, value) => key == passwordId);
    notifyListeners();
    password.delete();
  }

  Future<void> createFolder(Map<String, dynamic> attributes) async {
    Folder newFolder = await Folder.create(_ncProvider, attributes);
    _folders[newFolder.id] = newFolder;
    notifyListeners();
  }

  Future<Map<String, String>> _fetchLocal(List<String> keys) async {
    Map<String, String> map = {};
    for (var key in keys) {
      var val;
      try {
        val = await _ncProvider.storage.read(key: key);
      } catch (e) {}
      if (val != null) {
        map.putIfAbsent(key, () => val);
      }
    }
    return map;
  }

  Future<void> _storeLocal(Map<String, String> map) async {
    assert(map != null);
    map.forEach((key, value) async => await _ncProvider.storage.write(
          key: key,
          value: value,
        ));
  }

  void flush([notify = false]) {
    _ncProvider.keyChain = KeyChain.none();
    masterPassword = '';
    _ncProvider.storage.delete(key: 'masterPw');
    _passwords = {};
    _folders = {};
    _ncProvider.storage.deleteAll();
    sessionProvider.flush();
    _ncProvider.session = null;
    if (notify) notifyListeners();
  }
}

enum FetchResult { Success, NoConnection, WrongMasterPassword }
