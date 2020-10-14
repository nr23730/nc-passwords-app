import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../screens/nextcloud_auth_web_screen.dart';
import '../provider/nextcloud_auth_provider.dart';

class NextcloudAuthScreen extends StatelessWidget {
  static const routeName = 'nextcloud-auth';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(tl(context, 'web_auth_screen.title'))),
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
                    tl(context, 'web_auth_screen.input_server_url'),
                    softWrap: true,
                    style: TextStyle(fontSize: 19),
                  ),
                  SizedBox(
                    height: 10,
                  ),
                  _NextcloudUrlInput(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NextcloudUrlInput extends StatefulWidget {
  @override
  _NextcloudUrlInputState createState() => _NextcloudUrlInputState();
}

class _NextcloudUrlInputState extends State<_NextcloudUrlInput> {
  final _urlTextController = TextEditingController();

  Future<void> trySetUrlFromInput() async {
    var url = _urlTextController.text;
    if (url.startsWith('http://')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tl(context, 'dialog.error')),
          content: Text(
            tl(context, 'web_auth_screen.error_secure_connection'),
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
          title: Text(tl(context, 'dialog.error')),
          content: Text(
            tl(context, 'web_auth_screen.error_connection_nextcloud'),
            softWrap: true,
          ),
        ),
      );
    } else if (success != null && success) {
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
            decoration: InputDecoration(
              labelText: 'URL',
              hintText: "https://cloud.example.com",
            ),
            controller: _urlTextController,
            onSubmitted: (text) => trySetUrlFromInput(),
          ),
        ),
        IconButton(
          icon: Icon(
            Icons.launch,
            size: 40,
          ),
          onPressed: trySetUrlFromInput,
        )
      ],
    );
  }
}
