import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../provider/settings_provider.dart';
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
      final canCheckBiometrics = Provider.of<SettingsProvider>(
            context,
            listen: false,
          ).useBiometricAuth &&
          await auth.canCheckBiometrics;
      if (canCheckBiometrics) {
        authenticated = await auth.authenticateWithBiometrics(
          localizedReason: 'Scan your fingerprint to authenticate.',
          useErrorDialogs: true,
          stickyAuth: true,
        );
      } else {
        // Always authenticated when no biometric auth
        authenticated = true;
      }
    } on PlatformException catch (e) {}
    if (!mounted) return;
    setState(() {
      _isAuthenticating = false;
    });
    Provider.of<LocalAuthProvider>(
      context,
      listen: false,
    ).authenticated = authenticated;
    if (authenticated) {
      Navigator.of(context).pushReplacementNamed('/');
    }
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
            const SizedBox(
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
            const SizedBox(
              height: 30,
            ),
            const Text('Please authenticate to view your passwords!'),
            const SizedBox(
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
