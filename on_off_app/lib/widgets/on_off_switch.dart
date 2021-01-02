import 'package:flutter/material.dart';
import 'package:on_off_app/services/message_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';

class OnOffSwitch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _OnOffSwitchState();
}

class _OnOffSwitchState extends State<OnOffSwitch> {
  static const String _ON = "ON";
  static const String _OFF = "OFF";

  String _status;
  bool _isLoading;

  final MessageService _messageService = MessageService();
  Future<String> _futureMessage;

  @override
  void initState() {
    super.initState();
    _status = _OFF;
    _isLoading = false;
    _futureMessage = _messageService.getMessage(pool: true);
  }

  @override
  Widget build(BuildContext context) {
    var children = <Widget>[
      Positioned.fill(
        top: 0,
        left: 0,
        right: 0,
        bottom: 0,
        child: Container(
          color: Colors.black26,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: <Widget>[
              DefaultTextStyle(
                style: Theme.of(context).textTheme.headline3,
                textAlign: TextAlign.center,
                child: FutureBuilder<String>(
                  future: _futureMessage,
                  builder:
                      (BuildContext context, AsyncSnapshot<String> snapshot) {
                    if (snapshot.connectionState == ConnectionState.done &&
                        snapshot.data != null) {
                      print('response ${snapshot.data}');
                      _status = snapshot.data;
                    }
                    return Text('Device is $_status');
                  },
                ),
              ),
              Container(
                height: 100.0,
              ),
              RaisedButton(
                child: Text('Switch'),
                onPressed: () async {
                  if (!_isLoading) {
                    setState(() {
                      _isLoading = true;
                    });
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
                      } while (newStatus == _status && count < 20);
                      setState(() {
                        if (newStatus != _status) {
                          _futureMessage = Future.value(newStatus);
                        } else {
                          print('bad response');
                        }
                        _isLoading = false;
                      });
                    } else {
                      print('message not sent');
                    }
                  }
                },
              ),
            ],
          ),
        ),
      ),
    ];

    if (_isLoading) {
      children.add(
        Positioned.fill(
          top: 0,
          left: 0,
          right: 0,
          bottom: 0,
          child: Container(
            color: Colors.black.withOpacity(0.7),
            child: SpinKitRotatingCircle(
              color: Colors.white,
              size: 50.0,
            ),
          ),
        ),
      );
    }

    return Stack(
      children: children,
    );
  }
}
