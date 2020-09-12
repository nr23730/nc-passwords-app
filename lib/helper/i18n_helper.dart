import 'package:flutter/widgets.dart';
import 'package:flutter_i18n/flutter_i18n.dart';

String tl(final BuildContext context, final String key,
        {final String fallbackKey,
        final Map<String, String> translationParams}) =>
    FlutterI18n.translate(
      context,
      key,
      fallbackKey: fallbackKey,
      translationParams: translationParams,
    );
