import 'package:autofill_service/autofill_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../helper/i18n_helper.dart';
import '../provider/passwords_provider.dart';
import '../provider/search_history_provider.dart';
import '../widgets/app_drawer.dart';
import '../widgets/password_list_item.dart';
import './abstract_passwords_state.dart';

class PasswordsOverviewScreen extends StatefulWidget {
  static const routeName = 'passwords-overview';

  @override
  _PasswordsOverviewScreenState createState() =>
      _PasswordsOverviewScreenState();
}

class _PasswordsOverviewScreenState
    extends AbstractPasswordsState<PasswordsOverviewScreen> {
  final _searchTextController = TextEditingController();
  var _first = true;

  void _searchPassword(String searchString) {
    final newPasswords = passwords =
        Provider.of<PasswordsProvider>(context, listen: false)
            .searchPasswords(searchString);
    setState(() {
      passwords = newPasswords;
    });
  }

  @override
  void filter() async {
    super.filter();
    // Try loading search text from argument or autofill data
    if (_first) {
      _first = false;
      if (autofillMode) {
        final metadata = await AutofillService().getAutofillMetadata();
        var searchKey = '';
        if (metadata.webDomains.isNotEmpty)
          searchKey = metadata.webDomains.first.domain;
        if (searchKey.isEmpty) {
          if (metadata.packageNames.isNotEmpty) {
            searchKey = metadata.packageNames.first;
          }
        }
        final shp = Provider.of<SearchHistoryProvider>(
          context,
          listen: false,
        );
        await shp.loadFromStorage();
        _searchTextController.text =
            shp.getSearchSuggestionFromAutofillKey(searchKey);
      } else {
        //_searchTextController.text = 'test';
      }
    }
    _searchPassword(_searchTextController.text);
  }

  @override
  Widget build(BuildContext context) {
    final isLocal = Provider.of<PasswordsProvider>(
      context,
      listen: false,
    ).isLocal;
    return WillPopScope(
      onWillPop: showExitPopup,
      child: Scaffold(
        appBar: AppBar(
          title: Text(tl(context, 'general.all_passwords')),
          actions: [
            if (!autofillMode)
              IconButton(
                icon: Icon(Icons.refresh),
                onPressed: () => refreshPasswords(),
              ),
          ],
        ),
        drawer: autofillMode ? null : const AppDrawer(),
        floatingActionButton: isLocal || autofillMode
            ? null
            : FloatingActionButton(
                backgroundColor: Theme.of(context).accentColor,
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
                      child: Scrollbar(
                        child: ListView.builder(
                          cacheExtent: 10000,
                          itemCount: passwords.length,
                          itemBuilder: (ctx, i) => PasswordListItem(
                            passwords[i],
                            deletePassword: deletePassword,
                            autoFillMode: autofillMode,
                            searchQuery: _searchTextController.text,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
