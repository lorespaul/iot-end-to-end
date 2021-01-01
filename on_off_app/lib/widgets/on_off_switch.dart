import 'package:flutter/material.dart';
import 'package:on_off_app/services/message_service.dart';

class OnOffSwitch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _OnOffSwitchState();
}

class _OnOffSwitchState extends State<OnOffSwitch> {
  static const String _ON = "ON";
  static const String _OFF = "OFF";

  String _status;
  bool _buttonDisabled;

  final MessageService _messageService = MessageService();
  Future<String> _futureMessage;

  @override
  void initState() {
    super.initState();
    _status = _OFF;
    _buttonDisabled = false;
    _futureMessage = _messageService.getMessage();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        DefaultTextStyle(
          style: Theme.of(context).textTheme.headline2,
          textAlign: TextAlign.center,
          child: FutureBuilder<String>(
            future: _futureMessage,
            builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
              if (snapshot.connectionState == ConnectionState.done &&
                  snapshot.data != null) {
                print('response ${snapshot.data}');
                _status = snapshot.data;
              }
              return Text('Device is $_status');
            },
          ),
        ),
        RaisedButton(
          child: Text('Switch'),
          onPressed: () async {
            if (!_buttonDisabled) {
              _buttonDisabled = true;
              final sendStatus = _status == _OFF ? _ON : _OFF;
              print('sending message $sendStatus');
              final sent = await _messageService.sendMessage(sendStatus);
              if (sent) {
                String newStatus;
                int count = 0;
                do {
                  await Future.delayed(Duration(milliseconds: 500));
                  newStatus = await _messageService.getMessage();
                  count++;
                } while (newStatus == _status && count < 10);
                setState(() {
                  if (newStatus != _status) {
                    _futureMessage = Future.value(newStatus);
                  } else {
                    print('bad response');
                  }
                  _buttonDisabled = false;
                });
              } else {
                print('message not sent');
              }
            }
          },
        ),
      ],
    );
  }
}
