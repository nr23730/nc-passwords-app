import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

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
      filter();
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
      if (!success) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Error'),
            content: Text('No connection!'),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Ok'))
            ],
          ),
        );
      }
      if (passwordProvider.isLocal) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Local data'),
            content: Text(
                'You see a local cache, no changes are possible! Check your internet connection or the availability of your nextcloud server.'),
            actions: [
              FlatButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text('Ok'))
            ],
          ),
        );
      }
    }
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

  Future<void> createPassword([String folderId = '']) async {
    final created = await Navigator.pushNamed(
      context,
      PasswordEditScreen.routeName,
      arguments: {'folder': folderId},
    );
    if (created != null && created) refreshPasswords(false);
  }

  Future<void> deletePassword(Password password) async {
    final doDelete = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Are you sure?'),
        content:
            Text('Do you want to delete this password? \n${password.label}'),
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
    if (doDelete) {
      Provider.of<PasswordsProvider>(
        context,
        listen: false,
      ).deletePasswort(password.id);
      refreshPasswords(false);
    }
  }
}
