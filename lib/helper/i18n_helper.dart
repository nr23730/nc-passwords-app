import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

extension TranslateExtension on String {
  String tl(final BuildContext context,
          {final String fallbackKey,
          final Map<String, String> translationParams}) =>
      FlutterI18n.translate(
        context,
        this,
        fallbackKey: fallbackKey,
        translationParams: translationParams,
      );
}
