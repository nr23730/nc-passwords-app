import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:flutter_sodium/flutter_sodium.dart';

import './nextcloud_auth_provider.dart';
import './passwords_provider.dart';
import '../helper/key_chain.dart';

class NextcloudPasswordsSessionProvider with ChangeNotifier {
  static const _request = 'index.php/apps/passwords/api/1.0/session/request';
  static const _open = 'index.php/apps/passwords/api/1.0/session/open';
  static const _keepalive =
      'index.php/apps/passwords/api/1.0/session/keepalive';

  final NextcloudAuthProvider nextcloudAuthProvider;

  NextcloudPasswordsSessionProvider(this.nextcloudAuthProvider);

  bool get hasSession => nextcloudAuthProvider.session != null;

  Future<FetchResult> requestSession([String masterPassword = '']) async {
    print('requesting session..');
    var resp;
    try {
      resp = await nextcloudAuthProvider.httpGet(_request);
    } catch (e) {
      return FetchResult.NoConnection;
    }
    final data = json.decode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode >= 300) {
      final keyChainJsonString =
          await nextcloudAuthProvider.storage.read(key: 'keyChainJsonString');
      if (keyChainJsonString != null) {
        nextcloudAuthProvider.keyChain =
            KeyChain.fromMap(json.decode(keyChainJsonString));
        return FetchResult.Success;
      }
      return FetchResult.WrongMasterPassword;
    }
    if (data['challenge'] == null) {
      return FetchResult.Success;
    }
    if (masterPassword.length < 12) {
      return FetchResult.WrongMasterPassword;
    }
    final p = utf8.encode(masterPassword);
    final salt0 = Sodium.hex2bin(data['challenge']['salts'][0]);
    final salt1 = Sodium.hex2bin(data['challenge']['salts'][1]);
    final salt2 = Sodium.hex2bin(data['challenge']['salts'][2]);
    final x = Uint8List.fromList(p + salt0);
    final geneticHash =
        Sodium.cryptoGenerichash(Sodium.cryptoGenerichashBytesMax, x, salt1);
    final passwordHash = Sodium.cryptoPwhash(
      Sodium.cryptoBoxSeedbytes,
      geneticHash,
      salt2,
      Sodium.cryptoPwhashOpslimitInteractive,
      Sodium.cryptoPwhashMemlimitInteractive,
      Sodium.cryptoPwhashAlgDefault,
    );
    final secret = Sodium.bin2hex(passwordHash);
    // open session
    final resp2 = await nextcloudAuthProvider.httpPost(
      _open,
      body: json.encode({
        'challenge': secret,
      }),
    );
    if (resp2.statusCode > 300) {
      nextcloudAuthProvider.session = null;
      return FetchResult.WrongMasterPassword;
    }
    nextcloudAuthProvider.session = resp2.headers['x-api-session'];
    final key = json.decode(resp2.body)['keys']['CSEv1r1'];
    final keyE = Sodium.hex2bin(key);
    final keySalt = keyE.sublist(0, Sodium.cryptoPwhashSaltbytes);
    final keyPayload = keyE.sublist(Sodium.cryptoPwhashSaltbytes);
    final decryptionKey = Sodium.cryptoPwhash(
      Sodium.cryptoBoxSeedbytes,
      p,
      keySalt,
      Sodium.cryptoPwhashOpslimitInteractive,
      Sodium.cryptoPwhashMemlimitInteractive,
      Sodium.cryptoPwhashAlgDefault,
    );
    final nonce = keyPayload.sublist(0, Sodium.cryptoSecretboxNoncebytes);
    final cipher = keyPayload.sublist(Sodium.cryptoSecretboxNoncebytes);
    final keychainObject =
        Sodium.cryptoSecretboxOpenEasy(cipher, nonce, decryptionKey);
    final keyChainJsonString = utf8.decode(keychainObject);
    nextcloudAuthProvider.storage
        .write(key: 'keyChainJsonString', value: keyChainJsonString);
    nextcloudAuthProvider.keyChain =
        KeyChain.fromMap(json.decode(keyChainJsonString));
    _keepSessionAlive();
    return FetchResult.Success;
  }

  void _keepSessionAlive() {
    Future.delayed(Duration(seconds: 40), () async {
      final resp = await nextcloudAuthProvider.httpGet(_keepalive);
      if (nextcloudAuthProvider.session != null) _keepSessionAlive();
    });
  }

  void flush() {
    nextcloudAuthProvider.storage.delete(key: 'keyChainJsonString');
  }
}
