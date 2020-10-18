import 'package:autofill_service/autofill_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/utility_actions.dart';
import '../screens/password_edit_screen.dart';
import '../provider/password.dart';
import './password_detail_bottom_modal.dart';

class PasswordListItem extends StatelessWidget {
  final Password _password;
  final Function _deletePassword;
  final bool _autoFillMode;

  void _onListTileTap(BuildContext context) async {
    if (_autoFillMode) {
      await AutofillService().resultWithDataset(
        label: _password.label,
        username: _password.username,
        password: _password.password,
      );
    } else {
      await showModalBottomSheet(
        context: context,
        builder: (ctx) {
          return GestureDetector(
            onTap: () {},
            child: PasswordDetailBottomModal(_password, _deletePassword),
            behavior: HitTestBehavior.opaque,
          );
        },
      );
    }
  }

  const PasswordListItem(
      this._password, this._deletePassword, this._autoFillMode);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _password,
      builder: (context, child) => Consumer<Password>(
        builder: (context, password, child) => Column(
          children: [
            Container(
              child: ListTile(
                title: Text(password.label),
                subtitle: Text(password.username +
                    (_autoFillMode && password.url.isNotEmpty
                        ? '\n${password.url}'
                        : '')),
                onTap: () => _onListTileTap(context),
                onLongPress: _autoFillMode
                    ? null
                    : () => Navigator.of(context).pushNamed(
                          PasswordEditScreen.routeName,
                          arguments: {'password': password},
                        ),
                //IconButton(
                //  icon: Icon(Icons.content_copy),
                //   onPressed: () {
                //  copyToClipboard(context,_password,  SelectType.Username);
                //   },
                //  ),
                //  CircleAvatar(
                //   backgroundImage: _password.isFaviconAvailable
                //    ? NetworkImage(_password.favicon.url)
                //   : null,
                // ),
                trailing: _autoFillMode
                    ? null
                    : IconButton(
                        icon: Icon(Icons.content_copy),
                        onPressed: () {
                          copyToClipboard(
                              context, password, SelectType.Password);
                        },
                      ),
              ),
            ),
            Divider(),
          ],
        ),
      ),
    );
  }
}
