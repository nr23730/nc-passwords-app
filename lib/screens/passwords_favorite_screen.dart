import 'package:flutter/material.dart';

import '../helper/i18n_helper.dart';
import '../widgets/app_drawer.dart';
import '../widgets/password_list_item.dart';
import '../screens/abstract_passwords_state.dart';

class PasswordsFavoriteScreen extends StatefulWidget {
  static const routeName = '/passwords-favorite';

  @override
  _PasswordsFavoriteScreenState createState() =>
      _PasswordsFavoriteScreenState();
}

class _PasswordsFavoriteScreenState
    extends AbstractPasswordsState<PasswordsFavoriteScreen> {
  void _filterFavorites() {
    if (passwords != null) {
      final newPasswords = passwords.where((p) => p.favorite).toList();
      setState(() {
        passwords = newPasswords;
      });
    }
  }

  @override
  void filter() {
    super.filter();
    _filterFavorites();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: FittedBox(
          child: Text(tl(context, 'general.favorites')),
        ),
      ),
      drawer: const AppDrawer(),
      body: passwords == null
          ? Center(
              child: CircularProgressIndicator(),
            )
          : RefreshIndicator(
              onRefresh: () => refreshPasswords(),
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
    );
  }
}
