import 'package:autofill_service/autofill_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../helper/utility_actions.dart';

import '../screens/password_edit_screen.dart';
import '../provider/password.dart';
import '../provider/passwords_provider.dart';
import '../provider/favicon_provider.dart';
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
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;
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
                onLongPress: isLocal || _autoFillMode
                    ? null
                    : () => Navigator.of(context).pushNamed(
                          PasswordEditScreen.routeName,
                          arguments: {'password': password},
                        ),
                leading: ChangeNotifierProvider(
                  create: (context) => FaviconProvider(password),
                  builder: (context, child) => Consumer<FaviconProvider>(
                    child: Icon(Icons.lock_outline_rounded),
                    builder: (context, faviconProvider, child) => SizedBox(
                      width: 30,
                      height: 30,
                      child: FittedBox(
                        fit: BoxFit.fill,
                        alignment: Alignment.center,
                        child: password.cachedFavIconUrl.isEmpty
                            ? child
                            : CachedNetworkImage(
                                fadeInDuration: Duration(milliseconds: 0),
                                imageUrl: password.cachedFavIconUrl,
                                errorWidget: (context, url, error) => child,
                              ),
                      ),
                    ),
                  ),
                ),
                trailing: _autoFillMode
                    ? null
                    : Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          IconButton(
                            icon: Icon(Icons.supervisor_account_sharp),
                            onPressed: () {
                              copyToClipboard(
                                  context, password, SelectType.Username);
                            },
                          ),
                          IconButton(
                            icon: Icon(
                              Icons.vpn_key_sharp,
                              color: password.statusCodeColor,
                            ),
                            onPressed: () {
                              copyToClipboard(
                                  context, password, SelectType.Password);
                            },
                          ),
                        ],
                      ),
              ),
            ),
            Divider(
              color: Theme.of(context).accentColor.withAlpha(50),
            ),
          ],
        ),
      ),
    );
  }
}
