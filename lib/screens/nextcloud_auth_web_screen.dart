import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
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
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: new AppBar(
        title: Text('web_auth_screen.title'.tl(context)),
      ),
      body: Center(
        child: InAppWebView(
          initialUrl: widget.authUrl,
          initialHeaders: {
            'OCS-APIRequest': 'true',
          },
          initialOptions: InAppWebViewGroupOptions(
            crossPlatform: InAppWebViewOptions(
              useShouldOverrideUrlLoading: true,
              cacheEnabled: false,
              clearCache: true,
              userAgent: 'Nextcloud Passwords App',
              disableHorizontalScroll: true,
            ),
            android: AndroidInAppWebViewOptions(
              clearSessionCache: true,
              saveFormData: false,
              cacheMode: AndroidCacheMode.LOAD_NO_CACHE,
            ),
          ),
          shouldOverrideUrlLoading:
              (controller, shouldOverrideUrlLoadingRequest) async {
            final url = shouldOverrideUrlLoadingRequest.url;
            final uri1 = Uri.parse(widget.authUrl);
            final uri2 = Uri.parse(url);
            if (!url.startsWith('nc://') && uri1.host != uri2.host) {
              return ShouldOverrideUrlLoadingAction.CANCEL;
            }
            if (url.startsWith('nc://login')) {
              final nap = Provider.of<NextcloudAuthProvider>(
                context,
                listen: false,
              );
              await nap.setCredentials(url);
            }
            return ShouldOverrideUrlLoadingAction.ALLOW;
          },
          onLoadError: (controller, url, code, message) =>
              Navigator.of(context).pop(Provider.of<NextcloudAuthProvider>(
            context,
            listen: false,
          ).isAuthenticated),
          onLoadHttpError: (controller, url, statusCode, description) =>
              Navigator.of(context).pop(Provider.of<NextcloudAuthProvider>(
            context,
            listen: false,
          ).isAuthenticated),
          onReceivedServerTrustAuthRequest: (InAppWebViewController controller,
              ServerTrustChallenge challenge) async {
            return ServerTrustAuthResponse(
                action: ServerTrustAuthResponseAction.PROCEED);
          },
        ),
      ),
    );
  }
}
