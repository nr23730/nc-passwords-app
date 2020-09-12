import 'package:flutter/material.dart';
import 'package:flutter_webview_plugin/flutter_webview_plugin.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../provider/nextcloud_auth_provider.dart';

class NextcloudAuthWebScreen extends StatefulWidget {
  final String authUrl;

  NextcloudAuthWebScreen(this.authUrl);

  @override
  _NextcloudAuthWebScreenState createState() => _NextcloudAuthWebScreenState();
}

class _NextcloudAuthWebScreenState extends State<NextcloudAuthWebScreen> {
  final flutterWebViewPlugin = FlutterWebviewPlugin();
  var _loading = false;

  @override
  void initState() {
    super.initState();
    flutterWebViewPlugin.onHttpError.listen((error) {
      setState(() {
        _loading = true;
      });
      if (error.url.startsWith('nc://login')) {
        Provider.of<NextcloudAuthProvider>(
          context,
          listen: false,
        ).setCredentials(error.url);
      }
      flutterWebViewPlugin.close();
      Navigator.of(context).pop(error.url.startsWith('nc://login'));
    });
  }

  @override
  void dispose() {
    super.dispose();
    flutterWebViewPlugin.close();
    flutterWebViewPlugin.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        body: Center(
          child: const CircularProgressIndicator(),
        ),
      );
    }
    return WebviewScaffold(
      url: widget.authUrl,
      userAgent: 'Nextcloud Passwords App',
      headers: {
        'OCS-APIRequest': 'true',
      },
      appBar: new AppBar(
        title: Text(tl(context, 'web_auth_screen.title')),
      ),
      clearCache: true,
      clearCookies: true,
      withZoom: true,
      withLocalStorage: false,
      hidden: true,
      initialChild: Container(
        child: const Center(
          child: const CircularProgressIndicator(),
        ),
      ),
    );
  }
}
