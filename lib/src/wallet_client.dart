import 'dart:convert';
import 'dart:ffi';

import 'package:bip32/bip32.dart';
import 'package:bip39/bip39.dart' as bip39;
import 'package:http/http.dart' as http;
import 'package:martiandao_aptos_web3/src/token_client.dart';
import 'package:pinenacl/ed25519.dart';
import 'dart:async';
import 'account_client.dart';
import 'faucet_client.dart';
import 'rest_client.dart';
import 'utils.dart';

class WalletClient {
  static RestClient restClient = RestClient();
  static FaucetClient faucetClient = FaucetClient.fromRestClient(restClient);
  static TokenClient tokenClient = TokenClient.fromRestClient(restClient);

  // ignore: non_constant_identifier_names
  static final COIN_TYPE = 123420;
  // ignore: non_constant_identifier_names
  static final MAX_ACCOUNTS = 5;
  // ignore: non_constant_identifier_names
  static final ADDRESS_GAP = 10;

  Map<String, Account> accountCache = {};

  getAccountFromMnemonic(code) {
    if (!bip39.validateMnemonic(code)) {
      throw Exception("Invalid mnemonic");
    }
    var seed = bip39.mnemonicToSeed(code);
    BIP32 node = BIP32.fromSeed(seed);
    BIP32 exKey = node.derivePath("m/44'/$COIN_TYPE'/0'/0/0");
    var account = Account.fromSeed(exKey.privateKey!);
    return account;
  }

  getAccountFromMetaData(code, metaData) {
    if (!bip39.validateMnemonic(code)) {
      throw Exception("Invalid mnemonic");
    }
    var cacheKey = "${metaData['address']}-${metaData['derivationPath']}";
    if(accountCache.containsKey(cacheKey)){
      print("getting account form cache");
      return accountCache[cacheKey];
    }

    var seed = bip39.mnemonicToSeed(code);
    BIP32 node = BIP32.fromSeed(seed);
    BIP32 exKey = node.derivePath(metaData['derivationPath']);
    var account = Account.fromSeed(exKey.privateKey!, metaData['address']);
    accountCache[cacheKey] = account;
    return account;
  }

  FutureOr<Map<String, String>> createNewAccount(String code) async {
    Uint8List seed = bip39.mnemonicToSeed(code);
    BIP32 node = BIP32.fromSeed(seed);

    for (var i = 0; i < MAX_ACCOUNTS; i++) {
      var derivationPath = "m/44'/$COIN_TYPE'/$i'/0/0";
      BIP32 exKey = node.derivePath(derivationPath);
      Account acc = Account.fromSeed(exKey.privateKey!);
      var address = acc.authKey().toString();
      var url = "$testUrl/accounts/$address";
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 404) {
        continue;
      }
      await faucetClient.fundAccount(acc.authKey(), 0);
      return {"derivationPath": derivationPath, "address": address};
    }

    throw Exception("Max no. of accounts reached");
  }

  Future<Map> createWallet() async {
    var code = bip39.generateMnemonic();
    var accountMetadata = await createNewAccount(code);
    return {
      "code": code,
      "accounts": [accountMetadata]
    };
  }

  Future<Map> importWallet(String code) async {
    if (!bip39.validateMnemonic(code)) {
      throw Exception("Incorrect mnemonic passed");
    }
    Uint8List seed = bip39.mnemonicToSeed(code);
    BIP32 node = BIP32.fromSeed(seed);
    var accountMetaData = [];
    for (var i = 0; i < MAX_ACCOUNTS; i++) {
      bool flag = false;
      String address = "";
      String derivationPath = "";
      String authKey = "";

      for (var j = 0; j < ADDRESS_GAP; j++) {
        BIP32 exKey = node.derivePath("m/44'/$COIN_TYPE'/$i'/0/$j");
        Account acc = Account.fromSeed(exKey.privateKey!);

        if (j == 0) {
          address = acc.authKey().toString();
          var url = "$testUrl/accounts/$address";
          final response = await http.get(Uri.parse(url));
          if (response.statusCode == 404) {
            break;
          }
          var respBody = jsonDecode(response.body);
          authKey = respBody["authentication_key"];
        }

        acc = Account.fromSeed(exKey.privateKey!, address);
        if ("0x${acc.authKey().toString()}" == authKey) {
          flag = true;
          derivationPath = "m/44'/$COIN_TYPE'/$i'/0/$j";
          break;
        }
      }

      if (!flag) {
        break;
      }

      accountMetaData
          .add({"derivationPath": derivationPath, "address": address});
    }

    return {"code": code, "accounts": accountMetaData};
  }

  rotateAuthKey(code, metaData) async {
    Account account = await getAccountFromMetaData(code, metaData);
    var pathSplit = metaData['derivationPath'].split("/");
    var addressIndex = int.parse(pathSplit.last);
    if (addressIndex >= ADDRESS_GAP - 1) {
      throw Exception("Maximum key rotation reached");
    }
    var newDerivationPath =
        "${pathSplit.sublist(0, pathSplit.length - 1).join('/')}/${addressIndex + 1}";
    Account newAccount = await getAccountFromMetaData(code,
        {"address": metaData["address"], "derivationPath": newDerivationPath});

    var newAuthKey = newAccount.authKey().toString().split("0x").last;
    print(newAuthKey);
    return await signGenericTransaction(
        account, "0x1::Account::rotate_authentication_key", [newAuthKey]);
  }


  Future<int> getBalance(String address) async {
    var balance = await restClient.accountBalance(address);
    return balance;
  }

  Future<void> airdrop(Account account, int amount) async {
    await faucetClient.fundAccount(account.authKey(), amount);
  }

  Future<void> transfer(
      Account account, String recipientAddress, int amount) async {
    await restClient.transfer(account, recipientAddress, amount);
  }

  getSentEvents(String address) async {
    return await restClient.accountSentEvents(address);
  }

  getReceivedEvents(String address) async {
    return await restClient.accountReceivedEvents(address);
  }

  createNFTCollection(
      Account account, String name, String description, String uri) async {
    return await tokenClient.createCollection(account, name, description, uri);
  }

  createNFT(Account account, String collectionName, String name,
      String description, int supply, String uri) async {
    return await tokenClient.createToken(
        account, collectionName, name, description, supply, uri);
  }

  offerNFT(Account account, String receiverAddress, String creatorAddress,
      String collectionName, String tokenName, int amount) async {
    return await tokenClient.offerToken(account, receiverAddress,
        creatorAddress, collectionName, tokenName, amount);
  }

  cancelNFTOffer(Account account, String receiverAddress, String creatorAddress,
      String collectionName, String tokenName) async {
    var tokenId =
        await tokenClient.getTokenId(creatorAddress, collectionName, tokenName);
    return await tokenClient.cancelTokenOffer(
        account, receiverAddress, creatorAddress, tokenId);
  }

  claimNFT(Account account, String senderAddress, String creatorAddress,
      String collectionName, String tokenName) async {
    return await tokenClient.claimToken(
        account, senderAddress, creatorAddress, collectionName, tokenName);
  }

  signGenericTransaction(
      Account account, String functionName, List<String> args) async {
    Map payload = {
      "type": "script_function_payload",
      "function": functionName,
      "type_arguments": [],
      "arguments": args
    };

    return await tokenClient.submitTransactionHelper(account, payload);
  }

  getTokenIds(String address) async {
    var depositEvents = await restClient.getEventStream(
        address, "0x1::Token::TokenStore", "deposit_events");
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
      var accountResource =
          resources.where((r) => r["type"] == "0x1::Token::Collections");
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
    var accountResource =
        resources.where((r) => r["type"] == "0x1::Token::Collections");
    var token = await restClient.tableItem(
      accountResource.first["data"]["token_data"]["handle"],
      "0x1::Token::TokenId",
      "0x1::Token::TokenData",
      {"creator": creator, "collection": collectionName, "name": tokenName},
    );
    return token;
  }

  getCollection(String address, String collectionName) async {
    var resources = await restClient.accountResources(address);
    var accountResource =
        resources.where((r) => r["type"] == "0x1::Token::Collections");
    var collection = await restClient.tableItem(
      accountResource.first["data"]["token_data"]["handle"],
      "0x1::ASCII::String",
      "0x1::Token::Collection",
      collectionName,
    );
    return collection;
  }
}
