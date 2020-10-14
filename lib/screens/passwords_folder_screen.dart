import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../screens/abstract_passwords_state.dart';
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

  Future<void> updateFolder([Folder folder]) async {
    String name = folder == null ? '' : folder.label;
    await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(folder == null
            ? tl(context, 'folder_screen.create_folder')
            : tl(context, 'folder_screen.edit_folder')),
        content: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: tl(context, 'general.name'),
                ),
                onChanged: (value) => name = value,
              ),
            ),
          ],
        ),
        actions: [
          FlatButton(
            onPressed: () {
              name = '';
              Navigator.of(context).pop();
            },
            child: Text(tl(context, 'general.cancel')),
          ),
          FlatButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text(tl(context, 'general.ok')),
          ),
        ],
      ),
    );
    if (name.isNotEmpty) {
      final map = {
        'label': name,
        'parent':
            currentFolder == null ? Folder.defaultFolder : currentFolder.id,
      };
      if (folder == null) {
        await Provider.of<PasswordsProvider>(context, listen: false)
            .createFolder(map);
      } else {
        await folder.update(map);
      }
      refreshPasswords(false);
    }
  }

  Future<void> deleteFolder(Folder folder) async {
    var doDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(tl(context, 'folder_screen.delete_folder_title')),
        content: Text(tl(context, 'folder_screen.delete_folder_content') +
            '\n${folder.label}'),
        actions: [
          FlatButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text(tl(context, 'general.no')),
          ),
          FlatButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text(tl(context, 'general.yes')),
          ),
        ],
      ),
    );
    doDelete ??= false;
    if (doDelete) {
      await folder.delete();
      refreshPasswords();
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;
    final rows = folders == null
        ? Center(child: CircularProgressIndicator())
        : Card(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    if (currentFolder != null)
                      FlatButton.icon(
                        label: Text(currentFolder.label),
                        icon: Icon(Icons.arrow_back),
                        onPressed: goFolderBack,
                      ),
                    if (!isLocal)
                      FlatButton.icon(
                        label: Text(tl(context, 'folder_screen.new_folder')),
                        icon: Icon(Icons.create_new_folder),
                        onPressed: updateFolder,
                      ),
                  ],
                ),
                const Divider(
                  height: 1,
                ),
                Expanded(
                  child: Scrollbar(
                    child: ListView.builder(
                      itemCount: folders.length + passwords.length,
                      itemBuilder: (ctx, i) {
                        if (i < folders.length) {
                          return FolderListItem(folders[i], goIntoFolder,
                              updateFolder, deleteFolder);
                        } else {
                          return PasswordListItem(
                            passwords[i - folders.length],
                            deletePassword,
                            autofillMode,
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          );

    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          child: Text(
            tl(context, 'general.folder') +
                (currentFolder != null ? ' - ' + currentFolder.label : ''),
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => refreshPasswords(),
          ),
        ],
      ),
      floatingActionButton: isLocal
          ? null
          : FloatingActionButton(
              onPressed: () => createPassword(currentFolder == null
                  ? Folder.defaultFolder
                  : currentFolder.id),
              child: Icon(Icons.add),
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
    );
  }
}
