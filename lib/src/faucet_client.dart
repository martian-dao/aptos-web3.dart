import 'dart:convert';
import 'package:http/http.dart' as http;
import 'rest_client.dart';
import 'utils.dart';


class FaucetClient {
  var uri = faucetUrl;
  static RestClient _restClient = RestClient();
  FaucetClient({endpoint = faucetUrl}) {
    uri = endpoint;
  }
  FaucetClient.fromRestClient(RestClient restClient, {endpoint = faucetUrl}) {
    uri = endpoint;
    _restClient = restClient;
  }
  fundAccount(String authKey, int amount) async {
    var url = "$uri/mint?amount=$amount&auth_key=$authKey";
    final response = await http.post(Uri.parse(url));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }

    final tnxHashes = jsonDecode(response.body);
    for (final tnxHash in tnxHashes) {
      await _restClient.waitForTransaction(tnxHash);
    }
  }
}