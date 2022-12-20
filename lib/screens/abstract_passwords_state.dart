import 'package:autofill_service/autofill_service.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import './password_edit_screen.dart';
import '../helper/i18n_helper.dart';
import '../provider/folder.dart';
import '../provider/password.dart';
import '../provider/passwords_provider.dart';

abstract class AbstractPasswordsState<T extends StatefulWidget>
    extends State<T> {
  List<Password> passwords;
  List<Folder> folders;

  var _isInit = true;
  var autofillMode = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      refreshPasswords(!Provider.of<PasswordsProvider>(
        context,
        listen: false,
      ).isFetched);
    }
  }

  Future<void> refreshPasswords([bool fetch = true]) async {
    setState(() {
      passwords = null;
      folders = null;
    });
    final passwordProvider = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    );
    if (fetch) {
      var tryLocal = false;
      if (await AutofillService().hasEnabledAutofillServices) {
        autofillMode = await AutofillService().getAutofillMetadata() != null;
      }
      final success = await passwordProvider.fetchAll(tryLocalOnly: tryLocal);
      if (success == FetchResult.NoConnection && context != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('dialog.error'.tl(context)),
            content: Text('dialog.connection_error'.tl(context)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('general.ok'.tl(context)),
              )
            ],
          ),
        );
      }
      if (success == FetchResult.WrongMasterPassword && context != null) {
        String newPw = '';
        var obscureText = true;
        var storeMaster = false;
        await showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('general.password'.tl(context)),
            content: StatefulBuilder(
              builder: (context, setState) => SizedBox(
                height: 100,
                child: Column(
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: TextFormField(
                            initialValue: newPw,
                            keyboardType: TextInputType.visiblePassword,
                            obscureText: obscureText,
                            onChanged: (value) => newPw = value,
                            enableSuggestions: false,
                            autocorrect: false,
                          ),
                        ),
                        IconButton(
                          icon: Icon(obscureText
                              ? Icons.visibility_off
                              : Icons.visibility),
                          onPressed: () =>
                              setState(() => obscureText = !obscureText),
                        ),
                      ],
                    ),
                    Row(
                      children: [
                        Expanded(child: Text('general.save'.tl(context))),
                        Checkbox(
                          value: storeMaster,
                          onChanged: (value) =>
                              setState(() => storeMaster = value),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('general.ok'.tl(context)),
              ),
            ],
          ),
        );
        if (newPw.length >= 12) {
          passwordProvider.storeMaster = storeMaster;
          passwordProvider.masterPassword = newPw;
          Future.delayed(Duration(milliseconds: 200), () => refreshPasswords());
        }
      }
      if (success == FetchResult.NoConnection &&
          passwordProvider.isLocal &&
          !autofillMode) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text('dialog.local_data'.tl(context)),
            content: Text('dialog.local_cache_error'.tl(context)),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text('general.ok'.tl(context)),
              )
            ],
          ),
        );
      }
    }
    if (!mounted) return;
    final newPasswords = passwordProvider.passwords;
    newPasswords.sort();
    final newFolders = passwordProvider.folder;
    newFolders.sort();
    setState(() {
      passwords = newPasswords;
      folders = newFolders;
    });
    filter();
  }

  void filter() {}

  Future<void> createPassword([String folderId = Folder.defaultFolder]) async {
    final created = await Navigator.pushNamed(
      context,
      PasswordEditScreen.routeName,
      arguments: {'folder': folderId},
    );
    if (created != null && created) refreshPasswords(false);
  }

  Future<void> deletePassword(Password password) async {
    var doDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('dialog.are_you_sure'.tl(context)),
        content: Text(
            'dialog.want_delete_password'.tl(context) + '\n${password.label}'),
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
    doDelete ??= false;
    if (doDelete) {
      Provider.of<PasswordsProvider>(
        context,
        listen: false,
      ).deletePasswort(password.id);
      refreshPasswords(false);
    }
  }

  Future<bool> showExitPopup() async {
    if (autofillMode) {
      return true;
    }
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text('general.exit'.tl(context)),
        content: Text('dialog.are_you_sure_exit'.tl(context)),
        actions: [
          TextButton(
            child: Text('general.no'.tl(context)),
            onPressed: () => Navigator.pop(c, false),
          ),
          TextButton(
            child: Text('general.yes'.tl(context)),
            onPressed: () =>
                SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
          ),
        ],
      ),
    );
  }

  Future<void> updateFolder(Folder parentFolder, [Folder folder]) async {
    String name = folder == null ? '' : folder.label;
    await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(folder == null
            ? 'folder_screen.create_folder'.tl(context)
            : 'folder_screen.edit_folder'.tl(context)),
        content: Row(
          children: [
            Expanded(
              child: TextFormField(
                initialValue: name,
                decoration: InputDecoration(
                  labelText: 'general.name'.tl(context),
                ),
                onChanged: (value) => name = value,
              ),
            ),
          ],
        ),
        actions: [
          if (folder != null)
            IconButton(
              icon: Icon(Icons.delete),
              onPressed: () async {
                final ret = await deleteFolder(folder);
                if (ret != null && ret) Navigator.of(context).pop();
              },
            ),
          TextButton(
            onPressed: () {
              name = '';
              Navigator.of(context).pop();
            },
            child: Text('general.cancel'.tl(context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('general.ok'.tl(context)),
          ),
        ],
      ),
    );
    if (name.isNotEmpty) {
      final map = {
        'label': name,
        'parent': parentFolder == null ? Folder.defaultFolder : parentFolder.id,
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

  Future<bool> deleteFolder(Folder folder) async {
    var doDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('folder_screen.delete_folder_title'.tl(context)),
        content: Text('folder_screen.delete_folder_content'.tl(context) +
            '\n${folder.label}'),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
            },
            child: Text('general.no'.tl(context)),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(true);
            },
            child: Text('general.yes'.tl(context)),
          ),
        ],
      ),
    );
    doDelete ??= false;
    if (doDelete) {
      await folder.delete();
      refreshPasswords();
      return true;
    }
    return false;
  }
}
