import 'dart:convert';

import './abstract_model_object.dart';
import '../provider/nextcloud_auth_provider.dart';

class Folder extends AbstractModelObject {
  static const defaultFolder = '00000000-0000-0000-0000-000000000000';

  static const urlFolderShow = 'index.php/apps/passwords/api/1.0/folder/show';
  static const urlFolderUpdate =
      'index.php/apps/passwords/api/1.0/folder/update';
  static const urlFolderDelete =
      'index.php/apps/passwords/api/1.0/folder/delete';
  static const urlFolderCreate =
      'index.php/apps/passwords/api/1.0/folder/create';

  String parent;

  Folder(
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
    this.parent,
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
        );

  Folder.fromMap(NextcloudAuthProvider ncProvider, Map<String, dynamic> map)
      : parent = map['parent'],
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
        );

  Future<Map<String, dynamic>> fetch() async {
    return await _fetchAttributes(ncProvider, this.id);
  }

  static Future<Map<String, dynamic>> _fetchAttributes(
      NextcloudAuthProvider ncProvider, String id) async {
    final r1 = await ncProvider.httpPost(
      urlFolderShow,
      body: json.encode({'id': id}),
    );
    return json.decode(r1.body);
  }

  void setAttributesFromMap(Map<String, dynamic> map, [bool encrypt = false]) {
    if (encrypt) {
      map = _encryptAttributes(map, ncProvider);
    }
    if (map.containsKey('parent')) parent = map['parent'];
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
    if (map.containsKey('cseType')) cseType = map['cseType'];
    if (map.containsKey('cseKey')) cseKey = map['cseKey'];
  }

  Future<bool> update(Map<String, dynamic> newAttributes) async {
    try {
      Map<String, dynamic> requestBody = await fetch();
      setAttributesFromMap(requestBody);
      setAttributesFromMap(newAttributes, true);
      notifyListeners();
      requestBody.updateAll((key, value) =>
          newAttributes.keys.contains(key) ? newAttributes[key] : value);
      final r1 = await ncProvider.httpPatch(
        urlFolderUpdate,
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

  static Future<Folder> create(
      NextcloudAuthProvider ncProvider, Map<String, dynamic> attributes) async {
    try {
      final r1 = await ncProvider.httpPost(urlFolderCreate,
          body: json.encode(attributes));
      if (r1.statusCode == 201)
        return Folder.fromMap(
          ncProvider,
          await _fetchAttributes(
            ncProvider,
            json.decode(r1.body)['id'],
          ),
        );
    } catch (error) {}
    return null;
  }

  Future<bool> delete() async {
    try {
      final r1 = await ncProvider.httpDelete(
        urlFolderDelete,
        body: {'id': this.id},
      );
      return r1.statusCode < 300;
    } catch (error) {}
    return false;
  }

  static Map<String, dynamic> _encryptAttributes(
      Map<String, dynamic> map, NextcloudAuthProvider ncProvider) {
    if (map['cseType'] == null) {
      map['cseType'] = ncProvider.keyChain.type;
      map['cseKey'] = ncProvider.keyChain.current;
    }
    if (map.containsKey('label'))
      map['label'] = ncProvider.keyChain
          .encrypt(map['label'], map['cseType'], map['cseKey']);
    return map;
  }
}
