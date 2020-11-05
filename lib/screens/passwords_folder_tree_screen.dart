import 'dart:core';

import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
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
  bool longPress = false;
  bool editMode = false;
  String currentFolder = '';

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

  void clickFolder(String folderId, bool onTap) {
    if (onTap) longPress = false;
    currentFolder = folderId;
    if (_openFolders.contains(folderId) && onTap) {
      _openFolders.remove(folderId);
    } else if (onTap) {
      _openFolders.add(folderId);
    }
    setState(() {});
  }

  Future<void> _folderOptionsDialog([Folder currentFolder]) async {
    var isRoot = currentFolder == null;
    var folderId = isRoot ? Folder.defaultFolder : currentFolder.id;
    switch (await showDialog<String>(
      context: context,
      builder: (BuildContext context) {
        return SimpleDialog(
          children: <Widget>[
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'newPw');
              },
              child: Text(tl(context, 'edit_screen.create_password')),
            ),
            if (!isRoot) Divider(),
            if (!isRoot)
              SimpleDialogOption(
                onPressed: () {
                  Navigator.pop(context, 'editFolder');
                },
                child: Text(tl(context, 'folder_screen.edit_folder')),
              ),
            Divider(),
            SimpleDialogOption(
              onPressed: () {
                Navigator.pop(context, 'newSubfolder');
              },
              child: Text(tl(context, 'folder_screen.create_folder')),
            ),
          ],
        );
      },
    )) {
      case 'newPw':
        await createPassword(folderId);
        break;
      case 'editFolder':
        await updateFolder(
            Provider.of<PasswordsProvider>(
              context,
              listen: false,
            ).findFolderById(currentFolder.parent),
            currentFolder);
        break;
      case 'newSubfolder':
        await updateFolder(currentFolder);
        break;
    }
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
                        if (longPress &&
                            (currentItems[i]['value'] as Folder).id ==
                                currentFolder) {
                          return FolderListItem(currentItems[i]['value'],
                              onTap: () => clickFolder(
                                  (currentItems[i]['value'] as Folder).id,
                                  true),
                              iconData: _openFolders.contains(
                                      (currentItems[i]['value'] as Folder).id)
                                  ? Icons.folder_open_rounded
                                  : Icons.folder_rounded,
                              level: currentItems[i]['level'],
                              onLongPress: () {
                                clickFolder(
                                    (currentItems[i]['value'] as Folder).id,
                                    false);
                                longPress = true;
                              },
                              trailing: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.vpn_key_sharp),
                                    onPressed: null,
                                  ),
                                  IconButton(
                                      icon: Icon(Icons.create_new_folder_sharp),
                                      onPressed: null),
                                ],
                              ));
                        } else {
                          return FolderListItem(currentItems[i]['value'],
                              onTap: () => clickFolder(
                                  (currentItems[i]['value'] as Folder).id,
                                  true),
                              iconData: _openFolders.contains(
                                      (currentItems[i]['value'] as Folder).id)
                                  ? Icons.folder_open_rounded
                                  : Icons.folder_rounded,
                              level: currentItems[i]['level'],
                              onLongPress: () {
                                clickFolder(
                                    (currentItems[i]['value'] as Folder).id,
                                    false);
                                longPress = true;
                              });
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
              // TODO add translation
              tl(context, 'general.folder'),
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
            : FloatingActionButton(
                backgroundColor: Theme.of(context).accentColor,
                onPressed: _folderOptionsDialog,
                child: Icon(Icons.add),
              ),
      ),
    );
  }
}
