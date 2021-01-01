import 'package:http/http.dart';
import 'package:on_off_app/http/http_client.dart';

class MessageService {
  final Client client = HttpClient.getClient();

  final String host = "http://flask-message-broker.herokuapp.com/api";
  final String subscribe = "subscribe";
  final String topic = "home-light";
  final String topicResponse = "home-light-response";
  final String publish = "publish";
  final String message = "message";

  Future<String> getMessage(bool pool) async {
    var endpoint = "$host/$subscribe/$topicResponse";
    if (pool) {
      endpoint += "?poll=true";
    }
    var result = await client.get(endpoint);
    return result.body;
  }

  Future<bool> sendMessage(String m) async {
    var endpoint = "$host/$publish/$topic/$message/$m";
    var result = await client.get(endpoint);
    return result.statusCode == 201;
  }
}
