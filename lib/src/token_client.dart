import 'dart:convert';
import 'dart:ffi';
import 'package:hex/hex.dart';
import 'package:martiandao_aptos_web3/src/account_client.dart';
import 'package:martiandao_aptos_web3/src/rest_client.dart';

class TokenClient {
  static RestClient _restClient = RestClient();

  TokenClient();
  TokenClient.fromRestClient(RestClient restClient) {
    _restClient = restClient;
  }

  submitTransactionHelper(Account account, Map payload) async {
    final txnRequest =
        await _restClient.generateTransaction(account.address(), payload);
    final signedTxn = await _restClient.signTransaction(account, txnRequest);
    final res = await _restClient.submitTransaction(account, signedTxn);
    await _restClient.waitForTransaction(res["hash"]);
    return res["hash"];
  }

  createCollection(
      Account account, String name, String description, String uri) async {
    final payload = {
      "type": "script_function_payload",
      "function": "0x1::Token::create_unlimited_collection_script",
      "type_arguments": [],
      "arguments": [
        HEX.encode(utf8.encode(name)),
        HEX.encode(utf8.encode(description)),
        HEX.encode(utf8.encode(uri))
      ]
    };
    return await submitTransactionHelper(account, payload);
  }

  createToken(Account account, String collectionName, String name,
      String description, int supply, String uri) async {
    final payload = {
      "type": "script_function_payload",
      "function": "0x1::Token::create_limited_token_script",
      "type_arguments": [],
      "arguments": [
        HEX.encode(utf8.encode(collectionName)),
        HEX.encode(utf8.encode(name)),
        HEX.encode(utf8.encode(description)),
        true,
        supply.toString(),
        (supply + 1).toString(),
        HEX.encode(utf8.encode(uri))
      ]
    };
    return await submitTransactionHelper(account, payload);
  }

  offerToken(Account account, String receiver, String creator,
      String collectionName, String tokenName, int amount) async {
    final payload = {
      "type": "script_function_payload",
      "function": "0x1::TokenTransfers::offer_script",
      "type_arguments": [],
      "arguments": [
        receiver,
        creator,
        HEX.encode(utf8.encode(collectionName)),
        HEX.encode(utf8.encode(tokenName)),
        amount.toString()
      ]
    };
    return await submitTransactionHelper(account, payload);
  }

  claimToken(Account account, String sender, String creator,
      String collectionName, String tokenName) async {
    final payload = {
      "type": "script_function_payload",
      "function": "0x1::TokenTransfers::claim_script",
      "type_arguments": [],
      "arguments": [
        sender,
        creator,
        HEX.encode(utf8.encode(collectionName)),
        HEX.encode(utf8.encode(tokenName))
      ]
    };
    return await submitTransactionHelper(account, payload);
  }

  cancelTokenOffer(Account account, String receiver, String creator,
      int tokenCollectionNum) async {
    final payload = {
      "type": "script_function_payload",
      "function": "0x1::TokenTransfers::cancel_offer_script",
      "type_arguments": [],
      "arguments": [receiver, creator, tokenCollectionNum.toString()]
    };
    return await submitTransactionHelper(account, payload);
  }

  getTokenId(String creator, String collectionName, String tokenName) async {
    final resources = await _restClient.accountResources(creator);
    dynamic collections;
    for (var resource in resources) {
      if (resource["type"] == "0x1::Token::Collections") {
        collections = await _restClient.tableItem(
          resource["data"]["collections"]["handle"],
          "0x1::ASCII::String",
          "0x1::Token::Collection",
          collectionName,
        );
        break;
      }
    }

      var tokenData = await _restClient.tableItem(
        collections["tokens"]["handle"],
        "0x1::ASCII::String",
        "0x1::Token::TokenData",
        tokenName,
      );

      return tokenData["id"]["creation_num"];
  }

}
