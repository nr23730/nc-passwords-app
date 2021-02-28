import 'package:flutter/material.dart';
import 'package:nc_passwords_app/helper/custom_fields.dart';
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
  Map<String, dynamic> _data = {};
  Password _password;
  CustomFields _customFields;
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
        _data['folder'] = args['folder'] as String;
      } else {
        _data['folder'] = Folder.defaultFolder;
      }
      _customFields = CustomFields.empty();
      if (args['password'] != null) {
        _password = args['password'];
        pwTextController.text = _password.password;
        _data['folder'] = _password.folder;
        _data['customFields'] = _password.customFields;
        _customFields = _password.customFieldsObject;
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
      arguments: _data['folder'],
    );
    if (newFolderId != null) {
      setState(() {
        _data['folder'] = newFolderId;
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
    _data['customFields'] = _customFields.asJson;
    if (_password != null) {
      // Update
      await _password.update(_data);
    } else {
      // Create
      await Provider.of<PasswordsProvider>(
        context,
        listen: false,
      ).createPasswort(_data);
    }
    Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
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
                            onSaved: (newValue) => _data['label'] = newValue,
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
                            onSaved: (newValue) => _data['username'] = newValue,
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
                            onSaved: (newValue) => _data['password'] = newValue,
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
                            onSaved: (newValue) => _data['url'] = newValue,
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
                                label: Text(_data['folder'] ==
                                        Folder.defaultFolder
                                    ? '/'
                                    : Provider.of<PasswordsProvider>(context)
                                        .findFolderById(_data['folder'])
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
                            onSaved: (newValue) => _data['notes'] = newValue,
                          ),
                          if (_customFields.fields.length > 0) ...[
                            SizedBox(
                              height: 5,
                            ),
                            Divider(
                              color: Colors.black,
                            ),
                            Text('Custom Fields'),
                          ],
                          ..._customFields.fields
                              .map((f) => _customFieldItem(f)),
                          FlatButton.icon(
                            onPressed: () {
                              _customFields.createField('text', 'new', '');
                              setState(() {});
                            },
                            icon: Icon(Icons.add_circle_outline),
                            label: Text('Add custom field'), // TODO: tl
                          ),
                          // TODO: ADD BUTTON FOR CUSTOM FIELDS
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
    return StatefulBuilder(
        builder: (context, setState2) => Column(
              children: [
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Label', // TODO: tl
                  ),
                  keyboardType: TextInputType.url,
                  initialValue: field['label'],
                  validator: (value) =>
                      CustomFields.labelCheck(value) ? null : 'Invalid',
                  // TODO: tl
                  onSaved: (newValue) => field['label'] = newValue,
                ),
                TextFormField(
                  decoration: InputDecoration(
                    labelText: 'Value', // TODO: tl
                  ),
                  keyboardType: TextInputType.url,
                  initialValue: field['value'],
                  validator: (value) =>
                      CustomFields.valueCheck(value) ? null : 'Invalid',
                  // TODO: tl
                  onSaved: (newValue) => field['value'] = newValue,
                ),
                SizedBox(
                  height: 5,
                ),
                Divider(
                  color: Colors.black,
                ),
                // TODO: add DELETE BUTTON
                // TODO: add type BUTTON
              ],
            ));
  }
}
