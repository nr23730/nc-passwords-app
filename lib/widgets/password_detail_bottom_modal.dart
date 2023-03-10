import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../helper/utility_actions.dart';
import '../provider/folder.dart';
import '../provider/password.dart';
import '../provider/passwords_provider.dart';
import '../screens/password_edit_screen.dart';
import '../screens/passwords_folder_screen.dart';

class PasswordDetailBottomModal extends StatefulWidget {
  final Password password;
  final Function deletePassword;

  const PasswordDetailBottomModal(this.password, this.deletePassword);

  @override
  _PasswordDetailBottomModalState createState() =>
      _PasswordDetailBottomModalState();
}

class _PasswordDetailBottomModalState extends State<PasswordDetailBottomModal> {
  var _passwordVisible = false;

  @override
  Widget build(BuildContext context) {
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;
    final customFields = widget.password.customFieldsObject;
    return ChangeNotifierProvider.value(
      value: widget.password,
      child: Consumer<Password>(
        builder: (context, password, child) => Card(
          elevation: 5,
          child: Scrollbar(
            child: SingleChildScrollView(
              child: Container(
                padding: EdgeInsets.only(
                    top: 10,
                    left: 10,
                    right: 10,
                    bottom: MediaQuery.of(context).viewInsets.bottom + 10),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        IconButton(
                          icon: Icon(password.favorite
                              ? Icons.star
                              : Icons.star_border),
                          color: Colors.amber,
                          onPressed: isLocal
                              ? null
                              : () {
                                  password.toggleFavorite();
                                },
                        ),
                        IconButton(
                          icon: Icon(Icons.security),
                          color: password.statusCodeColor,
                          onPressed: () => showDialog(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: Text('general.status'.tl(context)),
                              content: Text(
                                'dialog.security_status'.tl(context) +
                                    ': ' +
                                    password.statusCode +
                                    '\nEncryption: ' +
                                    password.cseType,
                                softWrap: true,
                              ),
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.edit),
                          color: Colors.blue,
                          onPressed: isLocal
                              ? null
                              : () {
                                  Navigator.of(context).pushNamed(
                                    PasswordEditScreen.routeName,
                                    arguments: {'password': password},
                                  );
                                },
                        ),
                        IconButton(
                          icon: Icon(Icons.delete_outline),
                          color: Colors.red,
                          onPressed: isLocal
                              ? null
                              : () {
                                  Navigator.of(context).pop();
                                  widget.deletePassword(password);
                                },
                        ),
                      ],
                    ),
                    Divider(
                      color: Theme.of(context).accentColor.withAlpha(50),
                    ),
                    _infoItem(
                      'general.name'.tl(context),
                      Expanded(
                        child: Text(
                          password.label,
                          softWrap: true,
                        ),
                      ),
                      null,
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            'general.created'.tl(context) +
                                ': ' +
                                DateFormat.yMMMd().format(password.created),
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 11),
                          ),
                          Text(
                            'general.updated'.tl(context) +
                                ': ' +
                                DateFormat.yMMMd().format(password.updated),
                            textAlign: TextAlign.end,
                            style: TextStyle(fontSize: 11),
                          ),
                        ],
                      ),
                    ),
                    if (password.username.isNotEmpty)
                      _infoItem(
                        'general.user_name'.tl(context),
                        null,
                        Text(
                          password.username,
                          softWrap: true,
                        ),
                        IconButton(
                          icon: Icon(Icons.content_copy),
                          onPressed: () {
                            copyToClipboard(
                                context, password, SelectType.Username, false);
                          },
                        ),
                      ),
                    _infoItem(
                      'general.password'.tl(context),
                      IconButton(
                        icon: Icon(_passwordVisible
                            ? Icons.visibility
                            : Icons.visibility_off),
                        onPressed: () {
                          setState(() {
                            _passwordVisible = !_passwordVisible;
                          });
                        },
                      ),
                      Text(
                        _passwordVisible ? password.password : '***********',
                      ),
                      IconButton(
                        icon: Icon(Icons.content_copy),
                        onPressed: () {
                          copyToClipboard(
                              context, password, SelectType.Password, false);
                        },
                      ),
                    ),
                    if (password.url.isNotEmpty)
                      _infoItem(
                        'Url',
                        password.url.startsWith('http')
                            ? IconButton(
                                icon: Icon(Icons.open_in_browser),
                                onPressed: () => openUrl(password.url),
                              )
                            : null,
                        Text(password.url),
                        IconButton(
                          icon: Icon(Icons.content_copy),
                          onPressed: () {
                            copyToClipboard(
                                context, password, SelectType.Url, false);
                          },
                        ),
                      ),
                    if (password.folder != Folder.defaultFolder)
                      _infoItem(
                        'general.folder'.tl(context),
                        IconButton(
                            icon: Icon(Icons.folder_open),
                            onPressed: () {
                              Navigator.of(context).pop();
                              Navigator.of(context).popAndPushNamed(
                                PasswordsFolderScreen.routeName,
                                arguments: password.folder,
                              );
                            }),
                        Text(
                          Provider.of<PasswordsProvider>(context, listen: false)
                              .findFolderById(password.folder)
                              .label,
                        ),
                      ),
                    if (password.notes.isNotEmpty)
                      _infoItem(
                        'general.notes'.tl(context),
                        Expanded(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Text(password.notes),
                          ),
                        ),
                      ),
                    if (customFields.fields.length > 0)
                      Text('general.custom_fields'.tl(context)),
                    ...customFields.fields.map((f) => _customFieldItem(f)),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _customFieldItem(Map<String, String> field) {
    var vis = !(field['type'] == 'secret');
    return StatefulBuilder(
      builder: (context, setState2) => _infoItem(
        field['label'],
        field['type'] == 'url' || field['type'] == 'email'
            ? IconButton(
                icon: Icon(Icons.open_in_browser),
                onPressed: () => openUrl(field['value']),
              )
            : field['type'] == 'secret'
                ? IconButton(
                    icon: Icon(vis ? Icons.visibility : Icons.visibility_off),
                    onPressed: () {
                      setState2(() {
                        vis = !vis;
                      });
                    },
                  )
                : null,
        Text(
          vis ? (field['value'].isEmpty ? '-' : field['value']) : '*********',
        ),
        IconButton(
          icon: Icon(Icons.content_copy),
          onPressed: () {
            copyToClipboard(context, widget.password, SelectType.CustomField,
                false, field['value']);
          },
        ),
      ),
    );
  }

  Widget _infoItem(String lable, Widget child1,
      [Widget child2, Widget child3]) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            lable,
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: 35),
            child: Row(
              children: [
                child1 != null
                    ? child1
                    : SizedBox(
                        width: 50,
                      ),
                if (child2 != null)
                  Expanded(
                    child: Container(
                      alignment: Alignment.centerLeft,
                      child: Chip(
                        elevation: 4,
                        backgroundColor:
                            Theme.of(context).primaryColor.withAlpha(20),
                        label: FittedBox(
                          child: child2,
                        ),
                      ),
                    ),
                  ),
                if (child3 != null) child3,
              ],
            ),
          ),
          Divider(
            color: Theme.of(context).accentColor.withAlpha(50),
          )
        ],
      ),
    );
  }
}
