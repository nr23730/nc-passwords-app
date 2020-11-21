import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';

import '../helper/i18n_helper.dart';
import '../screens/passwords_folder_tree_screen.dart';
import '../screens/abstract_passwords_state.dart';
import '../provider/settings_provider.dart';
import '../provider/passwords_provider.dart';
import '../provider/folder.dart';
import '../widgets/app_drawer.dart';
import '../widgets/password_list_item.dart';
import '../widgets/folder_list_item.dart';

class PasswordsFolderScreen extends StatefulWidget {
  static const routeName = 'passwords-folder';

  @override
  _PasswordsFolderScreenState createState() => _PasswordsFolderScreenState();
}

class _PasswordsFolderScreenState
    extends AbstractPasswordsState<PasswordsFolderScreen> {
  Folder currentFolder;
  List<String> lastFolderIds = [];

  var _isInit = true;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
      final folderId = ModalRoute.of(context).settings.arguments as String;
      if (folderId != null) {
        currentFolder = Provider.of<PasswordsProvider>(
          context,
          listen: false,
        ).findFolderById(folderId);
      }
    }
    super.didChangeDependencies();
  }

  void _filterFolder() {
    final passwordProvider = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    );
    var folderId = Folder.defaultFolder;
    if (currentFolder != null) {
      folderId = currentFolder.id;
    }
    final newFolders = passwordProvider.getFoldersByParentFolder(folderId);
    newFolders.sort();
    final newPasswords = passwordProvider.getPasswordsByFolder(folderId);
    newPasswords.sort();
    final newCurrentFolder = passwordProvider.findFolderById(folderId);
    setState(() {
      passwords = newPasswords;
      currentFolder = newCurrentFolder;
      folders = newFolders;
    });
  }

  @override
  void filter() {
    super.filter();
    _filterFolder();
  }

  void goIntoFolder(String folderId) {
    currentFolder = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).findFolderById(folderId);
    _filterFolder();
  }

  void goFolderBack() {
    currentFolder = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).findFolderById(currentFolder.parent);
    _filterFolder();
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;
    final rows = folders == null
        ? Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: folders.length + passwords.length,
                    itemBuilder: (ctx, i) {
                      if (i < folders.length) {
                        return FolderListItem(
                          folders[i],
                          onTap: () => goIntoFolder(folders[i].id),
                          onLongPress: () =>
                              updateFolder(currentFolder, folders[i]),
                        );
                      } else {
                        return PasswordListItem(
                          passwords[i - folders.length],
                          deletePassword: deletePassword,
                          autoFillMode: autofillMode,
                        );
                      }
                    },
                  ),
                ),
              ),
            ],
          );
    return WillPopScope(
      onWillPop: showExitPopup,
      child: Scaffold(
        appBar: AppBar(
          leading: currentFolder != null
              ? IconButton(
                  icon: Icon(Icons.arrow_back),
                  onPressed: goFolderBack,
                )
              : null,
          title: FittedBox(
            child: Text(
              tl(context, 'general.folder') +
                  (currentFolder != null ? ' - ' + currentFolder.label : ''),
            ),
          ),
          actions: [
            IconButton(
                icon: Icon(Icons.account_tree_outlined),
                onPressed: () {
                  Provider.of<SettingsProvider>(context, listen: false)
                      .folderView = FolderView.TreeView;
                  Navigator.of(context).pushReplacementNamed(
                      PasswordsFolderTreeScreen.routeName);
                }),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => refreshPasswords(),
            ),
          ],
        ),
        floatingActionButton: isLocal || autofillMode
            ? null
            : SpeedDial(
                animatedIcon: AnimatedIcons.menu_close,
                animatedIconTheme: IconThemeData(size: 22.0),
                // this is ignored if animatedIcon is non null
                // child: Icon(Icons.add),
                curve: Curves.decelerate,
                overlayColor: Colors.black,
                overlayOpacity: 0,
                tooltip: 'Speed Dial',
                heroTag: 'speed-dial-hero-tag',
                backgroundColor: Theme.of(context).accentColor,
                foregroundColor:
                    Provider.of<SettingsProvider>(context, listen: false)
                                .themeStyle ==
                            ThemeStyle.Amoled
                        ? Colors.black
                        : Colors.white,
                elevation: 8.0,
                shape: CircleBorder(),
                children: [
                  SpeedDialChild(
                    child: Icon(Icons.vpn_key_sharp),
                    backgroundColor: Theme.of(context).accentColor,
                    labelWidget:
                        Text(tl(context, 'folder_screen.create_folder')),
                    onTap: () => createPassword(currentFolder == null
                        ? Folder.defaultFolder
                        : currentFolder.id),
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.create_new_folder_sharp),
                    backgroundColor: Theme.of(context).accentColor,
                    labelWidget:
                        Text(tl(context, 'folder_screen.create_folder')),
                    onTap: () => updateFolder(currentFolder),
                  ),
                ],
              ),
        drawer: currentFolder == null ? const AppDrawer() : null,
        body: passwords == null
            ? Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: () => refreshPasswords(),
                child: rows,
              ),
      ),
    );
  }

  Future<bool> showExitPopup() async {
    if (currentFolder != null) {
      goFolderBack();
      return false;
    }
    return super.showExitPopup();
  }
}
