import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../provider/folder.dart';
import '../provider/password.dart';
import '../provider/passwords_provider.dart';
import './password_edit_screen.dart';

abstract class AbstractPasswordsState<T extends StatefulWidget>
    extends State<T> {
  List<Password> passwords;
  List<Folder> folders;

  var _isInit = true;

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
      final success = await passwordProvider.fetchAll();
      if (!success && context != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tl(context, 'dialog.error')),
            content: Text(tl(context, 'dialog.connection_error')),
            actions: [
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tl(context, 'general.ok')),
              )
            ],
          ),
        );
      }
      if (passwordProvider.isLocal) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tl(context, 'dialog.local_data')),
            content: Text(tl(context, 'dialog.local_cache_error')),
            actions: [
              FlatButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tl(context, 'general.ok')),
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
        title: Text(tl(context, 'dialog.are_you_sure')),
        content: Text(
            tl(context, 'dialog.want_delete_password') + '\n${password.label}'),
        actions: [
          FlatButton(
            child: Text(tl(context, 'general.no')),
            onPressed: () => Navigator.of(context).pop(false),
          ),
          FlatButton(
            child: Text(tl(context, 'general.yes')),
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
}
