import 'dart:convert';
import 'package:pinenacl/ed25519.dart';
import 'package:http/http.dart' as http;
import 'dart:async';
import 'account_client.dart';
import 'utils.dart';

class RestClient {
  var uri = testUrl;
  final hex = HexCoder.instance;
  RestClient({endpoint = testUrl}) {
    uri = endpoint;
  }

  account(String accountAddress) async {
    var url = "$uri/accounts/$accountAddress";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }

    return jsonDecode(response.body);
  }

  accountResources(String accountAddress) async {
    var url = "$uri/accounts/$accountAddress/resources";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }

    return jsonDecode(response.body);
  }

  accountSentEvents(String accountAddress) async {
    var url =
        "$uri/accounts/$accountAddress/events/0x1::TestCoin::TransferEvents/sent_events";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }

    return jsonDecode(response.body);
  }

  accountReceivedEvents(String accountAddress) async {
    var url =
        "$uri/accounts/$accountAddress/events/0x1::TestCoin::TransferEvents/received_events";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }

    return jsonDecode(response.body);
  }

  generateTransaction(String sender, Map payload) async {
    var acc = await account(sender);
    var seqNum = acc["sequence_number"];
    return {
      "sender": "0x$sender",
      "sequence_number": seqNum.toString(),
      "max_gas_amount": "4000",
      "gas_unit_price": "1",
      "gas_currency_code": "XUS",
      "expiration_timestamp_secs":
          (DateTime.now().millisecondsSinceEpoch / 1000 + 600)
              .toInt()
              .toString(),
      "payload": payload,
    };
  }

  signTransaction(Account accountFrom, Map txnRequest) async {
    var url = "$uri/transactions/signing_message";
    JsonEncoder jsonEncoder = JsonEncoder();
    final response = await http.post(Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncoder.convert(txnRequest));
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }
    var result = jsonDecode(response.body);
    var toSign = hex.decode(result['message'].substring(2));
    final signature = accountFrom.signingKey.sign(toSign);
    final signatureHex = hex.encode(signature).substring(0, 128);
    txnRequest["signature"] = {
      "type": "ed25519_signature",
      "public_key": '0x${accountFrom.pubKey()}',
      "signature": '0x$signatureHex',
    };
    return txnRequest;
  }

  submitTransaction(Account accountFrom, Map txnRequest) async {
    var url = "$uri/transactions";
    JsonEncoder jsonEncoder = JsonEncoder();
    final response = await http.post(Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncoder.convert(txnRequest));
    if (response.statusCode != 202) {
      throw Exception(jsonDecode(response.body));
    }
    return jsonDecode(response.body);
  }

  transactionPending(String txnHash) async {
    var url = "$uri/transactions/$txnHash";
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 404) {
      return true;
    }
    if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    }
    return jsonDecode(response.body)['type'] == "pending_transaction";
  }

  waitForTransaction(String txnHash) async {
    var count = 0;
    while (await transactionPending(txnHash)) {
      assert(count < 10);
      await Future.delayed(Duration(seconds: 1));
      count += 1;
      if (count >= 10) {
        throw Exception('Waiting for transaction $txnHash timed out!');
      }
    }
  }

  accountBalance(String accountAddress) async {
    final resources = await accountResources(accountAddress);
    for (final resource in resources) {
      if (resource["type"] == "0x1::Coin::CoinStore<0x1::TestCoin::TestCoin>") {
        return int.parse(resource["data"]["coin"]["value"]);
      }
    }
    return null;
  }

  transfer(Account accountFrom, String recipient, int amount) async {
    final payload = {
      "type": "script_function_payload",
      "function": "0x1::Coin::transfer",
      "type_arguments": ["0x1::TestCoin::TestCoin"],
      "arguments": [
        '0x$recipient',
        amount.toString(),
      ]
    };
    final txnRequest =
        await generateTransaction(accountFrom.address(), payload);
    final signedTxn = await signTransaction(accountFrom, txnRequest);
    final res = await submitTransaction(accountFrom, signedTxn);
    return res["hash"].toString();
  }

  tableItem(
      String handle, String keyType, String valueType, dynamic key) async {
    var url = "$uri/tables/$handle/item";
    JsonEncoder jsonEncoder = JsonEncoder();
    final response = await http.post(Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncoder.convert(
            {"key_type": keyType, "value_type": valueType, "key": key}));

    if (response.statusCode == 404) {
      return null;
    } else if (response.statusCode != 200) {
      assert(response.statusCode == 200, response.body);
    } else {
      return jsonDecode(response.body);
    }
  }

  getEventStream(String address, String eventHandleStruct, String fieldName) async {
        var url =
        "$uri/accounts/$address/events/$eventHandleStruct/$fieldName";
        final response = await http.get(Uri.parse(url));
        if (response.statusCode == 404) {
          return [];
        }
        return jsonDecode(response.body);
    }
}
