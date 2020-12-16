import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:provider/provider.dart';
import 'package:flutter/rendering.dart';
import '../helper/i18n_helper.dart';

import '../screens/abstract_passwords_state.dart';
import '../screens/passwords_folder_screen.dart';
import '../provider/settings_provider.dart';
import '../provider/passwords_provider.dart';
import '../provider/folder.dart';
import '../widgets/app_drawer.dart';
import '../widgets/password_list_item.dart';
import '../widgets/folder_list_item.dart';

class PasswordsFolderTreeScreen extends StatefulWidget {
  static const routeName = 'passwords-folder-tree';

  @override
  _PasswordsFolderTreeScreenState createState() =>
      _PasswordsFolderTreeScreenState();
}

class _PasswordsFolderTreeScreenState
    extends AbstractPasswordsState<PasswordsFolderTreeScreen> {
  Set<String> _openFolders = {};

  var _isInit = true;
  String _currentSelectedFolder = '';
  String _tmpFolderID;

  @override
  void didChangeDependencies() {
    if (_isInit) {
      _isInit = false;
    }
    super.didChangeDependencies();
  }

  @override
  void filter() {
    super.filter();
  }

  void _clickFolder(String folderId, bool onTap) {
    _currentSelectedFolder = folderId;
    if (_openFolders.contains(folderId) && onTap) {
      if (folderId == _tmpFolderID) {
        _openFolders.remove(folderId);
      } else {
        _tmpFolderID = folderId;
      }
    } else if (onTap) {
      _tmpFolderID = folderId;
      _openFolders.add(folderId);
    }
    setState(() {});
  }

  List<Map<String, dynamic>> _computeCurrentItems(
      [String startFolder, int level = 0]) {
    if (startFolder == null) {
      return _computeCurrentItems(Folder.defaultFolder, 0);
    }
    final passwordProvider = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    );
    List<Map<String, dynamic>> items = [];
    final folders = passwordProvider.getFoldersByParentFolder(startFolder);
    folders.sort();
    // add all open folders
    for (final folder in folders) {
      items.add({
        'type': 'folder',
        'value': folder,
        'level': level,
      });
      if (_openFolders.contains(folder.id)) {
        items.addAll(_computeCurrentItems(folder.id, level + 1));
      }
    }
    final passwords = passwordProvider.getPasswordsByFolder(startFolder);
    passwords.sort();
    items.addAll(passwords.map((p) => {
          'type': 'password',
          'value': p,
          'level': level,
        }));
    return items;
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;
    final currentItems = _computeCurrentItems();
    final rows = folders == null
        ? Center(child: CircularProgressIndicator())
        : Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Scrollbar(
                  child: ListView.builder(
                    itemCount: currentItems.length,
                    itemBuilder: (ctx, i) {
                      if (currentItems[i]['type'] == 'folder') {
                        if (_openFolders.isNotEmpty &&
                            (currentItems[i]['value'] as Folder).id ==
                                _currentSelectedFolder) {
                          return FolderListItem(
                            currentItems[i]['value'],
                            onTap: () => _clickFolder(
                                (currentItems[i]['value'] as Folder).id, true),
                            iconData: _openFolders.contains(
                                    (currentItems[i]['value'] as Folder).id)
                                ? Icons.folder_open_rounded
                                : Icons.folder_rounded,
                            level: currentItems[i]['level'],
                            trailing: isLocal || autofillMode
                                ? null
                                : Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.vpn_key_sharp),
                                        onPressed: () => createPassword(
                                            (currentItems[i]['value'] as Folder)
                                                .id),
                                      ),
                                      IconButton(
                                        icon:
                                            Icon(Icons.create_new_folder_sharp),
                                        onPressed: () => updateFolder(
                                            currentItems[i]['value'] as Folder),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.edit),
                                        onPressed: () {
                                          final parent =
                                              Provider.of<PasswordsProvider>(
                                                      context,
                                                      listen: false)
                                                  .findFolderById(
                                                      (currentItems[i]['value']
                                                              as Folder)
                                                          .parent);
                                          updateFolder(
                                              parent,
                                              currentItems[i]['value']
                                                  as Folder);
                                        },
                                      ),
                                    ],
                                  ),
                          );
                        } else {
                          return FolderListItem(
                            currentItems[i]['value'],
                            onTap: () {
                              _clickFolder(
                                  (currentItems[i]['value'] as Folder).id,
                                  true);
                            },
                            iconData: _openFolders.contains(
                                    (currentItems[i]['value'] as Folder).id)
                                ? Icons.folder_open_rounded
                                : Icons.folder_rounded,
                            level: currentItems[i]['level'],
                          );
                        }
                      } else {
                        return PasswordListItem(
                          currentItems[i]['value'],
                          deletePassword: deletePassword,
                          autoFillMode: autofillMode,
                          level: currentItems[i]['level'],
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
          title: FittedBox(
            child: Text(
              'general.folder'.tl(context),
            ),
          ),
          actions: [
            IconButton(
                icon: Icon(Icons.view_stream_outlined),
                onPressed: () {
                  Provider.of<SettingsProvider>(context, listen: false)
                      .folderView = FolderView.FlatView;
                  Navigator.of(context)
                      .pushReplacementNamed(PasswordsFolderScreen.routeName);
                }),
            IconButton(
              icon: Icon(Icons.refresh),
              onPressed: () => refreshPasswords(),
            ),
          ],
        ),
        drawer: const AppDrawer(),
        body: passwords == null
            ? Center(
                child: CircularProgressIndicator(),
              )
            : RefreshIndicator(
                onRefresh: () => refreshPasswords(),
                child: rows,
              ),
        floatingActionButton: _openFolders.isNotEmpty || isLocal || autofillMode
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
                        Text('edit_screen.create_password'.tl(context)),
                    onTap: () => createPassword(Folder.defaultFolder),
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.create_new_folder_sharp),
                    backgroundColor: Theme.of(context).accentColor,
                    labelWidget:
                        Text('folder_screen.create_folder'.tl(context)),
                    onTap: () => updateFolder(null),
                  ),
                ],
              ),
      ),
    );
  }
}
