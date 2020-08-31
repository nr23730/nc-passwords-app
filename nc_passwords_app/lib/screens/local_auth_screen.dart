import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../provider/local_auth_provider.dart';

class LocalAuthScreen extends StatefulWidget {
  static const routeName = '/local-auth-screen';

  @override
  _LocalAuthScreenState createState() => _LocalAuthScreenState();
}

class _LocalAuthScreenState extends State<LocalAuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  bool _isAuthenticating = false;

  Future<void> _authenticate() async {
    bool authenticated = false;
    try {
      setState(() {
        _isAuthenticating = true;
      });
      final canCheckBiometrics = await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        authenticated = await auth.authenticateWithBiometrics(
          localizedReason: 'Scan your fingerprint to authenticate',
          useErrorDialogs: true,
          stickyAuth: true,
        );
      } else {
        // Always authenticated when no biometric auth
        Provider.of<LocalAuthProvider>(
          context,
          listen: false,
        ).authenticated = true;
      }
      setState(() {
        _isAuthenticating = false;
      });
    } on PlatformException catch (e) {
      print(e);
    }
    if (!mounted) return;

    Provider.of<LocalAuthProvider>(
      context,
      listen: false,
    ).authenticated = authenticated;
  }

  void _cancelAuthentication() {
    auth.stopAuthentication();
  }

  @override
  void initState() {
    super.initState();
    _authenticate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: EdgeInsets.all(10),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            SizedBox(
              height: 30,
            ),
            Container(
              width: double.infinity,
              child: const Text(
                'Authentication',
                style: TextStyle(
                  fontSize: 24,
                  color: Colors.grey,
                ),
                textAlign: TextAlign.center,
              ),
            ),
            SizedBox(
              height: 30,
            ),
            const Text('Please authenticate to view your passwords!'),
            SizedBox(
              height: 30,
            ),
            _isAuthenticating
                ? CircularProgressIndicator()
                : FlatButton(
                    onPressed: _authenticate,
                    color: Theme.of(context).accentColor,
                    child: const Text('Authenticate'),
                  ),
          ],
        ),
      ),
    );
  }
}
