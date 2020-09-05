import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:provider/provider.dart';

import '../screens/nextcloud_auth_web_screen.dart';
import '../provider/nextcloud_auth_provider.dart';

// TODO: make nice look

class NextcloudAuthScreen extends StatefulWidget {
  static const routeName = '/nextcloud-auth';

  @override
  _NextcloudAuthScreenState createState() => _NextcloudAuthScreenState();
}

class _NextcloudAuthScreenState extends State<NextcloudAuthScreen> {
  final _urlTextController = TextEditingController();

  Future<void> trySetUrlFromInput() async {
    var url = _urlTextController.text;
    if (url.startsWith('http://')) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Error'),
          content: Text(
            'The server should use a secure connection! Use "https://.."',
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
          title: const Text('Error'),
          content: Text(
            'Sorry, there was an error while trying to connect to the nextcloud server. '
            'Check URL or your internet connection.',
            softWrap: true,
          ),
        ),
      );
      Navigator.of(context).pushReplacementNamed('/');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Nextcloud Server')),
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Input your Nextcloud Server URL:',
              softWrap: true,
              style: TextStyle(fontSize: 19),
            ),
            SizedBox(
              height: 10,
            ),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    keyboardType: TextInputType.url,
                    decoration: InputDecoration(
                      labelText: 'URL',
                      hintText: "https://cloud.example.com",
                    ),
                    controller: _urlTextController,
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
            ),
            SizedBox(
              height: 50,
            ),
          ],
        ),
      ),
    );
  }
}
