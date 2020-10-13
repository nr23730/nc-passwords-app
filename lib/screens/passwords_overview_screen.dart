import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../provider/passwords_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/password_list_item.dart';
import './abstract_passwords_state.dart';

class PasswordsOverviewScreen extends StatefulWidget {
  static const routeName = '/passwords-overview';

  @override
  _PasswordsOverviewScreenState createState() =>
      _PasswordsOverviewScreenState();
}

class _PasswordsOverviewScreenState
    extends AbstractPasswordsState<PasswordsOverviewScreen> {
  final _searchTextController = TextEditingController();

  void _searchPassword(String searchString) {
    final newPasswords = passwords =
        Provider.of<PasswordsProvider>(context, listen: false)
            .searchPasswords(searchString);
    setState(() {
      passwords = newPasswords;
    });
  }

  @override
  void filter() {
    super.filter();
    _searchPassword(_searchTextController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;
    return Scaffold(
      appBar: AppBar(
        title: Text(tl(context, 'general.all_passwords')),
        actions: [
          IconButton(
            icon: Icon(Icons.refresh),
            onPressed: () => refreshPasswords(),
          ),
        ],
      ),
      drawer: const AppDrawer(),
      floatingActionButton: isLocal
          ? null
          : FloatingActionButton(
              onPressed: createPassword,
              child: Icon(Icons.add),
            ),
      body: passwords == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : Column(
              children: [
                Padding(
                  padding: EdgeInsets.all(5),
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(5),
                      child: TextField(
                        autocorrect: false,
                        decoration: InputDecoration(
                          labelText: tl(context, 'general.search'),
                          hintText: tl(context, 'general.search_hint'),
                          suffixIcon: IconButton(
                            onPressed: () {
                              _searchTextController.clear();
                              refreshPasswords(false);
                            },
                            icon: Icon(Icons.clear),
                          ),
                        ),
                        maxLines: 1,
                        controller: _searchTextController,
                        keyboardType: TextInputType.text,
                        onChanged: _searchPassword,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: RefreshIndicator(
                    onRefresh: () => refreshPasswords(),
                    child: Padding(
                      padding: const EdgeInsets.all(5.0),
                      child: Scrollbar(
                        child: ListView.builder(
                          itemCount: passwords.length,
                          itemBuilder: (ctx, i) => PasswordListItem(
                            passwords[i],
                            deletePassword,
                            autofillMode,
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
