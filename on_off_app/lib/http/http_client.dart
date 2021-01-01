import 'package:on_off_app/http/http_client_interceptor.dart';
import 'package:http/http.dart';
import 'package:http_interceptor/http_client_with_interceptor.dart';

class HttpClient {
  static Client _client;

  static Client getClient() {
    if (_client == null) {
      _client = HttpClientWithInterceptor.build(
          interceptors: [HttpClientInterceptor()]);
    }
    return _client;
  }
}
