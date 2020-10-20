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
    flutterWebViewPlugin.onUrlChanged.listen((url) async {
      if (url.startsWith('nc://login')) {
        setState(() {
          _loading = true;
        });
        final nap = Provider.of<NextcloudAuthProvider>(
          context,
          listen: false,
        );
        if (nap.isAuthenticated) {
          return;
        }
        await nap.setCredentials(url);
        flutterWebViewPlugin.close();
        Navigator.of(context).pop(true);
      }
    });
    flutterWebViewPlugin.onHttpError.listen((error) async {
      setState(() {
        _loading = true;
      });
      if (error.url.startsWith('nc://login')) {
        final nap = Provider.of<NextcloudAuthProvider>(
          context,
          listen: false,
        );
        if (nap.isAuthenticated) {
          return;
        }
        await nap.setCredentials(error.url);
        flutterWebViewPlugin.close();
        Navigator.of(context).pop(true);
      } else {
        flutterWebViewPlugin.close();
        Navigator.of(context).pop(false);
      }
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
