import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../provider/settings_provider.dart';
import '../provider/local_auth_provider.dart';
import '../provider/nextcloud_auth_provider.dart';
import '../provider/passwords_provider.dart';
import '../screens/passwords_favorite_screen.dart';
import '../screens/passwords_folder_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/passwords_overview_screen.dart';

class AppDrawer extends StatelessWidget {

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
            Divider(
              thickness: 2,
              color: Theme.of(context).accentColor.withAlpha(50),
            ),
            SizedBox(
              height: 10,
            ),
            ListTile(
              leading: Icon(Icons.description),
              title: Text(tl(context, "general.all_passwords")),
              onTap: () => Navigator.of(context)
                  .pushReplacementNamed(PasswordsOverviewScreen.routeName),
            ),
            ListTile(
              leading: Icon(Icons.folder_open),
              title: Text(tl(context, "general.folders")),
              onTap: () => Navigator.of(context)
                  .pushReplacementNamed(PasswordsFolderScreen.routeName),
            ),
            ListTile(
              leading: Icon(Icons.star),
              title: Text(tl(context, 'general.favorites')),
              onTap: () => Navigator.of(context)
                  .pushReplacementNamed(PasswordsFavoriteScreen.routeName),
            ),
            //ListTile(
            //  leading: Icon(Icons.tag),
            //  title: Text('Tags'),
            //  onTap: () {},
            //),
            ListTile(
                leading: Icon(Icons.settings),
                title: Text(tl(context, 'general.settings')),
                onTap: () => Navigator.of(context)
                    .pushReplacementNamed(SettingsScreen.routeName)),
            if (Provider.of<SettingsProvider>(context, listen: false)
                .useBiometricAuth)
              ListTile(
                leading: Icon(Icons.lock_outline),
                title: Text(tl(context, 'app_drawer.lock')),
                onTap: () {
                  Navigator.of(context).pop();
                  Provider.of<LocalAuthProvider>(
                    context,
                    listen: false,
                  ).authenticated = false;
                  Navigator.of(context).pushReplacementNamed('/');
                },
              ),
            ListTile(
              leading: Icon(Icons.exit_to_app),
              title: Text(tl(context, 'app_drawer.logout')),
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
        title: Text(tl(context, 'dialog.are_you_sure')),
        content: Text(tl(context, 'dialog.want_logout')),
        actions: [
          TextButton(
            child: Text(tl(context, 'general.no')),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text(tl(context, 'general.yes')),
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
