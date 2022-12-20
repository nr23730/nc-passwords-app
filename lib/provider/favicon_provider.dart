import 'dart:core';
import 'package:favicon/favicon.dart';
import 'package:flutter/foundation.dart';

import './password.dart';

class FaviconProvider with ChangeNotifier {
  Password _password;

  FaviconProvider(this._password) {
    assert(this._password != null);
    _getFavURL();
  }

  Future<void> _getFavURL() async {
    if (_password.url.isNotEmpty) {
      var url = _password.url.toLowerCase();
      // only fetch if there are differences detected
      if (_password.cachedFavIconUrl.isNotEmpty) {
        final uri = Uri.parse(url);
        if (url.contains(uri.host)) {
          return;
        }
      }
      try {
        var faviconUrl = '';
        final faviconUrlWithSizeInfo = await FaviconFinder.getAll(url);
        if (faviconUrlWithSizeInfo != null) {
          // No svg supported by CachedNetworkImage
          faviconUrl = faviconUrlWithSizeInfo
              .firstWhere((e) => !e.url.endsWith('.svg'))
              .url;
        }
        _password.cachedFavIconUrl = faviconUrl;
        notifyListeners();
      } catch (e) {
        // nothing
      }
    }
  }
}
