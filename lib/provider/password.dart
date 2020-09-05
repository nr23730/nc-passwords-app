import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';

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

  String username;
  String password;
  String url;
  String notes;
  String folder;
  String statusCode;
  String share;
  bool shared;

  Color get statusCodeColor {
    switch (statusCode){
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
      this.username,
      this.password,
      this.url,
      this.notes,
      this.folder,
      this.statusCode,
      this.share,
      this.shared)
      : super(
          ncProvider,
          id,
          label,
          created,
          updated,
          edited,
          hidden,
          trashed,
          favorite,
        );

  Password.fromMap(NextcloudAuthProvider ncProvider, Map<String, dynamic> map)
      : username = map['username'],
        password = map['password'],
        url = map['url'],
        notes = map['notes'],
        folder = map['folder'],
        statusCode = map['statusCode'],
        share = map['share'],
        shared = map['shared'],
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
        );

  Future<Map<String, dynamic>> fetch() async {
    return await _fetchAttributes(ncProvider, this.id);
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

  void setAttributesFromMap(Map<String, dynamic> map) {
    if (map.containsKey('username')) username = map['username'];
    if (map.containsKey('password')) password = map['password'];
    if (map.containsKey('url')) url = map['url'];
    if (map.containsKey('notes')) notes = map['notes'];
    if (map.containsKey('folder')) folder = map['folder'];
    if (map.containsKey('label')) label = map['label'];
    if (map.containsKey('created'))
      created = DateTime.fromMillisecondsSinceEpoch(map['created'] * 1000);
    if (map.containsKey('updated'))
      updated = DateTime.fromMillisecondsSinceEpoch(map['updated'] * 1000);
    if (map.containsKey('edited'))
      edited = DateTime.fromMillisecondsSinceEpoch(map['edited'] * 1000);
    if (map.containsKey('hidden')) hidden = map['hidden'];
    if (map.containsKey('trashed')) trashed = map['trashed'];
    if (map.containsKey('favorite')) favorite = map['favorite'];
    if (map.containsKey('statusCode')) statusCode = map['statusCode'];
    if (map.containsKey('share')) share = map['share'];
    if (map.containsKey('shared')) shared = map['shared'];
  }

  Future<bool> toggleFavorite() async {
    try {
      Map<String, dynamic> requestBody = await fetch();
      setAttributesFromMap(requestBody);
      notifyListeners();
      requestBody['favorite'] = favorite = !favorite;
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
      setAttributesFromMap(requestBody);
      setAttributesFromMap(newAttributes);
      notifyListeners();
      requestBody.updateAll((key, value) =>
          newAttributes.keys.contains(key) ? newAttributes[key] : value);
      print('G');
      final r1 = await ncProvider.httpPatch(
        urlPasswordUpdate,
        body: json.encode(requestBody),
      );
      if (r1.statusCode >= 300) {
        notifyListeners();
        return false;
      }
      return true;
    } catch (error) {
      print(error);
    }
    return false;
  }

  Future<bool> delete() async {
    try {
      final r1 = await ncProvider.httpDelete(
        urlPasswordDelete,
        body: {'id': this.id},
      );
      return r1.statusCode < 300;
    } catch (error) {}
    return false;
  }

  static Future<Password> create(
      NextcloudAuthProvider ncProvider, Map<String, dynamic> attributes) async {
    try {
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
}
