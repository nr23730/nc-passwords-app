import 'dart:convert';
import 'dart:io';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../helper/auth_exception.dart';
import '../provider/password.dart';
import '../provider/nextcloud_auth_provider.dart';
import './folder.dart';

class PasswordsProvider with ChangeNotifier {
  final NextcloudAuthProvider ncProvider;
  final _storage = FlutterSecureStorage();

  static const urlFolderList = 'index.php/apps/passwords/api/1.0/folder/list';
  static const urlPasswordList =
      'index.php/apps/passwords/api/1.0/password/list';

  Map<String, Password> _passwords = {};
  Map<String, Folder> _folders = {};

  List<Password> get passwords => [..._passwords.values];

  List<Folder> get folder => [..._folders.values];

  bool _isFetched = false;
  bool _isLocal = false;

  bool get isFetched {
    return _isFetched;
  }

  bool get isLocal {
    return _isLocal;
  }

  PasswordsProvider(this.ncProvider);

  List<Password> searchPasswords(String searchString) {
    searchString = searchString.toLowerCase();
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

  Future<bool> fetchAll() async {
    _passwords = {};
    _folders = {};
    _isFetched = false;
    _isLocal = false;
    // try load from local cache
    final data = await _fetchLocal([urlPasswordList, urlFolderList]);
    if (data[urlPasswordList] != null && data[urlFolderList] != null) {
      _setPasswords(data[urlPasswordList]);
      _setFolders(data[urlFolderList]);
      _isFetched = true;
      notifyListeners();
    }
    print('start fetching data..');
    try {
      final resp = await Future.wait([
        ncProvider.httpPost(
          urlPasswordList,
          body: json.encode({'detailLevel': 'model+folder'}),
        ),
        ncProvider.httpPost(
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
        return true;
      }
      return false;
    } catch (error) {
      return false;
    }
    return true;
  }

  void _setPasswords(String jsonData) {
    final data = json.decode(jsonData) as List<dynamic>;
    _passwords = Map.fromIterable(
      data.map((e) => Password.fromMap(ncProvider, e as Map<String, dynamic>)),
      key: (e) => (e as Password).id,
      value: (e) => e,
    );
  }

  void _setFolders(String jsonData) {
    final data = json.decode(jsonData) as List<dynamic>;
    _folders = Map.fromIterable(
      data.map((e) => Folder.fromMap(ncProvider, e as Map<String, dynamic>)),
      key: (e) => (e as Folder).id,
      value: (e) => e,
    );
  }

  Future<void> createPasswort(Map<String, dynamic> attributes) async {
    Password newPassword = await Password.create(ncProvider, attributes);
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
    Folder newFolder = await Folder.create(ncProvider, attributes);
    _folders[newFolder.id] = newFolder;
    notifyListeners();
  }

  Future<Map<String, String>> _fetchLocal(List<String> keys) async {
    Map<String, String> map = {};
    for (var key in keys) {
      final val = await _storage.read(key: key);
      if (val != null) {
        map.putIfAbsent(key, () => val);
      }
    }
    return map;
  }

  Future<void> _storeLocal(Map<String, String> map) async {
    assert(map != null);
    map.forEach((key, value) async => await _storage.write(
          key: key,
          value: value,
        ));
  }
}
