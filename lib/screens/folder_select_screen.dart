import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../provider/passwords_provider.dart';
import '../provider/folder.dart';
import '../widgets/folder_list_item.dart';

class FolderSelectScreen extends StatefulWidget {
  static const routeName = 'folder-select';

  @override
  _FolderSelectScreenState createState() => _FolderSelectScreenState();
}

class _FolderSelectScreenState extends State<FolderSelectScreen> {
  var currentFolderId = Folder.defaultFolder;
  var _isInit = true;

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

  List<Folder> get _getCurrentSubfolders =>
      Provider.of<PasswordsProvider>(context, listen: false)
          .getFoldersByParentFolder(currentFolderId);

  void goIntoFolder(String folderId) {
    setState(() {
      currentFolderId = folderId;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentFolder = Provider.of<PasswordsProvider>(context, listen: false)
        .findFolderById(currentFolderId);
    final isRootFolder = currentFolder == null;
    final folders = _getCurrentSubfolders;
    return Scaffold(
      appBar: AppBar(
        title: Text(tl(context, 'folder_select_screen.title')),
      ),
      body: Column(
        children: [
          SizedBox(
            width: 5,
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                color: isRootFolder ? Colors.grey : Colors.black,
                onPressed: isRootFolder
                    ? null
                    : () {
                        setState(() {
                          currentFolderId = currentFolder.parent;
                        });
                      },
              ),
              Row(
                children: [
                  Icon(Icons.folder_open),
                  SizedBox(
                    width: 3,
                  ),
                  Text(
                    isRootFolder ? '/' : currentFolder.label,
                    style: TextStyle(fontSize: 20),
                  ),
                ],
              ),
              IconButton(
                icon: Icon(Icons.done),
                color: Colors.green,
                onPressed: () {
                  Navigator.of(context).pop(currentFolderId);
                },
              ),
            ],
          ),
          Divider(),
          Expanded(
            child: Scrollbar(
              child: ListView.builder(
                itemCount: folders.length,
                itemBuilder: (ctx, i) {
                  return FolderListItem(
                    folders[i],
                    onTap: () => goIntoFolder(folders[i].id),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
