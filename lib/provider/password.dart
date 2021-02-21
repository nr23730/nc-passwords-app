import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:localstorage/localstorage.dart';

import './nextcloud_auth_provider.dart';
import '../provider/abstract_model_object.dart';

class Password extends AbstractModelObject {
  static const urlPasswordShow =
      'index.php/apps/passwords/api/1.0/password/show';
  static const urlPasswordUpdate =
      'index.php/apps/passwords/api/1.0/password/update';
  static const urlPasswordDelete =
      'index.php/apps/passwords/api/1.0/password/delete';
  static const urlPasswordCreate =
      'index.php/apps/passwords/api/1.0/password/create';

  final LocalStorage localCacheStorage = LocalStorage('passwordCache');
  static const _cachedFavIconUrlKey = 'cachedFavIconUrlKey.';

  String _username;
  String _password;
  String _url;
  String _cachedFavIconUrl = '';
  String _notes;
  String folder;
  String statusCode;
  String share;
  bool shared;
  String _customFields;

  String get cachedFavIconUrl => _cachedFavIconUrl;

  String get username => ncProvider.keyChain.decrypt(this.cseKey, _username);

  String get password => ncProvider.keyChain.decrypt(this.cseKey, _password);

  String get url => ncProvider.keyChain.decrypt(this.cseKey, _url);

  String get notes => ncProvider.keyChain.decrypt(this.cseKey, _notes);

  String get customFields =>
      ncProvider.keyChain.decrypt(this.cseKey, _customFields);

  static get cachedFavIconUrlKey => _cachedFavIconUrlKey;

  set cachedFavIconUrl(String value) {
    _cachedFavIconUrl = value;
    localCacheStorage.setItem(_cachedFavIconUrlKey + id, value);
  }

  Color get statusCodeColor {
    switch (statusCode) {
      case 'GOOD':
        return Colors.green;
      case 'OUTDATED':
        return Colors.yellow;
      case 'DUPLICATE':
        return Colors.orange;
      case 'BREACHED':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Password(
    NextcloudAuthProvider ncProvider,
    String id,
    String label,
    DateTime created,
    DateTime updated,
    DateTime edited,
    bool hidden,
    bool trashed,
    bool favorite,
    String cseType,
    String cseKey,
    this._username,
    this._password,
    this._url,
    this._notes,
    this.folder,
    this.statusCode,
    this.share,
    this.shared,
    this._customFields,
  ) : super(
          ncProvider,
          id,
          label,
          created,
          updated,
          edited,
          hidden,
          trashed,
          favorite,
          cseType,
          cseKey,
        ) {
    _loadLocalCaches();
  }

  Password.fromMap(NextcloudAuthProvider ncProvider, Map<String, dynamic> map)
      : _username = map['username'],
        _password = map['password'],
        _url = map['url'],
        _notes = map['notes'],
        folder = map['folder'],
        statusCode = map['statusCode'],
        share = map['share'],
        shared = map['shared'],
        _customFields = map['customFields'],
        super(
          ncProvider,
          map['id'],
          map['label'],
          DateTime.fromMillisecondsSinceEpoch(map['created'] * 1000),
          DateTime.fromMillisecondsSinceEpoch(map['updated'] * 1000),
          DateTime.fromMillisecondsSinceEpoch(map['edited'] * 1000),
          map['hidden'],
          map['trashed'],
          map['favorite'],
          map['cseType'],
          map['cseKey'],
        ) {
    _loadLocalCaches();
  }

  Future<void> _loadLocalCaches() async {
    var value = await localCacheStorage.getItem(_cachedFavIconUrlKey + id);
    if (value != null) {
      _cachedFavIconUrl = value;
    }
  }

  Future<void> _invalidLocalCaches() async {
    await localCacheStorage.setItem(_cachedFavIconUrlKey + id, '');
  }

  Future<Map<String, dynamic>> fetch() async {
    return _fetchAttributes(ncProvider, this.id);
  }

  static Future<Map<String, dynamic>> _fetchAttributes(
      NextcloudAuthProvider ncProvider, String id) async {
    try {
      final r1 = await ncProvider.httpPost(
        urlPasswordShow,
        body: json.encode({'id': id}),
      );
      return json.decode(r1.body);
    } catch (error) {}
    return null;
  }

  void _setAttributesFromMap(Map<String, dynamic> map, [bool encrypt = false]) {
    if (encrypt) {
      map = _encryptAttributes(map, ncProvider);
    }
    if (map.containsKey('username')) _username = map['username'];
    if (map.containsKey('password')) _password = map['password'];
    if (map.containsKey('url')) _url = map['url'];
    if (map.containsKey('notes')) _notes = map['notes'];
    if (map.containsKey('label')) label = map['label'];
    if (map.containsKey('created'))
      created = DateTime.fromMillisecondsSinceEpoch(map['created'] * 1000);
    if (map.containsKey('folder')) folder = map['folder'];
    if (map.containsKey('updated'))
      updated = DateTime.fromMillisecondsSinceEpoch(map['updated'] * 1000);
    if (map.containsKey('edited'))
      edited = DateTime.fromMillisecondsSinceEpoch(map['edited'] * 1000);
    if (map.containsKey('hidden')) hidden = map['hidden'];
    if (map.containsKey('trashed')) trashed = map['trashed'];
    if (map.containsKey('favorite')) favorite = map['favorite'];
    if (map.containsKey('statusCode')) statusCode = map['statusCode'];
    if (map.containsKey('cseType')) cseType = map['cseType'];
    if (map.containsKey('cseKey')) cseKey = map['cseKey'];
    if (map.containsKey('share')) share = map['share'];
    if (map.containsKey('shared')) shared = map['shared'];
    if (map.containsKey('customFields')) _customFields = map['customFields'];
  }

  Future<bool> toggleFavorite() async {
    try {
      favorite = !favorite;
      notifyListeners();
      Map<String, dynamic> requestBody = await fetch();
      _setAttributesFromMap(requestBody);
      favorite = !favorite;
      requestBody['favorite'] = favorite;
      final r1 = await ncProvider.httpPatch(
        urlPasswordUpdate,
        body: json.encode(requestBody),
      );
      if (r1.statusCode >= 300) {
        favorite = !favorite;
        notifyListeners();
        return false;
      }
      return true;
    } catch (error) {}
    return false;
  }

  Future<bool> update(Map<String, dynamic> newAttributes) async {
    try {
      Map<String, dynamic> requestBody = await fetch();
      _setAttributesFromMap(requestBody);
      _setAttributesFromMap(newAttributes, true);
      // invalid caches
      _invalidLocalCaches();
      notifyListeners();
      requestBody.updateAll((key, value) =>
          newAttributes.keys.contains(key) ? newAttributes[key] : value);
      final r1 = await ncProvider.httpPatch(
        urlPasswordUpdate,
        body: json.encode(requestBody),
      );
      if (r1.statusCode >= 300) {
        notifyListeners();
        return false;
      }
      return true;
    } catch (error) {}
    return false;
  }

  Future<bool> delete() async {
    try {
      final r1 = await ncProvider.httpDelete(
        urlPasswordDelete,
        body: {'id': this.id},
      );
      _invalidLocalCaches();
      return r1.statusCode < 300;
    } catch (error) {}
    return false;
  }

  static Future<Password> create(
      NextcloudAuthProvider ncProvider, Map<String, dynamic> attributes) async {
    try {
      attributes = _encryptAttributes(attributes, ncProvider);
      final r1 = await ncProvider.httpPost(urlPasswordCreate,
          body: json.encode(attributes));
      if (r1.statusCode == 201)
        return Password.fromMap(
          ncProvider,
          await _fetchAttributes(
            ncProvider,
            json.decode(r1.body)['id'],
          ),
        );
    } catch (error) {}
    return null;
  }

  static String randomPassword(int length) {
    const _chars =
        'AaBbCcDdEeFfGgHhIiJjKkLlMmNnOoPpQqRrSsTtUuVvWwXxYyZz1234567890';
    Random _rnd = Random();
    return String.fromCharCodes(Iterable.generate(
        length, (_) => _chars.codeUnitAt(_rnd.nextInt(_chars.length))));
  }

  static Map<String, dynamic> _encryptAttributes(
      Map<String, dynamic> map, NextcloudAuthProvider ncProvider) {
    if (map['cseType'] == null) {
      map['cseType'] = ncProvider.keyChain.type;
      map['cseKey'] = ncProvider.keyChain.current;
    }
    if (map['cseType'] == 'CSEv1r1') {
      map['hash'] = sha1.convert(utf8.encode(map['password'])).toString();
    }
    if (map.containsKey('username'))
      map['username'] = ncProvider.keyChain
          .encrypt(map['username'], map['cseType'], map['cseKey']);
    if (map.containsKey('password'))
      map['password'] = ncProvider.keyChain
          .encrypt(map['password'], map['cseType'], map['cseKey']);
    if (map.containsKey('url'))
      map['url'] = ncProvider.keyChain
          .encrypt(map['url'], map['cseType'], map['cseKey']);
    if (map.containsKey('notes'))
      map['notes'] = ncProvider.keyChain
          .encrypt(map['notes'], map['cseType'], map['cseKey']);
    if (map.containsKey('label'))
      map['label'] = ncProvider.keyChain
          .encrypt(map['label'], map['cseType'], map['cseKey']);
    if (map.containsKey('customFields'))
      map['customFields'] = ncProvider.keyChain
          .encrypt(map['customFields'], map['cseType'], map['cseKey']);
    return map;
  }
}
