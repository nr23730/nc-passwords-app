import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../provider/password.dart';
import '../provider/settings_provider.dart';
import '../provider/passwords_provider.dart';

class PasswordEditScreen extends StatefulWidget {
  static const routeName = '/passwords/edit';

  @override
  _PasswordEditScreenState createState() => _PasswordEditScreenState();
}

class _PasswordEditScreenState extends State<PasswordEditScreen> {
  final GlobalKey<FormState> _formKey = GlobalKey();
  final pwTextController = TextEditingController();
  Map<String, dynamic> data = {};
  Password _password;
  var _isInit = true;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_isInit) {
      final args =
          ModalRoute.of(context).settings.arguments as Map<String, dynamic>;
      if (args['password'] != null) {
        _password = args['password'];
        pwTextController.text = _password.password;
      }
      if (args['folder'] != null) {
        data['folder'] = args['folder'] as String;
      }
    }
  }

  @override
  void dispose() {
    super.dispose();
    pwTextController.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState.validate()) {
      return;
    }
    _formKey.currentState.save();
    if (_password != null) {
      // Update
      _password.update(data);
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
    return Scaffold(
      appBar: AppBar(
        title: Text(_password == null
            ? tl(context, 'edit_screen.create_password')
            : tl(context, 'edit_screen.edit_password')),
        actions: [
          IconButton(
            onPressed: _submit,
            icon: Icon(Icons.save),
          ),
        ],
      ),
      body: Form(
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
                        labelText: tl(context, 'general.name'),
                        hintText: tl(context, 'edit_screen.hint_name_password'),
                      ),
                      keyboardType: TextInputType.text,
                      initialValue: _password == null ? '' : _password.label,
                      validator: (value) => value.length < 1
                          ? tl(context, 'edit_screen.error_name_filled')
                          : null,
                      onSaved: (newValue) => data['label'] = newValue,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: tl(context, 'general.user_name'),
                        hintText: tl(context, 'edit_screen.hint_your_username'),
                      ),
                      keyboardType: TextInputType.emailAddress,
                      initialValue: _password == null ? '' : _password.username,
                      onSaved: (newValue) => data['username'] = newValue,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: tl(context, 'general.password'),
                        hintText: tl(context, 'edit_screen.hint_your_password'),
                        suffixIcon: IconButton(
                          onPressed: () {
                            pwTextController.text = Password.randomPassword(
                              Provider.of<SettingsProvider>(
                                context,
                                listen: false,
                              ).passwordStrength,
                            );
                          },
                          icon: Icon(Icons.autorenew),
                        ),
                      ),
                      controller: pwTextController,
                      keyboardType: TextInputType.visiblePassword,
                      //initialValue: _password == null ? '' : _password.password,
                      validator: (value) => value.length < 1
                          ? tl(context, 'edit_screen.error_password_filled')
                          : null,
                      onSaved: (newValue) => data['password'] = newValue,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Url',
                        hintText: 'http..',
                      ),
                      keyboardType: TextInputType.url,
                      initialValue: _password == null ? '' : _password.url,
                      validator: (value) =>
                          value != '' && !Uri.parse(value).isAbsolute
                              ? tl(context, 'edit_screen.error_url')
                              : null,
                      onSaved: (newValue) => data['url'] = newValue,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: tl(context, 'general.notes'),
                        hintText: tl(context, 'edit_screen.hint_notes'),
                      ),
                      minLines: 5,
                      maxLines: 8,
                      keyboardType: TextInputType.multiline,
                      initialValue: _password == null ? '' : _password.notes,
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
