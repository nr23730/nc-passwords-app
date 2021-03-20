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
          title: Text('dialog.error'.tl(context)),
          content: Text(
            'settings.need_pin_for_bio_auth'.tl(context),
            softWrap: true,
          ),
        ),
      );
      return;
    }
    if (await auth.authenticateWithBiometrics(
      localizedReason: 'local_auth_screen.please_authenticate'.tl(context),
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
        arguments: 'general.enter_pin'.tl(context),
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
              title: Text('dialog.error'.tl(context)),
              content: Text(
                'general.wrong_pin'.tl(context),
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
      arguments: 'general.enter_pin'.tl(context),
    );
    if (value1 != null && (value1 as String).isNotEmpty) {
      final value2 = await Navigator.of(context).pushNamed(
        PinScreen.routeName,
        arguments: 'general.enter_pin_again'.tl(context),
      );
      if (value2 != null) {
        if (value1 == value2) {
          settings.usePinAuth = true;
          localAuth.localPin = value2;
        } else {
          showDialog(
            context: context,
            builder: (context) => AlertDialog(
              title: Text('dialog.error'.tl(context)),
              content: Text(
                'general.wrong_pin'.tl(context),
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
        'general.all_passwords'.tl(context),
        Icons.vpn_key_sharp,
      ],
      StartView.Folders: ['general.folders'.tl(context), Icons.folder_rounded],
      StartView.Favorites: ["general.favorites".tl(context), Icons.star],
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

    final _deleteClipboardDurations = {
      0: [
        'settings.never'.tl(context),
        Icons.clear,
      ],
      10: [
        'settings.ten_seconds'.tl(context),
        Icons.timelapse,
      ],
      30: [
        'settings.thirty_seconds'.tl(context),
        Icons.timelapse,
      ],
      60: [
        'settings.one_minute'.tl(context),
        Icons.timelapse,
      ],
      320: [
        'settings.five_minutes'.tl(context),
        Icons.timelapse,
      ],
    };

    final _deleteClipboardDurationsMenuItems = _deleteClipboardDurations.keys
        .map(
          (key) => DropdownMenuItem(
            value: key,
            child: Row(
              children: [
                Icon(
                  _deleteClipboardDurations[key][1],
                  color: Theme.of(context).accentColor,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(_deleteClipboardDurations[key][0]),
              ],
            ),
          ),
        )
        .toList();

    final _lockAfterPausedSeconds = {
      0: [
        'settings.never'.tl(context),
        Icons.clear,
      ],
      10: [
        'settings.ten_seconds'.tl(context),
        Icons.timelapse,
      ],
      30: [
        'settings.thirty_seconds'.tl(context),
        Icons.timelapse,
      ],
      60: [
        'settings.one_minute'.tl(context),
        Icons.timelapse,
      ],
      320: [
        'settings.five_minutes'.tl(context),
        Icons.timelapse,
      ]
    };

    final _lockAfterPausedSecondsMenuItems = _lockAfterPausedSeconds.keys
        .map(
          (key) => DropdownMenuItem(
            value: key,
            child: Row(
              children: [
                Icon(
                  _lockAfterPausedSeconds[key][1],
                  color: Theme.of(context).accentColor,
                ),
                const SizedBox(
                  width: 5,
                ),
                Text(_lockAfterPausedSeconds[key][0]),
              ],
            ),
          ),
        )
        .toList();

    final themeStyles = {
      ThemeStyle.System: [
        'settings.system'.tl(context),
        Icons.format_paint_sharp,
      ],
      ThemeStyle.Light: [
        'settings.light_theme'.tl(context),
        Icons.format_paint_sharp,
      ],
      ThemeStyle.Dark: [
        'settings.dark_theme'.tl(context),
        Icons.format_paint_sharp,
      ],
      ThemeStyle.Amoled: [
        'settings.amoled'.tl(context),
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
        title: Text('general.settings'.tl(context)),
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
        child: SingleChildScrollView(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'settings.start_view'.tl(context),
                    style: TextStyle(fontSize: 16),
                  ),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) =>
                        DropdownButton(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'settings.pin_auth'.tl(context),
                    style: TextStyle(fontSize: 16),
                  ),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) =>
                        Checkbox(
                          value: settings.usePinAuth,
                          activeColor: Theme
                              .of(context)
                              .accentColor,
                          onChanged: (value) => setPinAuth(value, settings),
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
                      'settings.biometric_auth'.tl(context),
                      style: TextStyle(fontSize: 16),
                    ),
                    Consumer<SettingsProvider>(
                      builder: (context, settings, child) =>
                          Checkbox(
                            value: settings.useBiometricAuth,
                            activeColor: Theme
                                .of(context)
                                .accentColor,
                            onChanged: (value) =>
                                setBiometicAuth(value, settings),
                          ),
                    ),
                  ],
                ),
              const SizedBox(
                height: 10,
              ),
              if (Provider
                  .of<SettingsProvider>(context)
                  .usePinAuth)
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'settings.lockAfterPauseLabel'.tl(context),
                      style: TextStyle(fontSize: 16),
                    ),
                    Consumer<SettingsProvider>(
                      builder: (context, settings, child) =>
                          DropdownButton(
                            value: settings.lockAfterPausedSeconds,
                            onChanged: (value) {
                              settings.lockAfterPausedSeconds = value;
                            },
                            items: _lockAfterPausedSecondsMenuItems,
                          ),
                    ),
                  ],
                ),
              if (Provider
                  .of<SettingsProvider>(context)
                  .usePinAuth)
                const SizedBox(
                  height: 10,
                ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'settings.passwort_strength'.tl(context),
                    style: TextStyle(fontSize: 16),
                  ),
                  Expanded(
                    child: Consumer<SettingsProvider>(
                      builder: (context, settings, child) =>
                          Slider(
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'settings.delClipDurLabel'.tl(context),
                    style: TextStyle(fontSize: 16),
                  ),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) =>
                        DropdownButton(
                          value: settings.deleteClipboardAfterSeconds,
                          onChanged: (value) {
                            settings.deleteClipboardAfterSeconds = value;
                          },
                          items: _deleteClipboardDurationsMenuItems,
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
                      'settings.autofill'.tl(context),
                      style: TextStyle(fontSize: 16),
                    ),
                    Consumer<SettingsProvider>(
                      builder: (context, settings, child) =>
                          Checkbox(
                            activeColor: Theme
                                .of(context)
                                .accentColor,
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
                    'settings.theme'.tl(context),
                    style: TextStyle(fontSize: 16),
                  ),
                  Consumer<SettingsProvider>(
                    builder: (context, settings, child) =>
                        DropdownButton(
                          value: settings.themeStyle,
                          onChanged: (value) {
                            settings.themeStyle = value;
                          },
                          items: themeStylesMenuItems,
                        ),
                  ),
                ],
              ),
              if (Provider
                  .of<SettingsProvider>(context)
                  .themeStyle !=
                  ThemeStyle.System)
                Row(
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: [
                    Container(
                      child: Text(
                        'settings.accent_color'.tl(context),
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                    Spacer(),
                    Consumer<SettingsProvider>(
                        builder: (context, settings, child) =>
                            Container(
                              height: 30,
                              width: 30,
                              decoration: BoxDecoration(
                                border:
                                Border.all(width: 4, color: Colors.white),
                                borderRadius: BorderRadius.all(
                                  Radius.circular(10),
                                ),
                              ),
                              child: FlatButton(
                                color: settings.customAccentColor,
                                onPressed: () {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: Text(
                                        'settings.select_color'.tl(context),
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
                                            'general.select'.tl(context),
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
                      builder: (context, settings, child) =>
                          Checkbox(
                            value: settings.useCustomAccentColor,
                            activeColor: Theme
                                .of(context)
                                .accentColor,
                            onChanged: (value) =>
                            settings.useCustomAccentColor = value,
                          ),
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }
}
