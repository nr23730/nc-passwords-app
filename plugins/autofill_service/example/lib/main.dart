import 'dart:async';

import 'package:autofill_service/autofill_service.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';

final _logger = Logger('main');

void main() {
  Logger.root.level = Level.ALL;
  _logger.info('Initialized logger.');
  runApp(MyApp());
}

class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  bool _hasEnabledAutofillServices = false;

  @override
  void initState() {
    super.initState();
    _updateStatus();
  }

  // Platform messages are asynchronous, so we initialize in an async method.
  Future<void> _updateStatus() async {
    _hasEnabledAutofillServices =
        await AutofillService().hasEnabledAutofillServices;
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    _logger.info(
        'Building AppState. defaultRouteName:${WidgetsBinding.instance!.window.defaultRouteName}');
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Plugin example app'),
        ),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              Text(
                  'hasEnabledAutofillServices: $_hasEnabledAutofillServices\n'),
              RaisedButton(
                child: const Text('requestSetAutofillService'),
                onPressed: () async {
                  _logger.fine('Starting request.');
                  final response =
                      await AutofillService().requestSetAutofillService();
                  _logger.fine('request finished $response');
                  await _updateStatus();
                },
              ),
              RaisedButton(
                child: const Text('finish'),
                onPressed: () async {
                  _logger.fine('Starting request.');
                  final response = await AutofillService().resultWithDataset(
                    label: 'testl',
                    password: 'test',
                    username: 'test2',
                  );
                  _logger.fine('resultWithDataset $response');
                  await _updateStatus();
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
