import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/settings_provider.dart';
import '../provider/local_auth_provider.dart';
import '../provider/nextcloud_auth_provider.dart';
import '../provider/passwords_provider.dart';
import '../screens/passwords_favorite_screen.dart';
import '../screens/passwords_folder_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/passwords_overview_screen.dart';

class AppDrawer extends StatelessWidget {
  static const _divider = Divider(
    thickness: 2,
  );

  const AppDrawer();

  @override
  Widget build(BuildContext context) {
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;
    return Drawer(
      child: SingleChildScrollView(
        child: Column(
          children: [
            AppBar(
              title: Text('Nextcloud Password Manager'),
              automaticallyImplyLeading: false,
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.cloud_queue,
                        color: isLocal ? Colors.red : Colors.black,
                      ),
                      SizedBox(
                        width: 10,
                      ),
                      FittedBox(
                        child: Text(
                          Provider.of<NextcloudAuthProvider>(
                            context,
                            listen: false,
                          ).server,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(
                    height: 4,
                  ),
                  Row(
                    children: [
                      Icon(Icons.supervised_user_circle),
                      SizedBox(
                        width: 10,
                      ),
                      FittedBox(
                        child: Text(
                          Provider.of<NextcloudAuthProvider>(
                            context,
                            listen: false,
                          ).user,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            _divider,
            SizedBox(
              height: 10,
            ),
            ListTile(
              leading: Icon(Icons.description),
              title: Text('All Passwords'),
              onTap: () => Navigator.of(context)
                  .pushReplacementNamed(PasswordsOverviewScreen.routeName),
            ),
            _divider,
            ListTile(
              leading: Icon(Icons.folder_open),
              title: Text('Folders'),
              onTap: () => Navigator.of(context)
                  .pushReplacementNamed(PasswordsFolderScreen.routeName),
            ),
            _divider,
            ListTile(
              leading: Icon(Icons.star),
              title: Text('Favorites'),
              onTap: () => Navigator.of(context)
                  .pushReplacementNamed(PasswordsFavoriteScreen.routeName),
            ),
            _divider,
            //ListTile(
            //  leading: Icon(Icons.tag),
            //  title: Text('Tags'),
            //  onTap: () {},
            //),
            //_divider,
            ListTile(
                leading: Icon(Icons.settings),
                title: Text('Settings'),
                onTap: () => Navigator.of(context)
                    .pushReplacementNamed(SettingsScreen.routeName)),
            _divider,
            if (Provider.of<SettingsProvider>(context, listen: false)
                .useBiometricAuth)
              ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text('Lock Screen'),
                onTap: () {
                  Navigator.of(context).pop();
                  Provider.of<LocalAuthProvider>(
                    context,
                    listen: false,
                  ).authenticated = false;
                  Navigator.of(context).pushReplacementNamed('/');
                },
              ),
            if (Provider.of<SettingsProvider>(context, listen: false)
                .useBiometricAuth)
              _divider,
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text('Logout'),
              onTap: () => logout(context),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> logout(BuildContext context) async {
    final doLogout = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?'),
        content: Text('Do you really want to logout?'),
        actions: [
          FlatButton(
            child: Text('No'),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FlatButton(
            child: Text('Yes'),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (doLogout) {
      Navigator.of(context).pop();
      Provider.of<NextcloudAuthProvider>(
        context,
        listen: false,
      ).flushLogin();
      Navigator.of(context).pushReplacementNamed('/');
    }
  }
}
