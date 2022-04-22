import 'dart:convert';
import 'package:http/http.dart' as http;
import 'rest_client.dart';
import 'utils.dart';


class FaucetClient {
  var uri = faucetUrl;
  RestClient restClient = RestClient();
  FaucetClient({endpoint = faucetUrl}) {
    uri = endpoint;
  }
  fundAccount(String authKey, int amount) async {
    var url = "$uri/mint?amount=$amount&auth_key=$authKey";
    final response = await http.post(Uri.parse(url));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }

    final tnxHashes = jsonDecode(response.body);
    for (final tnxHash in tnxHashes) {
      await restClient.waitForTransaction(tnxHash);
    }
  }
}