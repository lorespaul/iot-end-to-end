import 'package:flutter/material.dart';
import 'package:on_off_app/services/message_service.dart';
import 'package:flutter_spinkit/flutter_spinkit.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

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
                    String statusTran;
                    switch (_status) {
                      case _ON:
                        statusTran = AppLocalizations.of(context).isOn;
                        break;
                      case _OFF:
                      default:
                        statusTran = AppLocalizations.of(context).isOff;
                        break;
                    }
                    return Text(
                      '${AppLocalizations.of(context).deviceStatusIs} $statusTran',
                      style: TextStyle(color: Colors.black87),
                    );
                  },
                ),
              ),
              Container(
                height: 100.0,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  RaisedButton(
                    padding: const EdgeInsets.fromLTRB(40.0, 20.0, 40.0, 20.0),
                    textColor: Colors.white,
                    color: Colors.blue,
                    child: Text(
                      AppLocalizations.of(context).goSwitch,
                      style: TextStyle(fontSize: 20),
                    ),
                    onPressed: _switch,
                  ),
                  Container(
                    width: 20.0,
                  ),
                  RaisedButton(
                    padding: const EdgeInsets.fromLTRB(40.0, 20.0, 40.0, 20.0),
                    textColor: Colors.white,
                    color: Colors.blue,
                    child: Text(
                      AppLocalizations.of(context).goUpdate,
                      style: TextStyle(fontSize: 20),
                    ),
                    onPressed: _update,
                  ),
                ],
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

  void _update() async {
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    if (!_isLoading) {
      setState(() {
        _isLoading = true;
      });
      _status = await _messageService.getMessage();
      setState(() {
        _futureMessage = Future.value(_status);
        _isLoading = false;
        _isSwitchDisabled = false;
      });
    }
  }

  void _switch({sendMessage = true}) async {
    if (!_isLoading && !_isSwitchDisabled) {
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
        } while (newStatus == _status && count < 20);

        final updateFuture = newStatus != _status;

        setState(() {
          if (updateFuture) {
            _futureMessage = Future.value(newStatus);
            _isSwitchDisabled = false;
          }
          _isLoading = false;
        });

        if (!updateFuture) {
          _showErrorMessage(AppLocalizations.of(context).errorUpdate);
        }
      } else {
        setState(() {
          _isLoading = false;
        });
        _showErrorMessage(
          AppLocalizations.of(context).errorRetry,
          sendMessage: true,
        );
      }
    }
  }

  void _showErrorMessage(String message, {sendMessage = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(minutes: 5),
        action: SnackBarAction(
          label: AppLocalizations.of(context).goUpdate,
          onPressed: () {
            if (sendMessage) {
              ScaffoldMessenger.of(context).hideCurrentSnackBar();
              _isSwitchDisabled = false;
              _switch(sendMessage: sendMessage);
            } else {
              _update();
            }
          },
        ),
      ),
    );
  }
}
