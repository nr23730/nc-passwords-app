import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_sodium/flutter_sodium.dart';

import '../helper/decypt_exception.dart';

class KeyChain {
  String _type;
  Map<String, dynamic> _keychain;
  String _current;

  String get type => _type;

  String get current => _current == null ? '' : _current;

  KeyChain(this._type, this._keychain, this._current);

  KeyChain.none() : this('none', {}, null);

  KeyChain.fromMap(Map<String, dynamic> map)
      : this._type = 'CSEv1r1',
        this._keychain = map['keys'],
        this._current = map['current'];

  String decrypt(String id, String encryptedValue) {
    if (encryptedValue.isEmpty || id.isEmpty) {
      return encryptedValue;
    }
    if (_keychain[id] == null) {
      throw DecryptException('No key for decryption found!');
    }
    final vals = Sodium.hex2bin(encryptedValue);
    final nonce = vals.sublist(0, Sodium.cryptoSecretboxNoncebytes);
    final cipher = vals.sublist(Sodium.cryptoSecretboxNoncebytes);
    final decryptedValue = Sodium.cryptoSecretboxOpenEasy(
        cipher, nonce, Sodium.hex2bin(_keychain[id]));
    return utf8.decode(decryptedValue);
  }

  String encrypt(String decryptedValue, String type, String key) {
    if (type == 'none' || decryptedValue.isEmpty || current.isEmpty) {
      return decryptedValue;
    }
    final nonce = Sodium.randombytesBuf(Sodium.cryptoSecretboxNoncebytes);
    final vals = utf8.encode(decryptedValue);
    final value =
        Sodium.cryptoSecretboxEasy(vals, nonce, Sodium.hex2bin(_keychain[key]));
    final encryptedValue = nonce.toList();
    encryptedValue.addAll(value);
    return Sodium.bin2hex(Uint8List.fromList(encryptedValue));
  }
}
