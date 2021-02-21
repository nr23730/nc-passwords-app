import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:provider/provider.dart';
import 'package:qrscan/qrscan.dart' as scanner;

import '../helper/i18n_helper.dart';
import '../provider/nextcloud_auth_provider.dart';
import '../provider/theme_provider.dart';
import '../screens/nextcloud_auth_web_screen.dart';

class NextcloudAuthScreen extends StatelessWidget {
  static const routeName = 'nextcloud-auth';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('web_auth_screen.title'.tl(context))),
      backgroundColor: Theme.of(context).accentColor,
      body: Center(
        child: Card(
          elevation: 4,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: 350,
              minHeight: 180,
              maxHeight: 180,
            ),
            child: Padding(
              padding: EdgeInsets.all(10),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'web_auth_screen.input_server_url'.tl(context),
                    softWrap: true,
                    style: TextStyle(fontSize: 19),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  _NextcloudUrlInput(),
                  if (Platform.isAndroid)
                    SizedBox(
                      height: 10,
                    ),
                  if (Platform.isAndroid)
                    FlatButton.icon(
                        onPressed: () async {
                          await passLinkConnect(context);
                        },
                        icon: Icon(Icons.camera_alt_outlined),
                        label: Text("App Password"))
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Future<void> passLinkConnect(BuildContext context) async {
    String barcodeScanRes;
    if (!await Permission.camera.request().isGranted) {
      return;
    }
    try {
      barcodeScanRes = await scanner.scan();
    } on PlatformException {
      barcodeScanRes = '-1';
    }
    if (barcodeScanRes.startsWith("nc")) {
      await Provider.of<NextcloudAuthProvider>(context, listen: false)
          .setCredentials(barcodeScanRes);
      Navigator.of(context).pushReplacementNamed("/");
    }
  }
}

class _NextcloudUrlInput extends StatefulWidget {
  @override
  _NextcloudUrlInputState createState() => _NextcloudUrlInputState();
}

class _NextcloudUrlInputState extends State<_NextcloudUrlInput> {
  final _urlTextController = TextEditingController();

  Future<void> trySetUrlFromInput(context) async {
    var url = _urlTextController.text;
    if (url.startsWith('http://')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('dialog.error'.tl(context)),
          content: Text(
            'web_auth_screen.error_secure_connection'.tl(context),
            softWrap: true,
          ),
        ),
      );
      return;
    }
    if (!url.startsWith('https://')) {
      url = 'https://$url';
    }
    _urlTextController.text = url;
    final ncAuth = Provider.of<NextcloudAuthProvider>(context, listen: false);
    ncAuth.server = url;
    final success = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (context) {
          return NextcloudAuthWebScreen(ncAuth.authUrl);
        },
      ),
    );
    if (success != null && !success) {
      await showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text('dialog.error'.tl(context)),
          content: Text(
            'web_auth_screen.error_connection_nextcloud'.tl(context),
            softWrap: true,
          ),
        ),
      );
    } else if (success != null && success) {
      Provider.of<ThemeProvider>(context, listen: false).update();
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            keyboardType: TextInputType.url,
            autocorrect: false,
            autofillHints: {AutofillHints.url},
            decoration: InputDecoration(
              labelText: 'URL',
              hintText: "https://cloud.example.com",
            ),
            controller: _urlTextController,
            onSubmitted: (text) => trySetUrlFromInput(context),
            autofocus: true,
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.launch,
            size: 40,
          ),
          onPressed: () => trySetUrlFromInput(context),
        )
      ],
    );
  }
}
