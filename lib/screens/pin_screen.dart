import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';

import '../helper/i18n_helper.dart';

class PinScreen extends StatefulWidget {
  static const routeName = 'pin';

  @override
  _PinScreenState createState() => _PinScreenState();
}

class _PinScreenState extends State<PinScreen> {
  String _currentInput = '';

  void _clearInput([String defaultValue = '']) {
    setState(() {
      _currentInput = '';
    });
  }

  void _input(String value) {
    setState(() {
      _currentInput += value;
    });
  }

  void _returnInput() {
    Navigator.of(context).pop(_currentInput);
  }

  var _controller = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(ModalRoute.of(context).settings.arguments as String),
      ),
      body: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.fromLTRB(0, 50, 0, 0),
                width: 170,
                child: TextFormField(
                  controller: _controller,
                  decoration: new InputDecoration(
                    icon: Icon(Icons.vpn_key_sharp),
                    border: InputBorder.none,
                    focusedBorder: InputBorder.none,
                    enabledBorder: InputBorder.none,
                    errorBorder: InputBorder.none,
                    disabledBorder: InputBorder.none,
                    hintText: '----',
                    counterText: '',
                    counterStyle: TextStyle(fontSize: 0),
                  ),
                  enableSuggestions: false,
                  autocorrect: false,
                  showCursor: false,
                  obscureText: true,
                  autofocus: true,
                  textAlign: TextAlign.left,
                  maxLength: 4,
                  textInputAction: TextInputAction.go,
                  keyboardType: TextInputType.number,
                  onChanged: (text) {
                    _currentInput = text;
                    if (text.length >= 4) {
                      _returnInput();
                    }
                  },
                  onFieldSubmitted: (text) {
                    _returnInput();
                  },
                  inputFormatters: <TextInputFormatter>[
                    FilteringTextInputFormatter.digitsOnly
                  ],
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 25,
                  ),
                ),
              )
            ],
          ),
          Spacer(),
          Row(
            children: [
              Container(
                padding: EdgeInsets.all(10),
                child: TextButton(
                  onPressed: () => _controller.clear(),
                  child: Text(
                    'general.clear'.tl(context),
                  ),
                ),
              ),
              Spacer(),
              Container(
                padding: EdgeInsets.all(10),
                child: TextButton(
                  onPressed: () {
                    if (_currentInput.length > 3) {
                      _returnInput();
                    } else {
                      showDialog(
                        context: context,
                        builder: (context) => AlertDialog(
                          title: Text('dialog.error'.tl(context)),
                          content: Text(
                            'general.pin_four_digits'.tl(context),
                            softWrap: true,
                          ),
                        ),
                      );
                    }
                  },
                  child: Text(
                    'general.ok'.tl(context),
                  ),
                ),
              )
            ],
          )
        ],
      ),
    );
  }

  Widget _buildNumberButton(String value) {
    return _buildButton(
      Text(
        value,
        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
      ),
      () => _input(value),
    );
  }

  Widget _buildButton(Widget child, Function f) {
    return OutlineButton(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18.0),
      ),
      padding: EdgeInsets.all(22),
      child: child,
      onPressed: f,
    );
  }
}
