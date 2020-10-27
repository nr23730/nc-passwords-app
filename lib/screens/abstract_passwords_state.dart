import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:autofill_service/autofill_service.dart';

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
        tryLocal = await AutofillService().getAutofillMetadata() != null;
        if (tryLocal) autofillMode = true;
      }
      final success = await passwordProvider.fetchAll(tryLocalOnly: tryLocal);
      if (!success && context != null) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tl(context, 'dialog.error')),
            content: Text(tl(context, 'dialog.connection_error')),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(tl(context, 'general.ok')),
              )
            ],
          ),
        );
      }
      if (passwordProvider.isLocal && !autofillMode) {
        showDialog(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(tl(context, 'dialog.local_data')),
            content: Text(tl(context, 'dialog.local_cache_error')),
            actions: [
              TextButton(
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
    return showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: Text(tl(context, 'general.exit')),
        content: Text(tl(context, 'dialog.are_you_sure_exit')),
        actions: [
          FlatButton(
            child: Text(tl(context, 'general.no')),
            onPressed: () => Navigator.pop(c, false),
          ),
          FlatButton(
            child: Text(tl(context, 'general.yes')),
            onPressed: () =>
                SystemChannels.platform.invokeMethod('SystemNavigator.pop'),
          ),
        ],
      ),
    );
  }
}
