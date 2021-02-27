import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nc_passwords_app/provider/settings_provider.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart' as urlLauncher;

import '../provider/password.dart';

enum SelectType { Password, Username, Url, CustomField }

void copyToClipboard(
    BuildContext context, Password password, SelectType selectType,
    [bool showSnackbar = true, String customFieldValue = '']) {
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
    case SelectType.CustomField:
      val = customFieldValue;
      name = 'Custom';
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
  final deleteAfterSeconds =
      Provider.of<SettingsProvider>(context, listen: false)
          .deleteClipboardAfterSeconds;
  if (deleteAfterSeconds > 0) {
    Future.delayed(
      Duration(seconds: deleteAfterSeconds),
      () => Clipboard.setData(ClipboardData(text: '')),
    );
  }
}

Future<void> openUrl(String url) async {
  if (await urlLauncher.canLaunch(url)) {
    urlLauncher.launch(url);
  }
}
