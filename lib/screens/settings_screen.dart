import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/settings_provider.dart';
import '../widgets/app_drawer.dart';

class SettingsScreen extends StatefulWidget {
  static const routeName = '/settings';

  @override
  _SettingsScreenState createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  static const _startViewValues = {
    StartView.AllPasswords: ["All Passwords", Icons.description],
    StartView.Folders: ["Folders", Icons.folder_open],
    StartView.Favorites: ["Favorites", Icons.star],
  };

  final _startViewMenuItems = _startViewValues.keys
      .map(
        (key) => DropdownMenuItem(
          value: key,
          child: Row(
            children: [
              Icon(_startViewValues[key][1]),
              const SizedBox(
                width: 5,
              ),
              Text(_startViewValues[key][0]),
            ],
          ),
        ),
      )
      .toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
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
                const Text(
                  'Start view',
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
                const Text(
                  'Use biometric auth',
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
                const Text(
                  'Password strengths',
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
          ],
        ),
      ),
    );
  }
}
