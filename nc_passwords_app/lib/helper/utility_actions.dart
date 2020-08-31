import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart' as urlLauncher;

import '../provider/password.dart';

enum SelectType { Password, Username, Url }

void copyToClipboard(
    BuildContext context, Password password, SelectType selectType,
    [bool showSnackbar = true]) {
  String val = '';
  String name = '';
  switch (selectType) {
    case SelectType.Password:
      val = password.password;
      name = 'Password';
      break;
    case SelectType.Username:
      val = password.username;
      name = 'Username';
      break;
    case SelectType.Url:
      val = password.url;
      name = 'Url';
      break;
  }
  Clipboard.setData(ClipboardData(text: val));
  if (showSnackbar) {
    Scaffold.of(context).hideCurrentSnackBar();
    Scaffold.of(context).showSnackBar(
      SnackBar(
        content: Text('$name for ${password.label} copied to clipboard'),
        duration: Duration(seconds: 4),
      ),
    );
  }
}

Future<void> openUrl(Password password) async {
  if (await urlLauncher.canLaunch(password.url)) {
    urlLauncher.launch(password.url);
  }
}
