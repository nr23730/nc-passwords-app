import 'package:flutter/cupertino.dart';

import 'nextcloud_auth_provider.dart';

class AbstractModelObject with ChangeNotifier implements Comparable {
  final NextcloudAuthProvider ncProvider;

  final String id;
  String _label;
  DateTime created;
  DateTime updated;
  DateTime edited;
  bool hidden;
  bool trashed;
  bool favorite;
  String cseType;
  String cseKey;

  AbstractModelObject(
    this.ncProvider,
    this.id,
    this._label,
    this.created,
    this.updated,
    this.edited,
    this.hidden,
    this.trashed,
    this.favorite,
    this.cseType,
    this.cseKey,
  );

  String get label => ncProvider.keyChain.decrypt(cseKey, _label);

  set label(String value) {
    _label = value;
  }

  @override
  int compareTo(other) {
    if (other is AbstractModelObject)
      return this.label.toLowerCase().compareTo(other.label.toLowerCase());
    return 0;
  }

  Map<String, dynamic> get asMap => {
        'id': id,
        'label': label,
        'edited': edited.millisecondsSinceEpoch / 1000,
        'hidden': hidden,
        'trashed': trashed,
        'favorite': favorite,
        'cseType': cseType,
        'cseKey': cseKey,
      };
}
