import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../provider/password.dart';
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
        title: Text(_password == null ? 'Create Password' : 'Edit Password'),
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
                        labelText: 'Name',
                        hintText: 'The label of the password',
                      ),
                      keyboardType: TextInputType.text,
                      initialValue: _password == null ? '' : _password.label,
                      validator: (value) => value.length < 1
                          ? 'The name has to be filled.'
                          : null,
                      onSaved: (newValue) => data['label'] = newValue,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'User',
                        hintText: 'Your Username',
                      ),
                      keyboardType: TextInputType.emailAddress,
                      initialValue: _password == null ? '' : _password.username,
                      onSaved: (newValue) => data['username'] = newValue,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Password',
                        hintText: 'Your password',
                        suffixIcon: IconButton(
                          onPressed: () {
                            pwTextController.text = Password.randomPassword(15);
                          },
                          icon: Icon(Icons.autorenew),
                        ),
                      ),
                      controller: pwTextController,
                      keyboardType: TextInputType.visiblePassword,
                      //initialValue: _password == null ? '' : _password.password,
                      validator: (value) => value.length < 1
                          ? 'The password has to be filled.'
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
                              ? 'Url invalid!'
                              : null,
                      onSaved: (newValue) => data['url'] = newValue,
                    ),
                    TextFormField(
                      decoration: InputDecoration(
                        labelText: 'Notes',
                        hintText: 'Some notes..',
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
