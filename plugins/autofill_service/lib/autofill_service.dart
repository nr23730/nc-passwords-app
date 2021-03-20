import 'dart:async';
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:logging/logging.dart';

final _logger = Logger('autofill_service');

enum AutofillServiceStatus {
  unsupported,
  disabled,
  enabled,
}

class AutofillPreferences {
  AutofillPreferences({this.enableDebug = false});

  factory AutofillPreferences.fromJson(Map<dynamic, dynamic> json) =>
      AutofillPreferences(enableDebug: json['enableDebug'] as bool);

  final bool enableDebug;

  Map<String, dynamic> toJson() => <String, dynamic>{
        'enableDebug': enableDebug,
      };
}

class AutofillService {
  factory AutofillService() => _instance;

  AutofillService._();

  static const MethodChannel _channel =
      MethodChannel('de.jbservices/autofill_service');

  static final _instance = AutofillService._();

  Future<bool> get hasAutofillServicesSupport async {
    if (!Platform.isAndroid) {
      return false;
    }
    final r = await _channel.invokeMethod<bool>('hasAutofillServicesSupport');
    return r != null && r;
  }

  Future<bool> get hasEnabledAutofillServices async {
    final r = await _channel.invokeMethod<bool>('hasAutofillServicesSupport');
    return await hasAutofillServicesSupport && r != null && r;
  }

  Future<AutofillMetadata> getAutofillMetadata() async {
    final result = await _channel
        .invokeMethod<Map<dynamic, dynamic>>('getAutofillMetadata');
    _logger.fine(
        'Got result for getAutofillMetadata $result (${result.runtimeType})');
    if (result == null) {
      return null;
    }
    return AutofillMetadata.fromJson(result);
  }

  Future<AutofillServiceStatus> status() async {
    if (!Platform.isAndroid) {
      return AutofillServiceStatus.unsupported;
    }
    final enabled =
        await _channel.invokeMethod<bool>('hasEnabledAutofillServices');
    if (enabled == null) {
      return AutofillServiceStatus.unsupported;
    } else if (enabled) {
      return AutofillServiceStatus.enabled;
    } else {
      return AutofillServiceStatus.disabled;
    }
  }

  Future<bool> requestSetAutofillService() async {
    final r = await _channel.invokeMethod<bool>('requestSetAutofillService');
    return r != null && r;
  }

  Future<bool> resultWithDataset(
      {String label, String username, String password}) async {
    final r = await _channel.invokeMethod<bool>(
        'resultWithDataset', <String, dynamic>{
      'label': label,
      'username': username,
      'password': password
    });
    return r != null && r;
  }

  Future<void> disableAutofillServices() async {
    return await _channel.invokeMethod('disableAutofillServices');
  }

  Future<AutofillPreferences> getPreferences() async {
    final json =
        await _channel.invokeMapMethod<String, dynamic>('getPreferences');
    _logger.fine('Got preferences $json');
    return AutofillPreferences.fromJson(json);
  }

  Future<void> setPreferences(AutofillPreferences preferences) async {
    _logger.fine('set prefs to ${preferences.toJson()}');
    await _channel.invokeMethod<void>(
        'setPreferences', {'preferences': preferences.toJson()});
  }
}

class AutofillMetadata {
  AutofillMetadata({this.packageNames, this.webDomains});

  factory AutofillMetadata.fromJson(Map<dynamic, dynamic> json) =>
      AutofillMetadata(
        packageNames: (json['packageNames'] as Iterable)
            .map((dynamic e) => e as String)
            .toSet(),
        webDomains: (json['webDomains'] as Iterable)
            .map((dynamic e) =>
                AutofillWebDomain.fromJson(e as Map<dynamic, dynamic>))
            .toSet(),
      );

  final Set<String> packageNames;
  final Set<AutofillWebDomain> webDomains;

  @override
  String toString() => toJson().toString();

  Map<String, Object> toJson() => {
        'packageNames': packageNames,
        'webDomains': webDomains.map((e) => e.toJson()),
      };
}

class AutofillWebDomain {
  AutofillWebDomain({this.scheme, this.domain});

  factory AutofillWebDomain.fromJson(Map<dynamic, dynamic> json) =>
      AutofillWebDomain(
        scheme: json['scheme'] as String,
        domain: json['domain'] as String,
      );

  final String scheme;
  final String domain;

  @override
  String toString() => toJson().toString();

  Map<String, Object> toJson() => {
        'scheme': scheme,
        'domain': domain,
      };
}
