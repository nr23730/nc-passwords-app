import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/passwords_provider.dart';
import '../provider/folder.dart';

class FolderListItem extends StatelessWidget {
  final Folder _folder;
  final Function onTap;
  final Function onLongPress;
  final IconData iconData;
  final int level;
  final Widget trailing;

  const FolderListItem(this._folder,
      {this.onTap,
      this.onLongPress,
      this.iconData = Icons.folder_rounded,
      this.level = 0,
      this.trailing})
      : assert(
          _folder != null,
          'A non-null Folder must be provided to a FolderListItem widget.',
        );

  @override
  Widget build(BuildContext context) {
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;
    return Column(
      children: [
        Row(
          children: [
            SizedBox(
              width: 15.0 * level,
            ),
            Expanded(
              child: ListTile(
                leading: Icon(
                  iconData,
                  size: 40,
                  color: Color(0xFF088FD8),
                ),
                title: Text(_folder.label),
                onTap: onTap,
                onLongPress:
                    isLocal || onLongPress == null ? null : onLongPress,
                trailing: trailing,
              ),
            ),
          ],
        ),
        Divider(
          color: Theme.of(context).accentColor.withAlpha(50),
        ),
      ],
    );
  }
}
