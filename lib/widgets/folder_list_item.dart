import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/passwords_provider.dart';
import '../provider/folder.dart';

class FolderListItem extends StatelessWidget {
  final Folder _folder;
  final Function setFolder;
  final Function updateFolder;
  final Function deleteFolder;

  const FolderListItem(this._folder, this.setFolder,
      [this.updateFolder, this.deleteFolder]);

  @override
  Widget build(BuildContext context) {
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;
    return Column(children: [
      ListTile(
        leading: Icon(Icons.folder_rounded, size: 40, color: Color(0xFF088FD8)),
        title: Text(_folder.label),
        onTap: () => setFolder(_folder.id),
        onLongPress: isLocal || updateFolder == null
            ? null
            : () => updateFolder(_folder),
      ),
      Divider(
        color: Theme.of(context).accentColor.withAlpha(50),
      ),
    ]);
  }
}
