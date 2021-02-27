import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:http/io_client.dart';

import '../helper/auth_exception.dart';
import '../helper/key_chain.dart';

class NextcloudAuthProvider with ChangeNotifier {
  static final _expCred = RegExp(r"nc:.*server:(.*)&user:(.*)&password:(.*)");
  static final _expCred2 = RegExp(r"nc:.*user:(.*)&password:(.*)&server:(.*)");
  static const _authPath = 'index.php/login/flow';
  static const _capabilitiesPath = '/ocs/v1.php/cloud/capabilities';

  static const _userFieldName = 'nc_user';
  static const _passwordFieldName = 'nc_password';
  static const _serverFieldName = 'nc_server';

  final storage = FlutterSecureStorage();

  String _user;
  String _password;
  String _server;
  String _capabilities;
  String session;
  IOClient _client;

  bool _certificateCheck(X509Certificate cert, String host, int port) => true;

  NextcloudAuthProvider() {
    _client =
        IOClient(HttpClient()..badCertificateCallback = _certificateCheck);
  }

  KeyChain keyChain = KeyChain.none();

  String get user => _user;

  bool get isAuthenticated => _user != null && _password != null;

  set server(String url) {
    _server = url;
    if (!_server.endsWith('/')) _server = '$_server/';
  }

  String get authUrl {
    return _server + _authPath;
  }

  String get server {
    return _server;
  }

  Map<String, String> getNCColors() {
    if (_capabilities == null) {
      return null;
    }
    final x = json.decode(_capabilities);
    final theming = x['ocs']['data']['capabilities']['theming'];
    if (theming == null) {
      return null;
    }
    return {
      'color': theming['color'],
      'color-text': theming['color-text'],
      'color-element': theming['color-element'],
      'color-element-bright': theming['color-element-bright'],
      'color-element-dark': theming['color-element-dark'],
      'background': theming['background'],
    };
  }

  Future<void> setCredentials(String urlNcResponse) async {
    urlNcResponse = Uri.decodeFull(urlNcResponse);
    var match = _expCred.firstMatch(urlNcResponse);
    var user;
    var password;
    var server;
    if (match != null) {
      user = match.group(2).replaceAll('+', ' ');
      password = match.group(3);
      server = match.group(1);
    }
    if (match == null) {
      match = _expCred2.firstMatch(urlNcResponse);
      if (match != null) {
        user = match.group(1).replaceAll('+', ' ');
        password = match.group(2);
        server = match.group(3);
      }
    }
    if (user != null && password != null && server != null) {
      await _setCredentials(
        user: user,
        password: password,
        server: server,
      );
    }
  }

  Future<void> _setCredentials(
      {String user, String password, String server}) async {
    if (server != null) {
      this.server = server;
    }
    // server must be set before!
    if (_server == null) {
      throw AuthException('Set the server before call setCredentials()!');
    }
    _user = user;
    _password = password;
    //notifyListeners();
    // save in secure storage
    Future.wait({
      storage.write(key: _userFieldName, value: _user),
      storage.write(key: _passwordFieldName, value: _password),
      storage.write(key: _serverFieldName, value: _server),
    });
    // try loading theming
    final response = await httpGet(_capabilitiesPath);
    if (response.statusCode >= 300) {
      return;
    }
    _capabilities = response.body;
    await storage.write(key: _capabilitiesPath, value: _capabilities);
  }

  Future<bool> autoLogin() async {
    _user = await storage.read(key: _userFieldName);
    _password = await storage.read(key: _passwordFieldName);
    _server = await storage.read(key: _serverFieldName);
    _capabilities = await storage.read(key: _capabilitiesPath);
    return _user != null;
  }

  Future<void> flushLogin() async {
    _user = null;
    _password = null;
    _server = null;
    _capabilities = null;
    session = null;
    notifyListeners();
    storage.deleteAll();
  }

  Future<http.Response> httpGet(url, {Map<String, String> headers}) async {
    headers = fixHeaders(headers);
    return _client.get(_server + url, headers: headers);
  }

  Future<http.Response> httpPost(url,
      {Map<String, String> headers, body, Encoding encoding}) async {
    headers = fixHeaders(headers);
    return _client.post(_server + url,
        headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> httpPut(url,
      {Map<String, String> headers, body, Encoding encoding}) async {
    headers = fixHeaders(headers);
    return _client.put(_server + url,
        headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> httpPatch(url,
      {Map<String, String> headers, body, Encoding encoding}) async {
    headers = fixHeaders(headers);
    return _client.patch(_server + url,
        headers: headers, body: body, encoding: encoding);
  }

  Future<http.StreamedResponse> httpDelete(url,
      {Map<String, String> headers, body}) async {
    headers = fixHeaders(headers, false);
    //if (body == null) return http.delete(_server + url, headers: headers);
    http.Request rq = http.Request('DELETE', Uri.parse(_server + url))
      ..headers.addAll(headers);
    if (body != null) {
      rq.bodyFields = body;
    }
    http.StreamedResponse response = await _client.send(rq);
    return response;
  }

  Map<String, String> fixHeaders(Map<String, String> headers,
      [bool contentType = true]) {
    if (headers == null) {
      headers = {};
    }
    final basicAuth = 'Basic ' + base64Encode(utf8.encode('$_user:$_password'));
    headers.addAll({
      'OCS-APIRequest': 'true',
      'authorization': basicAuth,
      if (session != null) 'x-api-session': session,
      if (contentType) 'Content-Type': 'application/json',
      if (contentType) 'accept': 'application/json'
    });
    return headers;
  }
}
