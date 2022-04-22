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

  Future<Map> importWallet(String code) async {
    Account account = getAccountFromMnemonic(code);
    faucetClient.fundAccount(account.authKey(), 10);
    return {"address": account.address()};
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
      String code, String description, String name, String uri) async {
    Account account = getAccountFromMnemonic(code);
    return await tokenClient.createCollection(account, description, name, uri);
  }

  createNFT(String code, String collectionName, String description, String name,
      int supply, String uri) async {
    Account account = getAccountFromMnemonic(code);
    return await tokenClient.createToken(
        account, collectionName, description, name, supply, uri);
  }

  offerNFT(String code, String receiverAddress, String creatorAddress,
      String collectionName, String tokenName, int amount) async {
    Account account = getAccountFromMnemonic(code);
    var tokenId =
        await tokenClient.getTokenId(creatorAddress, collectionName, tokenName);
    return await tokenClient.offerToken(
        account, receiverAddress, creatorAddress, tokenId, amount);
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
    var tokenId =
        await tokenClient.getTokenId(creatorAddress, collectionName, tokenName);
    return await tokenClient.claimToken(account, senderAddress, creatorAddress, tokenId);
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
}
