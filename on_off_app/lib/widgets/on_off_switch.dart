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
  bool _isSwitchDisabled;

  final MessageService _messageService = MessageService();
  Future<String> _futureMessage;

  @override
  void initState() {
    super.initState();
    _status = _OFF;
    _isLoading = false;
    _isSwitchDisabled = false;
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
                    return Text(
                      'Device is $_status',
                      style: TextStyle(color: Colors.black87),
                    );
                  },
                ),
              ),
              Container(
                height: 100.0,
              ),
              RaisedButton(
                padding: const EdgeInsets.fromLTRB(40.0, 20.0, 40.0, 20.0),
                textColor: Colors.white,
                color: Colors.blue,
                child: Text(
                  'Switch',
                  style: TextStyle(fontSize: 20),
                ),
                onPressed: _switch,
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
              color: Colors.blue,
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

  void _switch({sendMessage = true}) async {
    if (!_isLoading && (!_isSwitchDisabled || !sendMessage)) {
      setState(() {
        _isLoading = true;
        _isSwitchDisabled = true;
      });
      final sendStatus = _status == _OFF ? _ON : _OFF;
      print('sending message $sendStatus');

      final sent =
          sendMessage ? await _messageService.sendMessage(sendStatus) : true;

      if (sent) {
        String newStatus;
        int count = 0;
        do {
          await Future.delayed(Duration(milliseconds: 500));
          newStatus = await _messageService.getMessage();
          count++;
        } while (newStatus == _status && count < 1);

        final updateFuture = newStatus != _status;

        setState(() {
          if (updateFuture) {
            _futureMessage = Future.value(newStatus);
            _isSwitchDisabled = false;
          }
          _isLoading = false;
        });

        if (!updateFuture) {
          _showErrorMessage();
        }
      } else {
        _showErrorMessage();
      }
    }
  }

  void _showErrorMessage() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text(
          'Can\'t get device status. Click here to retry.',
        ),
        duration: const Duration(minutes: 5),
        action: SnackBarAction(
          label: 'UPDATE',
          onPressed: () {
            ScaffoldMessenger.of(context).hideCurrentSnackBar();
            _switch(sendMessage: false);
          },
        ),
      ),
    );
  }
}
