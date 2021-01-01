import 'package:flutter/material.dart';
import 'package:on_off_app/services/message_service.dart';

class OnOffSwitch extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _OnOffSwitchState();
}

class _OnOffSwitchState extends State<OnOffSwitch> {
  final MessageService _messageService = MessageService();
  Future<String> _futureMessage;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String>(
      future: _futureMessage,
      builder: (BuildContext context, AsyncSnapshot<String> snapshot) {
        return Center();
      },
    );
  }
}
