import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/passwords_provider.dart';
import '../provider/folder.dart';

class FolderListItem extends StatelessWidget {
  final Folder _folder;
  final Function setFolder;
  final Function updateFolder;

  const FolderListItem(this._folder, this.setFolder, this.updateFolder);

  @override
  Widget build(BuildContext context) {
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;
    return Card(
      elevation: 2,
      color: Colors.white70,
      child: ListTile(
        leading: Icon(Icons.folder_open),
        title: Text(_folder.label),
        onTap: () => setFolder(_folder.id),
        trailing: isLocal
            ? null
            : IconButton(
                icon: Icon(Icons.edit),
                onPressed: () => updateFolder(_folder),
              ),
      ),
    );
  }
}
