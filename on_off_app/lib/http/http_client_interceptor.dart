import 'package:http_interceptor/http_interceptor.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_guid/flutter_guid.dart';

class HttpClientInterceptor implements InterceptorContract {
  final String keyClientId = 'CLIENT_ID';

  String authVal;
  String clientId;

  HttpClientInterceptor() {
    authVal = DotEnv().env['AUTH_VAL'];
  }

  @override
  Future<RequestData> interceptRequest({RequestData data}) async {
    final client = await getClientId();
    try {
      data.headers.addAll(
        {
          'Authorization': authVal,
          'Client-Id': client,
        },
      );
    } catch (e) {
      print(e);
    }
    return data;
  }

  Future<String> getClientId() async {
    if (clientId == null) {
      final prefs = await SharedPreferences.getInstance();
      clientId = prefs.getString(keyClientId);
      if (clientId == null) {
        clientId = Guid.newGuid.toString();
        prefs.setString(keyClientId, clientId);
      }
    }
    return Future.value(clientId);
  }

  @override
  Future<ResponseData> interceptResponse({ResponseData data}) async => data;
}
