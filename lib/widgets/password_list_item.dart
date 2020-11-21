import 'package:autofill_service/autofill_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../helper/utility_actions.dart';

import '../screens/password_edit_screen.dart';
import '../provider/password.dart';
import '../provider/passwords_provider.dart';
import '../provider/favicon_provider.dart';
import '../provider/search_history_provider.dart';
import './password_detail_bottom_modal.dart';

class PasswordListItem extends StatelessWidget {
  final Password _password;
  final bool autoFillMode;
  final Function deletePassword;
  final int level;
  final String searchQuery;

  const PasswordListItem(this._password,
      {this.autoFillMode = false,
      this.deletePassword,
      this.level = 0,
      this.searchQuery = ''})
      : assert(
          _password != null,
          'A non-null Password must be provided to a PasswordListItem widget.',
        );

  void _onListTileTap(BuildContext context) async {
    if (autoFillMode) {
      final metadata = await AutofillService().getAutofillMetadata();
      var searchKey = '';
      if (metadata.webDomains.isNotEmpty)
        searchKey = metadata.webDomains.first.domain;
      if (searchKey.isEmpty) {
        if (metadata.packageNames.isNotEmpty) {
          searchKey = metadata.packageNames.first;
        }
      }
      Provider.of<SearchHistoryProvider>(
        context,
        listen: false,
      ).setAutofillHistory(searchKey, searchQuery);
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
            child: PasswordDetailBottomModal(_password, deletePassword),
            behavior: HitTestBehavior.opaque,
          );
        },
      );
    }
  }

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
            Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                SizedBox(
                  width: 15.0 * this.level,
                  child: Container(
                    color: Colors.green,
                  ),
                ),
                Expanded(
                  child: ListTile(
                    title: Text(password.label),
                    subtitle: Text(password.username +
                        (autoFillMode && password.url.isNotEmpty
                            ? '\n${password.url}'
                            : '')),
                    onTap: () => _onListTileTap(context),
                    onLongPress: isLocal || autoFillMode
                        ? null
                        : () => Navigator.of(context).pushNamed(
                              PasswordEditScreen.routeName,
                              arguments: {'password': password},
                            ),
                    leading: ChangeNotifierProvider(
                      create: (context) => FaviconProvider(password),
                      builder: (context, child) => Consumer<FaviconProvider>(
                        child: Icon(
                          Icons.lock_outline_rounded,
                          color: Theme.of(context).accentColor,
                        ),
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
                    trailing: autoFillMode
                        ? null
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                color: Theme.of(context).accentColor,
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
              ],
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
