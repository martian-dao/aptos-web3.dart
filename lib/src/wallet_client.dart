import 'dart:convert';
import 'dart:ffi';

import 'package:bip39/bip39.dart' as bip39;
import 'package:martiandao_aptos_web3/src/token_client.dart';
import 'dart:async';
import 'account_client.dart';
import 'faucet_client.dart';
import 'rest_client.dart';

class WalletClient {
  static RestClient restClient = RestClient();
  static FaucetClient faucetClient = FaucetClient.fromRestClient(restClient);
  static TokenClient tokenClient = TokenClient.fromRestClient(restClient);

  getAccountFromMnemonic(code) {
    if (!bip39.validateMnemonic(code)) {
      throw Exception("Invalid mnemonic");
    }
    var seed = bip39.mnemonicToSeed(code);
    var account = Account.fromSeed(seed.sublist(0, 32));

    return account;
  }

  Future<Map> createWallet() async {
    var code = bip39.generateMnemonic();
    Account account = getAccountFromMnemonic(code);
    await faucetClient.fundAccount(account.authKey(), 10);
    return {"code": code, "address": account.address()};
  }

  dynamic importWallet(String code) async {
    Account account = getAccountFromMnemonic(code);
    faucetClient.fundAccount(account.authKey(), 10);
    return [{"address": account.address()}];
  }

  Future<int> getBalance(String address) async {
    var balance = await restClient.accountBalance(address);
    return balance;
  }

  Future<void> airdrop(String code, int amount) async {
    Account account = getAccountFromMnemonic(code);
    await faucetClient.fundAccount(account.authKey(), amount);
  }

  Future<void> transfer(
      String code, String recipientAddress, int amount) async {
    Account account = getAccountFromMnemonic(code);
    await restClient.transfer(account, recipientAddress, amount);
  }

  getSentEvents(String address) async {
    return await restClient.accountSentEvents(address);
  }

  getReceivedEvents(String address) async {
    return await restClient.accountReceivedEvents(address);
  }

  createNFTCollection(
      String code, String name, String description, String uri) async {
    Account account = getAccountFromMnemonic(code);
    return await tokenClient.createCollection(account, name, description, uri);
  }

  createNFT(String code, String collectionName, String name, String description,
      int supply, String uri) async {
    Account account = getAccountFromMnemonic(code);
    return await tokenClient.createToken(
        account, collectionName, name, description, supply, uri);
  }

  offerNFT(String code, String receiverAddress, String creatorAddress,
      String collectionName, String tokenName, int amount) async {
    Account account = getAccountFromMnemonic(code);
    return await tokenClient.offerToken(
        account, receiverAddress, creatorAddress, collectionName,tokenName,amount);
  }

  cancelNFTOffer(String code, String receiverAddress, String creatorAddress,
      String collectionName, String tokenName) async {
    Account account = getAccountFromMnemonic(code);
    var tokenId =
        await tokenClient.getTokenId(creatorAddress, collectionName, tokenName);
    return await tokenClient.cancelTokenOffer(account, receiverAddress, creatorAddress, tokenId);
  }

  claimNFT(String code, String senderAddress, String creatorAddress,
      String collectionName, String tokenName) async {
    Account account = getAccountFromMnemonic(code);
    return await tokenClient.claimToken(account, senderAddress, creatorAddress, collectionName, tokenName);
  }

  signGenericTransaction(String code, String functionName, List<String> args) async {
    Account account = getAccountFromMnemonic(code);
    Map payload = {
      "type": "script_function_payload",
      "function": functionName,
      "type_arguments": [],
      "arguments": args
    };

    return await tokenClient.submitTransactionHelper(account, payload);
  }

    getTokenIds(String address) async {
      var depositEvents = await restClient.getEventStream(address, "0x1::Token::TokenStore", "deposit_events");
      // var withdrawEvents = await restClient.getEventStream(address, "0x1::Token::TokenStore", "withdraw_events");
       var tokenIds = [];
        for (var elem in depositEvents) {
            tokenIds.add(elem["data"]["id"]);
        }
        
        return tokenIds; 
    }

    getTokens(String address) async {
        var tokenIds = await getTokenIds(address);
        var tokens = [];
        for (var tokenId in tokenIds) {
            var resources = await restClient.accountResources(tokenId["creator"]);
            var accountResource = resources.where((r) => r["type"] == "0x1::Token::Collections");
            var token = await restClient.tableItem(
                accountResource.first["data"]["token_data"]["handle"],
                "0x1::Token::TokenId",
                "0x1::Token::TokenData",
                tokenId,
            );
            tokens.add(token);
        }
        return tokens;        
    }

    getToken(String creator, String collectionName, String tokenName) async {
        var resources = await restClient.accountResources(creator);
        var accountResource = resources.where((r) => r["type"] == "0x1::Token::Collections");
        var token = await restClient.tableItem(
            accountResource.first["data"]["token_data"]["handle"],
            "0x1::Token::TokenId",
            "0x1::Token::TokenData",
            {
              "creator": creator,
              "collection": collectionName,
              "name": tokenName
            },
        );
        return token;      
    }

    getCollection(String address, String collectionName) async {
        var resources = await restClient.accountResources(address);
        var accountResource = resources.where((r) => r["type"] == "0x1::Token::Collections");
        var collection = await restClient.tableItem(
            accountResource.first["data"]["token_data"]["handle"],
            "0x1::ASCII::String",
            "0x1::Token::Collection",
            collectionName,
        );
        return collection;    
    }
}
