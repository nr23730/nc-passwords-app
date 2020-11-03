import 'package:autofill_service/autofill_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../provider/local_auth_provider.dart';
import '../provider/settings_provider.dart';
import '../screens/pin_screen.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = 'settings';

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _hasEnabledAutofillServices = false;
  var _hasAutofillServicesSupport = false;
  final LocalAuthentication auth = LocalAuthentication();
  var _canCheckBiometrics = false;

  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  Future<void> _updateStatus() async {
    _hasAutofillServicesSupport =
        await AutofillService().hasAutofillServicesSupport;
    _hasEnabledAutofillServices =
        await AutofillService().hasEnabledAutofillServices;
    _canCheckBiometrics = await auth.canCheckBiometrics;
    setState(() {});
  }

  Future<void> setBiometicAuth(bool value, SettingsProvider settings) async {
    // Is Pin auth active?
    if (!settings.usePinAuth) {
      showDialog(
        context: context,
        builder: (context) => AlertDialog(
          title: Text(tl(context, 'dialog.error')),
          content: Text(
            tl(context, 'settings.need_pin_for_bio_auth'),
            softWrap: true,
          ),
        ),
      );
      return;
    }
    if (await auth.authenticateWithBiometrics(
      localizedReason: tl(context, 'local_auth_screen.please_authenticate'),
    )) {
      settings.useBiometricAuth = value;
    }
  }

  Future<void> setPinAuth(bool value, SettingsProvider settings) async {
    final localAuth = Provider.of<LocalAuthProvider>(
      context,
      listen: false,
    );
    // Set pin auth to FALSE
    if (!value) {
      final value1 = await Navigator.of(context).pushNamed(
        PinScreen.routeName,
        arguments: tl(context, "general.enter_pin"),
      );
      if (value1 != null) {
        if (localAuth.checkLocalPin(value1)) {
          settings.usePinAuth = false;
          settings.useBiometricAuth = false;
          localAuth.localPin = '';
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
      return;
    }
    // Set pin auth to TRUE
    final value1 = await Navigator.of(context).pushNamed(
      PinScreen.routeName,
      arguments: tl(context, "general.enter_pin"),
    );
    if (value1 != null && (value1 as String).isNotEmpty) {
      final value2 = await Navigator.of(context).pushNamed(
        PinScreen.routeName,
        arguments: tl(context, "general.enter_pin_again"),
      );
      if (value2 != null) {
        if (value1 == value2) {
          settings.usePinAuth = true;
          localAuth.localPin = value2;
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
  }

  @override
  Widget build(BuildContext context) {
    final _startViewValues = {
      StartView.AllPasswords: [
        tl(context, "general.all_passwords"),
        Icons.vpn_key_sharp,
      ],
      StartView.Folders: [
        tl(
          context,
          "general.folders",
        ),
        Icons.folder_rounded
      ],
      StartView.Favorites: [
        tl(
          context,
          "general.favorites",
        ),
        Icons.star
      ],
    };

    final _startViewMenuItems = _startViewValues.keys
        .map(
          (key) => DropdownMenuItem(
            value: key,
            child: Row(
              children: [
                Icon(
                  _startViewValues[key][1],
                  color: Color(0x9B000000),
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(_startViewValues[key][0]),
              ],
            ),
          ),
        )
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: Text(tl(context, 'general.settings')),
        leading: IconButton(
          icon: Icon(Icons.arrow_back),
          onPressed: () {
            Navigator.of(context).pop();
          },
        ),
      ),
      drawer: AppDrawer(),
      body: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tl(context, 'settings.start_view'),
                  style: TextStyle(fontSize: 16),
                ),
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) => DropdownButton(
                    value: settings.startView,
                    onChanged: (value) {
                      settings.startView = value;
                    },
                    items: _startViewMenuItems,
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            if (_canCheckBiometrics)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tl(context, 'settings.biometric_auth'),
                    style: TextStyle(fontSize: 16),
                  ),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) => Checkbox(
                      value: settings.useBiometricAuth,
                      onChanged: (value) => setBiometicAuth(value, settings),
                    ),
                  ),
                ],
              ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tl(context, 'settings.pin_auth'),
                  style: TextStyle(fontSize: 16),
                ),
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) => Checkbox(
                    value: settings.usePinAuth,
                    onChanged: (value) => setPinAuth(value, settings),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tl(context, 'settings.passwort_strength'),
                  style: TextStyle(fontSize: 16),
                ),
                Expanded(
                  child: Consumer<SettingsProvider>(
                    builder: (context, settings, child) => Slider(
                      value: settings.passwordStrength.toDouble(),
                      min: 5,
                      max: 30,
                      divisions: 25,
                      label: settings.passwordStrength.toString(),
                      inactiveColor: settings.passwordStrength < 8
                          ? Colors.red
                          : settings.passwordStrength < 13
                              ? Colors.orange
                              : settings.passwordStrength < 20
                                  ? Colors.yellow
                                  : Colors.green,
                      activeColor: settings.passwordStrength < 8
                          ? Colors.red
                          : settings.passwordStrength < 13
                              ? Colors.orange
                              : settings.passwordStrength < 20
                                  ? Colors.yellow
                                  : Colors.green,
                      onChanged: (value) {
                        settings.passwordStrengthNoWrite = value.round();
                      },
                      onChangeEnd: (value) {
                        settings.passwordStrength = value.round();
                      },
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(
              height: 10,
            ),
            if (_hasAutofillServicesSupport)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    tl(context, 'settings.autofill'),
                    style: TextStyle(fontSize: 16),
                  ),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) => Checkbox(
                      value: _hasEnabledAutofillServices,
                      onChanged: _hasEnabledAutofillServices
                          ? null
                          : (value) async {
                              await AutofillService()
                                  .requestSetAutofillService();
                              _updateStatus();
                            },
                    ),
                  ),
                ],
              ),
          ],
        ),
      ),
    );
  }
}
