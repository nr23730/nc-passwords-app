import 'package:autofill_service/autofill_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:local_auth/local_auth.dart';
import 'package:provider/provider.dart';
import 'package:flutter_colorpicker/flutter_colorpicker.dart';

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
  Color _pickerColor = Color(0xFF252525);

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
                  color: Theme.of(context).accentColor,
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

    final themeStyles = {
      ThemeStyle.System: [
        tl(context, "settings.system"),
        Icons.format_paint_sharp,
      ],
      ThemeStyle.Light: [
        tl(context, "settings.light_theme"),
        Icons.format_paint_sharp,
      ],
      ThemeStyle.Dark: [
        tl(context, "settings.dark_theme"),
        Icons.format_paint_sharp,
      ],
      ThemeStyle.Amoled: [
        tl(context, "settings.amoled"),
        Icons.format_paint_sharp,
      ],
    };

    final themeStylesMenuItems = themeStyles.keys
        .map(
          (key) => DropdownMenuItem(
            value: key,
            child: Row(
              children: [
                Icon(
                  themeStyles[key][1],
                  color: Theme.of(context).accentColor,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(themeStyles[key][0]),
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
                      activeColor: Theme.of(context).accentColor,
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
                    activeColor: Theme.of(context).accentColor,
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
                      activeColor: Theme.of(context).accentColor,
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
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  tl(context, 'settings.theme'),
                  style: TextStyle(fontSize: 16),
                ),
                Consumer<SettingsProvider>(
                  builder: (context, settings, child) => DropdownButton(
                    value: settings.themeStyle,
                    onChanged: (value) {
                      settings.themeStyle = value;
                    },
                    items: themeStylesMenuItems,
                  ),
                ),
              ],
            ),
            if (Provider.of<SettingsProvider>(context).themeStyle !=
                ThemeStyle.System)
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Container(
                    child: Text(
                      tl(context, 'settings.accent_color'),
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                  Spacer(),
                  Consumer<SettingsProvider>(
                      builder: (context, settings, child) => Container(
                            height: 30,
                            width: 30,
                            decoration: BoxDecoration(
                              border: Border.all(width: 4, color: Colors.white),
                              borderRadius: BorderRadius.all(
                                Radius.circular(10),
                              ),
                            ),
                            child: FlatButton(
                              color: settings.customAccentColor,
                              onPressed: () {
                                showDialog(
                                  context: context,
                                  child: AlertDialog(
                                    title: Text(
                                      tl(context, 'settings.select_color'),
                                    ),
                                    content: SingleChildScrollView(
                                      child: MaterialPicker(
                                        pickerColor: _pickerColor,
                                        onColorChanged: (color) => setState(
                                          () => _pickerColor = color,
                                        ),
                                      ),
                                    ),
                                    actions: <Widget>[
                                      FlatButton(
                                        child: Text(
                                          tl(context, 'general.select'),
                                        ),
                                        onPressed: () {
                                          setState(() =>
                                              settings.customAccentColor =
                                                  _pickerColor);
                                          Navigator.of(context).pop();
                                        },
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                          )),
                  Spacer(),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) => Checkbox(
                      value: settings.useCustomAccentColor,
                      activeColor: Theme.of(context).accentColor,
                      onChanged: (value) =>
                          settings.useCustomAccentColor = value,
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
