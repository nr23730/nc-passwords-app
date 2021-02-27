import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../provider/folder.dart';
import '../provider/password.dart';
import '../provider/passwords_provider.dart';
import '../provider/settings_provider.dart';
import '../screens/folder_select_screen.dart';

class PasswordEditScreen extends StatefulWidget {
  static const routeName = 'passwords-edit';

  @override
  _PasswordEditScreenState createState() => _PasswordEditScreenState();
}

class _PasswordEditScreenState extends State<PasswordEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final pwTextController = TextEditingController();
  Map<String, dynamic> data = {};
  Password _password;
  var _isInit = true;
  var _isLoading = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      _isLoading = false;
      _isInit = false;
      final args =
          ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
      if (args['folder'] != null) {
        data['folder'] = args['folder'] as String;
      } else {
        data['folder'] = Folder.defaultFolder;
      }
      if (args['password'] != null) {
        _password = args['password'];
        pwTextController.text = _password.password;
        data['folder'] = _password.folder;
        data['customFields'] = _password.customFields;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    pwTextController.dispose();
  }

  Future<void> selectFolder() async {
    final newFolderId = await Navigator.of(context).pushNamed(
      FolderSelectScreen.routeName,
      arguments: data['folder'],
    );
    if (newFolderId != null) {
      setState(() {
        data['folder'] = newFolderId;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();
    setState(() {
      _isLoading = true;
    });
    if (data['customFields'] == null) {
      data['customFields'] = '[]';
    }
    if (_password != null) {
      // Update
      await _password.update(data);
    } else {
      // Create
      await Provider.of<PasswordsProvider>(
        context,
        listen: false,
      ).createPasswort(data);
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final customFields = _password.customFieldsObject;
    return Scaffold(
      appBar: AppBar(
        title: Text(_password == null
            ? 'edit_screen.create_password'.tl(context)
            : 'edit_screen.edit_password'.tl(context)),
        actions: [
          IconButton(
            onPressed: _submit,
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: _isLoading
          ? Center(
        child: CircularProgressIndicator(),
      )
          : Form(
        key: _formKey,
        child: Padding(
          padding: EdgeInsets.all(5),
          child: SingleChildScrollView(
            child: Card(
              elevation: 5,
              child: Padding(
                padding: EdgeInsets.all(5),
                child: Column(
                  children: [
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'general.name'.tl(context),
                        hintText:
                        'edit_screen.hint_name_password'.tl(context),
                      ),
                      keyboardType: TextInputType.text,
                      initialValue:
                      _password == null ? '' : _password.label,
                      validator: (value) => value.length < 1
                          ? 'edit_screen.error_name_filled'.tl(context)
                          : null,
                      onSaved: (newValue) => data['label'] = newValue,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'general.user_name'.tl(context),
                        hintText:
                        'edit_screen.hint_your_username'.tl(context),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      initialValue:
                      _password == null ? '' : _password.username,
                      onSaved: (newValue) => data['username'] = newValue,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'general.password'.tl(context),
                        hintText:
                        'edit_screen.hint_your_password'.tl(context),
                        suffixIcon: IconButton(
                          onPressed: () {
                            pwTextController.text =
                                Password.randomPassword(
                                  Provider.of<SettingsProvider>(
                                    context,
                                    listen: false,
                                  ).passwordStrength,
                                );
                          },
                          icon: Icon(
                            Icons.autorenew,
                            color: Theme.of(context).accentColor,
                          ),
                        ),
                      ),
                      controller: pwTextController,
                      keyboardType: TextInputType.visiblePassword,
                      //initialValue: _password == null ? '' : _password.password,
                      validator: (value) => value.length < 1
                          ? 'edit_screen.error_password_filled'
                          .tl(context)
                          : null,
                      onSaved: (newValue) => data['password'] = newValue,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Url',
                        hintText: 'http..',
                      ),
                      keyboardType: TextInputType.url,
                      initialValue:
                      _password == null ? '' : _password.url,
                      validator: (value) =>
                      value != '' && !Uri.parse(value).isAbsolute
                          ? 'edit_screen.error_url'.tl(context)
                          : null,
                      onSaved: (newValue) => data['url'] = newValue,
                    ),
                    SizedBox(
                      height: 10,
                    ),
                    Row(
                      children: [
                        Text('general.folder'.tl(context)),
                        SizedBox(
                          width: 20,
                        ),
                        FlatButton.icon(
                          onPressed: selectFolder,
                          icon: Icon(Icons.folder_open),
                          label: Text(data['folder'] ==
                              Folder.defaultFolder
                              ? '/'
                              : Provider.of<PasswordsProvider>(context)
                              .findFolderById(data['folder'])
                              .label),
                        ),
                      ],
                    ),
                    SizedBox(
                      height: 5,
                    ),
                    Divider(
                      color: Colors.black,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'general.notes'.tl(context),
                        hintText: 'edit_screen.hint_notes'.tl(context),
                      ),
                      minLines: 5,
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      initialValue:
                      _password == null ? '' : _password.notes,
                      onSaved: (newValue) => data['notes'] = newValue,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
