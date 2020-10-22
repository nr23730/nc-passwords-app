import 'dart:convert';

import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../helper/auth_exception.dart';

class NextcloudAuthProvider with ChangeNotifier {
  static final _expCred = RegExp(r"nc:.*server:(.*)&user:(.*)&password:(.*)");
  static const _authPath = 'index.php/login/flow';
  static const _capabilitiesPath = '/ocs/v1.php/cloud/capabilities';

  static const _userFieldName = 'nc_user';
  static const _passwordFieldName = 'nc_password';
  static const _serverFieldName = 'nc_server';

  final _storage = FlutterSecureStorage();

  String _user;
  String _password;
  String _server;
  String _capabilities;

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
    final match = _expCred.firstMatch(urlNcResponse);
    final user = match.group(2);
    final password = match.group(3);
    if (user != null && password != null) {
      await _setCredentials(
        user: user,
        password: password,
      );
    }
  }

  Future<void> _setCredentials({String user, String password}) async {
    // server must be set before!
    if (_server == null) {
      throw AuthException('Set the server before call setCredentials()!');
    }
    _user = user;
    _password = password;
    //notifyListeners();
    // save in secure storage
    Future.wait({
      _storage.write(key: _userFieldName, value: _user),
      _storage.write(key: _passwordFieldName, value: _password),
      _storage.write(key: _serverFieldName, value: _server),
    });
    // try loading theming
    final response = await httpGet(_capabilitiesPath);
    if (response.statusCode >= 300) {
      return;
    }
    _capabilities = response.body;
    await _storage.write(key: _capabilitiesPath, value: _capabilities);
  }

  Future<bool> autoLogin() async {
    _user = await _storage.read(key: _userFieldName);
    _password = await _storage.read(key: _passwordFieldName);
    _server = await _storage.read(key: _serverFieldName);
    _capabilities = await _storage.read(key: _capabilitiesPath);
    return _user != null;
  }

  Future<void> flushLogin() async {
    _user = null;
    _password = null;
    _server = null;
    _capabilities = null;
    notifyListeners();
    _storage.deleteAll();
  }

  Future<http.Response> httpGet(url, {Map<String, String> headers}) async {
    headers = fixHeaders(headers);
    return http.get(_server + url, headers: headers);
  }

  Future<http.Response> httpPost(url,
      {Map<String, String> headers, body, Encoding encoding}) async {
    headers = fixHeaders(headers);
    return http.post(_server + url,
        headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> httpPut(url,
      {Map<String, String> headers, body, Encoding encoding}) async {
    headers = fixHeaders(headers);
    return http.put(_server + url,
        headers: headers, body: body, encoding: encoding);
  }

  Future<http.Response> httpPatch(url,
      {Map<String, String> headers, body, Encoding encoding}) async {
    headers = fixHeaders(headers);
    return http.patch(_server + url,
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
    http.StreamedResponse response = await http.Client().send(rq);
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
      if (contentType) 'Content-Type': 'application/json',
      if (contentType) 'accept': 'application/json'
    });
    return headers;
  }
}
