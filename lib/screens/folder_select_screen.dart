import 'package:flutter/material.dart';
import 'package:nc_passwords_app/provider/folder.dart';

import '../helper/i18n_helper.dart';

class FolderSelectScreen extends StatefulWidget {
  static const routeName = '/folder-select';

  @override
  _FolderSelectScreenState createState() => _FolderSelectScreenState();
}

class _FolderSelectScreenState extends State<FolderSelectScreen> {
  var _isInit = true;
  var currentFolderId = Folder.defaultFolder;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isInit = false;
      final arg = ModalRoute.of(context).settings.arguments as String;
      if (arg != null) {
        currentFolderId = arg;
      }
    }
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      appBar: AppBar(
        title: Text(tl(context, 'folder_select_screen.title')),
      ),
      body: CircularProgressIndicator(),
    );
  }
}
