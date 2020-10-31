import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:local_auth/local_auth.dart';

import '../helper/i18n_helper.dart';
import '../provider/settings_provider.dart';
import '../provider/local_auth_provider.dart';
import './pin_screen.dart';

class LocalAuthScreen extends StatefulWidget {
  static const routeName = 'local-auth-screen';

  @override
  _LocalAuthScreenState createState() => _LocalAuthScreenState();
}

class _LocalAuthScreenState extends State<LocalAuthScreen> {
  final LocalAuthentication auth = LocalAuthentication();
  var _isAuthenticating = false;

  Future<void> _authenticate() async {
    var authenticated = false;
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    final localAuth = Provider.of<LocalAuthProvider>(context, listen: false);
    setState(() {
      _isAuthenticating = true;
    });
    // Bio Auth
    if (settings.useBiometricAuth) {
      try {
        final canCheckBiometrics =
            settings.useBiometricAuth && await auth.canCheckBiometrics;
        if (canCheckBiometrics) {
          authenticated = await auth.authenticateWithBiometrics(
            localizedReason:
                tl(context, 'local_auth_screen.please_authenticate'),
            useErrorDialogs: true,
            stickyAuth: true,
          );
        } else {
          // Always authenticated when no biometric auth
          authenticated = true;
        }
      } on PlatformException catch (e) {}
      if (!mounted) return;
    }
    // Pin Auth
    if (!authenticated && settings.usePinAuth) {
      final value1 = await Navigator.of(context).pushNamed(
        PinScreen.routeName,
        arguments: tl(context, "general.enter_pin"),
      );
      if (value1 != null) {
        if (localAuth.checkLocalPin(value1)) {
          authenticated = true;
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text(tl(context, 'dialog.error')),
              content: Text(
                tl(context, 'general.wrong_pin'),
                softWrap: true,
              ),
            ),
          );
        }
      }
    }
    setState(() {
      _isAuthenticating = false;
    });
    localAuth.authenticated = authenticated;
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
    Future.delayed(Duration(milliseconds: 100), _authenticate);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).accentColor,
      body: Center(
        heightFactor: 2,
        child: Card(
          elevation: 4,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: 220,
              maxHeight: 220,
              maxWidth: 270,
            ),
            child: Padding(
              padding: const EdgeInsets.all(18),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.start,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
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
                  Text(tl(context, 'local_auth_screen.please_authenticate')),
                  const SizedBox(
                    height: 30,
                  ),
                  _isAuthenticating
                      ? CircularProgressIndicator()
                      : TextButton(
                          onPressed: _authenticate,
                          child: Text(
                              tl(context, 'local_auth_screen.authenticate')),
                        ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
