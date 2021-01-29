import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../provider/local_auth_provider.dart';
import '../provider/nextcloud_auth_provider.dart';
import '../provider/passwords_provider.dart';
import '../provider/search_history_provider.dart';
import '../provider/settings_provider.dart';
import '../screens/passwords_favorite_screen.dart';
import '../screens/passwords_folder_screen.dart';
import '../screens/passwords_folder_tree_screen.dart';
import '../screens/passwords_overview_screen.dart';
import '../screens/settings_screen.dart';

class AppDrawer extends StatelessWidget {
  const AppDrawer();

  @override
  Widget build(BuildContext context) {
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;

    return Provider.of<NextcloudAuthProvider>(
              context,
              listen: false,
            ).server ==
            null
        ? null
        : Drawer(
            child: SingleChildScrollView(
              child: Column(
                children: [
                  AppBar(
                    title: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Image.asset(
                          'assets/launcher/icon_full.png',
                          color: Theme.of(context).accentColor,
                          colorBlendMode: BlendMode.modulate,
                          fit: BoxFit.contain,
                          height: 50,
                        ),
                        Container(
                            padding: const EdgeInsets.fromLTRB(17, 0, 0, 0),
                            child: Text(
                              'NC Passwords',
                              style: TextStyle(fontSize: 30),
                            ))
                      ],
                    ),
                    automaticallyImplyLeading: false,
                    toolbarHeight: 100,
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.cloud_queue_sharp,
                              color: isLocal ? Colors.red : Color(0xFF00b0ff),
                              size: 25,
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
                            Icon(
                              Icons.supervisor_account,
                              size: 25,
                              color: Color(0xFF63dd15),
                            ),
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
                    leading: Icon(
                      Icons.vpn_key_sharp,
                      size: 25,
                      color: Theme.of(context).accentColor,
                    ),
                    title: Text('general.all_passwords'.tl(context)),
                    onTap: () => Navigator.of(context).pushReplacementNamed(
                        PasswordsOverviewScreen.routeName),
                  ),
                  ListTile(
                      leading: Icon(
                        Icons.folder_rounded,
                        size: 25,
                        color: Theme.of(context).accentColor,
                      ),
                      title: Text('general.folders'.tl(context)),
                      onTap: () {
                        if (Provider.of<SettingsProvider>(context,
                                    listen: false)
                                .folderView ==
                            FolderView.FlatView) {
                          Navigator.of(context).pushReplacementNamed(
                              PasswordsFolderScreen.routeName);
                        } else {
                          Navigator.of(context).pushReplacementNamed(
                              PasswordsFolderTreeScreen.routeName);
                        }
                      }),
                  ListTile(
                    leading: Icon(
                      Icons.star_sharp,
                      size: 25,
                      color: Theme.of(context).accentColor,
                    ),
                    title: Text('general.favorites'.tl(context)),
                    onTap: () => Navigator.of(context).pushReplacementNamed(
                        PasswordsFavoriteScreen.routeName),
                  ),
                  //ListTile(
                  //  leading: Icon(Icons.tag),
                  //  title: Text('Tags'),
                  //  onTap: () {},
                  //),
                  ListTile(
                    leading: Icon(
                      Icons.settings_sharp,
                      size: 25,
                      color: Theme.of(context).accentColor,
                    ),
                    title: Text('general.settings'.tl(context)),
                    onTap: () => Navigator.of(context)
                        .pushNamed(SettingsScreen.routeName),
                  ),
                  if (Provider.of<SettingsProvider>(context, listen: false)
                          .useBiometricAuth ||
                      Provider.of<SettingsProvider>(context, listen: false)
                          .usePinAuth)
                    ListTile(
                      leading: Icon(
                        Icons.lock_sharp,
                        size: 25,
                        color: Theme.of(context).accentColor,
                      ),
                      title: Text('app_drawer.lock'.tl(context)),
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
                    leading: Icon(
                      Icons.exit_to_app_sharp,
                      size: 25,
                      color: Theme.of(context).accentColor,
                    ),
                    title: Text('app_drawer.logout'.tl(context)),
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
        title: Text('dialog.are_you_sure'.tl(context)),
        content: Text('dialog.want_logout'.tl(context)),
        actions: [
          TextButton(
            child: Text('general.no'.tl(context)),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          TextButton(
            child: Text('general.yes'.tl(context)),
            onPressed: () => Navigator.of(context).pop(true),
          ),
        ],
      ),
    );
    if (doLogout) {
      await Provider.of<SearchHistoryProvider>(
        context,
        listen: false,
      ).clearHistory();
      Navigator.of(context).pop();
      Provider.of<NextcloudAuthProvider>(
        context,
        listen: false,
      ).flushLogin();
      Provider.of<PasswordsProvider>(
        context,
        listen: false,
      ).flush();
      Navigator.of(context).pushReplacementNamed('/');
    }
  }
}
