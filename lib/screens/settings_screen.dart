import 'package:autofill_service/autofill_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../provider/settings_provider.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = 'settings';

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  var _hasEnabledAutofillServices = false;
  var _hasAutofillServicesSupport = false;

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
    setState(() {});
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
                Icon(_startViewValues[key][1], color: Color(0x9B000000),),
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
                    onChanged: (value) {
                      settings.useBiometricAuth = value;
                    },
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
